# Turn-based Game Framework
Framework for a turn-based game that can be used as a base before customisation.

# Mechanism
- Two module scripts `Unit.lua` and `Player.lua`
    - `Unit.lua` handles server-sided logic and is **OOP** for each unit
    - `Player.lua` handles client-sided logic which allows players to act
- Two modules scripts communicate to each other (within and away) using Events
    - `nextRound` is within `Unit.lua` to tell units to act.
    ```lua
    -- Event(data: list)
    data = {
        action: number -- {0: Start, 1: Next, 2: Round, 3: Reorder, 4: Action, 5: Add, 6: Death, 7: Act, 8: React}
        send: number -- id
        receive: number -- id table
        -- misc. data
    }

# Credits
- FireAlexGame