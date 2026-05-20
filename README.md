# Turn-based Game Framework
Framework for a turn-based game that can be used as a base before customisation.

# Mechanism
- Two module scripts `Server.lua` and `Client.lua`
    - `Server` handles server-sided logic and is **OOP** for each unit
    - `Client.lua` handles client-sided logic which allows players to act
- Two modules scripts communicate to each other (within and away) using Events
    - `ServerAction` is within `Server.lua` to tell units to act.
    ```lua
    -- ServerAction: BindableFunction (data: list)
    data = {
        action: number -- {0: Start, 1: Next, 2: Round, 3: Reorder, 4: Damage, 5: Add, 6: Death, 7: Act}
        send: number -- id
        receive: number -- id | id table
        -- misc. data
    }
    ```
    - `ClientAction` is used to communicate between `Server.lua` and `Client.lua`
    ```lua
    -- ClientAction: RemoteFunction (data: list)
    data = {
        action: number -- {-1: Transfer Data; 1: PlayerAct, 2: Rest, 3: Attack, 4: PlayerAttack}
        send: number -- id / plr
        receive: number -- plr | plr table / id
        -- misc. data
    }
    ```

# Credits
- FireAlexGame