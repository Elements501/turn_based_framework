local BotSystem = {}
BotSystem.__index = BotSystem

export type BotSystemType = {
    unit: {},
    id: number,
    attackActions: {},
    ChooseAction: (self: BotSystemType, sharedList: {}) -> { skillList: {}, target: (number | {number})? }?,
}

function BotSystem.new(unit: {}, attackActions: {}, id: number)
    return setmetatable({ -- Get sum of the value of the effect variable -- Damage -- Heal
        unit = unit,
        id = id,
        attackActions = attackActions,
    }, BotSystem)
end

function BotSystem:ChooseAction(sharedList: {}): { skillList: {}, target: (number | {number})? }?
    local enemyIdList: {number} = {}
    local allyIdList: {number} = {}

    for _, checked in pairs(sharedList.unitList) do
        if checked == nil then continue end
        if checked.Team ~= self.unit.Team then
            table.insert(enemyIdList, checked.Id)
        else
            table.insert(allyIdList, checked.Id)
        end
    end

    local attackList: {number} = self.unit.Skills
    local attackAction = self.attackActions[attackList[math.random(1, #attackList)]]

    if attackAction.Target == 1 then
        return { skillList = attackAction, target = enemyIdList[math.random(1, #enemyIdList)] }
    elseif attackAction.Target == 2 then
        return { skillList = attackAction, target = allyIdList[math.random(1, #allyIdList)] }
    elseif attackAction.Target == -1 then
        return { skillList = attackAction, target = enemyIdList }
    elseif attackAction.Target == 0 then
        return { skillList = attackAction, target = nil }
    end

    warn("Unknown Target Range:", attackAction.Target)
    return nil
end

return BotSystem
