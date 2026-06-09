local module = {}
-- Services
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TWS: TweenService = game:GetService("TweenService")

-- Data
local GAME_DATA: {[string]: {}} = require(RS:WaitForChild("GameData"))
type AttackAction = GAME_DATA.AttackAction
type UnitType = GAME_DATA.UnitType
type Macros = GAME_DATA.Macros
local attackActions: AttackAction = GAME_DATA.attackActions
local unitTypes: UnitType = GAME_DATA.unitTypes
local MACROS: Macros = GAME_DATA.MACROS

-- Shared
local SHARED_LIST: {[string]: {}} = require(RS:WaitForChild("SharedList"))
local sharedList: SHARED_LIST.SharedList = SHARED_LIST

-- Package
local FH = require(RS:WaitForChild("FunctionHandler"))

function module.Init(plr)
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

        local notificationFrame: Frame = Instance.new("Frame")
        notificationFrame.Parent = screenGui
        notificationFrame.Name = "Notification"
        notificationFrame.Size = UDim2.fromScale(0.3, 0.5)
        notificationFrame.Position = UDim2.fromScale(0.7, 0.5)
        notificationFrame.BackgroundTransparency = 1
        local UiListLayout: UIListLayout = Instance.new("UIListLayout")
        UiListLayout.Parent = notificationFrame
        UiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        local notificationLabel: TextLabel = Instance.new("TextLabel") -- Template: no parents
        notificationLabel.Size = UDim2.fromScale(1, 0.1)
        notificationLabel.TextSize = 8
        notificationLabel.TextScaled = false
        notificationLabel.RichText = true

        return {
            [1] = screenGui,
            [2] = passButton,
            [3] = attackButton,
            [4] = actionFrame,
            [5] = attackActionFrame,
            [6] = targetFrame,
            [7] = notificationFrame,
            [8] = notificationLabel,
        }
    end
    local guiInstances: {Instance} = CreateGui()

    -- GUI Functions
    local unitId: number = 0
    guiInstances[2].Activated:Connect(function()
        guiInstances[4].Visible = false
        FH.ClientMessage({
            action = MACROS.FINISH_ACTION,
            send = plr,
            receive = unitId
        })
    end)
    guiInstances[3].Activated:Connect(function()
        guiInstances[4].Visible = false
        FH.ClientMessage({
            action = MACROS.ATTACK_ACTION,
            send = plr,
            receive = unitId,
        })
    end)

    local function PlayerInput(data)
        local unitData = data.unitData
        unitId = data.send -- Update Id of the unit controlling
        guiInstances[4].Visible = true

        print("Player Received", unitId, unitData)
        -- TODO: UI Management with unitData
    end

    local function RemoveChildUI(parentUI)
        for _, child in ipairs(parentUI:GetChildren()) do
            if child:IsA("UIGridLayout") then continue end
            child:Destroy()
        end
    end

    local function DisplayNotification(data)
        local msg = data.msg
        if msg == nil then warn("Unknown Notification") return end
        if msg.skill.Nature == 3 then return end -- No notification for 3: effect

        -- Create new notification
        local notif: TextLabel = guiInstances[8]:Clone()
        notif.Parent = guiInstances[7]

        local function FadeOut()
            local FADE_TIME: number = 1

            local tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            local tweenEnd = {
                BackgroundTransparency = 1,
                TextTransparency = 1,
                TextStrokeTransparency = 1
            }

            local fadeTween = TWS:Create(notif, tweenInfo, tweenEnd)
            fadeTween:Play()

            fadeTween.Completed:Connect(function()
                notif:Destroy()
            end)
        end
        -- TODO: If overflow, then FadeOut() the oldest one

        local function Decay()
            task.wait(5) -- Decay time
            FadeOut()
        end
        task.spawn(Decay)

        -- Set text
        local function StylisedAttack()
            notif.BorderSizePixel = 0
            notif.BackgroundTransparency = 0.5
            notif.BackgroundColor3 = Color3.new(1, 1, 1)
            notif.TextColor3 = Color3.new(0, 0, 0)

            notif.Text = msg.attackerName.." ("..msg.attackerId..") <font color=\"#333333\">attacked</font> "..msg.targetName.." ("..msg.targetId..") <font color=\"#333333\">with</font> "..msg.skill.Name
        end

        if msg.code == 1 then StylisedAttack()
        else warn("Unknown Notification") return end
    end

    local function AttackEnemy(skill, enemyList, allyList) -- enemyList is numbered, skill is string-indexed with Name
        local targetList: {[number]: number} = {}
        local allyTarBoolList = {
            [MACROS.SINGLE_ALLY_ATTACK] = true,
            [MACROS.MULTIPLE_ALLY_ATTACK] = true,
            [MACROS.ALL_ALLY_ATTACK] = true,
        }
        if allyTarBoolList[skill.Target] then targetList = allyList
        else targetList = enemyList end

        if skill.Target == MACROS.SINGLE_ENEMY_ATTACK or skill.Target == MACROS.SINGLE_ALLY_ATTACK then

            for _, target in ipairs(targetList) do
                local button: TextButton = Instance.new("TextButton")
                button.Parent = guiInstances[6]
                button.Text = target.Name
                button.Size = UDim2.fromScale(0.1, 1)

                button.Activated:Connect(function()
                    guiInstances[6].Visible = false
                    FH.ClientMessage({
                        action = MACROS.APPLY_DAMAGE,
                        send = plr,
                        receive = unitId,
                        skillList = skill,
                        target = target.Id,
                    })
                    RemoveChildUI(guiInstances[6])
                end)
            end
            guiInstances[6].Visible = true
        elseif skill.Target == MACROS.ALL_ENEMY_ATTACK or skill.Target == MACROS.ALL_ALLY_ATTACK then
            local targetIdList = {}

            for _, target in ipairs(targetList) do
                table.insert(targetIdList, target.Id)
            end

            FH.ClientMessage({
                action = MACROS.APPLY_DAMAGE,
                send = plr,
                receive = unitId,
                skillList = skill,
                target = targetIdList, -- -1: All enemies
            })
        elseif skill.Target == MACROS.SUMMON_ATTACK then -- Spawn Ally Unit
            FH.ClientMessage({
                action = MACROS.APPLY_DAMAGE,
                send = plr,
                receive = unitId,
                skillList = skill,
                -- TODO: Add target = "Team Name" which spawns the unit into a team -> .Target = 0: Summon General Unit
            })
        else warn("Unknown Target Range") return end
        RemoveChildUI(guiInstances[5])
    end

    local function ChooseAttackTarget(data) -- client 4
        if not (data.allyList and data.enemyList and data.skillList) then warn("Missing Data") return end

        local skillList = {}
        for _, skillNum in ipairs(data.skillList) do
            table.insert(skillList, attackActions[skillNum])
        end

        local skillNames: {string} = {}
        for _, skill in ipairs(skillList) do table.insert(skillNames, skill.Name) end

        for num, name in ipairs(skillNames) do
            local button: TextButton = Instance.new("TextButton")
            button.Parent = guiInstances[5]
            button.Text = name
            button.Size = UDim2.fromScale(0.1, 1)

            button.Activated:Connect(function()
                AttackEnemy(skillList[num], data.enemyList, data.allyList) -- skillList and skillNames must line up
                guiInstances[5].Visible = false
                return
            end)
        end

        guiInstances[5].Visible = true
    end

    -- Handler
    FH.RegisterClient(plr, MACROS.DISPLAY_NOTIFICATION, DisplayNotification)
    FH.RegisterClient(plr, MACROS.PLAYER_INPUT, PlayerInput)
    FH.RegisterClient(plr, MACROS.CHOOSE_ATTACK_TARGET, ChooseAttackTarget)
end

return module