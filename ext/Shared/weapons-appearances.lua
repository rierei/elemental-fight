local WeaponsAppearances = class('WeaponsAppearances')

local Uuid = require('__shared/utils/uuid')
local InstanceWait = require('__shared/utils/wait')

function WeaponsAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function WeaponsAppearances:RegisterVars()
    self.m_waitingGuids = {
        camo = {'07EA9024-7D81-11E1-91A4-E3E3C1704D3D', '7DE14177-6868-59B2-06B5-3C9AA2610EEC'},
        _RU_Helmet05_Navy = {'706BF6C9-0EAD-4382-A986-39D571DBFA77', '53828D27-7C4A-415A-892D-8D410136E1B6'},
    }

    self.m_waitingInstances = {
        meshVariationDatabase = nil,
        weaponEntities = {},
        skinnedMeshAsset1pWeaponGuids = {},
        skinnedMeshAsset3pWeaponGuids = {},
        meshVariationDatabaseEntrys1p = {},
        meshVariationDatabaseEntrys3p = {},
    }

    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_weaponBlueprints = {}
    self.m_meshMaterialVariations = {}
    self.m_meshVariationDatabaseEntrys = {}
    self.m_objectVariationAssets = {}
    self.m_blueprintVariationPairs = {}
    self.m_unlockAssets = {}

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

    InstanceWait(self.m_waitingGuids, function(p_instances)
        self:ReadInstances()
    end)
end

function WeaponsAppearances:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    self.m_meshVariationDatabase = MeshVariationDatabase(self.m_waitingInstances.meshVariationDatabase)
    self.m_meshVariationDatabase:MakeWritable()

    for _, l_value in pairs(self.m_waitingInstances.weaponEntities) do
        local s_weaponEntity = SoldierWeaponData(l_value)

        self.m_waitingInstances.skinnedMeshAsset1pWeaponGuids[s_weaponEntity.weaponStates[1].mesh1p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')
        self.m_waitingInstances.skinnedMeshAsset3pWeaponGuids[s_weaponEntity.weaponStates[1].mesh3p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')

        self.m_weaponBlueprints[s_weaponEntity.instanceGuid:ToString('D')] = s_weaponEntity.soldierWeaponBlueprint
    end

    for _, l_value in pairs(self.m_meshVariationDatabase.entries) do
        local s_meshVariationDatabaseEntry = MeshVariationDatabaseEntry(l_value)
        local s_skinnedMeshAsset1pWeaponGuid = self.m_waitingInstances.skinnedMeshAsset1pWeaponGuids[s_meshVariationDatabaseEntry.mesh.instanceGuid:ToString('D')]
        local s_skinnedMeshAsset3pWeaponGuid = self.m_waitingInstances.skinnedMeshAsset3pWeaponGuids[s_meshVariationDatabaseEntry.mesh.instanceGuid:ToString('D')]

        if s_meshVariationDatabaseEntry.variationAssetNameHash == 0 then
            if s_skinnedMeshAsset1pWeaponGuid ~= nil then
                self.m_waitingInstances.meshVariationDatabaseEntrys1p[s_skinnedMeshAsset1pWeaponGuid] = s_meshVariationDatabaseEntry
            end

            if s_skinnedMeshAsset3pWeaponGuid ~= nil then
                self.m_waitingInstances.meshVariationDatabaseEntrys3p[s_skinnedMeshAsset3pWeaponGuid] = s_meshVariationDatabaseEntry
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

    for _, l_value in pairs(self.m_waitingInstances.weaponEntities) do
        local s_weaponEntity = SoldierWeaponData(l_value)
        local s_meshVariationDatabaseEntry = self.m_waitingInstances.meshVariationDatabaseEntrys1p[s_weaponEntity.instanceGuid:ToString('D')]

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

-- creating MeshMaterialVariation for MeshVariationDatabaseMaterial
function WeaponsAppearances:CreateMeshMaterialVariations(p_entry)
    local s_newMeshMaterialVariation = MeshMaterialVariation(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'newMeshMaterialVariation'))
    p_entry.partition:AddInstance(s_newMeshMaterialVariation)

    local s_shaderGraph = ShaderGraph()
    s_shaderGraph.name = 'Weapons/Shaders/WeaponPresetShadowFP'

    local camoDarkening = VectorShaderParameter()
    camoDarkening.value = Vec4(0, 0, 1, 0)
    camoDarkening.parameterName = 'CamoDarkening'
    camoDarkening.parameterType = ShaderParameterType.ShaderParameterType_Color

    local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()
    s_surfaceShaderInstanceDataStruct.shader = s_shaderGraph
    s_surfaceShaderInstanceDataStruct.vectorParameters:add(camoDarkening)

    s_newMeshMaterialVariation.shader = s_surfaceShaderInstanceDataStruct

    self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')] = s_newMeshMaterialVariation
end

-- creating MeshVariationDatabaseEntry for ObjectVariationAsset
function WeaponsAppearances:CreateMeshVariationDatabaseEntrys(p_entry)
    local s_skinnedMeshAsset1pWeaponGuid = self.m_waitingInstances.skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]

    local s_meshVariationDatabaseEntry3p = self.m_waitingInstances.meshVariationDatabaseEntrys3p[s_skinnedMeshAsset1pWeaponGuid]

    local s_newMeshVariationDatabaseEntry1p = self:_CloneInstance(p_entry, 's_newMeshVariationDatabaseEntry1p')
    local s_newMeshVariationDatabaseEntry3p = self:_CloneInstance(s_meshVariationDatabaseEntry3p, 's_newMeshVariationDatabaseEntry3p')

    local s_meshMaterialVariation = self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')]

    s_newMeshVariationDatabaseEntry1p.materials[1].materialVariation = s_meshMaterialVariation
    s_newMeshVariationDatabaseEntry1p.materials[2].materialVariation = s_meshMaterialVariation
    s_newMeshVariationDatabaseEntry1p.variationAssetNameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D'))

    s_newMeshVariationDatabaseEntry3p.materials[1].materialVariation = s_meshMaterialVariation
    s_newMeshVariationDatabaseEntry3p.materials[2].materialVariation = s_meshMaterialVariation
    s_newMeshVariationDatabaseEntry3p.variationAssetNameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D'))

    self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry1p)
    self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry3p)

    self.m_meshVariationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] = s_newMeshVariationDatabaseEntry1p
