local module = {}
-- Services
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local PS: Players = game:GetService("Players")

-- Data
local GAME_DATA: {[string]: {}} = require(RS:WaitForChild("GameData"))
type AttackAction = GAME_DATA.AttackAction
type EffectVariable = GAME_DATA.EffectVariable
type UnitType = GAME_DATA.UnitType
local attackActions: AttackAction = table.clone(GAME_DATA.attackActions)
local effectKeys: {[number]: string} = table.clone(GAME_DATA.effectKeys)
local unitTypes: UnitType = table.clone(GAME_DATA.unitTypes)

-- Shared
local SHARED_LIST: {[string]: {}} = require(RS:WaitForChild("SharedList"))
local sharedList: SHARED_LIST.SharedList = SHARED_LIST

-- Package
local FH = require(RS:WaitForChild("FunctionHandler"))

-- Modules
local EffectSystem = require(RS:WaitForChild("EffectSystem"))
type Effect = EffectSystem.EffectSystemType
local BotSystem = require(RS:WaitForChild("BotSystem"))
type botAction = BotSystem.BotSystemType
local UiSystem = require(RS:WaitForChild("UiSystem"))
type UnitUi = UiSystem.UiSystemType

function module.UnitScript(part: Instance, metadata: {} | nil, id: number)
    local unit: {} = sharedList.unitList[id]
    -- Initialisation
    local function updateList(): boolean -- Check in onto the sharedList as a Unit
        -- Check In
        local baseStat = unitTypes[metadata.unitTypeNum]
        if not baseStat then warn("Unknown unitTypeNum", metadata and metadata.unitTypeNum) return false end

        local unitData = {}
        for key, value in pairs(baseStat) do
            unitData[key] = value
        end
        unitData.Team = metadata.Team
        unitData.Owner = metadata.Owner
        unitData.Id = id

        sharedList.unitList[id] = unitData -- sharedList.unitList[id] shares same address as unit, now unit can edit sharedList.unitList[id]
        unit = unitData
        sharedList.totalUnits += 1

        print(sharedList.unitList)
        return true
    end
    if not updateList() then warn("Failed to Check In") return end -- Run check in with False -> ERROR

    -- FH.ServerMessage({ -- TODO: Make units automatically add to id: 0, instead of FindUnits()
    --     action = 5,
    --     send = id,
    --     receive = 0,
    -- })

    -- Modules
    local unitUI: UnitUi = UiSystem.new(part, unit)
    local unitEffect: Effect = EffectSystem.new(unit, unitUI, id)
    local botAction: botAction = BotSystem.new(unit, attackActions, id)

    -- Unit Action
    local function FinishAction() -- No event
        FH.ServerMessage({
            action = 1,
            send = id,
            receive = 0,
        })
    end

    local function AttackAction()
        local plrOwner: Player = game:GetService("Players"):FindFirstChild(unit.Owner)
        if not plrOwner then warn("Unknown Player Action") return end

        if unit.Skills == nil then warn("Unknown Attack Action") return end

        local enemyList = {}
        local allyList = {}
        -- Obtain Enemies
        for _, unitChecked in pairs(sharedList.unitList) do
            if unitChecked.Team == unit.Team then continue end
            table.insert(enemyList, unitChecked)
        end
        -- Obtain Allies
        for _, unitChecked in pairs(sharedList.unitList) do
            if unitChecked.Team ~= unit.Team then continue end
            table.insert(allyList, unitChecked)
        end

        FH.ClientMessage({
            action = 4,
            send = id,
            receive = plrOwner,
            Type = unit.Type, --TODO: Investigate what is this for
            enemyList = enemyList,
            allyList = allyList,
            skillList = unit.Skills,
        })
    end

    local function ApplyDamage(data)
        print("Attack Used: ", data.skillList, "; On unit:", data.target)
        if data.skillList.Target == 1 or data.skillList.Target == 2 then -- Single or Ally Attack
            FH.ServerMessage({
                action = 4,
                send = id,
                receive = data.target,
                skillList = data.skillList,
            })
        elseif data.skillList.Target == -1 then -- Area Attack
            if typeof(data.target) ~= "table" then warn("Unknown Enemy List") return end
            for _, enemyId in ipairs(data.target) do
                FH.ServerMessage({
                    action = 4,
                    send = id,
                    receive = enemyId,
                    -- Extra
                    skillList = data.skillList
                })
            end
        elseif data.skillList.Target == 0 then -- Summon Ally Unit
            FH.ServerMessage({
                action = 5,
                send = id,
                receive = 0,
                -- Extra
                skillList = data.skillList
            })
        else warn("Unknown Target") return end

        task.wait(0.5) -- TODO: Animation
        FinishAction()
    end

    local function TakeDamage(data) -- server 4
        -- Notification
        for _, plr in ipairs(PS:GetPlayers()) do
            FH.ClientMessage({
                action = -2,
                send = id,
                receive = plr,
                msg = {
                    code = 1,
                    attackerId = data.send,
                    attackerName = sharedList.unitList[data.send].Name,
                    targetId = id,
                    targetName = unit.Name,
                    skill = data.skillList
                }
            })
        end

        if unit == nil then return end
        unitEffect:ApplyEffect(data)

        -- Calculate damage taken; TODO: Resistance + Critical + Vulnerability
        local damage: number? = data.skillList.Damage
        local nature: number? = data.skillList.Nature

        local function GetEffect(key)
            return unitEffect:GetEffect(key)
        end

        if damage >= 0 then -- Dealing damage
            local attackAdd = GetEffect(effectKeys[10]) or 0
            local attackMult = GetEffect(effectKeys[11]) or 1
            local Add: number; local Mult: number

            if nature == 1 then
                Add = GetEffect(effectKeys[12]) or 0; Mult = GetEffect(effectKeys[13]) or 1
                unit.Health -= ( damage + attackAdd + Add ) * (1 + unit.Power / 100) * attackMult * Mult
            elseif nature == 2 then
                Add = GetEffect(effectKeys[14]) or 0; Mult = GetEffect(effectKeys[15]) or 1
                unit.Health -= ( damage + attackAdd + Add ) * (1 + 0 / 100) * attackMult * Mult -- TODO: Stats that replace 0
            elseif nature == 3 then
                Add = GetEffect(effectKeys[16]) or 0; Mult = GetEffect(effectKeys[17]) or 1
                unit.Health -= ( damage + attackAdd + Add ) * (1 + 0 / 100) * attackMult * Mult
            end
        elseif damage < 0 then -- Doing healing
            local heal = -damage
            local healPerc = GetEffect(effectKeys[7]) or 0
            local healAdd = GetEffect(effectKeys[8]) or 0
            local healMult = GetEffect(effectKeys[9]) or 1
            local Add: number; local Mult: number

            if nature == 1 then
                Add = GetEffect(effectKeys[12]) or 0; Mult = GetEffect(effectKeys[13]) or 1
                unit.Health += ( heal + healAdd + Add ) * (1 + unit.Power / 100) * healMult * Mult
                unit.Health *= ( 1 + healPerc )
            elseif nature == 2 then
                Add = GetEffect(effectKeys[14]) or 0; Mult = GetEffect(effectKeys[15]) or 1
                unit.Health += ( heal + healAdd + Add ) * (1 + 0 / 100) * healMult * Mult
                unit.Health *= ( 1 + healPerc )
            elseif nature == 3 then
                Add = GetEffect(effectKeys[16]) or 0; Mult = GetEffect(effectKeys[17]) or 1
                unit.Health += ( heal + healAdd + Add ) * (1 + 0 / 100) * healMult * Mult
                unit.Health *= ( 1 + healPerc )
            end
        end
        unit.Health = math.round(unit.Health * 10) / 10
        if unit.Health > unit.MaxHealth then
            unit.Health = unit.MaxHealth
            -- TODO: Indicate skills that can overheal
        end

        unitUI:UpdateHealth(unit.Health, unit.MaxHealth)

        if unit.Health <= 0 then
            FH.ServerMessage({
                action = 6,
                send = id,
                receive = 0,
            })
            part:Destroy()
            FH.RemoveRegister(id) -- Kill all communications
        end
    end

    local function Action()
        print("Actioned: " .. id, sharedList, unit.Owner)

        unitEffect:ExecuteEffect()
        if unit == nil then return end -- Unit died by effect
        unitEffect:DecreaseEffectDuration()

        if unit.Owner == "ai" then
            local action = botAction:ChooseAction(sharedList)
            ApplyDamage({
                action = 4,
                send = id,
                receive = id,
                skillList = action.skillList,
                target = action.target,
            })
        else
            local plrOwner: Player = game:GetService("Players"):FindFirstChild(unit.Owner)
            if not plrOwner then warn("Unknown Player Action") return end
            FH.ClientMessage({
                action = 1,
                send = id,
                receive = plrOwner,
                unitData = unit
            })
        end
    end

    -- Handler
    FH.RegisterServer(id, 4, TakeDamage)
    FH.RegisterServer(id, 7, Action)

    FH.RegisterClient(id, 2, FinishAction)
    FH.RegisterClient(id, 3, AttackAction)
    FH.RegisterClient(id, 4, ApplyDamage)

end

return module