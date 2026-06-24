local PS = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Data
local GAME_DATA: {[string]: {}} = require(RS:WaitForChild("GameData"))
local MACROS: GAME_DATA.Macros = GAME_DATA.MACROS

-- Package
local FH = require(RS:WaitForChild("FunctionHandler"))

local EffectSystem = {}
EffectSystem.__index = EffectSystem

export type EffectSystemType = {
    unit: {},
    unitUI: {}, -- UnitUI.lua
    id: number,
    GetEffect: (self: EffectSystemType, key: string) -> number?,
    ApplyEffect: (self: EffectSystemType, data: {}) -> (),
    DecreaseEffectDuration: (self: EffectSystemType) -> (),
    ExecuteEffect: (self: EffectSystemType) -> (),
}

function EffectSystem.new(unit: {}, unitUI: {}, id: number)
    return setmetatable({
        unit = unit,
        unitUI = unitUI,
        id = id,
    }, EffectSystem)
end

function EffectSystem:GetEffect(key: string): number? -- Get sum of the value of the effect variable
    local num: number? = nil
    for _, effect in pairs(self.unit.Effect) do
        if effect and effect[key] then num = (num or 0) + effect[key] end
    end
    return num
end

function EffectSystem:ApplyEffect(existingEffect: boolean, effect: {}, attacker: {}) -- effect is always single
    if next(self.unit.Effect) == nil then self.unit.Effect = {} end
    effect.EffectId = self.unitUI:AddEffect(effect) -- effect passed by reference, changes is made to Unit
    effect.OwnerId = attacker.Id

    if not existingEffect then -- Effects that exist with the unit
        table.insert(self.unit.Effect, effect)
    end
end

function EffectSystem:DecreaseEffectDuration()
    local effectList = self.unit.Effect
    if not next(effectList) then return end

    for effectNumber, effect in pairs(effectList) do
        if not effect then continue end

        effect.Duration -= 1 -- TODO: Duration == -1 for infinite
        self.unitUI:UpdateEffect(effect.EffectId, effect.Duration)

        if effect.Duration == 0 then
            self.unitUI:RemoveEffect(effect.EffectId)
            effectList[effectNumber] = nil
        end
    end
end

function EffectSystem:ExecuteEffect()
    local effectList = self.unit.Effect
    if not next(effectList) then return end

    for _, effect in pairs(effectList) do
        if effect.Duration <= 0 then effect.Duration = 0 return end -- TODO: Change when .Duration = -1

        if effect.EffectId == nil then -- Pre-existing effect from unit spawn
            self:ApplyEffect(true, effect, self.unit)
        end

        task.spawn(function() -- Damage
            local dmg: number? = effect.Damage
            if dmg == nil then return end
            self.unit:TakeDamage(effect.OwnerId, { Name = effect.Name, Nature = 3, Damage = dmg })
        end)

        task.spawn(function() -- Heal
            local heal: number? = effect.HealConst
            if heal == nil and effect.HealPerc == nil then return end -- TODO: HealPercent-only heal
            self.unit:TakeDamage(effect.OwnerId, { Name = effect.Name, Nature = 3, Damage = -heal })
        end)
    end
end

return EffectSystem