end

-- creating ObjectVariationAsset for BlueprintAndVariationPair
function WeaponsAppearances:CreateObjectVariationAssets(p_entry)
    local s_newObjectVariationAsset = ObjectVariation(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'newObjectVariationAsset'))
    p_entry.partition:AddInstance(s_newObjectVariationAsset)

    s_newObjectVariationAsset.name = p_entry.instanceGuid:ToString('D')
    s_newObjectVariationAsset.nameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D'))

    self.m_registryContainer.assetRegistry:add(s_newObjectVariationAsset)

    self.m_objectVariationAssets[p_entry.instanceGuid:ToString('D')] = s_newObjectVariationAsset
end

-- creating BlueprintAndVariationPair for UnlockAsset
function WeaponsAppearances:CreateBlueprintAndVariationPairs(p_entry)
    local s_skinnedMeshAsset1pWeaponGuid = self.m_waitingInstances.skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]

    local s_newBlueprintAndVariationPair = BlueprintAndVariationPair(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'newBlueprintAndVariationPair'))
    p_entry.partition:AddInstance(s_newBlueprintAndVariationPair)

    s_newBlueprintAndVariationPair.name = p_entry.instanceGuid:ToString('D')
    s_newBlueprintAndVariationPair.baseAsset = self.m_weaponBlueprints[s_skinnedMeshAsset1pWeaponGuid]
    s_newBlueprintAndVariationPair.variation = self.m_objectVariationAssets[p_entry.instanceGuid:ToString('D')]

    self.m_registryContainer.assetRegistry:add(s_newBlueprintAndVariationPair)

    self.m_blueprintVariationPairs[p_entry.instanceGuid:ToString('D')] = s_newBlueprintAndVariationPair
end

-- creating UnlockAsset
function WeaponsAppearances:CreateUnlockAssets(p_entry)
    local s_skinnedMeshAsset1pWeaponGuid = self.m_waitingInstances.skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]

    local s_newUnlockAsset = UnlockAsset(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'newUnlockAsset'))
    p_entry.partition:AddInstance(s_newUnlockAsset)

    s_newUnlockAsset.name = p_entry.instanceGuid:ToString('D')
    s_newUnlockAsset.linkedTo:add(self.m_blueprintVariationPairs[p_entry.instanceGuid:ToString('D')])

    self.m_registryContainer.assetRegistry:add(s_newUnlockAsset)

    self.m_unlockAssets[s_skinnedMeshAsset1pWeaponGuid] = s_newUnlockAsset
end


-- replacing player weapons
function WeaponsAppearances:ReplacePlayerWeapons(p_player)
    local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(p_player.weapons[1])
    local s_weaponEntity = s_weaponUnlockAsset.weapon.object

    local s_unlockAsset = self.m_unlockAssets[s_weaponEntity.instanceGuid:ToString('D')]

    print(s_unlockAsset)

    -- local s_weaponUnlockAssets = p_player.weaponUnlocks[1]
    -- table.insert(s_weaponUnlockAssets, s_unlockAsset)

    p_player:SelectWeapon(0, s_weaponUnlockAsset, { s_unlockAsset })
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

return WeaponsAppearances