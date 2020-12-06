local WeaponsAppearances = class('WeaponsAppearances')

local Uuid = require('__shared/utils/uuid')
local InstanceWait = require('__shared/utils/wait')

function WeaponsAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function WeaponsAppearances:RegisterVars()
    self.m_waitingGuids = {
        _RU_Helmet05_Navy = {'706BF6C9-0EAD-4382-A986-39D571DBFA77', '53828D27-7C4A-415A-892D-8D410136E1B6'}
    }

    self.m_waitingInstances = {
        meshVariationDatabase = nil,
        weaponEntities = {},
        skinnedMeshAssetWeaponGuids = {},
        meshVariationDatabaseEntrys = {}
    }

    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_weaponCustomizationAssets = {}
    self.m_meshMaterialVariations = {}
    self.m_meshVariationDatabaseEntrys = {}
    self.m_objectVariationAssets = {}
    self.m_blueprintVariationPairs = {}
    self.m_unlockAssets = {}

    self.m_verbose = 2 -- prints debug information
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
                    print('Found SoldierWeaponData')
                end

                table.insert(self.m_waitingInstances.weaponEntities, l_instance)
            end
        end
    end)

    InstanceWait(self.m_waitingGuids, function(p_instances)
        self:ReadInstances()
    end)
end

function WeaponsAppearances:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    for _, l_value in pairs(self.m_waitingInstances.weaponEntities) do
        local s_weaponEntity = SoldierWeaponData(l_value)

        if s_weaponEntity.customization == nil then
            return
        end

        local s_weaponCustomizationAsset = VeniceSoldierWeaponCustomizationAsset(s_weaponEntity.customization)

        self.m_weaponCustomizationAssets[s_weaponEntity.instanceGuid:ToString('D')] = s_weaponCustomizationAsset

        self.m_waitingInstances.skinnedMeshAssetWeaponGuids[s_weaponEntity.mesh1p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')
        self.m_waitingInstances.skinnedMeshAssetWeaponGuids[s_weaponEntity.mesh3p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')

        self.m_weaponBlueprints[s_weaponEntity.instanceGuid:ToString('D')] = l_value.soldierWeaponBlueprint
    end

    for _, l_value in pairs(self.m_meshVariationDatabase.entries) do
        local s_meshVariationDatabaseEntry = MeshVariationDatabaseEntry(l_value)
        for ll_key, ll_value in pairs(self.m_waitingInstances.skinnedMeshAssetWeaponGuids) do
            self.m_waitingInstances.meshVariationDatabaseEntrys[ll_value] = {}
            if s_meshVariationDatabaseEntry.mesh.instanceGuid:ToString('D') == ll_key then
                self.m_waitingInstances.meshVariationDatabaseEntrys[ll_value]:add(s_meshVariationDatabaseEntry)
            end
        end
    end

    self:CreateInstances()
end

function WeaponsAppearances:CreateInstances()
    if self.m_verbose >= 1 then
        print('Creating Instances')
    end

    self.m_registryContainer = RegistryContainer()

    -- creating MeshMaterialVariation for MeshVariationDatabaseMaterial
    for l_key, l_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys) do
        local s_newMeshMaterialVariation = MeshMaterialVariation(self:_GenerateGuid(l_value.instanceGuid:ToString('D') .. 'newMeshMaterialVariation'))
        l_value[1].partition:AddInstance(s_newMeshMaterialVariation)

        local s_shaderGraph = ShaderGraph()
        s_shaderGraph.name = 'shaders/Root/CharacterRoot'

        local s_dirtColorParameter = VectorShaderParameter()
        s_dirtColorParameter.value = Vec4(0, 0, 1, 0)
        s_dirtColorParameter.parameterName = '_DirtColor'
        s_dirtColorParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()
        s_surfaceShaderInstanceDataStruct.shader = s_shaderGraph
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_dirtColorParameter)

        self.m_meshMaterialVariations[l_value[1].instanceGuid:ToString('D')] = s_newMeshMaterialVariation
    end

    -- creating MeshVariationDatabaseEntry for ObjectVariationAsset
    for l_key, l_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys) do
        local s_newMeshVariationDatabaseEntry1 = self:_CloneInstance(l_value[1], 's_newMeshVariationDatabaseEntry1')
        local s_newMeshVariationDatabaseEntry2 = self:_CloneInstance(l_value[2], 's_newMeshVariationDatabaseEntry2')

        local s_meshMaterialVariation = self.m_meshMaterialVariations[l_value[1].instanceGuid:ToString('D')]

        s_newMeshVariationDatabaseEntry1.materials[1].materialVariation = s_meshMaterialVariation
        s_newMeshVariationDatabaseEntry1.materials[2].materialVariation = s_meshMaterialVariation
        s_newMeshVariationDatabaseEntry1.variationAssetNameHash = MathUtils:FNVHash(l_value[1].instanceGuid:ToString('D'))

        s_newMeshVariationDatabaseEntry2.materials[1].materialVariation = s_meshMaterialVariation
        s_newMeshVariationDatabaseEntry2.materials[2].materialVariation = s_meshMaterialVariation
        s_newMeshVariationDatabaseEntry2.variationAssetNameHash = MathUtils:FNVHash(l_value[1].instanceGuid:ToString('D'))

        self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry1)
        self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry2)

        self.m_meshVariationDatabaseEntrys[l_value[1].instanceGuid:ToString('D')] = s_newMeshVariationDatabaseEntry1
    end

    -- creating ObjectVariationAsset for BlueprintAndVariationPair
    for l_key, l_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys) do
        local s_newObjectVariationAsset = ObjectVariation(self:_GenerateGuid(l_value[1].instanceGuid:ToString('D') .. 'newObjectVariationAsset'))
        l_value[1].partition:AddInstance(s_newObjectVariationAsset)

        s_newObjectVariationAsset.name = l_value[1].instanceGuid:ToString('D')
        s_newObjectVariationAsset.nameHash = MathUtils:FNVHash(l_value[1].instanceGuid:ToString('D'))

        self.m_registryContainer.assetRegistry:add(s_newObjectVariationAsset)

        self.m_objectVariationAssets[l_value[1].instanceGuid:ToString('D')] = s_newObjectVariationAsset
    end

    -- creating BlueprintAndVariationPair for UnlockAsset
    for l_key, l_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys) do
        local s_newBlueprintAndVariationPair = BlueprintAndVariationPair(self:_GenerateGuid(l_value[1].instanceGuid:ToString('D') .. 'newBlueprintAndVariationPair'))
        l_value[1].partition:AddInstance(s_newBlueprintAndVariationPair)

        s_newBlueprintAndVariationPair.name = l_value[1].instanceGuid:ToString('D')
        s_newBlueprintAndVariationPair.baseAsset = self.m_weaponBlueprints[l_key]
        s_newBlueprintAndVariationPair.variation = self.m_objectVariationAssets[l_value[1].instanceGuid:ToString('D')]

        self.m_registryContainer.assetRegistry:add(s_newBlueprintAndVariationPair)

        self.m_blueprintVariationPairs[l_value[1].instanceGuid:ToString('D')] = s_newBlueprintAndVariationPair
    end

    -- creating UnlockAsset for CustomizationUnlockParts
    for l_key, l_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys) do
        local s_newUnlockAsset = UnlockAsset(self:_GenerateGuid(l_value[1].instanceGuid:ToString('D') .. 'newUnlockAsset'))
        l_value[1].partition:AddInstance(s_newUnlockAsset)

        s_newUnlockAsset.name = l_value[1].instanceGuid:ToString('D')
        s_newUnlockAsset.linkedTo:add(self.m_blueprintVariationPairs[l_value[1].instanceGuid:ToString('D')])

        self.m_registryContainer.assetRegistry:add(s_newUnlockAsset)

        self.m_unlockAssets[l_key] = s_newUnlockAsset
    end

    -- patching CustomizationUnlockParts
    for l_key, l_value in pairs(self.m_weaponCustomizationAssets) do
        local s_customizationUnlockParts = l_value.customization.unlockParts[4]

        s_customizationUnlockParts:add(self.m_unlockAssets[l_key])
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
        print('Created WeaponCustomizationAssets: ' .. self:_Count(self.m_weaponCustomizationAssets))
        print('Created MeshMaterialVariations: ' .. self:_Count(self.m_meshMaterialVariations))
        print('Created VariationDatabaseEntrys: ' .. self:_Count(self.m_meshVariationDatabaseEntrys))
        print('Created ObjectVariationAssets: ' .. self:_Count(self.m_objectVariationAssets))
        print('Created BlueprintVariationPairs: ' .. self:_Count(self.m_blueprintVariationPairs))
        print('Created UnlockAssets: ' .. self:_Count(self.m_unlockAssets))
        print('Created RegistryContainerAssets: ' .. self:_Count(self.m_registryContainer.assetRegistry))
        print('Created RegistryContainerEntities: ' .. self:_Count(self.m_registryContainer.entityRegistry))
        print('Created RegistryContainerBlueprints: ' .. self:_Count(self.m_registryContainer.blueprintRegistry))
    end
