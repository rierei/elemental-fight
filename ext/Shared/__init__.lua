local ElementalFight = class('ElementalFight')

local BotsCustom = require('__shared/bots-custom')
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

    NetEvents:Subscribe('Bots:Spawn', function()
        print('NetEvent Bots:Spawn')

        local s_appearanceUnlockAsset = self.m_soldierAppearances.m_appearanceUnlockAssets['F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4']

        BotsCustom.spawn(s_appearanceUnlockAsset, Vec3(-306.493164, 70.434372, 270.194336))
    end)
end

g_elementalFight = ElementalFight()