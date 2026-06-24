local module = {}
-- Services
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TWS: TweenService = game:GetService("TweenService")
local UIS: UserInputService = game:GetService("UserInputService")

-- Data
local GAME_DATA: {[string]: {}} = require(RS:WaitForChild("GameData"))
local attackActions: GAME_DATA.AttackAction = GAME_DATA.attackActions
local MACROS: GAME_DATA.Macros = GAME_DATA.MACROS

-- Package
local FH = require(RS:WaitForChild("FunctionHandler"))
type Data = {
    action: number,
    send: number,
    receive: Player,
}

function module.Init(plr)
    -- GUI
    local function CreateGui(): {Instance}
        local screenGui: ScreenGui = Instance.new("ScreenGui")
        screenGui.Parent = plr.PlayerGui

        -- Action
        local actionFrame: Frame = Instance.new("Frame")
        actionFrame.Parent = screenGui
        actionFrame.Name = "Action"
        actionFrame.Size = UDim2.fromScale(0.8, 0.1)
        actionFrame.Position = UDim2.fromScale(0, 0.8)
        actionFrame.BackgroundTransparency = 1
        actionFrame.Visible = false
        local actionUIList: UIListLayout = Instance.new("UIListLayout")
        actionUIList.Parent = actionFrame
        actionUIList.FillDirection = Enum.FillDirection.Horizontal
        actionUIList.Padding = UDim.new(0.01, 0)
        local actionMargin: UIPadding = Instance.new("UIPadding")
        actionMargin.Parent = actionFrame
        actionMargin.PaddingBottom = UDim.new(0.05, 0)

        -- Pass button
        local passButton: TextButton = Instance.new("TextButton")
        passButton.Parent = actionFrame
        passButton.Text = "Pass"
        passButton.Size = UDim2.fromScale(1, 1)
        passButton.BackgroundColor3 = Color3.new(1, 1, 1)
        passButton.BackgroundTransparency = 0.5
        local passButtonRatio: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
        passButtonRatio.Parent = passButton
        passButtonRatio.AspectRatio = 2

        -- Attack button
        local attackButton: TextButton = Instance.new("TextButton")
        attackButton.Parent = actionFrame
        attackButton.Text = "Attack"
        attackButton.Size = UDim2.fromScale(1, 1)
        attackButton.BackgroundColor3 = Color3.new(1, 1 ,1)
        attackButton.BackgroundTransparency = 0.5
        local attackButtonRatio: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
        attackButtonRatio.Parent = attackButton
        attackButtonRatio.AspectRatio = 2

        -- Bottom Info Bar
        local infoFrame: Frame = Instance.new("Frame")
        infoFrame.Parent = screenGui
        infoFrame.Name = "Information"
        infoFrame.Size = UDim2.fromScale(0.8, 0.1)
        infoFrame.Position = UDim2.fromScale(0, 0.9)
        infoFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        infoFrame.BackgroundTransparency = 0.25
        local infoFrameList: UIListLayout = Instance.new("UIListLayout")
        infoFrameList.Parent = infoFrame
        infoFrameList.FillDirection = Enum.FillDirection.Horizontal
        infoFrameList.SortOrder = Enum.SortOrder.LayoutOrder

        local infoImage: ImageLabel = Instance.new("ImageLabel")
        infoImage.Parent = infoFrame
        infoImage.Name = "UnitIcon"
        infoImage.Size = UDim2.fromScale(1, 1)
        infoImage.Position = UDim2.fromScale(0, 0)
        infoImage.BorderSizePixel = 0
        infoImage.LayoutOrder = 1
        local infoImageSquare: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
        infoImageSquare.Parent= infoImage
        infoImageSquare.AspectRatio = 1

        local infoRightFrame: Frame = Instance.new("Frame")
        infoRightFrame.Parent = infoFrame
        infoRightFrame.Position = UDim2.fromScale(0, 0)
        infoRightFrame.Size = UDim2.fromScale(1, 1)
        infoRightFrame.BackgroundTransparency = 1
        infoRightFrame.LayoutOrder = 2
        local infoRightFrameFlex: UIFlexItem = Instance.new("UIFlexItem")
        infoRightFrameFlex.Parent = infoRightFrame
        infoRightFrameFlex.FlexMode = Enum.UIFlexMode.Fill

        local infoTitle: TextLabel = Instance.new("TextLabel")
        infoTitle.Parent = infoRightFrame
        infoTitle.Name = "Title"
        infoTitle.Text = ""
        infoTitle.Position = UDim2.fromScale(0, 0)
        infoTitle.Size = UDim2.fromScale(1, 0.2)
        infoTitle.TextColor3 = Color3.new(1, 1, 1)
        infoTitle.BackgroundColor3 = Color3.new(0, 0, 0)
        infoTitle.BackgroundTransparency = 0.5
        infoTitle.BorderSizePixel = 0

        local infoDetail: Frame = Instance.new("Frame")
        infoDetail.Parent = infoRightFrame
        infoDetail.Name = "Detail"
        infoDetail.Size = UDim2.fromScale(1, 0.8)
        infoDetail.Position = UDim2.fromScale(0, 0.2)
        infoDetail.BackgroundTransparency = 1
        local infoDetailGrid: UIGridLayout = Instance.new("UIGridLayout")
        infoDetailGrid.Parent = infoDetail
        infoDetailGrid.CellSize = UDim2.fromScale(0.2, 0.5)
        infoDetailGrid.CellPadding = UDim2.fromScale(0, 0)

        local infoTag: Frame = Instance.new("Frame")
        infoTag.Name = "Tag"
        infoTag.BackgroundTransparency = 1
        local infoTagList: UIListLayout = Instance.new("UIListLayout")
        infoTagList.Parent = infoTag
        infoTagList.FillDirection = Enum.FillDirection.Horizontal
        local infoTagIcon: ImageLabel = Instance.new("ImageLabel")
        infoTagIcon.Parent = infoTag
        infoTagIcon.Name = "Icon"
        infoTagIcon.Position = UDim2.fromScale(0, 0)
        infoTagIcon.Size = UDim2.fromScale(1, 1)
        infoTagIcon.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
        infoTagIcon.BorderSizePixel = 0
        local infoTagIconSquare: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
        infoTagIconSquare.Parent = infoTagIcon
        infoTagIconSquare.AspectRatio = 1
        local infoTagText: TextLabel = Instance.new("TextLabel")
        infoTagText.Name = "Words"
        infoTagText.Parent = infoTag
        infoTagText.Position = UDim2.fromScale(0.2, 0)
        infoTagText.Size = UDim2.fromScale(0.8, 1)
        infoTagText.BackgroundTransparency = 1
        infoTagText.TextWrapped = true

        local infoCancel: TextButton = Instance.new("TextButton")
        infoCancel.Parent = infoFrame
        infoCancel.Name = "InfoCancel"
        infoCancel.Text = "BACK"
        infoCancel.Size = UDim2.fromScale(0.05, 1)
        infoCancel.BackgroundColor3 = Color3.new(1, 1, 1)
        infoCancel.BackgroundTransparency = 0.5
        infoCancel.BorderSizePixel = 0
        infoCancel.LayoutOrder = 3
        infoCancel.Visible = false

        -- Attack Action
        local attackActionFrame: Frame = Instance.new("Frame")
        attackActionFrame.Parent = screenGui
        attackActionFrame.Name = "AttackAction"
        attackActionFrame.Size = UDim2.fromScale(0.8, 0.1)
        attackActionFrame.Position = UDim2.fromScale(0, 0.8)
        attackActionFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        attackActionFrame.BackgroundTransparency = 1
        attackActionFrame.Visible = false
        local attackActionUIList: UIListLayout = Instance.new("UIListLayout")
        attackActionUIList.Parent = attackActionFrame
        attackActionUIList.FillDirection = Enum.FillDirection.Horizontal
        attackActionUIList.Padding = UDim.new(0.01, 0)
        local attackActionMargin: UIPadding = Instance.new("UIPadding")
        attackActionMargin.Parent = attackActionFrame
        attackActionMargin.PaddingBottom = UDim.new(0.05, 0)

        local attackActionCancel: TextButton = Instance.new("TextButton")
        attackActionCancel.Parent = attackActionFrame
        attackActionCancel.Name = "CancelAttack"
        attackActionCancel.Text = "CANCEL"
        attackActionCancel.Size = UDim2.fromScale(1, 1)
        attackActionCancel.BackgroundColor3 = Color3.new(1, 1, 1)
        attackActionCancel.BackgroundTransparency = 0.5
        local attackCancelRatio: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
        attackCancelRatio.Parent = attackActionCancel
        attackCancelRatio.AspectRatio = 1

        local attackActionButton: TextButton = Instance.new("TextButton")
        attackActionButton.Name = "Template"
        attackActionButton.Size = UDim2.fromScale(1, 1)
        attackActionButton.BackgroundColor3 = Color3.new(1, 1, 1)
        attackActionButton.BackgroundTransparency = 0.5
        local attackActionButtonRatio: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
        attackActionButtonRatio.Parent = attackActionButton
        attackActionButtonRatio.AspectRatio = 2

        -- Choose Target
        local targetFrame: Frame = Instance.new("Frame")
        targetFrame.Parent = screenGui
        targetFrame.Name = "TargetFrame"
        targetFrame.Size = UDim2.fromScale(0.8, 0.1)
        targetFrame.Position = UDim2.fromScale(0, 0.8)
        targetFrame.BackgroundTransparency = 1
        targetFrame.Visible = false
        local targetFrameUIList: UIListLayout = Instance.new("UIListLayout")
        targetFrameUIList.Parent = targetFrame
        targetFrameUIList.FillDirection = Enum.FillDirection.Horizontal
        targetFrameUIList.Padding = UDim.new(0.01, 0)
        local targetFrameMargin: UIPadding = Instance.new("UIPadding")
        targetFrameMargin.Parent = targetFrame
        targetFrameMargin.PaddingBottom = UDim.new(0.05, 0)

        local targetCancel: TextButton = Instance.new("TextButton")
        targetCancel.Parent = targetFrame
        targetCancel.Name = "CancelAttack"
        targetCancel.Text = "CANCEL"
        targetCancel.Size = UDim2.fromScale(1, 1)
        targetCancel.BackgroundColor3 = Color3.new(1, 1, 1)
        targetCancel.BackgroundTransparency = 0.5
        local targetCancelRatio: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
        targetCancelRatio.Parent = targetCancel
        targetCancelRatio.AspectRatio = 1

        local targetButton: TextButton = Instance.new("TextButton")
        targetButton.Name = "Template"
        targetButton.Size = UDim2.fromScale(1, 1)
        targetButton.BackgroundColor3 = Color3.new(1, 1, 1)
        targetButton.BackgroundTransparency = 0.5
        local targetButtonRatio: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
        targetButtonRatio.Parent = targetButton
        targetButtonRatio.AspectRatio = 2

        -- Side Notification
        local notificationFrame: Frame = Instance.new("Frame")
        notificationFrame.Parent = screenGui
        notificationFrame.Name = "Notification"
        notificationFrame.Size = UDim2.fromScale(0.2, 0.3)
        notificationFrame.Position = UDim2.fromScale(0.8, 0.5)
        notificationFrame.BackgroundTransparency = 1
        local UiListLayout: UIListLayout = Instance.new("UIListLayout")
        UiListLayout.Parent = notificationFrame
        UiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        local notificationLabel: TextLabel = Instance.new("TextLabel") -- Template: no parents
        notificationLabel.Size = UDim2.fromScale(1, 0.1)
        notificationLabel.TextSize = 8
        notificationLabel.TextScaled = false
        notificationLabel.RichText = true
        notificationLabel.BackgroundTransparency = 0.5

        -- Order Panel
        local orderFrame: Frame = Instance.new("Frame")
        orderFrame.Parent = screenGui
        orderFrame.Name = "Order"
        orderFrame.Size = UDim2.fromScale(0.2, 0.2)
        orderFrame.Position = UDim2.fromScale(0.8, 0.8)
        orderFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        orderFrame.BackgroundTransparency = 0.5
        local orderFrameList: UIListLayout = Instance.new("UIListLayout")
        orderFrameList.Parent = orderFrame
        orderFrameList.Padding = UDim.new(0.01, 0)

        local orderText: TextLabel = Instance.new("TextLabel")
        orderText.Name = "OrderText"
        orderText.Size = UDim2.fromScale(1, 0.15)
        orderText.BackgroundTransparency = 0.5
        -- Other attributes are set in function

        -- Hover Box
        local hoverFrame: Frame = Instance.new("Frame")
        hoverFrame.Name = "HoverFrame"
        hoverFrame.Parent = screenGui
        hoverFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        hoverFrame.BackgroundTransparency = 0.5
        hoverFrame.BorderSizePixel = 0
        hoverFrame.Size = UDim2.fromScale(0.08, 0.03)
        hoverFrame.Visible = false
        local hoverText: TextLabel = Instance.new("TextLabel")
        hoverText.Parent = hoverFrame
        hoverText.Name = "HoverText"
        hoverText.BackgroundTransparency = 1
        hoverText.Size = UDim2.fromScale(1, 1)

        return {
            ["ScreenGui"] = screenGui,
            ["PassButton"] = passButton,
            ["AttackButton"] = attackButton,
            ["InformationFrame"] = infoFrame,
            ["ActionFrame"] = actionFrame,
            ["AttackActionFrame"] = attackActionFrame,
            ["AttackActionCancel"] = attackActionCancel,
            ["AttackActionButton"] = attackActionButton,
            ["TargetFrame"] = targetFrame,
            ["TargetCancel"] = targetCancel,
            ["TargetButton"] = targetButton,
            ["NotificationFrame"] = notificationFrame,
            ["NotificationLabel"] = notificationLabel,
            ["OrderFrame"] = orderFrame,
            ["OrderText"] = orderText,
            ["InfoFrame"] = infoFrame,
            ["InfoImage"] = infoImage,
            ["InfoTitle"] = infoTitle,
            ["InfoDetail"] = infoDetail, -- Info tag frame
            ["InfoTag"] = infoTag, -- Info tag template
            ["InfoCancel"] = infoCancel,
            ["HoverFrame"] = hoverFrame,
        }
    end
    local playerUI: {Instance} = CreateGui()

    local unitId: number = 0 -- Mutable: which id player is controlling

    -- Local Functions
    local function PlayerInput(data)
        local unitData = data.unitData
        unitId = data.send -- Update Id of the unit controlling
        playerUI.ActionFrame.Visible = true

        print("Player Received", unitId, unitData)
        -- TODO: UI Management with unitData
    end

    local function RemoveChildUI(parentUI)
        local exlcudedUIType: {string} = {"UIGridLayout", "UIListLayout", "UIPadding", "UIAspectRatioConstraint"}
        local exlcudedUIInstance: {Instance} = {playerUI.AttackActionCancel, playerUI.TargetCancel}
        local function CheckRemoval(ui)
            for _, excluded in ipairs(exlcudedUIType) do
                if ui:IsA(excluded) then return true end
            end
            for _, excluded in ipairs(exlcudedUIInstance) do
                if ui == excluded then return true end
            end
            return false
        end

        for _, child in ipairs(parentUI:GetChildren()) do
            if CheckRemoval(child) then continue end
            child:Destroy()
        end
    end

    -- GUI Functions
    playerUI.PassButton.Activated:Connect(function()
        playerUI.ActionFrame.Visible = false
        FH.ClientMessage({
            action = MACROS.FINISH_ACTION,
            send = plr,
            receive = unitId
        })
    end)
    playerUI.AttackButton.Activated:Connect(function()
        playerUI.ActionFrame.Visible = false
        FH.ClientMessage({
            action = MACROS.ATTACK_ACTION,
            send = plr,
            receive = unitId,
        })
    end)
    playerUI.AttackActionCancel.Activated:Connect(function()
        playerUI.ActionFrame.Visible = true
        playerUI.AttackActionFrame.Visible = false
        RemoveChildUI(playerUI.AttackActionFrame)
    end)
    playerUI.TargetCancel.Activated:Connect(function()
        playerUI.AttackActionFrame.Visible = true
        playerUI.TargetFrame.Visible = false
        RemoveChildUI(playerUI.TargetFrame)
    end)

    -- Module Functions
    local function DisplayNotification(data)
        local DURATION: number = 10
        local FADE_TIME: number = 1

        local msg = data.msg
        if msg == nil then warn("Unknown Notification") return end

        -- Create new notification
        local notif: TextLabel = playerUI.NotificationLabel:Clone()
        notif.Parent = playerUI.NotificationFrame

        local function FadeOut()
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
            task.delay(DURATION, FadeOut)
        end
        task.spawn(Decay)

        -- Set text
        if msg.code == "Damage" then
            notif.BorderSizePixel = 0
            notif.BackgroundTransparency = 0.5
            notif.BackgroundColor3 = Color3.new(0.85, 0.85, 0.85)
            notif.TextColor3 = Color3.new(0, 0, 0)

            notif.Text = msg.targetName.." ("..msg.targetId..") <font color=\"#333333\">Damaged by</font> "..msg.skill.Name.." <font color=\"#333333\">for</font> "..msg.skill.Damage

        elseif msg.code == "Attack" then
            notif.BorderSizePixel = 0
            notif.BackgroundTransparency = 0.5
            notif.BackgroundColor3 = Color3.new(1, 1, 1)
            notif.TextColor3 = Color3.new(0, 0, 0)

            notif.Text = msg.attackerName.." ("..msg.attackerId..") <font color=\"#333333\">Attacked with</font> "..msg.skill.Name

        else warn("Unknown Notification") return end
    end

    local function DisplayOrder(data: FH.Package): ()
        if not (data.unitList or data.actionOrder) then warn("Missing Order Data to Client") return end
        RemoveChildUI(playerUI.OrderFrame) -- Remove old order

        for idx, id in ipairs(data.actionOrder) do
            -- Order Label
            local label: TextLabel = playerUI.OrderText:Clone()
            label.Parent = playerUI.OrderFrame
            label.Text = data.unitList[id].Name .. " (" .. id .. ") "

            -- Highlight action unit
            if data.actionNumber == idx then
                label.BackgroundColor3 = Color3.new(0, 0, 0)
                label.TextColor3 = Color3.new(1, 1, 1)
            else
                label.BackgroundColor3 = Color3.new(1, 1, 1)
                label.TextColor3 = Color3.new(0, 0, 0)
            end
        end
    end

    local function ChooseAttackTarget(skill, enemyList, allyList) -- enemyList is numbered, skill is string-indexed with Name
        local targetList: {[number]: number} = {}
        local allyTarBoolList = {
            ["SingleAlly"] = true,
            ["MultiAlly"] = true,
            ["AllAlly"] = true,
        }
        if allyTarBoolList[skill.Target] then targetList = allyList
        else targetList = enemyList end

        if skill.Target == "SingleEnemy" or skill.Target == "SingleAlly" then

            for _, target in ipairs(targetList) do -- Create target buttons
                local button: TextButton = playerUI.TargetButton:Clone()
                button.Parent = playerUI.TargetFrame
                button.Text = target.Name

                button.Activated:Connect(function()
                    playerUI.TargetFrame.Visible = false
                    FH.ClientMessage({
                        action = MACROS.APPLY_DAMAGE,
                        send = plr,
                        receive = unitId,
                        skillList = skill,
                        target = target.Id,
                    })
                    RemoveChildUI(playerUI.AttackActionFrame) -- Remove all the Attack action buttons
                    RemoveChildUI(playerUI.TargetFrame)
                end)
            end
            playerUI.TargetFrame.Visible = true

        elseif skill.Target == "AllEnemy" or skill.Target == "AllAlly" then
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
            RemoveChildUI(playerUI.AttackActionFrame)

        elseif skill.Target == "Summon" then -- Spawn Ally Unit
            FH.ClientMessage({
                action = MACROS.APPLY_DAMAGE,
                send = plr,
                receive = unitId,
                skillList = skill,
                -- TODO: Add target = "Team Name" which spawns the unit into a team -> .Target = 0: Summon General Unit
            })
            RemoveChildUI(playerUI.AttackActionFrame)

        else warn("Unknown Target Range") return end
    end

    local function ChooseAttack(data)
        if not (data.allyList and data.enemyList and data.skillList) then warn("Missing Data") return end

        local skillList = {}
        for _, skillNum in ipairs(data.skillList) do
            table.insert(skillList, attackActions[skillNum])
        end

        for _, skill in ipairs(skillList) do -- Create buttons to choose Attack action
            local button: TextButton = playerUI.AttackActionButton:Clone()
            button.Parent = playerUI.AttackActionFrame
            button.Text = skill.Name .. ": " .. skill.Energy

            button.Activated:Connect(function()
                if data.unitList.Energy < skill.Energy then return end

                ChooseAttackTarget(skill, data.enemyList, data.allyList) -- skillList and skillNames must line up

                -- Buttons not removed as Choosing Target can be canceled
                playerUI.AttackActionFrame.Visible = false
            end)
        end

        playerUI.AttackActionFrame.Visible = true
    end

    local function InfoBar(data: Data & {unit: table, returnUnit: table?})
        local unit: {} = data.unit
        if type(unit) ~= "table" then warn("Unknown Unit Object") return end

        -- TODO: Set image
        playerUI.InfoTitle.Text = unit.Name
        playerUI.InfoCancel.Visible = false -- Hide for new unit replacing clicked info (returnUnit is object)

        RemoveChildUI(playerUI.InfoDetail)

        local function CreateTag(key, value): (TextLabel)
            local tag: TextLabel = playerUI.InfoTag:Clone()
            tag.Parent = playerUI.InfoDetail
            tag:WaitForChild("Words").Text = key .. ": " .. value
            return tag
        end

        for key, value in pairs(unit) do
            if type(value) == "function" then continue end
            if type(value) == "table" and getmetatable(value) ~= nil then continue end -- Class

            local excludedKeys = {
                Name = true,
                Skills = true,
                Effect = true,
                Instance = true,
            }
            if excludedKeys[key] then continue end

            CreateTag(key, value)
        end

        if type(data.returnUnit) == "table" then -- Clicked info bar
            local infoCancel: TextButton = playerUI.InfoCancel
            infoCancel.Visible = true

            infoCancel.Activated:Connect(function()
                InfoBar({
                    action = data.action,
                    send = data.send,
                    receive = data.receive,
                    unit = data.returnUnit,
                })
            end)
        end
    end

    local function HoverUnit(data: Data & {unit: table, mode: "Enter"|"Leave"})
        if not (data.unit and data.mode) then warn("Hover Missing Data") return end
        local unit = data.unit
        if not unit.Instance then warn("Unknown Unit Instance") return end

        if data.mode == "Enter" then
            -- Glow effect
            local highlight: Highlight = Instance.new("Highlight")
            highlight.Name = "Highlight"
            highlight.Parent = unit.Instance
            highlight.Adornee = unit.Instance
            highlight.FillTransparency = 0.5
            highlight.FillColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 1

            -- Hover box
            local hoverFrame: Frame = playerUI.HoverFrame
            hoverFrame.Visible = true
            local hoverText: TextLabel = hoverFrame:WaitForChild("HoverText")
            hoverText.Text = unit.Name.." ("..unit.Id..") "

            UIS.InputChanged:Connect(function(input) -- Move with mouse
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mousePos = input.Position

                    -- Determine whether the frame appears left / right to cursor
                    local offsetX: number = 0

                    local camera: Camera = workspace.CurrentCamera
                    local screenX = camera.ViewportSize.X
                    if mousePos.X <= screenX / 2 then
                        offsetX = 20
                    else
                        offsetX = -hoverFrame.AbsoluteSize.X - 20
                    end

                    hoverFrame.Position = UDim2.fromOffset(mousePos.X + offsetX, mousePos.Y)
                end
            end)

        elseif data.mode == "Leave" then
            -- Glow Effect
            unit.Instance:WaitForChild("Highlight"):Destroy()

            -- Hover Box
            playerUI.HoverFrame.Visible = false

        else warn("Unknown Hover Mode") return end

    end

    -- Handler
    FH.RegisterClient(plr, MACROS.DISPLAY_NOTIFICATION, DisplayNotification)
    FH.RegisterClient(plr, MACROS.DISPLAY_ORDER, DisplayOrder)
    FH.RegisterClient(plr, MACROS.PLAYER_INPUT, PlayerInput)
    FH.RegisterClient(plr, MACROS.CHOOSE_ATTACK, ChooseAttack)
    FH.RegisterClient(plr, MACROS.INFO_BAR, InfoBar)
    FH.RegisterClient(plr, MACROS.HOVER_UNIT, HoverUnit)
end

return module