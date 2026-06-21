local module = {}

local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RUNS: RunService = game:GetService("RunService")

export type Package = {
    action: number,
    send: number | Player,
    receive: number | Player,
    [string]: any,
}

type UnitAction = (data: Package) -> ()

local clientAction: RemoteFunction = (RS:FindFirstChild("ClientAction") :: RemoteFunction?) or Instance.new("RemoteFunction")
    clientAction.Name = "ClientAction"
    clientAction.Parent = RS

type ClientFunction = {[number | Player]: {[number]: UnitAction}}

local clientFunctions: ClientFunction = {}

local function Dispatch(funcList: ClientFunction, data: Package)
    local unitFunction: {[number]: UnitAction} = funcList[data.receive :: number]
    if not unitFunction then return end

    local unitAction: UnitAction = unitFunction[data.action]
    if not unitAction then return end

    task.spawn(unitAction, data)
end

-- Initialisation
function module.RegisterClient(key: number | Player, action: number, func: UnitAction)
    if not clientFunctions[key] then clientFunctions[key] = {} end
    clientFunctions[key][action] = func
end

function module.RemoveRegister(id: number)
    clientFunctions[id] = nil
end

-- Send Package
function module.ClientMessage(data: Package)
    if not data then warn("Missing Data") return end
    if type(data.receive) == "number" then
        clientAction:InvokeServer(data)
    elseif data.receive:IsA("Player") then
        clientAction:InvokeClient(data.receive :: Player, data)
    else warn("Wrong Client Format") return end
end

-- Receive Package
if RUNS:IsServer() then
    clientAction.OnServerInvoke = function(plr, data)
        if plr ~= data.receive and plr ~= data.send then warn("Receiver Discrepancy") return end -- Validation
        Dispatch(clientFunctions, data)
    end
elseif RUNS:IsClient() then
    clientAction.OnClientInvoke = function(data)
        Dispatch(clientFunctions, data)
    end
end

return module