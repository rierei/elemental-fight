local ElementalFight = class('ElementalFight')

local BotsCustom = require('__shared/bots-custom')
local WeaponUnlocks = require('__shared/weapons-unlocks')
local SoldierAppearances = require('__shared/soldiers-appearances')

function ElementalFight:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function ElementalFight:RegisterVars()
    self.m_elementNames = {'water', 'grass', 'fire'}

    -- self.m_weaponUnlocks = WeaponUnlocks()
    self.m_soldierAppearances = SoldierAppearances()
end

function ElementalFight:RegisterEvents()
    Events:Subscribe('Player:Chat', function(player, recipientMask, message)
        print('Event Player:Chat')

        math.randomseed(SharedUtils:GetTimeMS())
        local s_element = self.m_elementNames[math.random(#self.m_elementNames)]
        print(s_element)

        self.m_soldierAppearances:ReplacePlayerAppearance(player, s_element)

        local s_appearanceUnlockAsset = self.m_soldierAppearances.m_appearanceUnlockAssets['F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4'][s_element]
        -- local s_appearanceUnlockAsset = self.m_soldierAppearances.m_appearanceUnlockAssets['915CE40B-0A8B-4423-A769-FBBE45C0D834'][s_element]
        BotsCustom.spawn(s_appearanceUnlockAsset, player.soldier.transform.trans)
    end)

    NetEvents:Subscribe('Bots:Spawn', function()
        print('NetEvent Bots:Spawn')

        -- local s_appearanceUnlockAsset = self.m_soldierAppearances.m_appearanceUnlockAssets['F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4']
        local s_appearanceUnlockAsset = UnlockAsset(ResourceManager:SearchForInstanceByGuid(Guid('597C5F0A-66EF-4F42-B8CD-0CB9EBF64EED')))

        BotsCustom.spawn(s_appearanceUnlockAsset, Vec3(-306.493164, 70.434372, 270.194336))
    end)
end

g_elementalFight = ElementalFight()