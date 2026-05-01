local module = {}
-- Services
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local SELF: ModuleScript = RS:WaitForChild("Unit")

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
local nextAction: BindableFunction = (RS:FindFirstChild("nextAction") :: BindableFunction?) or Instance.new("BindableFunction")
    nextAction.Name = "nextAction"
    nextAction.Parent = RS
local actionFuncList = {}

function module.Init(part: Instance, id: number)
    -- Initialisation
    if id == 0 then -- Server scripts: id == 0
        require(SELF).ServerScript()
        return
    end

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

    nextAction:Invoke({
        action = 5,
        send = id,
        receive = 0,
    })

    -- Unit Action
    local function Act()
        print("Actioned: " .. id, sharedList)
        task.wait(1)
        nextAction:Invoke({
            action = 1,
            send = id,
            receive = 0,
        })
    end

    actionFuncList[id] = function(data)
        if data.receive ~= id then return end -- Not for this unit
        -- Execute server actions
        local function executeFunction(func)
            task.spawn(function()
                local result = func()
                if type(result) == table then if result.Error then warn(result.Error) end end
            end)
        end

        if (data.action == 7) then executeFunction(Act) end
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
        nextAction:Invoke({ -- Start Game
            action = 0,
            send = 0,
            receive = 0,
        })
    end
    task.spawn(FindUnits)

    -- Server Actions
     local function OrderUnits(): (boolean | table)
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

        nextAction:Invoke({
            action = 1,
            send = 0,
            receive = 0,
        })
    end

    local function RoundCounter(): (boolean | table)
        if sharedList.actionNumber > sharedList.totalUnits then
            sharedList.roundNumber += 1
            sharedList.actionNumber = 1
            print("Next Round")
            nextAction:Invoke({
                action = 1,
                send = 0,
                receive = 0,
            })
        else
            print("Server Action", sharedList)
            nextAction:Invoke({
                action = 7,
                send = 0,
                receive = sharedList.actionOrder[sharedList.actionNumber],
            })
            sharedList.actionNumber += 1
        end
    end

    -- Direct to correct function
    nextAction.OnInvoke = function(data)
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

        elseif actionFuncList[data.receive] then -- Unit
            actionFuncList[data.receive](data)
        end
    end

end

return module