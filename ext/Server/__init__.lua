local ElementalFight = class('ElementalFight')

local BotsCustom = require('__shared/bots-custom')
local WeaponUnlocks = require('__shared/weapons-unlocks')
local WeaponAppearances = require('__shared/weapons-appearances')
local SoldierAppearances = require('__shared/soldiers-appearances')

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
            grass = 0.5,
            fire = 0.5
        },
        water = {
            neutral = 0.5,
            water = 0.5,
            grass = 0.25,
            fire = 1.75
        },
        fire = {
            neutral = 0.5,
            water = 0.25,
            grass = 1.75,
            fire = 0.5
        },
        grass = {
            neutral = 0.5,
            water = 1.75,
            grass = 0.5,
            fire = 0.25
        }
    }

    -- self.m_weaponUnlocks = WeaponUnlocks()
    self.m_weaponAppearances = WeaponAppearances()
    -- self.m_soldierAppearances = SoldierAppearances()

    self.counter = 2
end

function ElementalFight:RegisterEvents()
    Events:Subscribe('Player:Chat', function(p_player, p_mask, p_message)
        print('Event Player:Chat')

        local s_usAssaultKit = ResourceManager:SearchForInstanceByGuid(Guid('A15EE431-88B8-4B35-B69A-985CEA934855'))
        local s_usEngiKit = ResourceManager:SearchForInstanceByGuid(Guid('0A99EBDB-602C-4080-BC3F-B388AA18ADDD'))
        local s_usReconKit = ResourceManager:SearchForInstanceByGuid(Guid('47949491-F672-4CD6-998A-101B7740F919'))
        local s_usSupportKit = ResourceManager:SearchForInstanceByGuid(Guid('BC1C1E63-2730-4E21-8ACD-FAC500D720C3'))

        local s_soldier1 = BotsCustom.spawnBot('Bot1', s_usAssaultKit, Vec3(-306.493164, 70.434372, 270.194336))
        local s_soldier2 = BotsCustom.spawnBot('Bot2', s_usEngiKit, Vec3(-306.493164, 70.434372, 272.194336))
        local s_soldier3 = BotsCustom.spawnBot('Bot3', s_usReconKit, Vec3(-306.493164, 70.434372, 274.194336))
        local s_soldier4 = BotsCustom.spawnBot('Bot4', s_usSupportKit, Vec3(-306.493164, 70.434372, 276.194336))

        local s_element = self.m_elementNames[self.counter]

        -- self.m_soldierAppearances:ReplacePlayerAppearance(s_soldier1.player, s_element)
        -- self.m_weaponUnlocks:ReplacePlayerWeapons(s_soldier1.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]

        -- self.m_soldierAppearances:ReplacePlayerAppearance(s_soldier2.player, s_element)
        -- self.m_weaponUnlocks:ReplacePlayerWeapons(s_soldier2.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]

        -- self.m_soldierAppearances:ReplacePlayerAppearance(s_soldier3.player, s_element)
        -- self.m_weaponUnlocks:ReplacePlayerWeapons(s_soldier3.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]

        -- self.m_soldierAppearances:ReplacePlayerAppearance(s_soldier4.player, s_element)
        -- self.m_weaponUnlocks:ReplacePlayerWeapons(s_soldier4.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
    end)

    Events:Subscribe('Player:Respawn', function(p_player)
        print('Event Player:Respawn')

        local s_element = self.m_elementNames[self.counter]
        print(s_element)

        -- self.m_weaponUnlocks:ReplacePlayerWeapons(p_player, s_element)
        self.m_weaponAppearances:ReplacePlayerWeapons(p_player, s_element)
        -- self.m_soldierAppearances:ReplacePlayerAppearance(p_player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
    end)

    Hooks:Install('Soldier:Damage', 1, function(p_hook, p_soldier, p_info, p_giver)
        print('Event Soldier:Damage')

        -- healing
        if p_info.damage < 0 then
            return
        end

        -- self
        if p_giver.weaponUnlock == nil then
            return
        end

        local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(p_giver.weaponUnlock)
        local s_weaponBlueprint = SoldierWeaponBlueprint(s_weaponUnlockAsset.weapon)
        local s_weaponEntity = SoldierWeaponData(s_weaponBlueprint.object)

        -- knife
        if s_weaponUnlockAsset.name:match('knife') then
            return
        end

        local s_appearanceUnlock = UnlockAsset(p_soldier.player.visualUnlocks[1])

        local s_soldierElement = s_appearanceUnlock.debugUnlockId
        local s_weaponElement = s_weaponEntity.damageGiverName

        local s_elementDamage = self.m_elementDamages[s_weaponElement]
        if s_elementDamage == nil then
            s_elementDamage = self.m_elementDamages['neutral']
        end

        local s_damageMultiplier = s_elementDamage[s_soldierElement]
        if s_damageMultiplier == nil then
            s_damageMultiplier = s_elementDamage['neutral']
        end

        p_info.damage = p_info.damage * s_damageMultiplier

        local s_isHeadshot = p_info.boneIndex == 1
        if s_isHeadshot then
            p_info.damage = p_info.damage * 1.25
        end

        print(s_soldierElement .. 'x' .. s_weaponElement .. '=' .. tostring(p_info.damage))

        p_hook:Pass(p_soldier, p_info)
    end)
end

g_elementalFight = ElementalFight()