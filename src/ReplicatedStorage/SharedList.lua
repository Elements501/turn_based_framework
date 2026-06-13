--!strict
local RS: ReplicatedStorage = game:GetService("ReplicatedStorage")
local GAME_DATA: {[string]:{}} = require(RS:WaitForChild("GameData"))

export type SharedList = {
    totalUnits: number,
    unitList: GAME_DATA.UnitType,
    roundNumber: number,
    actionOrder: {[number]: number},
    actionNumber: number,
}
local sharedList = {
    totalUnits = 0,
    unitList = {},
    roundNumber = 0,
    actionOrder = {},
    actionNumber = 1,
}

return sharedList