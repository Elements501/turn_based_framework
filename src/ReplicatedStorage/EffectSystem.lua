local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local FH = require(RS:WaitForChild("FunctionHandler"))

local EffectSystem = {}
EffectSystem.__index = EffectSystem

local GAME_DATA: {[string]: {}} = require(RS:WaitForChild("GameData"))
type Macros = GAME_DATA.Macros
local MACROS: Macros = GAME_DATA.MACROS

export type EffectSystemType = {
    unit: {},
    unitUI: {}, -- UiSystem.lua
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

function EffectSystem:ApplyEffect(data)
    local effect = data.skillList.Effect
    if effect == nil then return end

    if next(self.unit.Effect) == nil then self.unit.Effect = {} end
    effect.EffectId = self.unitUI:AddEffect(effect)

    if not data.selfApply then table.insert(self.unit.Effect, effect) end
end

function EffectSystem:DecreaseEffectDuration()
    local effectList = self.unit.Effect
    if not next(effectList) then return end

    for effectNumber, effect in pairs(effectList) do
        if not effect then continue end

        if effect.EffectId == nil then -- Pre-existing effect from unit spawn
            self:ApplyEffect({ selfApply = true, skillList = { Effect = effect } })
        end

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

    for _, effect in ipairs(effectList) do
        if effect.Duration <= 0 then effect.Duration = 0 return end
        print("Effect Executed", self.id, effect)

        task.spawn(function() -- Damage
            local dmg: number? = effect.Damage
            if dmg == nil then return end
            FH.ServerMessage({
                action = MACROS.TAKE_DAMAGE,
                send = self.id,
                receive = self.id,
                skillList = { Nature = 3, Damage = dmg },
            })
        end)

        task.spawn(function() -- Heal
            local heal: number? = effect.HealConst
            if heal == nil and effect.HealPerc == nil then return end -- TODO: HealPercent-only heal
            FH.ServerMessage({
                action = MACROS.TAKE_DAMAGE,
                send = self.id,
                receive = self.id,
                skillList = { Nature = 3, Damage = -heal },
            })
        end)
    end
end

return EffectSystem
