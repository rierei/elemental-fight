local ElementalFight = class('ElementalFight')

local SoldierAppearances = require('__shared/soldiers-appearances')
local WeaponAppearances = require('__shared/weapons-appearances')
local WeaponUnlocks = require('__shared/weapons-unlocks')

function ElementalFight:__init()
    self:RegisterVars()
end

function ElementalFight:RegisterVars()
    self.m_soldierAppearances = SoldierAppearances()
    self.m_weaponAppearances = WeaponAppearances()
    self.m_weaponUnlocks = WeaponUnlocks()
end

g_elementalFight = ElementalFight()