--!strict
export type Macros = {[number]: any}

local MACROS = { -- MACROS are used to save data
    -- Server -> Client Actions
    DISPLAY_NOTIFICATION = 21,
    PLAYER_INPUT = 22,
    CHOOSE_ATTACK = 23,
    DISPLAY_ORDER = 24,
    INFO_BAR = 25,
    HOVER_UNIT = 26,
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
        Effect = { [1] = { Name = "Regeneration", Duration = 2, HealConst = 1, Nature = 2 } }
    },
    [5] = {
        Name = "Poison Sting",
        Damage = 1,
        Nature = 2,
        Target = "SingleEnemy",
        Energy = 0,
        Effect = { [1] = { Name = "Poison", Duration = 3, Damage = 1, Nature = 2 } }
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
        Intelligence = 2,
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
        Intelligence = 1,
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
        Intelligence = 3,
        Speed = 2,
        MaxHealth = 12,
        Health = 12,
        MaxEnergy = 2,
        Energy  = 1,
        Effect = {},
        Skills = {3, 5}
    },
    [4] = {
        Name = "Spirit",
        Type = 4,
        Power = 2,
        Intelligence = 3,
        Speed = 5,
        MaxHealth = 10,
        Health = 8,
        MaxEnergy = 1,
        Energy  = 0,
        Effect = { [1] = { Name = "Spirit Mending", Duration = 99, HealConst = 0.5, HealMult = 1.5, Nature = 3 } },
        Skills = {1, 4}
    },
}

export type ImageUrl = {
    [string]: string
}

local imageUrl: ImageUrl = {
    Miscallenous = "72148980429899",
    Health = "76079425163243",
    MaxHealth = "105795245223959",
    Energy = "92627000783916",
    MaxEnergy = "90662494661566",
    Damage = "106701992419740",
    Power = "106701992419740",
    Intelligence = "98404423018087",
    Speed = "134156510847751",
}

export type EffectDescription = {
    [string]: string
}

local effectDescription: EffectDescription = {
    ["Poison"] = "Inflict effect damage per turn",
    ["Regeneration"] = "Provides magic healing per turn",
    ["Spirit Mending"] = "Provides small amount of self effect healing per turn"
}

-- Handler
local gameData = {
    ["attackActions"] = table.freeze(attackActions),
    ["unitTypes"] = table.freeze(unitTypes),
    ["MACROS"] = table.freeze(MACROS),
    ["imageUrl"] = table.freeze(imageUrl),
    ["effectDescription"] = table.freeze(effectDescription),
}

return gameData -- types are automatically exported as gameData.[type_name]