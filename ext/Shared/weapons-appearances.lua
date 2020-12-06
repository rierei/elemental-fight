local WeaponsAppearances = class('WeaponsAppearances')

local InstanceWait = require('__shared/utils/wait')
local InstanceUtils = require('__shared/utils/instances')

function WeaponsAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function WeaponsAppearances:RegisterVars()
    self.m_elementNames = {'water', 'grass', 'fire'}

    self.m_elementColors = {
        water = Vec3(0, 0.6, 1),
        grass = Vec3(0.2, 0.6, 0.1),
        fire = Vec3(1, 0.3, 0)
    }

    self.m_waitingGuids = {
        camo = {'07EA9024-7D81-11E1-91A4-E3E3C1704D3D', '7DE14177-6868-59B2-06B5-3C9AA2610EEC'},
        _RU_Helmet05_Navy = {'706BF6C9-0EAD-4382-A986-39D571DBFA77', '53828D27-7C4A-415A-892D-8D410136E1B6'},
    }

    self.m_waitingInstances = {
        meshVariationDatabase = nil, -- MeshVariationDatabase
        weaponEntities = {} -- SoldierWeaponData
    }

    self.m_registryContainer = nil -- RegistryContainer
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedMeshAsset1pWeaponGuids = {} -- WeaponStateData.mesh1p
    self.m_skinnedMeshAsset3pWeaponGuids = {} -- WeaponStateData.mesh3p
    self.m_meshVariationDatabaseEntrys1p = {} -- MeshVariationDatabaseEntry
    self.m_meshVariationDatabaseEntrys3p = {} -- MeshVariationDatabaseEntry
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintVariationPairs = {} -- BlueprintAndVariationPair
    self.m_unlockAssets = {} -- UnlockAsset

    self.m_currentLevel = nil

    self.m_verbose = 1 -- prints debug information
end

function WeaponsAppearances:RegisterEvents()
    -- waiting variation database
    Events:Subscribe('Partition:Loaded', function(p_partition)
        if not self.m_isInstancesLoaded then
            for _, l_instance in pairs(p_partition.instances) do
                if l_instance:Is('MeshVariationDatabase') and Asset(l_instance).name:match('Levels') then
                    if self.m_verbose >= 1 then
                        print('Found MeshVariationDatabase')
                    end

                    self.m_waitingInstances.meshVariationDatabase = l_instance
                end
            end
        end
    end)

    -- waiting weapon entities
    Events:Subscribe('Partition:Loaded', function(p_partition)
        for _, l_instance in pairs(p_partition.instances) do
            if l_instance:Is('SoldierWeaponData') then
                if self.m_verbose >= 2 then
                    print('Found WeaponData')
                end

                table.insert(self.m_waitingInstances.weaponEntities, l_instance)
            end
        end
    end)

    -- reading instances before level loads
    Events:Subscribe('Level:LoadResources', function(p_level, p_mode, p_dedicated)
        if self.m_currentLevel ~= nil and (self.m_currentLevel ~= p_level or self.m_currentMode ~= p_mode) then
            self:ReloadInstances()
        else
            self:RegisterWait()
        end

        self.m_currentLevel = p_level
        self.m_currentMode = p_mode
    end)
end

function WeaponsAppearances:RegisterWait()
    -- waiting instances
    InstanceWait(self.m_waitingGuids, function(p_instances)
        self:ReadInstances()
    end)
end

-- reseting created instances
function WeaponsAppearances:ReloadInstances()
    if self.m_verbose >= 1 then
        print('Reloading Instances')
    end

    self.m_waitingInstances.weaponEntities = {} -- SoldierWeaponData
    self.m_unlockAssets = {} -- UnlockAsset

    self:RegisterWait()
end

