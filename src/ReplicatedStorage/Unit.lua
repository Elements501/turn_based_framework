local Unit = {}
Unit.__index = Unit

-- Services
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local PS: Players = game:GetService("Players")

-- Data
local GAME_DATA: {[string]: {}} = require(RS:WaitForChild("GameData"))
local attackActions: GAME_DATA.AttackAction = GAME_DATA.attackActions
local MACROS: GAME_DATA.Macros = GAME_DATA.MACROS

-- Shared
local SHARED_LIST: {[string]: {}} = require(RS:WaitForChild("SharedList"))
local sharedList: SHARED_LIST.SharedList = SHARED_LIST

-- Package
local FH = require(RS:WaitForChild("FunctionHandler"))
type Data = {
    action: number,
    send: Player,
    receive: number,
}

-- Modules
local EffectSystem = require(RS:WaitForChild("EffectSystem"))
local BotSystem = require(RS:WaitForChild("BotSystem"))
local UnitUI = require(RS:WaitForChild("UnitUI"))

local function DeepCopy(original: {})
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = if type(value) == "table" then DeepCopy(value) else value
    end
    return copy
end

function Unit.new(data: {})
    return setmetatable(DeepCopy(data), Unit)
end

function Unit:Init(server)
    self.server = server -- Set server object

    local id: number = self.Id
    local part: Instance = self.Instance

    -- Register into shared state
    sharedList.unitList[id] = self
    sharedList.totalUnits += 1
    print(sharedList.unitList)

    -- Subsystems
    self.unitUI = UnitUI.new(part, self)
    self.unitEffect = EffectSystem.new(self, self.unitUI, id)
    self.botAction = BotSystem.new(self, id)

    -- Client handlers (player → server)
    FH.RegisterClient(id, MACROS.FINISH_ACTION, function() self:FinishAction() end)
    FH.RegisterClient(id, MACROS.ATTACK_ACTION, function() self:AttackAction() end)
    FH.RegisterClient(id, MACROS.APPLY_DAMAGE, function(data) self:ApplyDamage(data.skillList, data.target) end)

    -- Click detection
    local clickDetector: ClickDetector = Instance.new("ClickDetector")
    clickDetector.Name = "ClickDetector"
    clickDetector.Parent = part
    clickDetector.CursorIcon = "rbxassetid://"

    clickDetector.MouseHoverEnter:Connect(function(playerHovered)
        FH.ClientMessage({
            action = MACROS.HOVER_UNIT,
            send = id,
            receive = playerHovered,
            unit = self:Serialize(),
            mode = "Enter"
        })
    end)

    clickDetector.MouseHoverLeave:Connect(function(playerHovered)
        FH.ClientMessage({
            action = MACROS.HOVER_UNIT,
            send = id,
            receive = playerHovered,
            unit = self:Serialize(),
            mode = "Leave"
        })
    end)

    clickDetector.MouseClick:Connect(function(playerWhoClicked)
        FH.ClientMessage({
            action = MACROS.INFO_BAR,
            send = id,
            receive = playerWhoClicked,
            unit = self:Serialize(),
            returnUnit = sharedList.unitList[sharedList.actionOrder[sharedList.actionNumber - 1]]:Serialize() -- Actioning unit
        })
    end)
end

function Unit:Serialize() -- Create self copy without cyclic reference
    local data = {}
    for key, value in pairs(self) do
        if type(value) == "userdata" and typeof(value) ~= "Instance" then continue end -- Connect function and userdata
        if type(value) == "table" and getmetatable(value) ~= nil then continue end -- Class from the unit

        data[key] = value -- Copy a pure value table
    end
    return data
end

function Unit:FinishAction()
    self.server:RoundCounter()
end

function Unit:AttackAction()
    local plrOwner: Player = PS:FindFirstChild(self.Owner)
    if not plrOwner then warn("Unknown Player Action") return end
    if self.Skills == nil then warn("Unknown Attack Action") return end

    local enemyList = {}
    local allyList = {}
    for _, unitChecked in pairs(sharedList.unitList) do
        if unitChecked.Team == self.Team then
            table.insert(allyList, unitChecked:Serialize())
        else
            table.insert(enemyList, unitChecked:Serialize())
        end
    end

    FH.ClientMessage({
        action = MACROS.CHOOSE_ATTACK,
        send = self.Id,
        receive = plrOwner,
        unitList = self:Serialize(),
        enemyList = enemyList,
        allyList = allyList,
        skillList = self.Skills,
    })
end

