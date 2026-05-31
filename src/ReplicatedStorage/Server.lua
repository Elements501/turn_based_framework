local module = {}
-- Services
local Players = game:GetService("Players")
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local SELF: ModuleScript = RS:WaitForChild("Server")

-- Variables
local sharedList = {
    -- Units
    totalUnits = 0,
    unitList = {},
    -- Rounds
    roundNumber = 0,
    actionOrder = {}, -- Down the id number
    actionNumber = 1, -- Which unit gets to act
}

-- Data
local attackActionList = {
    [1] =   { Name = "Scream",   Damage = 2,   Target = -1,  Effect = {} },
    [2] =   { Name = "Stab",    Damage = 5,  Target = 1,   Effect = {} },
    [3] =   { Name = "Bump",    Damage = 3,   Target = 1,   Effect = {} },
    [4] =   { Name = "Mitosis", Damage = 2,   Target = 0,   Effect = {} },
}
local unitAttackList = {
    [1] = {1, 2},
    [2] = {3, 4},
}

local unitNumList = {
    [1] = {
        Name = "Goblin",
        Num = 1,
        Strength = 5,
        Dexerity = 1,
        Intelligence = 1,
        Vitality = 3,
        Charisma = 1,
        MaxHealth = 10,
        Health = 10,
        Effect = {}
    },
    [2] = {
        Name = "Slime",
        Num = 2,
        Strength = 3,
        Dexerity = 2,
        Intelligence = 1,
        Vitality = 5,
        Charisma = 1,
        MaxHealth = 20,
        Health = 20,
        Effect = {}
    },
}

local serverAction: BindableFunction = (RS:FindFirstChild("ServerAction") :: BindableFunction?) or Instance.new("BindableFunction")
    serverAction.Name = "ServerAction"
    serverAction.Parent = RS
local serverFuncList = {}
local clientAction: RemoteFunction = (RS:FindFirstChild("ClientAction") :: RemoteFunction?) or Instance.new("RemoteFunction")
    clientAction.Name = "ClientAction"
    clientAction.Parent = RS
local clientFuncList = {}

function module.Init(part: Instance, data: {} | nil, id: number) -- Remove part in the future
    -- Initialisation
    if id == 0 then -- Server scripts: id == 0
        require(SELF).ServerScript()
    else
        require(SELF).UnitScript(part, data, id)
    return end
end

