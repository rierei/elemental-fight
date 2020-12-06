local ElementalFight = class('ElementalFight')

local WeaponUnlocks = require('__shared/weapons-unlocks')
local SoldierAppearances = require('__shared/soldiers-appearances')

function ElementalFight:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function ElementalFight:RegisterVars()
    -- self.m_weaponUnlocks = WeaponUnlocks()
    self.m_soldierAppearances = SoldierAppearances()
end

function ElementalFight:RegisterEvents()
    Events:Subscribe('Player:Chat', function(player, recipientMask, message)
        print('Event Player:Chat')

        self.m_soldierAppearances:ReplacePlayerAppearance(player)
    end)
end

g_elementalFight = ElementalFight()