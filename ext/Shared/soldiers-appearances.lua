local SoldiersAppearances = class('SoldiersAppearances')

local Uuid = require('__shared/utils/uuid')
local InstanceWait = require('__shared/utils/wait')

function SoldiersAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function SoldiersAppearances:RegisterVars()
    self.m_appearanceUnlockAssetGuids = {
        assault = 'F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4'
    }

    self.m_meshVariationDatabaseGuid = 'B056DEA3-8F11-D2FA-20FA-7A5C3F94A15E'

    self.m_waitingInstances = {
        upperSkinnedSocketObject = nil,
        lowerSkinnedSocketObject = nil,
        meshVariationDatabase = nil,
        appearanceUnlockAssets = {}
    }

    self.m_registryContainer = nil -- RegistryContainer
    self.m_databaseEntryIndexes = {}
    self.m_meshMaterialVariations = {}
    self.m_meshVariationDatabaseMaterials = {}
    self.m_variationDatabaseEntrys = {}
    self.m_objectVariationAssets = {}
    self.m_blueprintvariationPairs = {}
    self.m_linkUnlockAssets = {}
    self.m_appearanceUnlockAssets = {}

    self.m_verbose = 1 -- prints information
end

function SoldiersAppearances:RegisterEvents()
    Events:Subscribe('Partition:Loaded', function(p_partition)
        for _, l_instance in pairs(p_partition.instances) do
            self:ReadInstance(l_instance)
        end
    end)

    Events:Subscribe('Level:Destroy', function()
        if self.m_verbose >= 1 then
            print('Event Level:Destroy')
        end

        self:RegisterVars()
    end)

    local s_waitingGuids = {
        US_Helmet09_Desert = {'5B06C0E2-AFDC-455A-BDC4-11B77E1A8AFE', 'B1A0F507-D7F8-4301-8DE6-C6198364FE3B'},
        US_Upperbody04_Desert = {'CDEF869B-959A-11E0-86C2-B30910735269', 'C9F07E77-DA10-1781-CA13-715928514D59'},
        Arms1P_BareGlove03_Afro = {'2871BA93-D577-11E0-A7F0-894741C432F0', '67A32FD0-AEE3-61D0-7041-D6B811C9BFE6'},
        US_LB03_Desert = {'6149C356-959B-11E0-86C2-B30910735269', '494B07F4-4C11-1D87-E024-4FE4EB042055'},
        upperSkinnedSocketObject = {'1F5CC239-BE4F-4D03-B0B5-A0FF89976036', '59F371BF-DAD4-4AE9-9963-1568A9B8D661'},
        lowerSkinnedSocketObject = {'1F5CC239-BE4F-4D03-B0B5-A0FF89976036', 'B4063A93-0A43-4ABD-8463-B53027FA1304'},
        meshVariationDatabase = {'B056DEA3-8F11-D2FA-20FA-7A5C3F94A15E' ,'B056DEA3-8F11-D2FA-20FA-7A5C3F94A15E'}
    }

    InstanceWait(s_waitingGuids, function(p_instances)
        self.m_waitingInstances.upperSkinnedSocketObject = p_instances['upperSkinnedSocketObject']
        self.m_waitingInstances.upperSkinnedSocketObject:MakeWritable()

        self.m_waitingInstances.lowerSkinnedSocketObject = p_instances['lowerSkinnedSocketObject']
        self.m_waitingInstances.lowerSkinnedSocketObject:MakeWritable()

        self.m_waitingInstances.meshVariationDatabase = p_instances['meshVariationDatabase']
        self.m_waitingInstances.meshVariationDatabase:MakeWritable()

        self:CreateInstances()
    end)
end

function SoldiersAppearances:ReadInstance(p_instance)
    -- waiting appearance unlocks
    for l_key, l_value in pairs(self.m_appearanceUnlockAssetGuids) do
        if p_instance.instanceGuid:ToString('D') == l_value then
            if self.m_verbose >= 1 then
                print('Found AppearanceUnlockAsset')
            end

            self.m_waitingInstances.appearanceUnlockAssets[l_key] = p_instance
        end
    end
end