function module.UnitScript(part: Instance, metadata: {} | nil, id: number)
    -- Initialisation
    local function updateList(): boolean -- Check in onto the sharedList as a Unit
        -- Check In
        local baseStat = unitNumList[metadata.unitTypeNum]
        if not baseStat then warn("Unknown unitTypeNum", metadata and metadata.unitTypeNum) return false end

        local unitData = {}
        for key, value in pairs(baseStat) do
            unitData[key] = value
        end
        unitData.Team = metadata.Team
        unitData.Owner = metadata.Owner
        unitData.Id = id

        sharedList.unitList[id] = unitData
        sharedList.totalUnits += 1

        print(sharedList.unitList)
        return true
    end
    if not updateList() then warn("Failed to Check In") return end -- Run check in with False -> ERROR

    local function CreateHpBar(): {Instance}
        local hpBar: BillboardGui = Instance.new("BillboardGui")
        hpBar.Parent = part
        hpBar.Adornee = part
        hpBar.Name = "HpBar " .. id
        hpBar.Size = UDim2.fromScale(5, 1)
        hpBar.ExtentsOffset = Vector3.new(0, 3, 0)

        local hpBarBackground: Frame = Instance.new("Frame")
        hpBarBackground.Parent = hpBar
        hpBarBackground.BackgroundColor3 = Color3.new(1, 1, 1)
        hpBarBackground.BackgroundTransparency = 0
        hpBarBackground.Size = UDim2.fromScale(1, 1)
        hpBarBackground.ZIndex = 0

        local hpBarBar: Frame = Instance.new("Frame")
        hpBarBar.Parent = hpBar
        hpBarBar.BackgroundColor3 = Color3.new(0, 0, 0)
        hpBarBar.BackgroundTransparency = 0
        hpBarBar.Size = UDim2.fromScale(0.96, 0.8)
        hpBarBar.Position = UDim2.fromScale(0.02, 0.1)
        hpBarBar.ZIndex = 1

        local hpBarText: TextLabel = Instance.new("TextLabel")
        hpBarText.Parent = hpBar
        hpBarText.Text = sharedList.unitList[id].Health .. " / " .. sharedList.unitList[id].MaxHealth
        hpBarText.TextColor3 = Color3.new(0.5, 0.5, 0.5)
        hpBarText.Size = UDim2.fromScale(1, 1)
        hpBarText.BackgroundTransparency = 1
        hpBarText.TextScaled = true
        hpBarText.ZIndex = 2

        return {hpBar, hpBarBackground, hpBarBar, hpBarText} -- TEMP: no return False case; TODO: Add checking
    end
    local unitUI: {} = CreateHpBar()
    if not unitUI then warn("Failed to Create HP Bar") return end -- False -> Error

    local function UpdateUI()
        unitUI[4].Text = sharedList.unitList[id].Health .. " / " .. sharedList.unitList[id].MaxHealth
        unitUI[3].Size = UDim2.fromScale(sharedList.unitList[id].Health / sharedList.unitList[id].MaxHealth, unitUI[3].Size.Y.Scale)
    end

    -- serverAction:Invoke({ -- TODO: Make units automatically add to id: 0, instead of FindUnits()
    --     action = 5,
    --     send = id,
    --     receive = 0,
    -- })

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

        if unitAttackList[unit.Num] == nil then warn("Unknown Attack Action") return end

        -- Obtain Enemies
        local enemyList = {}
        for _, unitChecked in pairs(sharedList.unitList) do
            if unitChecked.Team == unit.Team then continue end
            local enemy: {} = unitChecked
            table.insert(enemyList, enemy)
        end

        clientAction:InvokeClient(plrOwner, {
            action = 4,
            send = id,
            receive = plrOwner,
            -- Skill
            Num = unit.Num,
            enemyList = enemyList
        })
    end

    local function ApplyDamage(data)
        print("Attack Used: ", data.skillList, "; On unit:", data.target)
        if data.skillList.Target == 1 then -- Single Attack
            serverAction:Invoke({
                action = 4,
                send = id,
                receive = data.target,
                -- Extra
                skillList = data.skillList
            })
        elseif data.skillList.Target == -1 then -- Area Attack
            if typeof(data.target) ~= "table" then warn("Unknown Enemy List") return end
            for _, enemyId in ipairs(data.target) do
            serverAction:Invoke({
                action = 4,
                send = id,
                receive = enemyId,
                -- Extra
                skillList = data.skillList
            })
            end
        elseif data.skillList.Target == 0 then -- Summon Ally Unit
            serverAction:Invoke({
                action = 5,
                send = id,
                receive = 0,
                -- Extra
                skillList = data.skillList
            })
        else warn("Unknown Target") return end
        task.wait(1) -- TODO: Animation
        FinishAction()
    end

    local function TakeDamage(data)
        -- TODO: Calculate any effect

        -- Calculate damage taken; TODO: Resistance + Critical + Vulnerability
        print(id, "Take Damage", data.skillList.Damage)
        sharedList.unitList[id].Health -= data.skillList.Damage
        UpdateUI()

        if sharedList.unitList[id].Health <= 0 then
            serverAction:Invoke({
                action = 6,
                send = id,
                receive = 0,
            })
            part:Destroy()
        return end
    end

    local function botAction()
        -- Obtain Enemy (Player Units)
        local enemyIdList: {number} = {} -- List of enemy stats
        for _, enemy in ipairs(sharedList.unitList) do
            if enemy.Team ~= sharedList.unitList[id].Team then
                table.insert(enemyIdList, enemy.Id)
            end
        end
        -- Smart Action
        local attackList: {number} = unitAttackList[sharedList.unitList[id].Num]
        local rngAction: number = math.random(1, #attackList)

        local attackAction: {} = attackActionList[attackList[rngAction]]
        if attackAction.Target == 1 then -- Single Attack
            local randEnemyId: number = enemyIdList[math.random(1, #enemyIdList)]
            ApplyDamage({
                action = 4,
                send = id,
                receive = id,
                skillList = attackAction,
                target = randEnemyId
            })
        elseif attackAction.Target == -1  then -- Area Attack
            ApplyDamage({
                action = 4,
                send = id,
                receive = id,
                skillList = attackAction,
                target = enemyIdList
            })
        elseif attackAction.Target ==  0 then -- Spawn Ally Unit
            ApplyDamage({
                action = 4,
                send = id,
                receive = id,
                skillList = attackAction,
            })
        else warn("Unknown Target Range") return end
    return end

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
                local result = func(data)
                if type(result) == table then if result.Error then warn(result.Error) end end
            end)
        end

        if (data.action == 4) then executeFunction(TakeDamage) end
        if (data.action == 7) then executeFunction(Action) end
    end

    clientFuncList[id] = function(data)
        if data.receive ~= id then return end

        local function executeFunction(func)
            task.spawn(function()
                local result = func(data)
                if type(result) == table then if result.Error then warn(result.Error) end end
            end)
        end

        if (data.action == 2) then executeFunction(FinishAction) end -- Rest
        if (data.action == 3) then executeFunction(AttackAction) end
        if (data.action == 4) then executeFunction(ApplyDamage) end
    end
end

function module.ServerScript()
    -- Server Initialisation -- TODO: Repeatable: can activate / reset by cmd
    local idCounter: number = 1

    local function InitialiseEnemy() -- Create enemies for start of level
        serverAction:Invoke({
            action = 5,
            send = 0,
            receive = 0,
            unitTypeNum = 1,
            unitTeam = "Ememy",
            unitOwner = "ai",
        })
        task.wait(1)
        serverAction:Invoke({
            action = 5,
            send = 0,
            receive = 0,
            unitTypeNum = 2,
            unitTeam = "Ememy",
            unitOwner = "ai",
        })
        task.wait(1)
        serverAction:Invoke({
            action = 5,
            send = 0,
            receive = 0,
            unitTypeNum = 2,
            unitTeam = "Ally",
            unitOwner = "FireAlexGame",
        })
        task.wait(1)
    end
    task.spawn(InitialiseEnemy)

    local function FindUnits()
        task.wait(3) -- TEMP: Wait for all instances to load

        local possibleUnits: {Instance} = game:GetService("Workspace").Game:GetChildren()
        for _, obj in ipairs(possibleUnits) do
            require(SELF).Init(obj, idCounter)
            idCounter += 1
        end

        task.wait(1) -- TEMP: Wait for all instances to check in
        -- TODO: Can get a number of total units, wait until totalUnits == #UnitNumGiven
        serverAction:Invoke({ -- Order Units
            action = 3,
            send = 0,
            receive = 0,
        })
        serverAction:Invoke({ -- Start Game
            action = 1,
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
                ["attackActionList"] = attackActionList,
                ["unitAttackList"] = unitAttackList,
                ["unitType"] = unitNumList,
            }
        })
    end

     local function OrderUnits(data)
        local function DecreaseOrder() -- To prevent skip over next unit
            local unitId: number = data.unit
            if unitId == nil then warn("Unknown Unit Deleted") return end

            if table.find(sharedList.actionOrder, unitId) < sharedList.actionNumber then -- Unit act before now
                sharedList.actionNumber -= 1 -- Consider summoned acted
            end
        end
        if data.mode == -1 then DecreaseOrder() end

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

        local function IncreaseOrder() -- To prevent same unit run twice
            local unitId: number = data.unit
            if unitId == nil then warn("Unknown Unit Added") return end

            if table.find(sharedList.actionOrder, unitId) < sharedList.actionNumber then -- Unit act before now
                sharedList.actionNumber += 1 -- Consider summoned acted
            end
        end
        if data.mode == 1 then IncreaseOrder() end
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

    local function RemoveUnit(data)
        serverAction:Invoke{
            action = 3,
            send = 0,
            receive = 0,
            unit = data.send, -- Prevent skip over next unit
            mode = -1, -- Delete
        }

        sharedList.unitList[data.send] = nil
        sharedList.totalUnits -= 1
    end

    local function SummonUnit(data)
        local unitNum: number = nil -- Summoned: .Attack; Server: .unitTypeNum
        if not data.skillList then
            unitNum = data.unitTypeNum
        elseif not data.skillList.Damage then
            unitNum = data.unitTypeNum
        else
            unitNum = data.skillList.Damage
        end
        if unitNum == nil then warn("Unknown Unit Number: ", data) return end

        if unitNumList[unitNum] == nil then warn("Out of Range: ", unitNum) return end -- No unit existed in list

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

        require(SELF).Init(part, dataList, idCounter)

        serverAction:Invoke({
            action = 3,
            send = 0,
            receive = 0,
            unit = idCounter, -- For counter to know which unit is summoned, prevent same unit run twice
            mode = 1, -- add
        })
        idCounter += 1
        return
    end

    -- Direct to correct function
    serverAction.OnInvoke = function(data)
        if data.receive == 0 then -- Server
            -- Execute server actions
            local function executeFunction(func)
                task.spawn(function()
                    local result = func(data)
                    if type(result) == table then if result.Error then warn(result.Error) end end
                end)
            end

            if (data.action == 1) then executeFunction(RoundCounter) end
            if (data.action == 3) then executeFunction(OrderUnits) end
            if (data.action == 5) then executeFunction(SummonUnit) end
            if (data.action == 6) then executeFunction(RemoveUnit) end

        elseif serverFuncList[data.receive] then -- Unit
            serverFuncList[data.receive](data)
        end
    end

    clientAction.OnServerInvoke = function(plr, data)
        if data.receive == 0 then -- Server
            -- Client to Sever direct
            local function executeFunction(func)
                task.spawn(function()
                    local result = func(data)
                    if type(result) == table then if result.Error then warn(result.Error) end end
                end)
            end

            if (data.action == -1) then executeFunction(TransferData) end

        elseif clientFuncList[data.receive] then -- Unit
            clientFuncList[data.receive](data)
        end
    end

end

return module