local ElementalFight = class('ElementalFight')

local ElementalConfig = require('__shared/elemental-config')
local SoldierAppearances = require('__shared/soldiers-appearances')
local WeaponAppearances = require('__shared/weapons-appearances')
local WeaponUnlocks = require('__shared/weapons-unlocks')
local VehicleAppearances = require('__shared/vehicles-appearances')
local VehicleBlueprints = require('__shared/vehicles-blueprints')

function ElementalFight:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function ElementalFight:RegisterVars()
    self.m_soldierAppearances = SoldierAppearances()
    self.m_vehicleAppearances = VehicleAppearances()
    self.m_weaponAppearances = WeaponAppearances()
    self.m_vehicleBlueprints = VehicleBlueprints(self.m_vehicleAppearances)
    self.m_weaponUnlocks = WeaponUnlocks()

    self.m_verbose = 0 -- prints debug information
end

function ElementalFight:RegisterEvents()
    Hooks:Install('Soldier:Damage', 1, function (p_hook, p_soldier, p_info, p_giver)
        self:_SoldierDamage(p_hook, p_soldier, p_info, p_giver)
    end)

    Events:Subscribe('ElementalFight:CustomizePlayer', function(p_guid, p_element, p_secondary)
        local s_player = PlayerManager:GetPlayerByGuid(p_guid)

        if s_player == nil then
            return
        end

        self:CustomizePlayer(s_player, p_element, p_secondary)
    end)

    if ElementalConfig.vehicles then
        Events:Subscribe('ElementalFight:CustomizeVehicle', function(p_vehicle, p_element)
            self:CustomizeVehicle(p_vehicle, p_element)
        end)
    end
end

-- applying elemental damage multipliers
function ElementalFight:_SoldierDamage(p_hook, p_soldier, p_info, p_giver)
    if self.m_verbose >= 1 then
        print('Event Soldier:Damage')
    end

    if p_soldier == nil or p_soldier.player == nil or p_giver == nil then
        return
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

    -- getting giver weapon element
    local s_weaponElement = s_weaponEntity.damageGiverName
    if ElementalConfig.damages[s_weaponElement] == nil then
        s_weaponElement = 'neutral'
    end

    -- getting taker soldier element
    local s_soldierElement = UnlockAsset(p_soldier.player.visualUnlocks[1]).debugUnlockId
    if s_soldierElement == nil or ElementalConfig.damages[s_soldierElement] == nil then
        s_soldierElement = 'neutral'
    end

    -- getting element damage multiplier
    local s_elementDamage = ElementalConfig.damages[s_weaponElement]
    local s_damageMultiplier = s_elementDamage[s_soldierElement]

    if self.m_verbose >= 1 then
        print(s_weaponElement .. ' x ' .. s_soldierElement .. ' = ' .. s_damageMultiplier)
        print(p_info.damage .. ' ' .. p_info.damage * s_damageMultiplier)
    end

    p_info.damage = p_info.damage * s_damageMultiplier
    p_hook:Pass(p_soldier, p_info)
end

-- customising player appearance and weapons
function ElementalFight:CustomizePlayer(p_player, p_element, p_secondary)
    local s_customizeSoldier = CustomizeSoldierData()
    s_customizeSoldier.activeSlot = 0
    s_customizeSoldier.removeAllExistingWeapons = true

    if p_element ~= 'neutral' then
        s_customizeSoldier.clearVisualState = true
        s_customizeSoldier.restoreToOriginalVisualState = true

        -- custom soldier appearance
        local s_soldierVisualUnlockAsset = self.m_soldierAppearances:GetUnlockAsset(p_player, p_element)

        -- adding soldier visual unlock
        p_player:SelectUnlockAssets(p_player.customization, { s_soldierVisualUnlockAsset })
        s_customizeSoldier.unlocks:add(s_soldierVisualUnlockAsset)

        -- applying custom soldier appearance
        for _, l_value in pairs(s_soldierVisualUnlockAsset.linkedTo) do
            local s_customizeVisual = CustomizeVisual()
            s_customizeVisual.visual:add(UnlockAsset(l_value))

            s_customizeSoldier.visualGroups:add(s_customizeVisual)
        end
    end

    -- custom weapon appearances
    local s_weaponVisualUnlockAssets = self.m_weaponAppearances:GetUnlockAssets(p_player.weapons, p_element, p_secondary)

    -- custom weapon unlock assets
    local s_weaponUnlockAssets = self.m_weaponUnlocks:GetUnlockAssets(p_player.weapons, p_element, p_secondary)

    -- adding custom weapons and appearances
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

            if s_weaponVisualUnlockAsset ~= nil then
                s_unlockWeaponAndSlot.unlockAssets:add(s_weaponVisualUnlockAsset)
            end

            for l_key, l_value in pairs(s_weaponUnlockAssets) do
                if not Asset(l_value).name:lower():match('camo') then
                    s_unlockWeaponAndSlot.unlockAssets:add(UnlockAssetBase(l_value))
                end
            end

            s_customizeSoldier.weapons:add(s_unlockWeaponAndSlot)
        end
    end

    p_player.soldier:ApplyCustomization(s_customizeSoldier)
end

-- replacing vehicle with custom
function ElementalFight:CustomizeVehicle(p_vehicle, p_element)
    if p_element == 'neutral' then
        return
    end

    local s_vehicleBlueprint = self.m_vehicleBlueprints:GetVehicleBlueprint(p_vehicle.data, p_element)
    if s_vehicleBlueprint == nil then
        return
    end

    local s_transform = SpatialEntity(p_vehicle).transform

    local s_controllableEntity = ControllableEntity(p_vehicle)

    local s_teamId = s_controllableEntity.teamId

    local s_players = {}
    for i = 0, s_controllableEntity.entryCount - 1, 1 do
        local s_player = s_controllableEntity:GetPlayerInEntry(i)

        if s_player ~= nil then
            s_players[i] = s_player
            s_player:ExitVehicle(true, false)
        end
    end

    p_vehicle:Destroy()

    local s_params = EntityCreationParams()
    s_params.transform = s_transform
    s_params.networked = true

    local s_bus = EntityManager:CreateEntitiesFromBlueprint(s_vehicleBlueprint, s_params)

    local s_vehicle = nil
    for _, l_entity in pairs(s_bus.entities) do
        if l_entity:Is('ServerVehicleEntity') then
            s_vehicle = l_entity
        end

        l_entity:Init(Realm.Realm_ClientAndServer, true)
    end

    local s_controllableEntity = ControllableEntity(s_vehicle)

    s_vehicle:PropertyChanged('Team', s_teamId)

    for l_key, l_value in pairs(s_players) do
        l_value:EnterVehicle(s_vehicle, l_key)
    end
end

g_elementalFight = ElementalFight()