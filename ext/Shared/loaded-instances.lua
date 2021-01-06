local LoadedInstances = class('LoadedInstances')

local ElementalConfig = require('__shared/elemental-config')
local InstanceWait = require('__shared/utils/wait')

local ConstsUtils = require('__shared/utils/consts')

function LoadedInstances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function LoadedInstances:RegisterVars()
    self.m_currentLevel = nil
    self.m_currentMode = nil

    self.m_isLevelLoaded = false
    self.m_isMeshVariationDatabaseLoaded = false

    self.m_instanceTypes = {
        SoldierWeaponUnlockAsset = true,
        SoldierWeaponBlueprint = true,
        SoldierWeaponData = true,

        WeaponProjectileModifier = true,
        WeaponFiringDataModifier = true,
    }

    self.m_loadedInstances = {
        SoldierWeaponUnlockAsset = {},
        SoldierWeaponBlueprint = {},
        SoldierWeaponData = {},

        VehicleBlueprint = {},
        VehicleEntityData = {},

        WeaponMeshProjectileEntityData = {},
        WeaponProjectileBlueprint = {},

        VehicleMeshProjectileEntityData = {},
        VehicleProjectileBlueprint = {},

        WeaponProjectileModifier = {},
        WeaponFiringDataModifier = {},

        MaterialGridData = nil,
        MeshVariationDatabase = nil
    }

    self.m_verbose = 1
end

