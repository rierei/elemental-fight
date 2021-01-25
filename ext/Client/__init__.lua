local ElementalFight = class('ElementalFight')

local SoldierAppearances = require('__shared/soldiers-appearances')
local WeaponAppearances = require('__shared/weapons-appearances')
local WeaponUnlocks = require('__shared/weapons-unlocks')
local VehicleAppearances = require('__shared/vehicles-appearances')
local VehicleBlueprints = require('__shared/vehicles-blueprints')

function ElementalFight:__init()
    self:RegisterVars()
end

function ElementalFight:RegisterVars()
    self.m_soldierAppearances = SoldierAppearances()
    self.m_vehicleAppearances = VehicleAppearances()
    self.m_weaponAppearances = WeaponAppearances()
    self.m_vehicleBlueprints = VehicleBlueprints(self.m_vehicleAppearances)
    self.m_weaponUnlocks = WeaponUnlocks()
end

g_elementalFight = ElementalFight()