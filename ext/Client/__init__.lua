local ElementalFight = class('ElementalFight')

local WeaponUnlocks = require('__shared/weapons-unlocks')
local WeaponAppearances = require('__shared/weapons-appearances')
local SoldierAppearances = require('__shared/soldiers-appearances')

function ElementalFight:__init()
    self:RegisterVars()
end

function ElementalFight:RegisterVars()
    -- self.m_weaponUnlocks = WeaponUnlocks()
    self.m_weaponAppearances = WeaponAppearances()
    -- self.m_soldierAppearances = SoldierAppearances()
end

g_elementalFight = ElementalFight()