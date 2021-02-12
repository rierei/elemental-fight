local WeaponsAppearances = class('WeaponsAppearances')

local LoadedInstances = require('__shared/loaded-instances')
local ElementalConfig = require('__shared/elemental-config')
local InstanceUtils = require('__shared/utils/instances')

function WeaponsAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function WeaponsAppearances:RegisterVars()
    self.m_currentLevel = nil
    self.m_currentMode = nil

    self.m_waitingInstances = {
        meshVariationDatabase = nil, -- MeshVariationDatabase
        weaponEntities = {}, -- SoldierWeaponData
        weaponShaders = {} -- ShaderGraph
    }

    self.m_registryContainer = nil -- RegistryContainer
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedMeshAsset1pWeaponGuids = {} -- WeaponStateData.mesh1p
    self.m_skinnedMeshAsset3pWeaponGuids = {} -- WeaponStateData.mesh3p
    self.m_meshVariationDatabaseEntrys1p = {} -- MeshVariationDatabaseEntry
    self.m_meshVariationDatabaseEntrys3p = {} -- MeshVariationDatabaseEntry
    self.m_databaseEntryMaterialIndexes = {} -- MeshVariationDatabaseEntry.materials
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint

    self.m_surfaceShaderStructs = {} -- SurfaceShaderInstanceDataStruct
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintVariationPairs = {} -- BlueprintAndVariationPair
    self.m_unlockAssets = {} -- UnlockAsset

    self.m_verbose = 1 -- prints debug information
end

function WeaponsAppearances:RegisterEvents()
    Events:Subscribe('Level:Destroy', function()
        self.m_unlockAssets = {}
    end)

    -- reading instances when MeshVariationDatabase loads
    Events:Subscribe('LoadedInstances:MeshVariationDatabase', function(p_instances)
        self:ReadInstances(p_instances)
    end)
end