function WeaponsAppearances:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    self.m_meshVariationDatabase = MeshVariationDatabase(self.m_waitingInstances.meshVariationDatabase)
    self.m_meshVariationDatabase:MakeWritable()

    -- reading weapon entities
    for _, l_value in pairs(self.m_waitingInstances.weaponEntities) do
        local s_weaponEntity = SoldierWeaponData(l_value)

        self.m_skinnedMeshAsset1pWeaponGuids[s_weaponEntity.weaponStates[1].mesh1p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')
        self.m_skinnedMeshAsset3pWeaponGuids[s_weaponEntity.weaponStates[1].mesh3p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')

        self.m_weaponBlueprints[s_weaponEntity.instanceGuid:ToString('D')] = s_weaponEntity.soldierWeaponBlueprint
    end

    -- reading mesh variations
    for _, l_value in pairs(self.m_meshVariationDatabase.entries) do
        local s_meshVariationDatabaseEntry = MeshVariationDatabaseEntry(l_value)
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

    self:CreateInstances()

    -- removing hanging references
    self.m_waitingInstances.meshVariationDatabase = nil

    -- removing hanging references
    self.m_registryContainer = nil -- RegistryContainer
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedMeshAsset1pWeaponGuids = {} -- WeaponStateData.mesh1p
    self.m_skinnedMeshAsset3pWeaponGuids = {} -- WeaponStateData.mesh3p
    self.m_meshVariationDatabaseEntrys1p = {} -- MeshVariationDatabaseEntry
    self.m_meshVariationDatabaseEntrys3p = {} -- MeshVariationDatabaseEntry
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint
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

    for _, l_value in pairs(self.m_waitingInstances.weaponEntities) do
        local s_weaponEntity = SoldierWeaponData(l_value)
        local s_meshVariationDatabaseEntry = self.m_meshVariationDatabaseEntrys1p[s_weaponEntity.instanceGuid:ToString('D')]

        if s_meshVariationDatabaseEntry ~= nil then
            self:CreateMeshMaterialVariations(s_meshVariationDatabaseEntry)
            self:CreateMeshVariationDatabaseEntrys(s_meshVariationDatabaseEntry)
            self:CreateObjectVariationAssets(s_meshVariationDatabaseEntry)
            self:CreateBlueprintAndVariationPairs(s_meshVariationDatabaseEntry)
            self:CreateUnlockAssets(s_meshVariationDatabaseEntry)
        end
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
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

-- creating MeshMaterialVariation for MeshVariationDatabaseMaterial
function WeaponsAppearances:CreateMeshMaterialVariations(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry.materials[1]

    for _, l_element in pairs(self.m_elementNames) do
        local s_shaderGraph = ShaderGraph()
        s_shaderGraph.name = 'Weapons/Shaders/WeaponPresetShadowFP'

        local s_color = self.m_elementColors[l_element]

        local s_camoDarkeningParameter = VectorShaderParameter()
        s_camoDarkeningParameter.value = Vec4(s_color.x, s_color.y, s_color.z, 0)
        s_camoDarkeningParameter.parameterName = 'CamoDarkening'
        s_camoDarkeningParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        local s_emissiveParameter = VectorShaderParameter()
        s_emissiveParameter.value = Vec4(1, 1, 1, 1)
        s_emissiveParameter.parameterName = 'Emissive'
        s_emissiveParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()
        s_surfaceShaderInstanceDataStruct.shader = s_shaderGraph
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_camoDarkeningParameter)
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_emissiveParameter)

        local s_databaseEntryMaterials = {}

        -- dont customize radio beacon and c4
        if not p_entry.mesh.name:match('radio_beacon') and not p_entry.mesh.name:match('c4') then
            for ll_key, ll_value in pairs(p_entry.materials) do
                local s_isNoCamo1p = false
                local s_isNoCamo3p = false
                local s_isPreset1p = false
                local s_isPreset3p = false
                local s_isShadow1p = false

                if ll_value.material.shader.shader ~= nil then
                    s_isNoCamo1p = ll_value.material.shader.shader.name:match('WeaponPresetShadowNoCamoFP')
                    s_isNoCamo3p = ll_value.material.shader.shader.name:match('WeaponPresetNoCamo3P')
                    s_isPreset1p = ll_value.material.shader.shader.name:match('WeaponPresetFP')
                    s_isPreset3p = ll_value.material.shader.shader.name:match('WeaponPreset3P')
                    s_isShadow1p = ll_value.material.shader.shader.name:match('WeaponPresetShadowFP')
                end

                if s_isNoCamo1p or s_isNoCamo3p or s_isPreset1p or s_isPreset3p or s_isShadow1p then
                    local s_newMeshMaterialVariation = MeshMaterialVariation(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'MeshMaterialVariation' .. l_element .. ll_key))
                    p_entry.partition:AddInstance(s_newMeshMaterialVariation)

                    s_newMeshMaterialVariation.shader = s_surfaceShaderInstanceDataStruct

                    s_databaseEntryMaterials[ll_key] = s_newMeshMaterialVariation
                end
            end
        end

        s_elements[l_element] = s_databaseEntryMaterials
    end

    self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')] = s_elements
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
    local s_meshMaterialVariations = self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')]

    for _, l_element in pairs(self.m_elementNames) do
        local s_newMeshVariationDatabaseEntry1p = InstanceUtils:CloneInstance(p_entry, l_element)
        local s_newMeshVariationDatabaseEntry3p = InstanceUtils:CloneInstance(s_meshVariationDatabaseEntry3p, l_element)

        for ll_key, ll_value in pairs(s_meshMaterialVariations[l_element]) do
            s_newMeshVariationDatabaseEntry1p.materials[ll_key].materialVariation = ll_value
            s_newMeshVariationDatabaseEntry3p.materials[ll_key].materialVariation = ll_value
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

    for _, l_element in pairs(self.m_elementNames) do
        local s_newObjectVariationAsset = ObjectVariation(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'ObjectVariationAsset' .. l_element))
        p_entry.partition:AddInstance(s_newObjectVariationAsset)

        s_newObjectVariationAsset.name = p_entry.instanceGuid:ToString('D') .. l_element
        s_newObjectVariationAsset.nameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D') .. l_element)

        self.m_registryContainer.assetRegistry:add(s_newObjectVariationAsset)

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

    for _, l_element in pairs(self.m_elementNames) do
        local s_newBlueprintAndVariationPair = BlueprintAndVariationPair(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'BlueprintAndVariationPair' .. l_element))
        p_entry.partition:AddInstance(s_newBlueprintAndVariationPair)

        s_newBlueprintAndVariationPair.name = p_entry.instanceGuid:ToString('D')
        s_newBlueprintAndVariationPair.baseAsset = s_weaponBlueprint
        s_newBlueprintAndVariationPair.variation = self.m_objectVariationAssets[p_entry.instanceGuid:ToString('D')][l_element]

        self.m_registryContainer.assetRegistry:add(s_newBlueprintAndVariationPair)

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
    s_elements['neutral'] = p_entry.materials

    local s_skinnedMeshAsset1pWeaponGuid = self.m_skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]

    for _, l_element in pairs(self.m_elementNames) do
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
function WeaponsAppearances:GetUnlockAssets(p_player, p_element)
    local s_unlocks = {}

    for l_key, l_value in pairs(p_player.weapons) do
        local s_unlockAsset = nil

        if l_value ~= nil then
            local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(l_value)
            local s_weaponEntity = s_weaponUnlockAsset.weapon.object
            s_unlockAsset = self.m_unlockAssets[s_weaponEntity.instanceGuid:ToString('D')][p_element]
        end

        s_unlocks[l_key] = s_unlockAsset
    end

    return s_unlocks
end

return WeaponsAppearances