local ElementalFight = class('ElementalFight')

local ElementalConfig = require('__shared/elemental-config')
local SoldierAppearances = require('__shared/soldiers-appearances')
local WeaponAppearances = require('__shared/weapons-appearances')
local WeaponUnlocks = require('__shared/weapons-unlocks')

local BotsCustom = require('__shared/bots-custom')

function ElementalFight:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function ElementalFight:RegisterVars()
    self.m_elementNames = {'neutral', 'water', 'grass', 'fire'}

    self.m_soldierAppearances = SoldierAppearances()
    self.m_weaponAppearances = WeaponAppearances()
    self.m_weaponUnlocks = WeaponUnlocks()

    self.counter = 2

    self.m_verbose = 2 -- prints debug information
end

function ElementalFight:RegisterEvents()
    Events:Subscribe('Player:Chat', function(p_player, p_mask, p_message)
        if self.m_verbose >= 1 then
            print('Event Player:Chat')
        end

        local s_USAssaultKit = ResourceManager:SearchForInstanceByGuid(Guid('A15EE431-88B8-4B35-B69A-985CEA934855'))
        local s_USEngiKit = ResourceManager:SearchForInstanceByGuid(Guid('0A99EBDB-602C-4080-BC3F-B388AA18ADDD'))
        local s_USReconKit = ResourceManager:SearchForInstanceByGuid(Guid('BC1C1E63-2730-4E21-8ACD-FAC500D720C3'))
        local s_USSupportKit = ResourceManager:SearchForInstanceByGuid(Guid('47949491-F672-4CD6-998A-101B7740F919'))

        local s_RUAssaultKit = ResourceManager:SearchForInstanceByGuid(Guid('28EC16E7-0BBF-4CB0-9321-473C6EC54125'))
        local s_RUEngiKit = ResourceManager:SearchForInstanceByGuid(Guid('DB0FCE83-2505-4948-8661-660DD0C64B63'))
        local s_RUReconKit = ResourceManager:SearchForInstanceByGuid(Guid('84A4BE20-B110-42E5-9588-365643624525'))
        local s_RUSupportKit = ResourceManager:SearchForInstanceByGuid(Guid('4D0F249B-4464-4F97-A248-A88F57EF5CAA'))

        local s_soldier1 = BotsCustom.spawnBot('Bot1', s_USAssaultKit, Vec3(-306.493164, 70.434372, 270.194336))
        local s_soldier2 = BotsCustom.spawnBot('Bot2', s_USEngiKit, Vec3(-306.493164, 70.434372, 272.194336))
        local s_soldier3 = BotsCustom.spawnBot('Bot3', s_USReconKit, Vec3(-306.493164, 70.434372, 274.194336))
        local s_soldier4 = BotsCustom.spawnBot('Bot4', s_USSupportKit, Vec3(-306.493164, 70.434372, 276.194336))

        local s_soldier5 = BotsCustom.spawnBot('Bot5', s_RUAssaultKit, Vec3(-306.493164, 70.434372, 278.194336))
        local s_soldier6 = BotsCustom.spawnBot('Bot6', s_RUEngiKit, Vec3(-306.493164, 70.434372, 280.194336))
        local s_soldier7 = BotsCustom.spawnBot('Bot7', s_RUReconKit, Vec3(-306.493164, 70.434372, 282.194336))
        local s_soldier8 = BotsCustom.spawnBot('Bot8', s_RUSupportKit, Vec3(-306.493164, 70.434372, 284.194336))

        local s_element = self.m_elementNames[self.counter]
        self:CustomizePlayer(s_soldier1.player, s_element)
        self:CustomizePlayer(s_soldier5.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]
        self:CustomizePlayer(s_soldier2.player, s_element)
        self:CustomizePlayer(s_soldier6.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        s_element = self.m_elementNames[self.counter]
        self:CustomizePlayer(s_soldier3.player, s_element)
        self:CustomizePlayer(s_soldier7.player, s_element)

        self.counter = self.counter % #self.m_elementNames + 1
        local s_element = self.m_elementNames[self.counter]
        self:CustomizePlayer(s_soldier4.player, s_element)
        self:CustomizePlayer(s_soldier8.player, s_element)

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
        if self.m_verbose >= 2 then
            print('Event Soldier:Damage')
        end

        -- soldier healing
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

        -- knife takedown
        if s_weaponUnlockAsset.name:match('Knife') and p_info.boneIndex == 4294967295 then
            return
        end

        local s_soldierElement = nil
        if #p_soldier.player.selectedUnlocks > 0 then
            s_soldierElement = UnlockAsset(p_soldier.player.selectedUnlocks[1]).debugUnlockId
        end

        local s_weaponElement = s_weaponEntity.damageGiverName
        if ElementalConfig.damages[s_weaponElement] == nil then
            s_weaponElement = 'neutral'
        end

        if s_soldierElement == nil or ElementalConfig.damages[s_soldierElement] == nil then
            s_soldierElement = 'neutral'
        end

        local s_elementDamage = ElementalConfig.damages[s_weaponElement]
        local s_damageMultiplier = s_elementDamage[s_soldierElement]

        if self.m_verbose >= 2 then
            print(s_weaponElement .. ' x ' .. s_soldierElement .. ' = ' .. s_damageMultiplier)
            print(p_info.damage .. ' ' .. p_info.damage * s_damageMultiplier)
        end

        p_info.damage = p_info.damage * s_damageMultiplier
        p_hook:Pass(p_soldier, p_info)
    end)
end

function ElementalFight:CustomizePlayer(p_player, p_element)
    if p_element == 'neutral' then
        return
    end

    local s_customizeSoldier = CustomizeSoldierData()
    s_customizeSoldier.activeSlot = 0
    s_customizeSoldier.removeAllExistingWeapons = true
    s_customizeSoldier.clearVisualState = true

    local s_soldierVisualUnlockAsset = self.m_soldierAppearances:GetUnlockAsset(p_player, p_element)

    s_customizeSoldier.unlocks:add(s_soldierVisualUnlockAsset)

	for key, value in pairs(s_soldierVisualUnlockAsset.linkedTo) do
		local s_customizeVisual = CustomizeVisual()
		s_customizeVisual.visual:add(UnlockAsset(value))

		s_customizeSoldier.visualGroups:add(s_customizeVisual)
	end

    local s_weaponVisualUnlockAssets = self.m_weaponAppearances:GetUnlockAssets(p_player, p_element)
    local s_weaponUnlockAssets = self.m_weaponUnlocks:GetUnlockAssets(p_player, p_element)

    for i = #p_player.weapons, 1, -1 do
        local s_weaponUnlockAsset = s_weaponUnlockAssets[i]
        local s_weaponVisualUnlockAsset = s_weaponVisualUnlockAssets[i]

        if s_weaponUnlockAsset ~= nil then
            local s_weaponUnlockAssets = p_player.weaponUnlocks[i]
            if s_weaponUnlockAssets == nil then
                s_weaponUnlockAssets = {}
            end

            local s_unlockWeaponAndSlot = UnlockWeaponAndSlot()
            s_unlockWeaponAndSlot.weapon = s_weaponUnlockAsset
            s_unlockWeaponAndSlot.slot = i - 1

            s_unlockWeaponAndSlot.unlockAssets:add(s_weaponVisualUnlockAsset)

            for l_key, l_value in pairs(s_weaponUnlockAssets) do
                if not Asset(l_value).name:lower():match('Camo') then
                    s_unlockWeaponAndSlot.unlockAssets:add(UnlockAssetBase(l_value))
                end
            end

            s_customizeSoldier.weapons:add(s_unlockWeaponAndSlot)
        end
    end

    p_player.soldier:ApplyCustomization(s_customizeSoldier)
end

g_elementalFight = ElementalFight()