local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local GAME_DATA: {[string]: {}} = require(RS:WaitForChild("GameData"))
local attackActions: GAME_DATA.AttackAction = GAME_DATA.attackActions
local MACROS: GAME_DATA.Macros = GAME_DATA.MACROS

local BotSystem = {}
BotSystem.__index = BotSystem

export type BotSystemType = {
    unit: {},
    id: number,
    ChooseAction: (self: BotSystemType, sharedList: {}) -> { skillList: {}, target: (number | {number})? }?,
}

function BotSystem.new(unit: {}, id: number)
    return setmetatable({
        unit = unit,
        id = id,
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

    -- Remove attacks with insufficient energy
    for key, attackNum in pairs(attackList) do
        if self.unit.Energy < attackActions[attackNum].Energy then table.remove(attackList, key) end
    end
    local attackAction = attackActions[attackList[math.random(1, #attackList)]]

    if not next(enemyIdList) then warn("All Enemies Died") return end
    if not next(allyIdList) then warn("All Allies Died") return end

    if attackAction.Target == "SingleEnemy" then
        return { skillList = attackAction, target = enemyIdList[math.random(1, #enemyIdList)] }
    elseif attackAction.Target == "SingleAlly" then
        return { skillList = attackAction, target = allyIdList[math.random(1, #allyIdList)] }
    elseif attackAction.Target == "AllEnemy" then
        return { skillList = attackAction, target = enemyIdList }
    elseif attackAction.Target == "AllAlly" then
        return { skillList = attackAction, target = allyIdList }
    elseif attackAction.Target == "Summon" then
        return { skillList = attackAction, target = nil }
    end

    warn("Unknown Target Range:", attackAction.Target)
    return nil
end

return BotSystem
