local ElementalFight = class('ElementalFight')

local WeaponAppearances = require('__shared/weapons-appearances')
local WeaponUnlocks = require('__shared/weapons-unlocks')
local SoldierAppearances = require('__shared/soldiers-appearances')

function ElementalFight:__init()
    self:RegisterVars()
end

function ElementalFight:RegisterVars()
    self.m_weaponAppearances = WeaponAppearances()
    self.m_weaponUnlocks = WeaponUnlocks()
    self.m_soldierAppearances = SoldierAppearances()
end

g_elementalFight = ElementalFight()