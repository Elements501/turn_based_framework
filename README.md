# Turn-based Game Framework
Framework for a turn-based game that can be used as a base before customisation.

# Version
**v0.2** — `b709b14` (main)
- Full UI features

# Mechanism
- Server <-> Client communicate using `FunctionHandler.lua`
    - `RegisterClient(key, action, function)` records the function, called via the `action` number to the `key` (unit id or Player)
    - `ClientMessage(data)` dispatches to the registered function; server components call each other's methods directly (no server-to-server FH routing)

- Communication uses a single RemoteFunction `ClientAction`:
    ```lua
    -- ClientAction: RemoteFunction (data: list)
    data = {
        action: number
        --   21–26: Server → Client (DISPLAY_NOTIFICATION, PLAYER_INPUT, CHOOSE_ATTACK, DISPLAY_ORDER, INFO_BAR, HOVER_UNIT)
        --   41–43: Client → Server (FINISH_ACTION, ATTACK_ACTION, APPLY_DAMAGE)
        send:    number | Player
        receive: number | Player
        -- misc. data
    }
    ```

- Permanent game data is stored in `GameData.lua`. Changing game state is stored in `SharedList.lua`

- `Server`, `Unit`, `EffectSystem`, `BotSystem`, and `UnitUI` are all OOP classes instantiated with `.new()`

- **Energy system** — each unit has `Energy` / `MaxEnergy`. Skills cost `Energy` to use; a unit gains +1 energy at the start of its turn. Skills whose cost exceeds current energy are unavailable (hidden from bot, blocked on client)

- **Turn order** — `Server:OrderUnits()` sorts all units by Speed (ties broken by Id). `Server:RoundCounter()` broadcasts the current order and highlights the acting unit via `DISPLAY_ORDER`

- **Unit interactions (client-side)**
    - Hovering a unit shows a tooltip (name + id) that follows the cursor, and adds a `Highlight` glow to the model
    - Clicking a unit opens the **Info Bar** (bottom panel) showing that unit's stats; a BACK button returns to the currently acting unit's info
    - The acting unit's info is shown automatically at the start of its turn

- **Notifications** — side panel shows styled messages for `"Attack"` (attacker used skill) and `"Damage"` (target took damage) events; fade out after 10 s

- Attack targets are plain strings: `"SingleEnemy"`, `"SingleAlly"`, `"AllEnemy"`, `"AllAlly"`, `"Summon"`

# TODO
- [ ] Smart bot action (currently random among affordable skills)
- [ ] Animation Handler
- [ ] SFX
- [ ] Reset/Preset
- [ ] Magic and Effect nature buffs (`natureBuff` for Nature 2 & 3)
- [ ] HealPercent-only heal
- [ ] Implement infinite-duration effects (Duration = -1)
- [ ] Unit icon images (Info Bar + effect icons)
- [ ] Summon target team routing (`.Target = "Summon"` → specify team)

# Credits
- FireAlexGame
