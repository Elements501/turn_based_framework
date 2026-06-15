--!strict
export type Macros = {[number]: any}

local MACROS = { -- MACROS are used to save data
    -- Server <-> Server Actions
    ROUND_COUNTER = 1,
    ORDER_UNITS = 2,
    TAKE_DAMAGE = 3,
    SUMMON_UNIT = 4,
    REMOVE_UNIT = 5,
    UNIT_ACTION = 6,
    -- Server -> Client Actions
    DISPLAY_NOTIFICATION = 21,
    PLAYER_INPUT = 22,
    CHOOSE_ATTACK = 23,
    -- Client -> Server Actions
    FINISH_ACTION = 41,
    ATTACK_ACTION = 42,
    APPLY_DAMAGE = 43,
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
        Energy: number,
        Effect: EffectVariable?
    }
}

local attackActions: AttackAction = {
    [1] = {
        Name = "Scream",
        Damage = 2,
        Nature = 1,
        Target = "AllEnemy",
        Energy = 0,
        Effect = nil
    },
    [2] = {
        Name = "Stab",
        Damage = 5,
        Nature = 1,
        Target = "SingleEnemy",
        Energy = 1,
        Effect = nil
    },
    [3] = {
        Name = "Bump",
        Damage = 3,
        Nature = 1,
        Target = "SingleEnemy",
        Energy = 0,
        Effect = nil
    },
    [4] = {
        Name = "Heal",
        Damage = -2,
        Nature = 2,
        Target = "SingleAlly",
        Energy = 1,
        Effect = { Name = "Regeneration", Duration = 2, HealConst = 1 }
    },
    [5] = {
        Name = "Poison",
        Damage = 1,
        Nature = 2,
        Target = "SingleEnemy",
        Energy = 0,
        Effect = { Name = "Poison", Duration = 3, Damage = 1 }
    },
    [6] = {
        Name = "Mitosis",
        Damage = 2,
        Nature = 2,
        Target = "Summon",
        Energy = 3,
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
        MaxEnergy: number,
        Energy: number,
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
        MaxEnergy = 3,
        Energy  = 0,
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
        MaxEnergy = 5,
        Energy  = 0,
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
        MaxEnergy = 2,
        Energy  = 1,
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
        MaxEnergy = 1,
        Energy  = 0,
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