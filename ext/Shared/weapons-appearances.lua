local WeaponsAppearances = class('WeaponsAppearances')

local Uuid = require('__shared/utils/uuid')
local InstanceWait = require('__shared/utils/wait')

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
        meshVariationDatabase = nil,
        weaponEntities = {}
    }

    self.m_registryContainer = nil
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedMeshAsset1pWeaponGuids = {}
    self.m_skinnedMeshAsset3pWeaponGuids = {}
    self.m_meshVariationDatabaseEntrys1p = {}
    self.m_meshVariationDatabaseEntrys3p = {}
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

        self.m_skinnedMeshAsset1pWeaponGuids[s_weaponEntity.weaponStates[1].mesh1p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')
        self.m_skinnedMeshAsset3pWeaponGuids[s_weaponEntity.weaponStates[1].mesh3p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')

        self.m_weaponBlueprints[s_weaponEntity.instanceGuid:ToString('D')] = s_weaponEntity.soldierWeaponBlueprint
    end

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
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry.materials[1]

    for _, l_element in pairs(self.m_elementNames) do
        local s_newMeshMaterialVariation = MeshMaterialVariation(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'MeshMaterialVariation' .. l_element))
        p_entry.partition:AddInstance(s_newMeshMaterialVariation)

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

        s_newMeshMaterialVariation.shader = s_surfaceShaderInstanceDataStruct

        s_elements[l_element] = s_newMeshMaterialVariation
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

    for _, l_element in pairs(self.m_elementNames) do
        local s_newMeshVariationDatabaseEntry1p = self:_CloneInstance(p_entry, l_element)
        local s_newMeshVariationDatabaseEntry3p = self:_CloneInstance(s_meshVariationDatabaseEntry3p, l_element)

        local s_meshMaterialVariation = self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')][l_element]

        for l_key, l_value in pairs(s_newMeshVariationDatabaseEntry1p.materials) do
            local s_isNoCamo1p = false
            local s_isNoCamo3p = false
            local s_isPreset1p = false
            local s_isPreset3p = false
            local s_isShadow1p = false

            local s_isMedicBag = false
            local s_isAmmoBag = false

            if l_value.material.shader.shader ~= nil then
                s_isNoCamo1p = l_value.material.shader.shader.name:match('WeaponPresetShadowNoCamoFP')
                s_isNoCamo3p = l_value.material.shader.shader.name:match('WeaponPresetNoCamo3P')
                s_isPreset1p = l_value.material.shader.shader.name:match('WeaponPresetFP')
                s_isPreset3p = l_value.material.shader.shader.name:match('WeaponPreset3P')
                s_isShadow1p = l_value.material.shader.shader.name:match('WeaponPresetShadowFP')

                s_isMedicBag = l_value.material.shader.shader.name:match('Medicbag_main')
                s_isAmmoBag = l_value.material.shader.shader.name:match('Ammobag_main')
            end

            if s_isNoCamo1p or s_isNoCamo3p or s_isPreset1p or s_isPreset3p or s_isShadow1p or s_isMedicBag or s_isAmmoBag then
                s_newMeshVariationDatabaseEntry1p.materials[l_key].materialVariation = s_meshMaterialVariation
                s_newMeshVariationDatabaseEntry3p.materials[l_key].materialVariation = s_meshMaterialVariation
            end
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
        local s_newObjectVariationAsset = ObjectVariation(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'ObjectVariationAsset' .. l_element))
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
        local s_newBlueprintAndVariationPair = BlueprintAndVariationPair(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'BlueprintAndVariationPair' .. l_element))
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
        local s_newUnlockAsset = UnlockAsset(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'UnlockAsset' .. l_element))
        p_entry.partition:AddInstance(s_newUnlockAsset)

        s_newUnlockAsset.name = p_entry.instanceGuid:ToString('D') .. l_element
        s_newUnlockAsset.linkedTo:add(self.m_blueprintVariationPairs[p_entry.instanceGuid:ToString('D')][l_element])

        self.m_registryContainer.assetRegistry:add(s_newUnlockAsset)

        s_elements[l_element] = s_newUnlockAsset
    end

    self.m_unlockAssets[s_skinnedMeshAsset1pWeaponGuid] = s_elements
end


-- replacing player weapons
function WeaponsAppearances:ReplacePlayerWeapons(p_player, p_element)
    if self.m_verbose >= 1 then
        print('Replace Weapons')
    end

    if p_element == 'neutral' then
        return
    end

    for i = #p_player.weapons, 1, -1 do
        local s_weaponUnlockAsset = p_player.weapons[i]
        if s_weaponUnlockAsset ~= nil then
            local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(p_player.weapons[i])
            local s_weaponEntity = s_weaponUnlockAsset.weapon.object
            local s_unlockAsset = self.m_unlockAssets[s_weaponEntity.instanceGuid:ToString('D')][p_element]

            local s_weaponUnlockAssets = p_player.weaponUnlocks[i]
            if s_weaponUnlockAssets == nil then
                s_weaponUnlockAssets = {}
            end

            table.insert(s_weaponUnlockAssets, s_unlockAsset)

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

return WeaponsAppearances