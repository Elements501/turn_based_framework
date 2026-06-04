# Turn-based Game Framework
Framework for a turn-based game that can be used as a base before customisation.

# Mechanism
- Two module scripts `Server.lua` and `Client.lua`
    - `Server` handles server-sided logic and is **OOP** for each unit
    - `Client.lua` handles client-sided logic which allows players to act
- Two modules scripts communicate to each other (within and away) using Functions
    > Functions are used as it yields, so Roblox does not tries to run everything at once; however, Functions can only bound one function, so a handler is created to multi-thread. <!> The output of functinos are not used yet, but can be

    - `ServerAction` is within `Server.lua` to tell units to act.
    ```lua
    -- ServerAction: BindableFunction (data: list)
    data = {
        action: number -- {1: Next, 2: Round, 3: Reorder, 4: Damage, 5: Add, 6: Death, 7: Act}
        send: number -- id
        receive: number -- id | id table
        -- misc. data
    }
    ```
    - `ClientAction` is used to communicate between `Server.lua` and `Client.lua`
    ```lua
    -- ClientAction: RemoteFunction (data: list)
    data = {
        action: number -- {-2: Transfer Notification, -1: (DEP); 1: PlayerAct, 2: Rest, 3: AttackAction, 4: AttackTarget}
        send: number -- id / plr
        receive: number -- plr | plr table / id
        -- misc. data
    }
- `ApplyDamage(): function` reads `data.skillList.Target` to communicate its action, and then expects a format in the package: set in the Data list of `attackActionList`
    ``` lua
    data = {
        (...) -- Essential Details
        skillList = {
            Nature: "number", -- Target chooses type of effect affecting the attack: eg) {[1] = "Physical", [2] = "Magical", [3]="Effect"}
            Target: "number", -- skillList.Target = { -3: All Attack, -2: Enemy Area Attack, -1: All Enemy Attack, 0: Summon Unit, 1: Single Attack, 2: Ally Attack, 3: All Ally Attack, 4: Self Attack}
        }
    }
    ```
- `Status Effects` uses a `.Effect: {}` list to contains all the status effect in `unitList[id]`, it is a sparse numbered list with each index meaning
    ``` lua
    {
        [0] = "effectId" -- Pairs effectGui with effect in unitList; used within a unit
        [1] = "Name", [2] = "Duration",
        [3] = "Damage", [4] = "DamageAdd", [5] = "DamageMult",
        [6] = "HealConst", [7] = "HealPercent", [8] = "HealAdd", [9] = "HealMult",
        [10] = "AttackAdd", [11] = "AttackMult",
        [12] = "OneAdd", [13] = "OneMult",
        [14] = "TwoAdd", [14] = "TwoMult",
        [15] = "ThreeAdd", [16] = "ThreeMult",
    }
    ```

# Credits
- FireAlexGame