function LoadedInstances:RegisterEvents()
    -- reading loaded instances
    Events:Subscribe('Partition:Loaded', function(p_partition)
        if not self.m_isLevelLoaded then
            for _, l_instance in pairs(p_partition.instances) do
                local s_typeName = l_instance.typeInfo.name

                if self.m_instanceTypes[s_typeName] then
                    if self.m_verbose >= 2 then
                        print('Found ' .. s_typeName)
                    end

                    local s_type = _G[s_typeName]
                    if s_type ~= nil then
                        l_instance = s_type(l_instance)
                    end

                    self:SaveInstance(self.m_loadedInstances[s_typeName], l_instance)
                else
                    self:CheckInstance(l_instance)
                end
            end
        end
    end)

    -- removing instances on level destroy
    Events:Subscribe('Level:Destroy', function()
        if self.m_verbose >= 1 then
            print('Level:Destroy')
        end

        self.m_isLevelLoaded = false
        self.m_isMeshVariationDatabaseLoaded = false
    end)

    -- removing instances on level load
    Events:Subscribe('Level:LoadResources', function(p_level, p_mode, p_dedicated)
        if self.m_verbose >= 1 then
            print('Level:LoadResources')
        end

        -- removing instances on level change
        if self.m_currentLevel ~= nil and (self.m_currentLevel ~= p_level or self.m_currentMode ~= p_mode) then
            if self.m_verbose >= 1 then
                print('Level ' .. p_level)
            end

            self.m_loadedInstances.SoldierWeaponData = {}
        end

        self.m_currentLevel = p_level
        self.m_currentMode = p_mode
    end)

    -- disabling instance reading after level load
    Events:Subscribe('Level:Loaded', function(p_level, p_mode)
        if self.m_verbose >= 1 then
            print('Level:Loaded')
        end

        if self.m_verbose >= 1 then
            print('Loaded SoldierWeaponUnlockAssets: ' .. #self.m_loadedInstances.SoldierWeaponUnlockAsset)
            print('Loaded SoldierWeaponBlueprints: ' .. #self.m_loadedInstances.SoldierWeaponBlueprint)
            print('Loaded VehicleBlueprints: ' .. #self.m_loadedInstances.VehicleBlueprint)
            print('Loaded VehicleEntityDatas: ' .. #self.m_loadedInstances.VehicleEntityData)
            print('Loaded WeaponMeshProjectileEntityDatas: ' .. #self.m_loadedInstances.WeaponMeshProjectileEntityData)
            print('Loaded WeaponProjectileBlueprints: ' .. #self.m_loadedInstances.WeaponProjectileBlueprint)
            print('Loaded VehicleMeshProjectileEntityDatas: ' .. #self.m_loadedInstances.VehicleMeshProjectileEntityData)
            print('Loaded VehicleProjectileBlueprints: ' .. #self.m_loadedInstances.VehicleProjectileBlueprint)
            print('Loaded MaterialGridData: ' .. tostring(self.m_loadedInstances.MaterialGridData ~= nil))
            print('Loaded MeshVariationDatabase: ' .. tostring(self.m_loadedInstances.MeshVariationDatabase ~= nil))
        end

        self.m_loadedInstances.SoldierWeaponUnlockAsset = {}
        self.m_loadedInstances.SoldierWeaponBlueprint = {}

        self.m_loadedInstances.VehicleBlueprint = {}
        self.m_loadedInstances.VehicleEntityData = {}

        self.m_loadedInstances.WeaponMeshProjectileEntityData = {}
        self.m_loadedInstances.WeaponProjectileBlueprint = {}

        self.m_loadedInstances.VehicleMeshProjectileEntityData = {}
        self.m_loadedInstances.VehicleProjectileBlueprint = {}

        self.m_loadedInstances.MaterialGridData = {}
        self.m_loadedInstances.MeshVariationDatabase = {}

        self.m_isLevelLoaded = true
    end)
end

function LoadedInstances:CheckInstance(p_instance)
    if p_instance:Is('MeshVariationDatabase') then
        if
            not string.starts(p_instance.partition.name, 'levels/') or
            string.starts(p_instance.partition.name, self.m_currentLevel:lower()) or
            self.m_isMeshVariationDatabaseLoaded
        then
            return
        end

        p_instance = MeshVariationDatabase(p_instance)
        if #p_instance.entries > 800 then
            self.m_loadedInstances.MeshVariationDatabase = p_instance
            self.m_isMeshVariationDatabaseLoaded = true

            local s_waitingGuids = ConstsUtils.baseAppearanceGuids
            if self.m_currentLevel:match('XP4') then
                s_waitingGuids = ConstsUtils.xp4AppearanceGuids
            end

            InstanceWait(s_waitingGuids, function (p_instances)
                if self.m_verbose >= 1 then
                    print('LoadedInstances:MeshVariationDatabase')
                end

                Events:DispatchLocal('LoadedInstances:MeshVariationDatabase', p_instances)
            end)
        end
    elseif p_instance:Is('MaterialGridData') then
        if self.m_verbose >= 2 then
            print('Found MaterialGridData')
        end

        self.m_loadedInstances.MaterialGridData = MaterialGridData(p_instance)
    elseif p_instance:Is('MeshProjectileEntityData') then
        if self.m_verbose >= 2 then
            print('Found MeshProjectileEntityData')
        end

        local s_type = _G[p_instance.typeInfo.name]
        p_instance = s_type(p_instance)

        if string.starts(p_instance.partition.name, 'weapons/') then
            self:SaveInstance(self.m_loadedInstances.MeshProjectileEntityData, p_instance)
        end
    elseif p_instance.typeInfo.name == 'ProjectileBlueprint' then
        if self.m_verbose >= 2 then
            print('Found ProjectileBlueprint')
        end

        p_instance = ProjectileBlueprint(p_instance)

        if string.starts(p_instance.partition.name, 'weapons/') then
            self:SaveInstance(self.m_loadedInstances.ProjectileBlueprint, p_instance)
        end
    elseif p_instance:Is('VehicleEntityData') then
        if self.m_verbose >= 2 then
            print('Found VehicleEntityData')
        end

        if string.starts(p_instance.partition.name, 'vehicles/') then
            p_instance = VehicleEntityData(p_instance)

            table.insert(self.m_loadedInstances.VehicleEntityData, p_instance)
        end
    elseif p_instance:Is('VehicleBlueprint') then
        if self.m_verbose >= 2 then
            print('Found VehicleBlueprint')
        end

        if string.starts(p_instance.partition.name, 'vehicles/') then
            p_instance = VehicleBlueprint(p_instance)

            table.insert(self.m_loadedInstances.VehicleBlueprint, p_instance)
        end
    end
end

function LoadedInstances:SaveInstance(p_table, p_instance)
    local s_key = MathUtils:FNVHash(p_instance.instanceGuid:ToString('D'))

    p_table[s_key] = p_instance
end

function LoadedInstances:GetInstances(p_type)
    local s_instances = self.m_loadedInstances[p_type]

    local s_keys = {}
    for l_key, _ in pairs(s_instances) do
        table.insert(s_keys, l_key)
    end

    table.sort(s_keys)

    local s_result = {}
    for _, l_value in pairs(s_keys) do
        table.insert(s_result, s_instances[l_value])
    end

    return s_result
end

return LoadedInstances()