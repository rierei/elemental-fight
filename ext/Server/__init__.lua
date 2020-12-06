local ElementalFight = class('ElementalFight')

local BotsCustom = require('__shared/bots-custom')
local SoldierAppearances = require('__shared/soldiers-appearances')
local WeaponAppearances = require('__shared/weapons-appearances')
local WeaponUnlocks = require('__shared/weapons-unlocks')

function ElementalFight:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function ElementalFight:RegisterVars()
    self.m_elementNames = {'neutral', 'water', 'grass', 'fire'}

    self.m_elementDamages = {
        neutral = {
            neutral = 1,
            water = 0.5,
            fire = 0.5,
            grass = 0.5
        },
        water = {
            neutral = 0.5,
            water = 0.5,
            fire = 1,
            grass = 0.25
        },
        fire = {
            neutral = 0.5,
            water = 0.25,
            fire = 0.5,
            grass = 1
        },
        grass = {
            neutral = 0.5,
            water = 1,
            fire = 0.25,
            grass = 0.5
        }
    }

    self.m_soldierAppearances = SoldierAppearances()
    self.m_weaponAppearances = WeaponAppearances()
    self.m_weaponUnlocks = WeaponUnlocks()

    self.counter = 2

    self.m_verbose = 1 -- prints debug information
end

function ElementalFight:RegisterEvents()
    Events:Subscribe('Player:Chat', function(p_player, p_mask, p_message)
        if self.m_verbose >= 1 then
            print('Event Player:Chat')
        end

        local s_usAssaultKit = ResourceManager:SearchForInstanceByGuid(Guid('A15EE431-88B8-4B35-B69A-985CEA934855'))
        local s_usEngiKit = ResourceManager:SearchForInstanceByGuid(Guid('0A99EBDB-602C-4080-BC3F-B388AA18ADDD'))
        local s_usReconKit = ResourceManager:SearchForInstanceByGuid(Guid('47949491-F672-4CD6-998A-101B7740F919'))
        local s_usSupportKit = ResourceManager:SearchForInstanceByGuid(Guid('BC1C1E63-2730-4E21-8ACD-FAC500D720C3'))

        local s_soldier1 = BotsCustom.spawnBot('Bot1', s_usAssaultKit, Vec3(-306.493164, 70.434372, 270.194336))
        local s_soldier2 = BotsCustom.spawnBot('Bot2', s_usEngiKit, Vec3(-306.493164, 70.434372, 272.194336))
        local s_soldier3 = BotsCustom.spawnBot('Bot3', s_usReconKit, Vec3(-306.493164, 70.434372, 274.194336))
        local s_soldier4 = BotsCustom.spawnBot('Bot4', s_usSupportKit, Vec3(-306.493164, 70.434372, 276.194336))

        local s_element = self.m_elementNames[self.counter]
        self:CustomizePlayer(s_soldier1.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]
        self:CustomizePlayer(s_soldier2.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]
        self:CustomizePlayer(s_soldier3.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]
        self:CustomizePlayer(s_soldier4.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
    end)

    Events:Subscribe('Player:Respawn', function(p_player)
        if self.m_verbose >= 1 then
            print('Event Player:Respawn')
        end

        local s_element = self.m_elementNames[self.counter]
        print(s_element)

        self:CustomizePlayer(p_player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
    end)

    Hooks:Install('Soldier:Damage', 1, function(p_hook, p_soldier, p_info, p_giver)
        if self.m_verbose >= 1 then
            print('Event Player:Damage')
        end

        -- healing
        if p_info.damage < 0 then
            return
        end

        -- non weapon
        if p_giver.weaponUnlock == nil then
            return
        end

        local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(p_giver.weaponUnlock)
        local s_weaponBlueprint = SoldierWeaponBlueprint(s_weaponUnlockAsset.weapon)
        local s_weaponEntity = SoldierWeaponData(s_weaponBlueprint.object)

        -- knife
        if s_weaponUnlockAsset.name:match('Knife') then
            return
        end

        local s_appearanceUnlock = UnlockAsset(p_soldier.player.visualUnlocks[1])

        local s_weaponElement = s_weaponEntity.damageGiverName
        if self.m_elementDamages[s_weaponElement] == nil then
            s_weaponElement = 'neutral'
        end

        local s_soldierElement = s_appearanceUnlock.debugUnlockId
        if self.m_elementDamages[s_soldierElement] == nil then
            s_soldierElement = 'neutral'
        end

        local s_elementDamage = self.m_elementDamages[s_weaponElement]
        local s_damageMultiplier = s_elementDamage[s_soldierElement]

        print(s_soldierElement .. ' x ' .. s_weaponElement .. ' = ' .. s_damageMultiplier)

        if p_info.boneIndex == 1 then
            s_damageMultiplier = s_damageMultiplier * 1.25
        end

        p_info.damage = p_info.damage * s_damageMultiplier
        p_hook:Pass(p_soldier, p_info)
    end)
end

function ElementalFight:CustomizePlayer(p_player, p_element)
    if p_element == 'neutral' then
        return
    end

    local s_soldierVisualUnlockAsset = self.m_soldierAppearances:GetUnlockAsset(p_player, p_element)
    local s_weaponVisualUnlockAssets = self.m_weaponAppearances:GetUnlockAssets(p_player, p_element)
    local s_weaponUnlockAssets = self.m_weaponUnlocks:GetUnlockAssets(p_player, p_element)

    p_player:SelectUnlockAssets(p_player.customization, { s_soldierVisualUnlockAsset })

    for i = #p_player.weapons, 1, -1 do
        local s_weaponUnlockAsset = s_weaponVisualUnlockAssets[i]
        local s_weaponVisualUnlockAsset = s_weaponUnlockAssets[i]

        if s_weaponUnlockAsset ~= nil then
            local s_weaponUnlockAssets = p_player.weaponUnlocks[i]
            if s_weaponUnlockAssets == nil then
                s_weaponUnlockAssets = {}
            end

            table.insert(s_weaponUnlockAssets, s_weaponVisualUnlockAsset)

            p_player:SelectWeapon(i - 1, s_weaponUnlockAsset, s_weaponUnlockAssets)
        end
    end
end

g_elementalFight = ElementalFight()