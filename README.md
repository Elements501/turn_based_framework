# Turn-based Game Framework
Framework for a turn-based game that can be used as a base before customisation.

# Version
**Latest stable** — `9564f7b` (main)
- Refactored scripts into shorter modules

# Mechanism
- Server <-> Server and Server <-> Client communicate using the `FunctionHandler.lua` module
    - `Register(id, action, function)` records the function, which can be called using the number `action` to the number `id`
    - `ServerMessage()` and `ClientMessage()` then calls the registered functions

- Server <-> Client communicate to each other (within and away) using Functions in `FunctionHandler.lua`
    > Functions are used as it yields, so Roblox does not tries to run everything at once; however, Functions can only bound one function, so a handler is created to multi-thread.
    - `ClientAction` is used to communicate between Server and Client
    ```lua
    -- ClientAction: RemoteFunction (data: list)
    data = {
        action: number -- {-2: Transfer Notification, -1: (DEP); 1: PlayerAct, 2: Rest, 3: AttackAction, 4: AttackTarget}
        send: number | Player
        receive: number | Player
        -- misc. data
    }
    ```

- Permanent game data is stored in `GameData.lua`. Changing game data is stored in `SharedList.lua`

# TODO
- [ ] Smart bot action
- [ ] Animation Handler
- [ ] UI and SFX
- [ ] Reset/Preset
- [ ] Implement TODO target styles and effects

# Credits
- FireAlexGame