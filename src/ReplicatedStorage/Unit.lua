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

    local function CreateHpBar(): {Instance}
        local topBar: BillboardGui = Instance.new("BillboardGui")
        topBar.Parent = part
        topBar.Adornee = part
        topBar.Name = "HpBar " .. id
        topBar.Size = UDim2.fromScale(5, 2)
        topBar.ExtentsOffset = Vector3.new(0, 6, 0)

        local UIListLayout: UIListLayout = Instance.new("UIListLayout")
        UIListLayout.Parent = topBar
        UIListLayout.Name = "UIListLayout"
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

        -- Hp Bar
        local hpBarBackground: Frame = Instance.new("Frame")
        hpBarBackground.Parent = topBar
        hpBarBackground.Name = "Health Bar"
        hpBarBackground.BackgroundColor3 = Color3.new(1, 1, 1)
        hpBarBackground.BackgroundTransparency = 0
        hpBarBackground.Size = UDim2.fromScale(1, 0.5)
        hpBarBackground.ZIndex = 0
        hpBarBackground.LayoutOrder = 2

        local hpBarBar: Frame = Instance.new("Frame")
        hpBarBar.Parent = hpBarBackground
        hpBarBar.BackgroundColor3 = Color3.new(0, 0, 0)
        hpBarBar.BackgroundTransparency = 0
        hpBarBar.Size = UDim2.fromScale(0.96, 0.8)
        hpBarBar.Position = UDim2.fromScale(0.02, 0.1)
        hpBarBar.ZIndex = 1

        local hpBarText: TextLabel = Instance.new("TextLabel")
        hpBarText.Parent = hpBarBackground
        hpBarText.Text = unit.Health .. " / " .. unit.MaxHealth
        hpBarText.TextColor3 = Color3.new(0.5, 0.5, 0.5)
        hpBarText.Size = UDim2.fromScale(1, 1)
        hpBarText.TextScaled = true
        hpBarText.BackgroundTransparency = 1
        hpBarText.ZIndex = 2

        -- Status Effect
        local statusBackground: Frame = Instance.new("Frame")
        statusBackground.Parent = topBar
        statusBackground.Name = "Status Bar"
        statusBackground.Size = UDim2.fromScale(1, 0.5)
        statusBackground.BackgroundTransparency = 1
        statusBackground.ZIndex = 0
        statusBackground.LayoutOrder = 1

        local UiPadding: UIPadding = Instance.new("UIPadding")
        UiPadding.Parent = statusBackground
        UiPadding.PaddingBottom = UDim.new(0.05, 0)

        local UiGridLayout: UIGridLayout = Instance.new("UIGridLayout")
        UiGridLayout.Parent = statusBackground
        UiGridLayout.Name = "UIGridLayout"
        UiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UiGridLayout.CellPadding = UDim2.fromScale(0.02, 0.05)
        UiGridLayout.CellSize = UDim2.fromScale(0.2, 1)

        local effectGui: Frame = Instance.new("Frame") -- Template, no parent
        effectGui.BackgroundTransparency = 1

        local effectGuiImage: ImageLabel = Instance.new("ImageLabel")
        effectGuiImage.Name = "EffectImage"
        effectGuiImage.Parent = effectGui
        effectGuiImage.Size = UDim2.fromScale(1, 1)
        effectGuiImage.ZIndex = 0

        local effectGuiText: TextLabel = Instance.new("TextLabel")
        effectGuiText.Name = "EffectText"
        effectGuiText.Parent = effectGui
        effectGuiText.Size = UDim2.fromScale(1, 1)
        hpBarText.TextColor3 = Color3.new(0.5, 0.5, 0.5)
        hpBarText.TextScaled = true
        effectGuiText.BackgroundTransparency = 1
        effectGuiText.ZIndex = 1

        return {
            [1] = topBar,
            [2] = hpBarBackground,
            [3] = hpBarBar,
            [4] = hpBarText,
            [5] = statusBackground,
            [6] = effectGui,
            [7] = {} -- List for holding effectGui Clones
        } -- TEMP: no return False case; TODO: Add checking
    end
    local unitUI: {} = CreateHpBar()
    if not unitUI then warn("Failed to Create HP Bar") return end -- False -> Error

    -- FH.ServerMessage({ -- TODO: Make units automatically add to id: 0, instead of FindUnits()
    --     action = 5,
    --     send = id,
    --     receive = 0,
    -- })

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

    local effectId: number = 1
    local function ApplyEffect(data) -- No event
        local effect: {} = data.skillList.Effect or nil
        if effect == nil then return end -- Attack has no effect

        -- Create Gui
        local effectFrame: Frame = unitUI[5]
        local effectTemplate: Frame = unitUI[6]

        local newEffect: Frame = effectTemplate:Clone()
        newEffect.Name = effect[effectKeys[1]]
        newEffect.Parent = effectFrame

        newEffect.EffectText.Text = effect[effectKeys[2]]
        -- TODO: Set newEffect.EffectImage

        -- Add effect into the list
        if next(unit.Effect) == nil then unit.Effect = {} end -- Init .Effect table
        effect[effectKeys[0]] = effectId -- Give unique effectId
        unitUI[7][effectId] = newEffect
        effectId += 1
        -- Prevent double insertion in .Effect
        if not data.selfApply then table.insert(unit.Effect, effect) end -- Self apply does not have .Damage
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
        -- Apply Effect
        ApplyEffect(data)

        -- Calculate damage taken; TODO: Resistance + Critical + Vulnerability
        local damage: number | nil = data.skillList.Damage
        local nature: number | nil = data.skillList.Nature

        local function GetEffect(key: string): number?
            local num: number? = nil
            for _, effect in pairs(unit.Effect) do
                if effect and effect[key] then num = (num or 0) + effect[key] end
            end
            return num
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

        -- Update Gui
        unitUI[4].Text = unit.Health .. " / " .. unit.MaxHealth
        unitUI[3].Size = UDim2.fromScale(unit.Health / unit.MaxHealth * 0.96, unitUI[3].Size.Y.Scale)

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

    local function botAction()
        -- Obtain Enemy
        local enemyIdList: {number} = {} -- List of enemy stats
        for _, enemy in pairs(sharedList.unitList) do -- Cannot ipairs() as unitList has nil holes after unit dies
            if enemy == nil then continue end -- Dead unit has [_] = nil
            if enemy.Team ~= unit.Team then
                table.insert(enemyIdList, enemy.Id)
            end
        end
        -- Obtain Allies
        local allyIdList: {number} = {} -- List of enemy stats
        for _, ally in pairs(sharedList.unitList) do -- Cannot ipairs() as unitList has nil holes after unit dies
            if ally == nil then continue end -- Dead unit has [_] = nil
            if ally.Team == unit.Team then
                table.insert(allyIdList, ally.Id)
            end
        end

        -- Smart Action
        local attackList: {number} = unit.Skills
        local rngAction: number = math.random(1, #attackList)

        local attackAction: {} = attackActions[attackList[rngAction]]
        if attackAction.Target == 1 then -- Single Attack
            local randEnemyId: number = enemyIdList[math.random(1, #enemyIdList)]
            ApplyDamage({ -- Call func directly to mock player control; TODO: Change to use Events
                action = 4,
                send = id,
                receive = id,
                skillList = attackAction,
                target = randEnemyId
            })
        elseif attackAction.Target == 2 then -- Ally Attack
            local randAllyId: number = allyIdList[math.random(1, #allyIdList)]
            ApplyDamage({ -- Call func directly to mock player control; TODO: Change to use Events
                action = 4,
                send = id,
                receive = id,
                skillList = attackAction,
                target = randAllyId
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

    local function DecreaseEffectDuration()
        local effectList: {} = unit.Effect
        if not next(effectList) then return end -- If effectList is {}

        for effectNumber, effect in pairs(effectList) do
            if not effect then continue end -- effect is nil. Sparse list is not processed

            -- Pre-existing Effects
            if effect[effectKeys[0]] == nil then
                ApplyEffect({selfApply = true, skillList = {Effect = effect}}) -- Mock effect is applied by attack
            end

            -- List
            effect[effectKeys[2]] -= 1 -- TODO: effect[2] == -1 for infinite duration
            --Gui
            unitUI[7][ effect[effectKeys[0]] ].EffectText.Text = effect[effectKeys[2]]

            if effect[ effectKeys[2] ] == 0 then -- Run out
                -- Gui
                unitUI[7][ effect[ effectKeys[0]] ]:Destroy()
                unitUI[7][ effect[ effectKeys[0]] ] = nil -- Create sparse list
                -- List
                effectList[effectNumber] = nil
            end
        end
    end

    local function ExecuteEffect()
        local effectList: {} = unit.Effect
        if not next(effectList) then return end

        for _, effect in ipairs(effectList) do
            if effect[effectKeys[2]] <= 0 then effect[effectKeys[2]] = 0 return end
            print("Effect Executed", id, effect)

            local function Damage()
                local Dmg: number | nil = effect[effectKeys[3]]
                if Dmg == nil then return end

                FH.ServerMessage({
                    action = 4,
                    send = id,
                    receive = id,
                    skillList = {
                        Nature = 3,
                        Damage = Dmg,
                    } -- Mask effect as skill
                })
            end
            task.spawn(Damage)

            local function Heal() -- Separate from Damage: process effect with both [3] and [6]
                local heal: number | nil = effect[effectKeys[6]]
                if heal == nil and effect[effectKeys[7]] == nil then return end

                FH.ServerMessage({
                    action = 4,
                    send = id,
                    receive = id,
                    skillList = {
                        Nature = 3,
                        Damage = -heal, -- Indicate TakeDamage() that this is heal
                    } -- Mask effect as skill
                })
            end
            task.spawn(Heal)
        end

    end

    local function Action()
        print("Actioned: " .. id, sharedList, unit.Owner)

        ExecuteEffect()
        if unit == nil then return end -- Unit died by effect
        DecreaseEffectDuration()

        if unit.Owner == "ai" then
            botAction()
            return
        end

        local plrOwner: Player = game:GetService("Players"):FindFirstChild(unit.Owner)
        if not plrOwner then warn("Unknown Player Action") return end
        FH.ClientMessage({
            action = 1,
            send = id,
            receive = plrOwner,
            unitData = unit
        })
    end

    -- Handler
    FH.RegisterServer(id, 4, TakeDamage)
    FH.RegisterServer(id, 7, Action)

    FH.RegisterClient(id, 2, FinishAction)
    FH.RegisterClient(id, 3, AttackAction)
    FH.RegisterClient(id, 4, ApplyDamage)

end

return module