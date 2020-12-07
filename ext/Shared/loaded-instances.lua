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

    self.m_weaponUnlockAssets = {} -- SoldierWeaponUnlockAsset
    self.m_materialGridAsset = nil -- MaterialContainerAsset
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase

    self.m_verbose = 1
end

function LoadedInstances:RegisterEvents()
    -- reading loaded instances
    Events:Subscribe('Partition:Loaded', function(p_partition)
        if not self.m_isLevelLoaded then
            for _, l_instance in pairs(p_partition.instances) do
                -- waiting weapon unlocks
                if l_instance:Is('SoldierWeaponUnlockAsset') then
                    if self.m_verbose >= 2 then
                        print('Found WeaponUnlockAsset')
                    end

                    table.insert(self.m_weaponUnlockAssets, l_instance)
                end

                -- waiting material grid
                if l_instance:Is('MaterialGridData') then
                    if self.m_verbose >= 1 then
                        print('Found MaterialGridData')
                    end

                    self.m_materialGridAsset = l_instance
                end

                -- waiting variation database
                if l_instance:Is('MeshVariationDatabase') and Asset(l_instance).name:match('Levels') then
                    if self.m_verbose >= 1 then
                        print('Found MeshVariationDatabase')
                    end

                    self.m_meshVariationDatabase = l_instance
                end
            end
        end
    end)

    -- removing instances on level destroy
    Events:Subscribe('Level:Destroy', function()
        self.m_materialGridAsset = nil -- MaterialContainerAsset
        self.m_meshVariationDatabase = nil -- MeshVariationDatabase

        self.m_isLevelLoaded = false
    end)

    -- removing instances on level load
    Events:Subscribe('Level:LoadResources', function(p_level, p_mode, p_dedicated)
        -- removing instances on level change
        if self.m_currentLevel ~= nil and (self.m_currentLevel ~= p_level or self.m_currentMode ~= p_mode) then
            self.m_weaponUnlockAssets = {} -- SoldierWeaponUnlockAsset
        end

        self.m_currentLevel = p_level
        self.m_currentMode = p_mode
    end)

    -- disabling instance reading after level load
    Events:Subscribe('Level:Loaded', function(p_level, p_mode)
        self.m_isLevelLoaded = true
    end)
end

return LoadedInstances()