function Unit:ApplyDamage(skillList: {}, target: number | {number})
    if self.Energy < skillList.Energy then warn("Insufficient Energy") return end

    for _, plr in ipairs(PS:GetPlayers()) do
        FH.ClientMessage({
            action = MACROS.DISPLAY_NOTIFICATION,
            send = self.Id,
            receive = plr,
            msg = {
                code = "Attack",
                attackerId = self.Id,
                attackerName = self.Name,
                skill = skillList,
            }
        })
    end

    self.Energy -= skillList.Energy
    self.unitUI:UpdateEnergy()

    if skillList.Target == "SingleEnemy" or skillList.Target == "SingleAlly" then
        local targetUnit = sharedList.unitList[target]
        if targetUnit then targetUnit:TakeDamage(self.Id, skillList) end

    elseif skillList.Target == "AllEnemy" or skillList.Target == "AllAlly" then
        if typeof(target) ~= "table" then warn("Unknown Target List") return end
        for _, targetId in ipairs(target) do
            local targetUnit = sharedList.unitList[targetId]
            if targetUnit then targetUnit:TakeDamage(self.Id, skillList) end
        end

    elseif skillList.Target == "Summon" then
        self.server:SummonUnit(skillList.Damage, self.Team, self.Owner)

    else warn("Unknown Target") return end

    task.wait(0.5) -- TODO: Animation
    self:FinishAction()
end

function Unit:TakeDamage(attackerId, skillList)
    if not attackerId then warn("Unknown Attacker") return end
    local id: number = self.Id
    local attacker = sharedList.unitList[attackerId]

    for _, plr in ipairs(PS:GetPlayers()) do
        FH.ClientMessage({
            action = MACROS.DISPLAY_NOTIFICATION,
            send = id,
            receive = plr,
            msg = {
                code = "Damage",
                targetId = id,
                targetName = self.Name,
                skill = skillList
            }
        })
    end

    if skillList.Effect ~= nil then
        for _, effect in ipairs(skillList.Effect) do
            self.unitEffect:ApplyEffect(false, effect, attacker)
        end
    end

    local damage: number? = skillList.Damage
    local nature: number? = skillList.Nature

    local function GetNatureModifier(): (number, number, number)
        local add = 0 local mult = 1 local naturePerc = 0
        if nature == 1 then
            add = attacker.unitEffect:GetEffect("PhyAdd") or 0
            mult = attacker.unitEffect:GetEffect("PhyMult") or 1
            naturePerc = attacker.Power

        elseif nature == 2 then
            add = attacker.unitEffect:GetEffect("MagicAdd") or 0
            mult = attacker.unitEffect:GetEffect("MagicMult") or 1
            naturePerc = attacker.Intelligence

        elseif nature == 3 then
            add = attacker.unitEffect:GetEffect("EffectAdd") or 0
            mult = attacker.unitEffect:GetEffect("EffectMult") or 1

        else warn("Unknown Nature") return end

        print("NATURE: ", nature, add, mult, naturePerc)
        return add, mult, naturePerc
    end
    local add: number, mult: number, naturePerc: number = GetNatureModifier()

    if damage >= 0 then -- Damage
        local attackAdd = attacker.unitEffect:GetEffect("AttackAdd") or 0
        local attackMult = attacker.unitEffect:GetEffect("AttackMult") or 1

        self.Health -= ( damage + attackAdd + add ) * (1 + naturePerc / 100) * attackMult * mult

    elseif damage < 0 then -- Healing
        local heal = -damage
        local healAdd = attacker.unitEffect:GetEffect("HealAdd") or 0
        local healMult = attacker.unitEffect:GetEffect("HealMult") or 1

        self.Health += ( heal + healAdd + add ) * (1 + naturePerc / 100) * healMult * mult

        local healPerc = attacker.unitEffect:GetEffect("HealPerc") or 0
        self.Health *= ( 1 + healPerc )
    end

    self.Health = math.round(self.Health * 10) / 10
    if self.Health > self.MaxHealth then
        self.Health = self.MaxHealth
    end
    self.unitUI:UpdateHealth()

    if self.Health <= 0 then
        self.server:RemoveUnit(id)
        self.Instance:Destroy()
        FH.RemoveRegister(id)
    end
end

function Unit:Action()
    local id: number = self.Id
    print("Actioned: " .. id, sharedList, self.Owner)

    -- Show info bar
    for _, plr in ipairs(PS:GetPlayers()) do
        FH.ClientMessage({
            action = MACROS.INFO_BAR,
            send = id,
            receive = plr,
            unit = self:Serialize(),
        })
    end

    self.unitEffect:ExecuteEffect()
    if sharedList.unitList[id] == nil then return end -- Unit died by effect
    self.unitEffect:DecreaseEffectDuration()

    if self.Energy < self.MaxEnergy then self.Energy += 1 end
    self.unitUI:UpdateEnergy()

    if self.Owner == "ai" then
        local action = self.botAction:ChooseAction(sharedList)
        self:ApplyDamage(action.skillList, action.target)
    else
        local plrOwner: Player = PS:FindFirstChild(self.Owner)
        if not plrOwner then warn("Unknown Player Action") return end
        FH.ClientMessage({
            action = MACROS.PLAYER_INPUT,
            send = id,
            receive = plrOwner,
            unitData = self:Serialize()
        })
    end
end

return Unit
