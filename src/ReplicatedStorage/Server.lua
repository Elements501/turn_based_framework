local Server = {}
Server.__index = Server

-- Services
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local PS: Players = game:GetService("Players")

-- Data
local GAME_DATA: {[string]: {}} = require(RS:WaitForChild("GameData"))
local unitTypes: GAME_DATA.UnitType = GAME_DATA.unitTypes
local MACROS: GAME_DATA.Macros = GAME_DATA.MACROS

-- Shared
local SHARED_LIST: {[string]: {}} = require(RS:WaitForChild("SharedList"))
local sharedList: SHARED_LIST.SharedList = SHARED_LIST

-- Package
local FH = require(RS:WaitForChild("FunctionHandler"))
local Unit = require(RS:WaitForChild("Unit"))

function Server.new()
    return setmetatable({ idCounter = 1 }, Server)
end

function Server.ServerScript()
    Server.new():Init()
end

function Server:Init()
    task.spawn(function() self:InitialiseEnemy() end)
    task.spawn(function() self:StartGame() end)
end

function Server:InitialiseEnemy()
    task.wait(0.5)
    self:SummonUnit(2, "Enemy", "ai")
    self:SummonUnit(2, "Ally", "FireAlexGame")
    self:SummonUnit(2, "Ally", "FireAlexGame")
end

function Server:StartGame()
    task.wait(1)
    self:OrderUnits({})
    self:RoundCounter()
end

function Server:OrderUnits(data: {})
    local function ChangeOrder(mode: number)
        local unitId: number = data.unit
        if unitId == nil then warn("Unknown Unit Deleted") return end

        local unitOrder: number = table.find(sharedList.actionOrder, unitId)
        if unitOrder == nil then warn("Unknown Unit Order") return end

        if unitOrder < sharedList.actionNumber then
            sharedList.actionNumber += mode
        end
    end

    if data.mode == -1 then ChangeOrder(-1) end

    local dexList = {}
    for unitId, unitData in pairs(sharedList.unitList) do
        table.insert(dexList, {
            Id = unitId,
            Speed = unitData.Speed
        })
    end
    if #dexList == 0 then warn("No Units Found") return end

    table.sort(dexList, function(a, b)
        if a.Speed == b.Speed then return a.Id < b.Id else return a.Speed > b.Speed end
    end)

    local orderedList = {}
    for _, unitData in ipairs(dexList) do
        table.insert(orderedList, unitData.Id)
    end
    sharedList.actionOrder = orderedList

    if data.mode == 1 then ChangeOrder(1) end
end

function Server:RoundCounter()
    local serializedUnitList = {}
    for id, unit in pairs(sharedList.unitList) do
        serializedUnitList[id] = unit:Serialize()
    end

    for _, plr in ipairs(PS:GetPlayers()) do
        FH.ClientMessage({
            action = MACROS.DISPLAY_ORDER,
            send = 0,
            receive = plr,
            unitList = serializedUnitList,
            actionOrder = sharedList.actionOrder,
            actionNumber = sharedList.actionNumber,
        })
    end

    if sharedList.actionNumber > sharedList.totalUnits then
        sharedList.roundNumber += 1
        sharedList.actionNumber = 1

        task.wait(1)
        print("Next Round")
        self:RoundCounter()
    else
        local nextId = sharedList.actionOrder[sharedList.actionNumber]
        sharedList.actionNumber += 1
        local nextUnit = sharedList.unitList[nextId]
        if nextUnit then task.spawn(function() nextUnit:Action() end) end
    end
end

function Server:SummonUnit(unitTypeNum: number, team: string, owner: string | Player)
    if unitTypes[unitTypeNum] == nil then warn("Out of Range: ", unitTypeNum) return end

    local part: Instance = Instance.new("Part")
    part.Parent = game.Workspace
    part.Position = Vector3.new(0, 0, self.idCounter * 5)

    local dataList = GAME_DATA.unitTypes[unitTypeNum]
    dataList.Team = team
    dataList.Owner = owner
    dataList.Id = self.idCounter
    dataList.Instance = part

    local unit = Unit.new(dataList)
    unit:Init(self)

    self:OrderUnits({ unit = self.idCounter, mode = 1 })
    self.idCounter += 1
end

function Server:RemoveUnit(unitId: number)
    self:OrderUnits({ unit = unitId, mode = -1 })

    table.remove(sharedList.actionOrder, table.find(sharedList.actionOrder, unitId))
    sharedList.unitList[unitId] = nil
    sharedList.totalUnits -= 1
end

return Server