function SoldiersAppearances:CreateInstances()
    self.m_registryContainer = RegistryContainer()

    for l_key, l_instance in pairs(self.m_waitingInstances.appearanceUnlockAssets) do
        local s_appearanceUnlockAsset = UnlockAsset(l_instance)

        -- extracting link UnlockAsset from appearance UnlockAsset
        local s_linkUnlockAssets = {}
        for _, ll_value in pairs(s_appearanceUnlockAsset.linkedTo) do
            local s_linkUnlockAsset = UnlockAsset(ll_value)
            table.insert(s_linkUnlockAssets, s_linkUnlockAsset)
        end

        -- extracting BlueprintAndVariationPair from link UnlockAsset
        local s_blueprintAndVariationPairs = {}
        for _, ll_value in pairs(s_linkUnlockAssets) do
            for _, lll_value in pairs(ll_value.linkedTo) do
                if lll_value:Is('BlueprintAndVariationPair') then
                    local s_blueprintAndVariationPair = BlueprintAndVariationPair(lll_value)
                    table.insert(s_blueprintAndVariationPairs, s_blueprintAndVariationPair)
                end
            end
        end

        -- extracting ObjectVariationAsset from BlueprintAndVariationPair
        local s_objectVariationAssets = {}
        for _, ll_value in pairs(s_blueprintAndVariationPairs) do
            local s_objectVariationAsset = ObjectVariation(ll_value.variation)
            table.insert(s_objectVariationAssets, s_objectVariationAsset)
        end

        local s_meshVariationDatabaseEntrys = {}
        -- extracting MeshVariationDatabaseEntry from MeshVariationDatabase with ObjectVariationAsset
        local s_meshVariationDatabase = self.m_waitingInstances.meshVariationDatabase
        for _, l_value in pairs(s_meshVariationDatabase.entries) do
            local s_meshVariationDatabaseEntry = MeshVariationDatabaseEntry(l_value)
            for _, ll_value in pairs(s_objectVariationAssets) do
                if s_meshVariationDatabaseEntry.variationAssetNameHash == ll_value.nameHash then
                    s_meshVariationDatabaseEntrys[s_meshVariationDatabaseEntry.instanceGuid:ToString('D')] = s_meshVariationDatabaseEntry
                end
            end
        end

        -- extract MeshVariationDatabaseMaterial from MeshVariationDatabaseEntry
        for _, ll_value in pairs(s_meshVariationDatabaseEntrys) do
            local s_skinnedMeshAsset = SkinnedMeshAsset(ll_value.mesh)

            local s_meshMaterialIndex = nil
            if s_skinnedMeshAsset.name == 'characters/arms/arms1p_bareglove03/arms1p_bareglove03_Mesh' then
                s_meshMaterialIndex = 4
            -- elseif s_skinnedMeshAsset.name == 'characters/upperbody/us_upperbody04/us_upperbody04_Mesh' then
            --     s_meshMaterialIndex = 1
            -- elseif s_skinnedMeshAsset.name == 'Characters/LowerBody/US_Lowerbody03/US_LB03_Desert' then
            --     s_meshMaterialIndex = 1
            end

            -- searching MeshVariationDatabaseMaterial
            if s_meshMaterialIndex ~= nil then
                for lll_key, lll_value in pairs(ll_value.materials) do
                    if lll_value.material.instanceGuid == s_skinnedMeshAsset.materials[s_meshMaterialIndex].instanceGuid then
                        print(lll_key)
                        self.m_databaseEntryIndexes[ll_value.instanceGuid:ToString('D')] = lll_key
                    end
                end
            end
        end

        -- processing MeshVariationDatabaseEntry
        for _, ll_value in pairs(s_meshVariationDatabaseEntrys) do
            self:CreateMeshMaterialVariations(ll_value)
            self:CreateVariationDatabaseMaterials(ll_value)
            self:CreateMeshVariationDatabaseEntrys(ll_value)
        end

        -- processing ObjectVariationAsset
        for _, ll_value in pairs(s_objectVariationAssets) do
            self:CreateObjectVariationAssets(ll_value)
        end

        -- processing BlueprintAndVariationPair
        for _, ll_value in pairs(s_blueprintAndVariationPairs) do
            self:CreateBlueprintAndVariationPair(ll_value)
        end

        -- processing UnlockAsset
        for _, ll_value in pairs(s_linkUnlockAssets) do
            self:CreateLinkUnlockAsset(ll_value)
        end

        -- processing UnlockAsset
        self:CreateAppearanceUnlockAsset(s_appearanceUnlockAsset)
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
        print('Created databaseEntryIndexes: ' .. self:_Count(self.m_databaseEntryIndexes))
        print('Created meshMaterialVariations: ' .. self:_Count(self.m_meshMaterialVariations))
        print('Created variationDatabaseEntrys: ' .. self:_Count(self.m_variationDatabaseEntrys))
        print('Created objectVariationAssets: ' .. self:_Count(self.m_objectVariationAssets))
        print('Created blueprintvariationPairs: ' .. self:_Count(self.m_blueprintvariationPairs))
        print('Created linkUnlockAssets: ' .. self:_Count(self.m_linkUnlockAssets))
        print('Created appearanceUnlockAssets: ' .. self:_Count(self.m_appearanceUnlockAssets))
        print('Created RegistryContainerAssets: ' .. self:_Count(self.m_registryContainer.assetRegistry))
        print('Created RegistryContainerEntities: ' .. self:_Count(self.m_registryContainer.entityRegistry))
        print('Created RegistryContainerBlueprints: ' .. self:_Count(self.m_registryContainer.blueprintRegistry))
    end
