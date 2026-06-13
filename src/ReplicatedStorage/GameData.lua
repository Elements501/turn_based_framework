--!strict
export type Macros = {[number]: any}

local MACROS = {
    -- Server <-> Server Actions
    ROUND_COUNTER = 1,
    ORDER_UNITS = 3,
    TAKE_DAMAGE = 4,
    SUMMON_UNIT = 5,
    REMOVE_UNIT = 6,
    UNIT_ACTION = 7,
    -- Server -> Client Actions
    DISPLAY_NOTIFICATION = -2,
    PLAYER_INPUT = 1,
    CHOOSE_ATTACK_TARGET = 4,
    -- Client -> Server Actions
    FINISH_ACTION = 2,
    ATTACK_ACTION = 3,
    APPLY_DAMAGE = 4,
    -- Target
    SELF_ATTACK = -1,
    SUMMON_ATTACK = 0,
    SINGLE_ENEMY_ATTACK = 1,
    MULTIPLE_ENEMY_ATTACK = 2,
    ALL_ENEMY_ATTACK = 3,
    SINGLE_ALLY_ATTACK = 4,
    MULTIPLE_ALLY_ATTACK = 5,
    ALL_ALLY_ATTACK = 6,
}

export type EffectVariable = {
    EffectId: number?,
    Name: string,
    Duration: number,
    -- Constant Damage
    Damage: number?,
    DamageAdd: number?,
    DamageMult: number?,
    -- Constant Heal
    HealConst: number?,
    HealPerc: number?,
    HealAdd: number?,
    HealMult: number?,
    -- Damage Buff
    AttackAdd: number?,
    AttackMult: number?,
    -- Attack Nature Buff
    PhyAdd: number?,
    PhyMult: number?,
    MagicAdd: number?,
    MagicMult: number?,
    EffectAdd: number?,
    EffectMult: number?,
}

export type AttackAction = {
    [number]: {
        Name: string,
        Damage: number,
        Nature: number,
        Target: number,
        Effect: EffectVariable?
    }
}

local attackActions: AttackAction = {
    [1] = {
        Name = "Scream",
        Damage = 2,
        Nature = 1,
        Target = MACROS.ALL_ENEMY_ATTACK,
        Effect = nil
    },
    [2] = {
        Name = "Stab",
        Damage = 5,
        Nature = 1,
        Target = MACROS.SINGLE_ENEMY_ATTACK,
        Effect = nil
    },
    [3] = {
        Name = "Bump",
        Damage = 3,
        Nature = 1,
        Target = MACROS.SINGLE_ENEMY_ATTACK,
        Effect = nil
    },
    [4] = {
        Name = "Heal",
        Damage = -2,
        Nature = 2,
        Target = MACROS.SINGLE_ALLY_ATTACK,
        Effect = { Name = "Regeneration", Duration = 2, HealConst = 1 }
    },
    [5] = {
        Name = "Poison",
        Damage = 1,
        Nature = 2,
        Target = MACROS.SINGLE_ENEMY_ATTACK,
        Effect = { Name = "Poison", Duration = 3, Damage = 1 }
    },
    [6] = {
        Name = "Mitosis",
        Damage = 2,
        Nature = 2,
        Target = MACROS.SUMMON_ATTACK,
        Effect = nil
    },
}

export type UnitType = {
    [number]: {
        Name: string,
        Type: number,
        Power: number,
        Speed: number,
        MaxHealth: number,
        Health: number,
        Effect: EffectVariable?,
        Skills: {number},
        Owner: string|Players?,
        Team: string?,
        Id: number?,
    }
}

local unitTypes: UnitType = {
    [1] = {
        Name = "Goblin",
        Type = 1,
        Power = 5,
        Speed = 3,
        MaxHealth = 10,
        Health = 10,
        Effect = {},
        Skills = {1, 2}
    },
    [2] = {
        Name = "Slime",
        Type = 2,
        Power = 3,
        Speed = 1,
        MaxHealth = 20,
        Health = 20,
        Effect = {},
        Skills = {3, 6}
    },
    [3] = {
        Name = "Spider",
        Type = 3,
        Power = 5,
        Speed = 2,
        MaxHealth = 8,
        Health = 8,
        Effect = {},
        Skills = {3, 5}
    },
    [4] = {
        Name = "Spirit",
        Type = 4,
        Power = 2,
        Speed = 5,
        MaxHealth = 8,
        Health = 8,
        Effect = {
            [1] = { Name = "Spirit Mending", Duration = 99, HealConst = 0.5, HealMult = 1.5, },
        },
        Skills = {1, 4}
    },
}

-- Handler
local gameData = {
    ["attackActions"] = table.freeze(attackActions),
    ["unitTypes"] = table.freeze(unitTypes),
    ["MACROS"] = table.freeze(MACROS),
}

return gameData -- types are automatically exported as gameData.[type_name]