end

-- replacing player weapons
function WeaponsAppearances:ReplacePlayerWeapons(p_player)
    for i = #p_player.weapons, 1, -1 do
        local s_weaponUnlockAsset = p_player.weapons[i]
        if s_weaponUnlockAsset ~= nil then
            local s_unlockAsset = self.m_unlockAssets[s_weaponUnlockAsset.instanceGuid:ToString('D')]

            local s_weaponUnlockAssets = p_player.weaponUnlocks[i]
            if s_weaponUnlockAssets == nil then
                s_weaponUnlockAssets = {}
            end

            s_weaponUnlockAssets:add(s_unlockAsset)

            p_player:SelectWeapon(i - 1, s_weaponUnlockAsset, s_weaponUnlockAssets)
        end
    end
end

-- cloning the instance and adding to partition
function WeaponsAppearances:_CloneInstance(p_instance, p_variation)
    if self.m_verbose >= 2 then
        print('Clone: ' .. p_instance.typeInfo.name)
    end

    local s_seed = p_instance.instanceGuid:ToString('D') .. p_variation
    local s_partition = p_instance.partition

    local s_newGuid = self:_GenerateGuid(s_seed)
    local s_newInstance = p_instance:Clone(s_newGuid)
    s_partition:AddInstance(s_newInstance)

    -- casting the instance
    local s_typeName = s_newInstance.typeInfo.name
    local s_type = _G[s_typeName]

    if s_type ~= nil then
        s_newInstance = s_type(s_newInstance)
    end

    return s_newInstance
end

-- generating UUID for the provided seed
function WeaponsAppearances:_GenerateGuid(p_seed)
    Uuid.randomseed(MathUtils:FNVHash(p_seed))
    return Guid(Uuid())
end

-- counting table elements
function WeaponsAppearances:_Count(p_table)
    local s_count = 0

    for _, _ in pairs(p_table) do
        s_count = s_count + 1
    end

    return s_count
end