end

-- creating MeshMaterialVariation for MeshVariationDatabaseMaterial
function SoldiersAppearances:CreateMeshMaterialVariations(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_variations = {}

    local s_meshVariationDatabaseMaterialIndex = self.m_databaseEntryIndexes[p_entry.instanceGuid:ToString('D')]

    for l_key, l_value in pairs(p_entry.materials) do
        if l_key == s_meshVariationDatabaseMaterialIndex then
            local s_newMeshMaterialVariation = nil

            if l_value.variation ~= nil then
                s_newMeshMaterialVariation = self:_CloneInstance(l_value.variation)
            else
                s_newMeshMaterialVariation = MeshMaterialVariation(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. l_key))
                p_entry.partition:AddInstance(s_newMeshMaterialVariation)
            end

            local shader = ShaderGraph()
            shader.name = 'shaders/Root/CharacterRoot'

            local dirtColorParameter = VectorShaderParameter()
            dirtColorParameter.value = Vec4(0, 0.6, 1, 0)
            dirtColorParameter.parameterName = '_DirtColor'
            dirtColorParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

            local dirtScaleParameter = VectorShaderParameter()
            dirtScaleParameter.value = Vec4(10, 0, 0, 0)
            dirtScaleParameter.parameterName = '_DirtScaleMax'
            dirtScaleParameter.parameterType = ShaderParameterType.ShaderParameterType_Scalar

            s_newMeshMaterialVariation.shader.shader = shader
            s_newMeshMaterialVariation.shader.vectorParameters:add(dirtColorParameter)
            s_newMeshMaterialVariation.shader.vectorParameters:add(dirtScaleParameter)

            s_variations[l_key] = s_newMeshMaterialVariation
        end
    end

    self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')] = s_variations
end

-- creating MeshVariationDatabaseMaterial for MeshVariationDatabaseEntry
function SoldiersAppearances:CreateVariationDatabaseMaterials(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshVariationDatabaseMaterials')
    end

    local s_materials = {}

    local s_meshVariationDatabaseMaterialIndex = self.m_databaseEntryIndexes[p_entry.instanceGuid:ToString('D')]

    for l_key, l_value in pairs(p_entry.materials) do
        if l_key == s_meshVariationDatabaseMaterialIndex then
            local s_newMeshVariationDatabaseMaterial = l_value:Clone()

            local s_variationDatabaseEntryGuid = p_entry.instanceGuid:ToString('D')
            s_newMeshVariationDatabaseMaterial.materialVariation = self.m_meshMaterialVariations[s_variationDatabaseEntryGuid][l_key]

            s_materials[l_key] = s_newMeshVariationDatabaseMaterial
        end
    end

    self.m_meshVariationDatabaseMaterials[p_entry.instanceGuid:ToString('D')] = s_materials
end

-- creating MeshVariationDatabaseEntry for ObjectVariationAsset
function SoldiersAppearances:CreateMeshVariationDatabaseEntrys(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshVariationDatabaseEntrys')
    end

    local s_newMeshVariationDatabaseEntry = self:_CloneInstance(p_entry)

    local s_meshVariationDatabaseMaterials = self.m_meshVariationDatabaseMaterials[p_entry.instanceGuid:ToString('D')]
    for l_key, l_value in pairs(s_meshVariationDatabaseMaterials) do
        s_newMeshVariationDatabaseEntry.materials[l_key] = l_value
    end

    s_newMeshVariationDatabaseEntry.variationAssetNameHash = MathUtils:FNVHash('testing/abc' .. p_entry.variationAssetNameHash)

    self.m_waitingInstances.meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry)

    self.m_variationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] = s_newMeshVariationDatabaseEntry
end

