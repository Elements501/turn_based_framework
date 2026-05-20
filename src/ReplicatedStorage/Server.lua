local module = {}
-- Services
local Players = game:GetService("Players")
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local SELF: ModuleScript = RS:WaitForChild("Server")

-- Variables
local sharedList = {
    -- Units
    totalUnits = 0,
    unitList = {},
    teamList = {}, -- List of existing teams
    -- Rounds
    roundNumber = 0,
    actionOrder = {}, -- Down the id number
    actionNumber = 1, -- Which unit gets to act
}

-- Data
local attackActionList = {
    Test1 = {
        Punch = { Damage = 5, Target = -1, Effect = {} },
        Stab = { Damage = 10, Target = 1, Effect = {} },
        Kick = { Damage = 5, Target = 1, Effect = {} }
    }
}

local serverAction: BindableFunction = (RS:FindFirstChild("ServerAction") :: BindableFunction?) or Instance.new("BindableFunction")
    serverAction.Name = "ServerAction"
    serverAction.Parent = RS
local serverFuncList = {}
local clientAction: RemoteFunction = (RS:FindFirstChild("ClientAction") :: RemoteFunction?) or Instance.new("RemoteFunction")
    clientAction.Name = "ClientAction"
    clientAction.Parent = RS
local clientFuncList = {}

function module.Init(part: Instance, id: number)
    -- Initialisation
    if id == 0 then -- Server scripts: id == 0
        require(SELF).ServerScript()
    else
        require(SELF).UnitScript(part, id)
    return end
end

function module.UnitScript(part: Instance, id: number)
    -- Initialisation
    local function updateList() -- Check in onto the sharedList as a Unit
        local unit = part -- DEMO: Change in case of using Models
        -- Validation
        local attrList = unit:GetAttributes(); if not attrList then warn("Unknown Unit") return end

        local attrFormat = {
            -- Stats
            Strength = "number",
            Dexerity = "number",
            Intelligence = "number",
            Vitality = "number",
            Charisma = "number",
            -- Rounds
            Team = "string",
            Name = "string",
            Owner = "string",
        }
        for key, attrType in pairs(attrFormat) do -- Ensure attributes list are correct
            if attrList[key] == nil then warn("Missing Attributes: " .. key .. attrType) return false end
            if typeof(attrList[key]) ~= attrType then warn("Wrong Attributes Typing") return false end
        end

        -- Check In
        sharedList.unitList[id] = attrList
        sharedList.totalUnits += 1

        if not table.find(sharedList.teamList, attrList.Team) then -- Insert teamList
            table.insert(sharedList.teamList, attrList.Team)
        end

        return true
    end
    if not updateList() then warn("Failed to Check In") return end -- Run check in with False -> ERROR

    serverAction:Invoke({
        action = 5,
        send = id,
        receive = 0,
    })

    -- Unit Action
    local function FinishAction()
        serverAction:Invoke({
            action = 1,
            send = id,
            receive = 0,
        })
    end

    local function AttackAction()
        local unit = sharedList.unitList[id]
        local plrOwner: Player = game:GetService("Players"):FindFirstChild(unit.Owner)
        if not plrOwner then warn("Unknown Player Action") return end

        if attackActionList[unit.Name] == nil then warn("Unknown Attack Action") return end

        -- Obtain Enemies
        local enemyList = {}
        for _, enemy in pairs(sharedList.unitList) do
            if enemy.Team == unit.Team then continue end
            table.insert(enemyList, enemy)
        end

        clientAction:InvokeClient(plrOwner, {
            action = 4,
            send = id,
            receive = plrOwner,
            -- Skill
            Name = unit.Name,
            enemyList = enemyList
        })
    end

    local function botAction()
        -- Smart Action
        task.wait(1)
        FinishAction()
    end

    local function Action()
        local unit = sharedList.unitList[id]
        print("Actioned: " .. id, sharedList, unit.Owner)

        if unit.Owner == "ai" then
            botAction()
            return
        end

        local plrOwner: Player = game:GetService("Players"):FindFirstChild(unit.Owner)
        if not plrOwner then warn("Unknown Player Action") return end
        clientAction:InvokeClient(plrOwner, {
            action = 1,
            send = id,
            receive = plrOwner,
            unitData = unit
        })
    end

    serverFuncList[id] = function(data)
        if data.receive ~= id then return end -- Not for this unit

        local function executeFunction(func)
            task.spawn(function()
                local result = func()
                if type(result) == table then if result.Error then warn(result.Error) end end
            end)
        end

        if (data.action == 7) then executeFunction(Action) end
    end

    clientFuncList[id] = function(data)
        if data.receive ~= id then return end

        local function executeFunction(func)
            task.spawn(function()
                local result = func()
                if type(result) == table then if result.Error then warn(result.Error) end end
            end)
        end

        if (data.action == 2) then executeFunction(FinishAction) end -- Rest
        if (data.action == 3) then executeFunction(AttackAction) end
    end
