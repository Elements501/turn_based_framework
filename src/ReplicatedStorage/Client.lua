local module = {}
-- Services
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local SELF: ModuleScript = RS:WaitForChild("Client")

local clientAction: RemoteFunction = (RS:FindFirstChild("ClientAction") :: RemoteFunction?) or Instance.new("RemoteFunction")
    clientAction.Name = "ClientAction"
    clientAction.Parent = RS
local clientFuncList = {}

function module.Init(plr)
    -- GUI
    local function CreateGui(): {Instance}
        local screenGui: ScreenGui = Instance.new("ScreenGui")
        screenGui.Parent = plr.PlayerGui
        local mainFrame: Frame = Instance.new("Frame")
        mainFrame.Parent = screenGui
        mainFrame.Size = UDim2.fromScale(1, 0.2)
        mainFrame.Position = UDim2.fromScale(0, 0.8)
        mainFrame.BackgroundTransparency = 1
        local passButton: TextButton = Instance.new("TextButton")
        passButton.Parent = mainFrame
        passButton.Text = "Pass"
        passButton.Size = UDim2.fromScale(0.1, 1)

        screenGui.Enabled = false
        return {screenGui, passButton}
    end
    local guiInstances: {Instance} = CreateGui()
    local screenGui: ScreenGui = guiInstances[1]
    local passButton: TextButton = guiInstances[2]

    -- GUI Functions
    local unitId: number = 0
    passButton.Activated:Connect(function()
        screenGui.Enabled = false
        clientAction:InvokeServer({
            action = 2,
            send = plr,
            receive = unitId
        })
    end)

    local function PlayerInput(id, unitData)
        print("Player Received", id, unitData)
        unitId = id
        screenGui.Enabled = true
    end

    clientAction.OnClientInvoke = function(data)
        if data.receive ~= plr then return end

        if (data.action == 1) then PlayerInput(data.send, data.unitData) end
    end
end

return module