-- creating ObjectVariationAsset for BlueprintAndVariationPair
function SoldiersAppearances:CreateObjectVariationAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create ObjectVariationAssets')
    end

    local s_newObjectVariationAsset = self:_CloneInstance(p_asset)

    s_newObjectVariationAsset.name = 'testing/abc' .. p_asset.nameHash
    s_newObjectVariationAsset.nameHash = MathUtils:FNVHash('testing/abc' .. p_asset.nameHash)

    if p_asset.name == 'Characters/Arms/Arms1P_BareGlove03/Arms1P_BareGlove03_Afro' then
        self.m_waitingInstances.upperSkinnedSocketObject.variation1pGuids:add(s_newObjectVariationAsset.instanceGuid)
    else
        self.m_waitingInstances.lowerSkinnedSocketObject.variation3pGuids:add(s_newObjectVariationAsset.instanceGuid)
    end

    self.m_registryContainer.assetRegistry:add(s_newObjectVariationAsset)

    self.m_objectVariationAssets[p_asset.instanceGuid:ToString('D')] = s_newObjectVariationAsset
end

-- creating BlueprintAndVariationPair for Link UnlockAsset
function SoldiersAppearances:CreateBlueprintAndVariationPair(p_data)
    if self.m_verbose >= 2 then
        print('Create BlueprintAndVariationPairs')
    end

    local s_newBlueprintAndVariationPair = self:_CloneInstance(p_data)

    s_newBlueprintAndVariationPair.variation = self.m_objectVariationAssets[s_newBlueprintAndVariationPair.variation.instanceGuid:ToString('D')]

    self.m_registryContainer.assetRegistry:add(s_newBlueprintAndVariationPair)

    self.m_blueprintvariationPairs[p_data.instanceGuid:ToString('D')] = s_newBlueprintAndVariationPair
end

-- creating link UnlockAsset for appearance UnlockAsset
function SoldiersAppearances:CreateLinkUnlockAsset(p_asset)
    if self.m_verbose >= 2 then
        print('Create LinkUnlockAssets')
    end

    local s_newLinkUnlockAsset = self:_CloneInstance(p_asset)

    for l_key, l_value in pairs(s_newLinkUnlockAsset.linkedTo) do
        if l_value:Is('BlueprintAndVariationPair') then
            local s_newBlueprintVariationPair = self.m_blueprintvariationPairs[l_value.instanceGuid:ToString('D')]

            s_newLinkUnlockAsset.linkedTo[l_key] = s_newBlueprintVariationPair
        end
    end

    self.m_registryContainer.assetRegistry:add(s_newLinkUnlockAsset)

    self.m_linkUnlockAssets[p_asset.instanceGuid:ToString('D')] = s_newLinkUnlockAsset
end

-- creating appearance UnlockAsset
function SoldiersAppearances:CreateAppearanceUnlockAsset(p_asset)
    if self.m_verbose >= 2 then
        print('Create AppearanceUnlockAssets')
    end

    local s_newAppearanceUnlockAsset = self:_CloneInstance(p_asset)

    for l_key, l_value in pairs(s_newAppearanceUnlockAsset.linkedTo) do
        s_newAppearanceUnlockAsset.linkedTo[l_key] = self.m_linkUnlockAssets[l_value.instanceGuid:ToString('D')]
    end

    self.m_registryContainer.assetRegistry:add(s_newAppearanceUnlockAsset)

    self.m_appearanceUnlockAssets[p_asset.instanceGuid:ToString('D')] = s_newAppearanceUnlockAsset
end

function SoldiersAppearances:ReplacePlayerAppearance(p_player)
    local s_appearanceUnlockAsset = self.m_appearanceUnlockAssets[p_player.visualUnlocks[1].instanceGuid:ToString('D')]
	p_player:SelectUnlockAssets(p_player.customization, { s_appearanceUnlockAsset })
end

-- cloning the instance and adding to partition
function SoldiersAppearances:_CloneInstance(p_instance)
    if self.m_verbose >= 2 then
        print('Clone: ' .. p_instance.typeInfo.name)
    end

    local p_variation = 'test'

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
function SoldiersAppearances:_GenerateGuid(p_seed)
    Uuid.randomseed(MathUtils:FNVHash(p_seed))
    return Guid(Uuid())
end

-- counting table elements
function SoldiersAppearances:_Count(p_table)
    local s_count = 0

    for _, _ in pairs(p_table) do
        s_count = s_count + 1
    end

    return s_count
end

return SoldiersAppearances