function WeaponsAppearances:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    self.m_waitingInstances.meshVariationDatabase = LoadedInstances.m_loadedInstances.MeshVariationDatabase
    self.m_waitingInstances.weaponEntities = LoadedInstances:GetInstances('SoldierWeaponData')

    self.m_meshVariationDatabase = self.m_waitingInstances.meshVariationDatabase
    self.m_meshVariationDatabase:MakeWritable()

    self.m_waitingInstances.weaponShaders['WeaponPresetShadowFP'] = p_instances['WeaponPresetShadowFP']
    self.m_waitingInstances.weaponShaders['WeaponPresetShadowNoCamoFP'] = p_instances['WeaponPresetShadowNoCamoFP']

    -- reading weapon entities
    for _, l_value in pairs(self.m_waitingInstances.weaponEntities) do
        local s_weaponEntity = l_value

        self.m_skinnedMeshAsset1pWeaponGuids[s_weaponEntity.weaponStates[1].mesh1p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')
        self.m_skinnedMeshAsset3pWeaponGuids[s_weaponEntity.weaponStates[1].mesh3p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')

        self.m_weaponBlueprints[s_weaponEntity.instanceGuid:ToString('D')] = s_weaponEntity.soldierWeaponBlueprint
    end

    -- reading mesh variations
    for i = 1, LoadedInstances.m_variationDatabaseEntryCount, 1 do
        local l_value = self.m_meshVariationDatabase.entries[i]
        local s_meshVariationDatabaseEntry = l_value
        local s_skinnedMeshAsset1pWeaponGuid = self.m_skinnedMeshAsset1pWeaponGuids[s_meshVariationDatabaseEntry.mesh.instanceGuid:ToString('D')]
        local s_skinnedMeshAsset3pWeaponGuid = self.m_skinnedMeshAsset3pWeaponGuids[s_meshVariationDatabaseEntry.mesh.instanceGuid:ToString('D')]

        if s_meshVariationDatabaseEntry.variationAssetNameHash == 0 then
            if s_skinnedMeshAsset1pWeaponGuid ~= nil then
                self.m_meshVariationDatabaseEntrys1p[s_skinnedMeshAsset1pWeaponGuid] = s_meshVariationDatabaseEntry
            end

            if s_skinnedMeshAsset3pWeaponGuid ~= nil then
                self.m_meshVariationDatabaseEntrys3p[s_skinnedMeshAsset3pWeaponGuid] = s_meshVariationDatabaseEntry
            end
        end
    end

    -- reading material indexes
    for _, l_value in pairs(self.m_meshVariationDatabaseEntrys1p) do
        local s_materialVariationIndexes = {}

        for ll_key, ll_value in pairs(l_value.materials) do
            local s_shaderGraph = ll_value.material.shader.shader

            local s_isNoCamo1p = false
            local s_isNoCamo3p = false
            local s_isPreset1p = false
            local s_isPreset3p = false
            local s_isShadow1p = false

            if s_shaderGraph ~= nil then
                s_isNoCamo1p = s_shaderGraph.name:match('WeaponPresetShadowNoCamoFP')
                s_isNoCamo3p = s_shaderGraph.name:match('WeaponPresetNoCamo3P')
                s_isPreset1p = s_shaderGraph.name:match('WeaponPresetFP')
                s_isPreset3p = s_shaderGraph.name:match('WeaponPreset3P')
                s_isShadow1p = s_shaderGraph.name:match('WeaponPresetShadowFP')
            end

            if s_isNoCamo3p or s_isPreset1p or s_isPreset3p or s_isShadow1p then
                s_materialVariationIndexes[ll_key] = '1AFD6691-9CB6-4195-A4D1-6C925C0C3C2B' -- WeaponPresetShadowFP
            elseif s_isNoCamo1p then
                s_materialVariationIndexes[ll_key] = 'E776B701-3905-4211-9DAD-67A2F4B06176' -- WeaponPresetShadowNoCamoFP
            end
        end

        self.m_databaseEntryMaterialIndexes[l_value.instanceGuid:ToString('D')] = s_materialVariationIndexes
    end

    if InstanceUtils:Count(self.m_meshVariationDatabaseEntrys1p) == 0 and SharedUtils:IsClientModule() then
        ResourceManager:DestroyDynamicCompartment(ResourceCompartment.ResourceCompartment_Game)
    else
        self:CreateInstances()
    end

    -- removing hanging references
    self.m_waitingInstances = {
        meshVariationDatabase = nil, -- MeshVariationDatabase
        weaponEntities = {}, -- SoldierWeaponData
        weaponShaders = {} -- ShaderGraph
    }

    -- removing hanging references
    self.m_registryContainer = nil
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase

    self.m_skinnedMeshAsset1pWeaponGuids = {} -- WeaponStateData.mesh1p
    self.m_skinnedMeshAsset3pWeaponGuids = {} -- WeaponStateData.mesh3p
    self.m_meshVariationDatabaseEntrys1p = {} -- MeshVariationDatabaseEntry
    self.m_meshVariationDatabaseEntrys3p = {} -- MeshVariationDatabaseEntry
    self.m_databaseEntryMaterialIndexes = {} -- MeshVariationDatabaseEntry.materials
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint

    self.m_surfaceShaderStructs = {} -- SurfaceShaderInstanceDataStruct
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintVariationPairs = {} -- BlueprintAndVariationPair
end

function WeaponsAppearances:CreateInstances()
    if self.m_verbose >= 1 then
        print('Creating Instances')
    end

    self.m_registryContainer = RegistryContainer()

    for _, l_value in pairs(self.m_waitingInstances.weaponShaders) do
        self:CreateSurfaceShaderStructs(l_value)
        self:CreateMeshMaterialVariations(l_value)
    end

    for _, l_value in pairs(self.m_waitingInstances.weaponEntities) do
        local s_weaponEntity = l_value
        local s_meshVariationDatabaseEntry = self.m_meshVariationDatabaseEntrys1p[s_weaponEntity.instanceGuid:ToString('D')]

        if s_meshVariationDatabaseEntry ~= nil then
            self:CreateMeshVariationDatabaseEntrys(s_meshVariationDatabaseEntry)
            self:CreateObjectVariationAssets(s_meshVariationDatabaseEntry)
            self:CreateBlueprintAndVariationPairs(s_meshVariationDatabaseEntry)
            self:CreateUnlockAssets(s_meshVariationDatabaseEntry)
        end
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
        print('Created SurfaceShaderStructs: ' .. InstanceUtils:Count(self.m_surfaceShaderStructs))
        print('Created MeshMaterialVariations: ' .. InstanceUtils:Count(self.m_meshMaterialVariations))
        print('Created VariationDatabaseEntrys: ' .. InstanceUtils:Count(self.m_meshVariationDatabaseEntrys))
        print('Created ObjectVariationAssets: ' .. InstanceUtils:Count(self.m_objectVariationAssets))
        print('Created BlueprintVariationPairs: ' .. InstanceUtils:Count(self.m_blueprintVariationPairs))
        print('Created UnlockAssets: ' .. InstanceUtils:Count(self.m_unlockAssets))
        print('Created RegistryContainerAssets: ' .. InstanceUtils:Count(self.m_registryContainer.assetRegistry))
        print('Created RegistryContainerEntities: ' .. InstanceUtils:Count(self.m_registryContainer.entityRegistry))
        print('Created RegistryContainerBlueprints: ' .. InstanceUtils:Count(self.m_registryContainer.blueprintRegistry))
    end
end

-- creating SurfaceShaderInstanceDataStruct for MeshMaterialVariation
function WeaponsAppearances:CreateSurfaceShaderStructs(p_asset)
    local s_elements = {}

    for _, l_element in pairs(ElementalConfig.names) do
        local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()

        local s_color = ElementalConfig.colors[l_element]

        local s_camoDarkeningParameter = VectorShaderParameter()
        s_camoDarkeningParameter.value = Vec4(s_color.x, s_color.y, s_color.z, 0)
        s_camoDarkeningParameter.parameterName = 'CamoDarkening'
        s_camoDarkeningParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        local s_emissiveParameter = VectorShaderParameter()
        s_emissiveParameter.value = Vec4(1, 1, 1, 1)
        s_emissiveParameter.parameterName = 'Emissive'
        s_emissiveParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        s_surfaceShaderInstanceDataStruct.shader = p_asset
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_camoDarkeningParameter)
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_emissiveParameter)

        s_elements[l_element] = s_surfaceShaderInstanceDataStruct
    end

    self.m_surfaceShaderStructs[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshMaterialVariation for MeshVariationDatabaseMaterial
function WeaponsAppearances:CreateMeshMaterialVariations(p_asset)
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_elements = {}

    local s_surfaceShaderStructs = self.m_surfaceShaderStructs[p_asset.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshMaterialVariation = MeshMaterialVariation(InstanceUtils:GenerateGuid(p_asset.instanceGuid:ToString('D') .. 'MeshMaterialVariation' .. l_element))
        -- p_asset.partition:AddInstance(s_newMeshMaterialVariation)

        s_newMeshMaterialVariation.shader = s_surfaceShaderStructs[l_element]

        s_elements[l_element] = s_newMeshMaterialVariation
    end

    self.m_meshMaterialVariations[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshVariationDatabaseEntry for ObjectVariationAsset
function WeaponsAppearances:CreateMeshVariationDatabaseEntrys(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshVariationDatabaseEntrys')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry

    local s_skinnedMeshAsset1pWeaponGuid = self.m_skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]
    local s_meshVariationDatabaseEntry3p = self.m_meshVariationDatabaseEntrys3p[s_skinnedMeshAsset1pWeaponGuid]
    local s_materialVariationIndexes = self.m_databaseEntryMaterialIndexes[p_entry.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshVariationDatabaseEntry1p = InstanceUtils:CloneInstance(p_entry, l_element)
        local s_newMeshVariationDatabaseEntry3p = InstanceUtils:CloneInstance(s_meshVariationDatabaseEntry3p, l_element)

        for ll_key, ll_value in pairs(s_materialVariationIndexes) do
            local s_meshMaterialVariation = self.m_meshMaterialVariations[ll_value][l_element]

            s_newMeshVariationDatabaseEntry1p.materials[ll_key].materialVariation = s_meshMaterialVariation
            s_newMeshVariationDatabaseEntry3p.materials[ll_key].materialVariation = s_meshMaterialVariation
        end

        s_newMeshVariationDatabaseEntry1p.variationAssetNameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D') .. l_element)
        s_newMeshVariationDatabaseEntry3p.variationAssetNameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D') .. l_element)

        self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry1p)
        self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry3p)

        s_elements[l_element] = s_newMeshVariationDatabaseEntry1p
    end

    self.m_meshVariationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating ObjectVariationAsset for BlueprintAndVariationPair
function WeaponsAppearances:CreateObjectVariationAssets(p_entry)
    if self.m_verbose >= 2 then
        print('Create ObjectVariationAssets')
    end

    local s_elements = {}
    s_elements['neutral'] = nil

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newObjectVariationAsset = ObjectVariation(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'ObjectVariationAsset' .. l_element))
        p_entry.partition:AddInstance(s_newObjectVariationAsset)

        s_newObjectVariationAsset.name = p_entry.instanceGuid:ToString('D') .. l_element
        s_newObjectVariationAsset.nameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D') .. l_element)

        s_elements[l_element] = s_newObjectVariationAsset
    end

    self.m_objectVariationAssets[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating BlueprintAndVariationPair for UnlockAsset
function WeaponsAppearances:CreateBlueprintAndVariationPairs(p_entry)
    if self.m_verbose >= 2 then
        print('Create BlueprintAndVariationPairs')
    end

    local s_elements = {}
    s_elements['neutral'] = nil

    local s_skinnedMeshAsset1pWeaponGuid = self.m_skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]
    local s_weaponBlueprint = self.m_weaponBlueprints[s_skinnedMeshAsset1pWeaponGuid]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newBlueprintAndVariationPair = BlueprintAndVariationPair(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'BlueprintAndVariationPair' .. l_element))
        p_entry.partition:AddInstance(s_newBlueprintAndVariationPair)

        s_newBlueprintAndVariationPair.name = p_entry.instanceGuid:ToString('D')
        s_newBlueprintAndVariationPair.baseAsset = s_weaponBlueprint
        s_newBlueprintAndVariationPair.variation = self.m_objectVariationAssets[p_entry.instanceGuid:ToString('D')][l_element]

        s_elements[l_element] = s_newBlueprintAndVariationPair
    end

    self.m_blueprintVariationPairs[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating UnlockAsset
function WeaponsAppearances:CreateUnlockAssets(p_entry)
    if self.m_verbose >= 2 then
        print('Create UnlockAssets')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_entry.materials

    local s_skinnedMeshAsset1pWeaponGuid = self.m_skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newUnlockAsset = UnlockAsset(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'UnlockAsset' .. l_element))
        p_entry.partition:AddInstance(s_newUnlockAsset)

        s_newUnlockAsset.name = p_entry.instanceGuid:ToString('D') .. l_element
        s_newUnlockAsset.linkedTo:add(self.m_blueprintVariationPairs[p_entry.instanceGuid:ToString('D')][l_element])

        self.m_registryContainer.assetRegistry:add(s_newUnlockAsset)

        s_elements[l_element] = s_newUnlockAsset
    end

    self.m_unlockAssets[s_skinnedMeshAsset1pWeaponGuid] = s_elements
end

-- getting custom unlocks
function WeaponsAppearances:GetUnlockAssets(p_weapons, p_element, p_secondary)
    local s_unlocks = {}

    for l_key, l_value in pairs(p_weapons) do
        local s_unlockAsset = nil

        local s_element = p_element
        if l_key == 2 then
            s_element = p_secondary
        end

        if l_value ~= nil then
            local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(l_value)
            local s_weaponEntity = s_weaponUnlockAsset.weapon.object
            s_unlockAsset = self.m_unlockAssets[s_weaponEntity.instanceGuid:ToString('D')]

            if s_element == 'neutral' then
                s_unlockAsset = nil
            else
                s_unlockAsset = s_unlockAsset[s_element]
            end
        end

        s_unlocks[l_key] = s_unlockAsset
    end

    return s_unlocks
end

return WeaponsAppearances()