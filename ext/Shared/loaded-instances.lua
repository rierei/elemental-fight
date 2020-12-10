local LoadedInstances = class('LoadedInstances')

local ElementalConfig = require('__shared/elemental-config')

function LoadedInstances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function LoadedInstances:RegisterVars()
    self.m_currentLevel = nil
    self.m_currentMode = nil

    self.m_isLevelLoaded = false

    self.m_instanceTypes = {
        SoldierWeaponUnlockAsset = true,
        SoldierWeaponBlueprint = true,
        SoldierWeaponData = true,

        ProjectileBlueprint = true,

        WeaponProjectileModifier = true,
        WeaponFiringDataModifier = true,
    }

    self.m_loadedInstances = {
        SoldierWeaponUnlockAsset = {},
        SoldierWeaponBlueprint = {},
        SoldierWeaponData = {},

        MeshProjectileEntityData = {},
        ProjectileBlueprint = {},

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

                    table.insert(self.m_loadedInstances[s_typeName], l_instance)
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

        self.m_loadedInstances.SoldierWeaponUnlockAsset = {}
        self.m_loadedInstances.SoldierWeaponBlueprint = {}

        self.m_loadedInstances.MeshProjectileEntityData = {}
        self.m_loadedInstances.ProjectileBlueprint = {}

        self.m_loadedInstances.WeaponProjectileModifier = {}
        self.m_loadedInstances.WeaponFiringDataModifier = {}

        self.m_loadedInstances.MaterialGridData = {}
        self.m_loadedInstances.MeshVariationDatabase = {}

        self.m_isLevelLoaded = true
    end)
end

function LoadedInstances:CheckInstance(p_instance)
    if p_instance:Is('MeshVariationDatabase') and Asset(p_instance).name:match('Levels') then
        if self.m_verbose >= 2 then
            print('Found MeshVariationDatabase')
        end

        self.m_loadedInstances.MeshVariationDatabase = MeshVariationDatabase(p_instance)
    elseif p_instance:Is('MaterialGridData') then
        if self.m_verbose >= 2 then
            print('Found MaterialGridData')
        end

        self.m_loadedInstances.MaterialGridData = MaterialGridData(p_instance)
    elseif p_instance:Is('MeshProjectileEntityData') then
        if self.m_verbose >= 2 then
            print('Found MeshProjectileEntityData')
        end

        table.insert(self.m_loadedInstances.MeshProjectileEntityData, MeshProjectileEntityData(p_instance))
    end
end

return LoadedInstances()