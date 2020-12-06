local ElementalFight = class('ElementalFight')

local BotsCustom = require('__shared/bots-custom')
local WeaponUnlocks = require('__shared/weapons-unlocks')
local SoldierAppearances = require('__shared/soldiers-appearances')

function ElementalFight:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function ElementalFight:RegisterVars()
    self.m_currentMap = nil

    self.m_elementNames = {'water', 'grass', 'fire'}

    self.m_weaponUnlocks = WeaponUnlocks()
    -- self.m_soldierAppearances = SoldierAppearances()
end

function ElementalFight:RegisterEvents()
    -- Events:Subscribe('Player:Chat', function(player, recipientMask, message)
    --     print('Event Player:Chat')

    --     -- math.randomseed(SharedUtils:GetTimeMS())
    --     -- local s_element = self.m_elementNames[math.random(#self.m_elementNames)]
    --     -- print(s_element)

    --     -- self.m_soldierAppearances:ReplacePlayerAppearance(player, s_element)
    --     -- self.m_weaponUnlocks:ReplacePlayerWeapons(player, s_element)

    --     -- BotsCustom.spawn(player.visualUnlocks[1], player.soldier.transform.trans)
    --     -- local s_appearanceUnlockAsset = self.m_soldierAppearances.m_appearanceUnlockAssets['F2ADB1BC-466F-4B51-90D1-E8F8670C7BE7'][s_element]

    --     local s_assaultAppearanceGuid = self.m_soldierAppearances.m_waitingInstances.appearanceUnlockAssets['assault'].instanceGuid:ToString('D')
    --     local s_assaultUnlockAsset = self.m_soldierAppearances.m_appearanceUnlockAssets[s_assaultAppearanceGuid]['water']
    --     BotsCustom.spawn(s_assaultUnlockAsset, Vec3(-306.493164, 70.434372, 270.194336))
    -- end)

    Events:Subscribe('Player:Respawn', function(player)
        print('Event Player:Respawn')

        if player.SelectWeapon == nil then
            return
        end

        math.randomseed(SharedUtils:GetTimeMS())
        local s_element = self.m_elementNames[math.random(#self.m_elementNames)]
        print(s_element)

        self.m_weaponUnlocks:ReplacePlayerWeapons(player, s_element)
        -- self.m_soldierAppearances:ReplacePlayerAppearance(player, s_element)
    end)

    Events:Subscribe('Level:Destroy', function()
        print('Level:Destroy')
    end)

    Events:Subscribe('Level:LoadingInfo', function(screenInfo)
        print('Level:LoadingInfo ' .. screenInfo)
    end)

    Events:Subscribe('Level:LoadResources', function(levelName, gameMode, isDedicatedServer)
        print('Level:LoadResources ' .. levelName)

        if self.m_currentMap == nil then
            self.m_currentMap = levelName
        else
            if self.m_currentMap ~= levelName then
                self.m_currentMap = levelName
                self.m_weaponUnlocks:Reset()
                -- self.m_soldierAppearances:Reset()
            else
                self.m_weaponUnlocks:RegisterResources()
                -- self.m_soldierAppearances:RegisterResources()
            end
        end
    end)

    -- NetEvents:Subscribe('Bots:Spawn', function()
    --     print('NetEvent Bots:Spawn')

    --     -- local s_appearanceUnlockAsset = self.m_soldierAppearances.m_appearanceUnlockAssets['F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4']
    --     local s_appearanceUnlockAsset = UnlockAsset(ResourceManager:SearchForInstanceByGuid(Guid('597C5F0A-66EF-4F42-B8CD-0CB9EBF64EED')))

    --     BotsCustom.spawn(s_appearanceUnlockAsset, Vec3(-306.493164, 70.434372, 270.194336))
    -- end)
end

g_elementalFight = ElementalFight()