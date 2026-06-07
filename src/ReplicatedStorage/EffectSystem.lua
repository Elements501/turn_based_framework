local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local FH = require(RS:WaitForChild("FunctionHandler"))

local EffectSystem = {}
EffectSystem.__index = EffectSystem

export type EffectSystemType = {
    unit: {},
    unitUI: {},
    id: number,
    effectId: number,
    GetEffect: (self: EffectSystemType, key: string) -> number?,
    ApplyEffect: (self: EffectSystemType, data: {}) -> (),
    DecreaseEffectDuration: (self: EffectSystemType) -> (),
    ExecuteEffect: (self: EffectSystemType) -> (),
}


function EffectSystem.new(unit: {}, unitUI: {}, id: number)
    return setmetatable({
        unit     = unit,
        unitUI   = unitUI,
        id       = id,
        effectId = 1,
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

    local newEffect: Frame = self.unitUI[6]:Clone()
    newEffect.Name = effect.Name
    newEffect.Parent = self.unitUI[5]
    newEffect.EffectText.Text = effect.Duration
    -- TODO: Set newEffect.EffectImage

    if next(self.unit.Effect) == nil then self.unit.Effect = {} end
    effect.EffectId = self.effectId
    self.unitUI[7][self.effectId] = newEffect
    self.effectId += 1

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
        self.unitUI[7][effect.EffectId].EffectText.Text = effect.Duration

        if effect.Duration == 0 then
            self.unitUI[7][effect.EffectId]:Destroy()
            self.unitUI[7][effect.EffectId] = nil
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
                action = 4,
                send = self.id,
                receive = self.id,
                skillList = { Nature = 3, Damage = dmg },
            })
        end)

        task.spawn(function() -- Heal
            local heal: number? = effect.HealConst
            if heal == nil and effect.HealPercent == nil then return end -- TODO: HealPercent-only heal
            FH.ServerMessage({
                action = 4,
                send = self.id,
                receive = self.id,
                skillList = { Nature = 3, Damage = -heal },
            })
        end)
    end
end

return EffectSystem
