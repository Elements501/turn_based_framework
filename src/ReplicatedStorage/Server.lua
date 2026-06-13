local module = {}
-- Services
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local PS: Players = game:GetService("Players")
local SELF: ModuleScript = RS:WaitForChild("Server")
local UNIT: ModuleScript = RS:WaitForChild("Unit")

-- Data
local GAME_DATA: {[string]: {}} = require(RS:WaitForChild("GameData"))
local attackActions: GAME_DATA.AttackAction = GAME_DATA.attackActions
local unitTypes: GAME_DATA.UnitType = GAME_DATA.unitTypes
local MACROS: GAME_DATA.Macros = GAME_DATA.MACROS

-- Shared
local SHARED_LIST: {[string]: {}} = require(RS:WaitForChild("SharedList"))
local sharedList: SHARED_LIST.SharedList = SHARED_LIST

-- Package
local FH = require(RS:WaitForChild("FunctionHandler"))

function module.ServerScript()
    -- Server Initialisation -- TODO: Repeatable: can activate / reset by cmd
    local idCounter: number = 1

    local function InitialiseEnemy() -- Create enemies for start of level
        local function SpawnUnit(type: number, team: string, owner: Player | string): ()
        FH.ServerMessage({
            action = MACROS.SUMMON_UNIT,
            send = 0,
            receive = 0,
            unitTypeNum = type,
            unitTeam = team,
            unitOwner = owner,
        })
        end

        task.wait(0.5) -- Wait for all the require
        SpawnUnit(1, "Enemy", "ai")
        SpawnUnit(2, "Ally", "FireAlexGame")
        SpawnUnit(3, "Ally", "FireAlexGame")
        SpawnUnit(4, "Ally", "FireAlexGame")
    end
    task.spawn(InitialiseEnemy)

    local function StartGame()
        task.wait(1) -- Wait for everything to spawn in
        FH.ServerMessage({ -- Order Units
            action = MACROS.ORDER_UNITS,
            send = 0,
            receive = 0,
        })
        FH.ServerMessage({ -- Start Game
            action = MACROS.ROUND_COUNTER,
            send = 0,
            receive = 0,
        })
    end
    task.spawn(StartGame)

    -- Server Actions
    local function OrderUnits(data)

        local function ChangeOrder(mode: number) -- To prevent skip over next unit
            local unitId: number = data.unit
            if unitId == nil then warn("Unknown Unit Deleted") return end

            if table.find(sharedList.actionOrder, unitId) < sharedList.actionNumber then -- Unit act before now
                sharedList.actionNumber += mode -- Consider summoned acted
            end
        end
        if data.mode == -1 then ChangeOrder(-1) end -- Unit Removed

        local dexList = {}
        for unitId, unitList in pairs(sharedList.unitList) do
            table.insert(dexList, {
                Unit = unitId,
                Spd = unitList.Speed
            })
        end
        if #dexList == 0 then warn("No Units Found") return {Error = "Order"} end

        table.sort(dexList, function(a, b)
            return a.Spd > b.Spd
        end)

        local orderedList = {}
        for _, unitData in ipairs(dexList) do
            table.insert(orderedList, unitData.Unit)
        end
        sharedList.actionOrder = orderedList

        if data.mode == 1 then ChangeOrder(1) end -- Unit Added
    end

    local function RoundCounter()
        if sharedList.actionNumber > sharedList.totalUnits then -- Next round
            sharedList.roundNumber += 1
            sharedList.actionNumber = 1

            task.wait(1)
            print("Next Round")
            FH.ServerMessage({
                action = MACROS.ROUND_COUNTER,
                send = 0,
                receive = 0,
            })
        else -- Next unit
            FH.ServerMessage({
                action = MACROS.UNIT_ACTION,
                send = 0,
                receive = sharedList.actionOrder[sharedList.actionNumber],
            })
            sharedList.actionNumber += 1
        end
    end

    local function RemoveUnit(data)
        FH.ServerMessage({
            action = MACROS.ORDER_UNITS,
            send = 0,
            receive = 0,
            unit = data.send, -- Prevent skip over next unit
            mode = -1, -- Delete
        })

        table.remove(sharedList.actionOrder, table.find(sharedList.actionOrder, data.send)) -- Remove order
        sharedList.unitList[data.send] = nil -- Remove stats
        sharedList.totalUnits -= 1
    end

    local function SummonUnit(data)
        local unitNum: number = (data.skillList and data.skillList.Damage) or data.unitTypeNum
        if unitNum == nil then warn("Unknown Unit Number: ", data) return end

        if unitTypes[unitNum] == nil then warn("Out of Range: ", unitNum) return end -- No unit existed in list

        local unitTeam = data.unitTeam or sharedList.unitList[data.send].Team -- Summoned: .Team (same team); Server: .unitTeam
        if unitTeam == nil then warn("Unknown Team") return end
        local unitOwner = data.unitOwner or sharedList.unitList[data.send].Owner -- Summoned: .Owner (same); Server: .unitOwner
        if unitOwner == nil then warn("Unknown Owner") return end

        local dataList = {
            unitTypeNum = unitNum,
            Team = unitTeam,
            Owner = unitOwner,
        }
        local part: Instance = Instance.new("Part")
        part.Parent = game.Workspace
        part.Position = Vector3.new(0, 0, idCounter * 5)

        require(UNIT).UnitScript(part, dataList, idCounter)

        FH.ServerMessage({
            action = MACROS.ORDER_UNITS,
            send = 0,
            receive = 0,
            unit = idCounter, -- For counter to know which unit is summoned, prevent same unit run twice
            mode = 1, -- add
        })
        idCounter += 1
        return
    end

    -- Handler
    FH.RegisterServer(0, MACROS.ROUND_COUNTER, RoundCounter)
    FH.RegisterServer(0, MACROS.ORDER_UNITS, OrderUnits)
    FH.RegisterServer(0, MACROS.SUMMON_UNIT, SummonUnit)
    FH.RegisterServer(0, MACROS.REMOVE_UNIT, RemoveUnit)

end

return module