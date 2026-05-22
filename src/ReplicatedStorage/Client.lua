local module = {}
-- Services
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local SELF: ModuleScript = RS:WaitForChild("Client")

local clientAction: RemoteFunction = (RS:FindFirstChild("ClientAction") :: RemoteFunction?) or Instance.new("RemoteFunction")
    clientAction.Name = "ClientAction"
    clientAction.Parent = RS
local clientFuncList = {}

-- Data
local dataList = {}

function module.Init(plr)
    -- Fill Data
    clientAction:InvokeServer({
        action = -1,
        send = plr,
        receive = 0,
    })
    local function RecieveData(data)
        dataList = data.dataList
        print(plr, dataList)
    end

    -- GUI
    local function CreateGui(): {Instance}
        local screenGui: ScreenGui = Instance.new("ScreenGui")
        screenGui.Parent = plr.PlayerGui
        local actionFrame: Frame = Instance.new("Frame")
        actionFrame.Parent = screenGui
        actionFrame.Size = UDim2.fromScale(1, 0.2)
        actionFrame.Position = UDim2.fromScale(0, 0.8)
        actionFrame.BackgroundTransparency = 1
        actionFrame.Visible = false
        local actionUIGrid: UIGridLayout = Instance.new("UIGridLayout")
        actionUIGrid.Parent = actionFrame
        local passButton: TextButton = Instance.new("TextButton")
        passButton.Parent = actionFrame
        passButton.Text = "Pass"
        passButton.Size = UDim2.fromScale(0.1, 1)
        local attackButton: TextButton = Instance.new("TextButton")
        attackButton.Parent = actionFrame
        attackButton.Text = "Attack"
        attackButton.Size = UDim2.fromScale(0.1, 1)

        local attackActionFrame: Frame = Instance.new("Frame")
        attackActionFrame.Parent = screenGui
        attackActionFrame.Size = UDim2.fromScale(1, 0.2)
        attackActionFrame.Position = UDim2.fromScale(0, 0.8)
        attackActionFrame.BackgroundTransparency = 1
        attackActionFrame.Visible = false
        local attackActionUIGrid: UIGridLayout = Instance.new("UIGridLayout")
        attackActionUIGrid.Parent = attackActionFrame
        local targetFrame: Frame = Instance.new("Frame")
        targetFrame.Parent = screenGui
        targetFrame.Size = UDim2.fromScale(1, 0.2)
        targetFrame.Position = UDim2.fromScale(0, 0.8)
        targetFrame.BackgroundTransparency = 1
        targetFrame.Visible = false
        local targetUIGrid: UIGridLayout = Instance.new("UIGridLayout")
        targetUIGrid.Parent = targetFrame

        return {screenGui, passButton, attackButton, actionFrame, attackActionFrame, targetFrame}
    end
    local guiInstances: {Instance} = CreateGui()
    local actionFrame: Frame = guiInstances[4]

    -- GUI Functions
    local unitId: number = 0
    guiInstances[2].Activated:Connect(function()
        actionFrame.Visible = false
        clientAction:InvokeServer({
            action = 2,
            send = plr,
            receive = unitId
        })
    end)
    guiInstances[3].Activated:Connect(function()
        actionFrame.Visible = false
        clientAction:InvokeServer({
            action = 3,
            send = plr,
            receive = unitId,
        })
    end)

    local function PlayerInput(data)
        local unitData = data.unitData or nil
        unitId = data.send or nil
        actionFrame.Visible = true

        print("Player Received", unitId, unitData)
        -- TODO: UI Management with unitData
    end

    local function RemoveChildUI(parentUI)
        for _, child in ipairs(parentUI:GetChildren()) do
            if child:IsA("UIGridLayout") then continue end
            child:Destroy()
        end
    end

    local function AttackEnemy(skill, enemyList) -- enemyList is numbered, skill is string-indexed with Name
        if skill.Target == 1 then -- Single Attack
            for _, enemy in ipairs(enemyList) do
                local button: TextButton = Instance.new("TextButton")
                button.Parent = guiInstances[6]
                button.Text = enemy.Name
                button.Size = UDim2.fromScale(0.1, 1)

                button.Activated:Connect(function()
                    guiInstances[6].Visible = false
                    clientAction:InvokeServer({
                        action = 4,
                        send = plr,
                        receive = unitId,
                        -- Extra
                        skillList = skill,
                        target = enemy.Id
                        -- TODO: Add buffs / debuffs
                    })
                    RemoveChildUI(guiInstances[6])
                end)
            end
            guiInstances[6].Visible = true
        elseif skill.Target == -1  then -- Area Attack
            -- Get enemy Id
            local targetIdList = {}
            for _, enemy in ipairs(enemyList) do
                table.insert(targetIdList, enemy.Id)
            end

            clientAction:InvokeServer({
                action = 4,
                send = plr,
                receive = unitId,
                -- Extra
                skillList = skill,
                target = targetIdList, -- -1: All enemies
            })
        else warn("Unknown Target Range") return end
        RemoveChildUI(guiInstances[5])
    end

    local function ChooseAttackTarget(data)
        if (not data.enemyList) then warn("Missing Data") return end

        local skillList = {}
        for _, i in ipairs(dataList.unitAttackList[data.Name]) do
            table.insert(skillList, dataList.attackActionList[i])
        end

        local skillNames: {string} = {}
        for _, skill in ipairs(skillList) do table.insert(skillNames, skill.Name) end

        for num, name in ipairs(skillNames) do
            local button: TextButton = Instance.new("TextButton")
            button.Parent = guiInstances[5]
            button.Text = name
            button.Size = UDim2.fromScale(0.1, 1)

            button.Activated:Connect(function()
                AttackEnemy(skillList[num], data.enemyList) -- skillList and skillNames must line up
                guiInstances[5].Visible = false
                return
            end)
        end

        guiInstances[5].Visible = true
    end

    clientAction.OnClientInvoke = function(data)
        if data.receive ~= plr then return end

        -- TODO: Create check function like executeFunction()
        if (data.action == -1) then RecieveData(data) end
        if (data.action == 1) then PlayerInput(data) end
        if (data.action == 4) then ChooseAttackTarget(data) end
    end
end

return module