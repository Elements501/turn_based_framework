--!strict
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
    HealPercent: number?,
    HealAdd: number?,
    HealMult: number?,
    -- Damage Buff
    AttackAdd: number?,
    AttackMult: number?,
    -- Attack Nature Buff
    OneAdd: number?,
    OneMult: number?,
    TwoAdd: number?,
    TwoMult: number?,
    ThreeAdd: number?,
    ThreeMult: number?,
}

local effectKeys: {[number]: string} = {
    [0] = "EffectId",
    [1] = "Name",
    [2] = "Duration",
    -- Constant Damage
    [3] = "Damage",
    [4] = "DamageAdd",
    [5] = "DamageMult",
    -- Constant Heal
    [6] = "HealConst",
    [7] = "HealPercent",
    [8] = "HealAdd",
    [9] = "HealMult",
    -- Damage Buff
    [10] = "AttackAdd",
    [11] = "AttackMult",
    -- Attack Nature Buff
    [12] = "OneAdd",
    [13] = "OneMult",
    [14] = "TwoAdd",
    [15] = "TwoMult",
    [16] = "ThreeAdd",
    [17] = "ThreeMult",
} -- TODO: Heal Buff

export type AttackAction = {
    [number]: {
        Name: string,
        Damage: number,
        Nature: number,
        Traget: number,
        Effect: EffectVariable?
    }
}

local attackActions: AttackAction = {
    [1] = {
        Name = "Scream",
        Damage = 2,
        Nature = 1,
        Target = -1,
        Effect = nil
    },
    [2] = {
        Name = "Stab",
        Damage = 5,
        Nature = 1,
        Target = 1,
        Effect = nil
    },
    [3] = {
        Name = "Bump",
        Damage = 3,
        Nature = 1,
        Target = 1,
        Effect = nil
    },
    [4] = {
        Name = "Heal",
        Damage = -2,
        Nature = 2,
        Target = 2,
        Effect = { Name = "Regeneration", Duration = 2, HealConst = 1 }
    },
    [5] = {
        Name = "Poison",
        Damage = 1,
        Nature = 2,
        Target = 1,
        Effect = { Name = "Poison", Duration = 3, Damage = 1 }
    },
    [6] = {
        Name = "Mitosis",
        Damage = 2,
        Nature = 2,
        Target = 0,
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
    ["effectKeys"] = table.freeze(effectKeys),
    ["unitTypes"] = table.freeze(unitTypes),
}

return gameData -- types are automatically exported as gameData.[type_name]