end

function module.ServerScript()
    -- Server Initialisation -- TODO: Repeatable: can activate / reset by cmd
    local function FindUnits()
        local possibleUnits: {Instance} = game:GetService("Workspace").Game:GetChildren()
        for _, obj in ipairs(possibleUnits) do
            require(SELF).Init(obj, sharedList.totalUnits + 1)
        end

        task.wait(3) -- TEMP: Wait for all instances to check in
        -- TODO: Can get a number of total units, wait until totalUnits == #UnitNumGiven
        serverAction:Invoke({ -- Start Game
            action = 0,
            send = 0,
            receive = 0,
        })
    end
    task.spawn(FindUnits)

    -- Server Actions
    local function TransferData(data)
        if ( not data.send:IsA("Player") ) then warn("Wrong Data Passed") end -- data.send should be Player, special
        clientAction:InvokeClient(data.send, {
            action = -1,
            send = 0,
            receive = data.send,
            dataList = {
                ["attackActionList"] = attackActionList
            }
        })
    end

     local function OrderUnits()
        local dexList = {}
        for unitId, unitList in pairs(sharedList.unitList) do
            table.insert(dexList, {
                Unit = unitId,
                Dex = unitList.Dexerity
            })
        end
        if #dexList == 0 then warn("No Units Found") return {Error = "Order"} end

        table.sort(dexList, function(a, b)
            return a.Dex > b.Dex
        end)

        local orderedList = {}
        for _, unitData in ipairs(dexList) do
            table.insert(orderedList, unitData.Unit)
        end
        sharedList.actionOrder = orderedList

        serverAction:Invoke({
            action = 1,
            send = 0,
            receive = 0,
        })
    end

    local function RoundCounter()
        if sharedList.actionNumber > sharedList.totalUnits then
            sharedList.roundNumber += 1
            sharedList.actionNumber = 1
            print("Next Round")
            serverAction:Invoke({
                action = 1,
                send = 0,
                receive = 0,
            })
        else
            print("Server Action", sharedList)
            serverAction:Invoke({
                action = 7,
                send = 0,
                receive = sharedList.actionOrder[sharedList.actionNumber],
            })
            sharedList.actionNumber += 1
        end
    end

    -- Direct to correct function
    serverAction.OnInvoke = function(data)
        if data.receive == 0 then -- Server
            -- Execute server actions
            local function executeFunction(func)
                task.spawn(function()
                    local result = func()
                    if type(result) == table then if result.Error then warn(result.Error) end end
                end)
            end

            if (data.action == 0 or data.action == 3) then executeFunction(OrderUnits) end
            if (data.action == 1) then executeFunction(RoundCounter) end

        elseif serverFuncList[data.receive] then -- Unit
            serverFuncList[data.receive](data)
        end
    end

    clientAction.OnServerInvoke = function(plr, data)
        if data.receive == 0 then -- Server
            -- Client to Sever direct
            local function executeFunction(func)
                task.spawn(function()
                    local result = func()
                    if type(result) == table then if result.Error then warn(result.Error) end end
                end)
            end

            if (data.action == -1) then executeFunction(function() return TransferData(data) end) end

        elseif clientFuncList[data.receive] then -- Unit
            clientFuncList[data.receive](data)
        end
    end

end

return module