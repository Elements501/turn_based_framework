local module = {}
-- Services
local RS = game:GetService("ReplicatedStorage")
local SELF = require(RS.Unit)

-- Variables
local roleNumber: number = 0 -- 0: Server
local sharedList = {
    -- Units
    totalUnits = 0;
    unitList = {};
    -- Rounds
    roundNumber = 0,
    actionOrder = {}, -- Down the id number
}
local nextAction: BindableEvent = (RS:FindFirstChild("nextAction") :: BindableEvent?) or Instance.new("RemoteEvent")
    nextAction.Name = "nextAction"
    nextAction.Parent = RS

function module.init(id)
    if id == 0 then -- Server scripts: id == 0
        SELF.serverScript()
        return
    end
    -- Get All Tagged: Run init() for them. init with GetAttributes() -> List

    -- List init
    sharedList.totalEntity += 1
end

function module.serverScript()

    local function OrderUnits()
    end
    -- Add list for who go first
    nextAction:InvokeServver()
end

nextAction.OnServerInvoke = function()
    -- Read list is it your turn

    -- Invoke again if done
end

return module