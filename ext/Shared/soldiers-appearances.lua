local SoldiersAppearances = class('SoldiersAppearances')

local Uuid = require('__shared/utils/uuid')
local InstanceWait = require('__shared/utils/wait')

function SoldiersAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function SoldiersAppearances:RegisterVars()
    self.m_elementNames = {'water', 'grass', 'fire'}

    self.m_elementColors = {
        water = Vec3(0, 0.6, 1),
        grass = Vec3(0.2, 0.6, 0.1),
        fire = Vec3(1, 0.3, 0)
    }

    self.m_waitingGuids = {
        meshVariationDatabase = {'B056DEA3-8F11-D2FA-20FA-7A5C3F94A15E' ,'B056DEA3-8F11-D2FA-20FA-7A5C3F94A15E'}, -- MeshVariationDatabase
        characterSocketListAsset = {'1F5CC239-BE4F-4D03-B0B5-A0FF89976036', '8F1A9F10-6BF8-442A-909F-AF0D9F8E1608'}, -- CharacterSocketListAsset

        Arms1P_BareGlove03_Afro = {'2871BA93-D577-11E0-A7F0-894741C432F0', '67A32FD0-AEE3-61D0-7041-D6B811C9BFE6'}, -- UnlockAsset

        MP_US_Assault_Appearance01 = {'6252040E-A16A-11E0-AAC3-854900935C42', 'F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4'}, -- UnlockAsset
        US_Helmet09_Desert = {'5B06C0E2-AFDC-455A-BDC4-11B77E1A8AFE', 'B1A0F507-D7F8-4301-8DE6-C6198364FE3B'}, -- UnlockAsset
        US_LB03_Desert = {'6149C356-959B-11E0-86C2-B30910735269', '494B07F4-4C11-1D87-E024-4FE4EB042055'}, -- UnlockAsset
        US_Upperbody04_Desert = {'CDEF869B-959A-11E0-86C2-B30910735269', 'C9F07E77-DA10-1781-CA13-715928514D59'}, -- UnlockAsset

        MP_US_Engi_Appearance01 = {'DD279859-1C83-4E2F-B8F4-36DD17024F2D', '915CE40B-0A8B-4423-A769-FBBE45C0D834'}, -- UnlockAsset
        US_Cap03_Desert = {'5090CBF1-959F-11E0-86C2-B30910735269', 'FA3E6AEB-B8AB-56B2-A54F-D15679697F85'}, -- UnlockAsset
        US_Upperbody06_Desert = {'212716EE-959E-11E0-86C2-B30910735269', '5EC450DD-7D00-8A29-0247-D29436AC1E69'}, -- UnlockAsset
        US_Lowerbody01_Desert = {'0D26F740-959F-11E0-86C2-B30910735269', '0D211E8E-8998-9CE9-5019-830E352121A5'}, -- UnlockAsset

        MP_US_Recon_Appearance01 = {'01D8C694-A16B-11E0-AAC3-854900935C42', '2A0397D6-59DA-3FF8-AD44-393FB92C4B8E'}, -- UnlockAsset
        Shemagh02_Desert = {'77B07832-95AB-11E0-B23E-855EFEEC204F', '4C7386EB-E271-5AA7-C74A-A41313E23C56'}, -- UnlockAsset
        US_Upperbody08_Desert = {'D7076033-959F-11E0-86C2-B30910735269', 'DCF386FD-977A-388A-9B48-D4FEB646B616'}, -- UnlockAsset
        US_Lowerbody02_Desert = {'04CD68B5-95AB-11E0-B23E-855EFEEC204F', '8B1E3C1F-7209-3B09-FC47-E1447C1E6D46'}, -- UnlockAsset
    }

    self.m_meshMaterialIndexes = {
        arms1p_bareglove03 = { 2, 4 },
        us_upperbody04 = { 1, 3 },
        us_lb03 = { 1 },
        us_helmet09 = { 1 }
    }

    self.m_waitingInstances = {
        meshVariationDatabase = nil,
        characterSocketListAsset = nil,
        appearanceUnlockAssets = {},
        linkUnlockAssets = {},
        blueprintAndVariationPairs = {},
        objectVariationAssets = {},
        meshVariationDatabaseEntrys = {}
    }

    self.m_registryContainer = nil -- RegistryContainer
    self.m_skinnedSocketObjects = {} -- SkinnedSocketObject
    self.m_databaseEntryMaterialIndexes = {} -- MeshVariationDatabaseEntry.materials
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseMaterials = {} -- MeshVariationDatabaseMaterial
    self.m_variationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintvariationPairs = {} -- BlueprintAndVariationPair
    self.m_linkUnlockAssets = {} -- UnlockAsset
    self.m_appearanceUnlockAssets = {} -- UnlockAsset

    self.m_verbose = 1 -- prints information
end

function SoldiersAppearances:RegisterEvents()
    InstanceWait(self.m_waitingGuids, function(p_instances)
        self:ReadInstances(p_instances)
    end)

    Events:Subscribe('Level:Destroy', function()
        if self.m_verbose >= 1 then
            print('Event Level:Destroy')
        end

        self:RegisterVars()
    end)
end

function SoldiersAppearances:ReadInstances(p_instances)
    self.m_waitingInstances.meshVariationDatabase = p_instances['meshVariationDatabase']
    self.m_waitingInstances.meshVariationDatabase:MakeWritable()

    self.m_waitingInstances.characterSocketListAsset = p_instances['characterSocketListAsset']

    self.m_waitingInstances.appearanceUnlockAssets['assault'] = p_instances['MP_US_Assault_Appearance01']
    self.m_waitingInstances.appearanceUnlockAssets['engi'] = p_instances['MP_US_Engi_Appearance01']
    -- self.m_waitingInstances.appearanceUnlockAssets['recon'] = p_instances['MP_US_Recon_Appearance01']

    for l_class, l_instance in pairs(self.m_waitingInstances.appearanceUnlockAssets) do
        self.m_skinnedSocketObjects[l_class] = {}
        self.m_databaseEntryMaterialIndexes[l_class] = {}

        self.m_waitingInstances.linkUnlockAssets[l_class] = {}
        self.m_waitingInstances.blueprintAndVariationPairs[l_class] = {}
        self.m_waitingInstances.objectVariationAssets[l_class] = {}
        self.m_waitingInstances.meshVariationDatabaseEntrys[l_class] = {}

        self:ReadLinkUnlockAssets(l_instance, l_class)
        self:ReadBlueprintAndVariationPairs(l_class)
        self:ReadObjectVariationAssets(l_class)
        self:ReadSkinnedSocketObjects(l_class)
        self:ReadMeshVariationDatabaseEntrys(l_class)
        self:ReadMeshVariationDatabaseMaterialIndexes(l_class)
    end

    self:CreateInstances()
end

-- reading link UnlockAssets for BlueprintAndVariationPairs
function SoldiersAppearances:ReadLinkUnlockAssets(p_asset, p_class)
    for _, l_value in pairs(p_asset.linkedTo) do
        if l_value.isLazyLoaded then
            print(l_value.instanceGuid)
        end

        local s_linkUnlockAsset = UnlockAsset(l_value)
        table.insert(self.m_waitingInstances.linkUnlockAssets[p_class], s_linkUnlockAsset)
    end
end

-- reading BlueprintAndVariationPair for ObjectVariation
function SoldiersAppearances:ReadBlueprintAndVariationPairs(p_class)
    for _, l_value in pairs(self.m_waitingInstances.linkUnlockAssets[p_class]) do
        for _, ll_value in pairs(l_value.linkedTo) do
            if ll_value:Is('BlueprintAndVariationPair') then
                local s_blueprintAndVariationPair = BlueprintAndVariationPair(ll_value)
                table.insert(self.m_waitingInstances.blueprintAndVariationPairs[p_class], s_blueprintAndVariationPair)
            end
        end
    end
end

-- reading ObjectVariation for SkinnedSocketObject and MeshVariationDatabaseEntry
function SoldiersAppearances:ReadObjectVariationAssets(p_class)
    for _, l_value in pairs(self.m_waitingInstances.blueprintAndVariationPairs[p_class]) do
        local s_objectVariationAsset = ObjectVariation(l_value.variation)
        table.insert(self.m_waitingInstances.objectVariationAssets[p_class], s_objectVariationAsset)
    end
end

-- reading SkinnedSocketObjects
function SoldiersAppearances:ReadSkinnedSocketObjects(p_class)
    for _, l_value in pairs(self.m_waitingInstances.objectVariationAssets[p_class]) do
        for _, ll_value in pairs(self.m_waitingInstances.characterSocketListAsset.skinnedVisualSockets) do
            local s_socketData = SocketData(ll_value)

            for _, lll_value in pairs(s_socketData.availableObjects) do
                local s_skinnedSocketObject = SkinnedSocketObjectData(lll_value)

                for _, llll_value in pairs(s_skinnedSocketObject.variation1pGuids) do
                    if l_value.instanceGuid == llll_value then
                        self.m_skinnedSocketObjects[p_class][l_value.instanceGuid:ToString('D')] = { is1p = true, object = s_skinnedSocketObject}
                        s_skinnedSocketObject:MakeWritable()
                    end
                end

                for _, llll_value in pairs(s_skinnedSocketObject.variation3pGuids) do
                    if l_value.instanceGuid == llll_value then
                        self.m_skinnedSocketObjects[p_class][l_value.instanceGuid:ToString('D')] = { is1p = false, object = s_skinnedSocketObject}
                        s_skinnedSocketObject:MakeWritable()
                    end
                end
            end
        end
    end
end

-- reading MeshVariationDatabaseEntry
function SoldiersAppearances:ReadMeshVariationDatabaseEntrys(p_class)
    for _, l_value in pairs(self.m_waitingInstances.meshVariationDatabase.entries) do
        local s_meshVariationDatabaseEntry = MeshVariationDatabaseEntry(l_value)
        for _, ll_value in pairs(self.m_waitingInstances.objectVariationAssets[p_class]) do
            if s_meshVariationDatabaseEntry.variationAssetNameHash == ll_value.nameHash then
                self.m_waitingInstances.meshVariationDatabaseEntrys[p_class][s_meshVariationDatabaseEntry.instanceGuid:ToString('D')] = s_meshVariationDatabaseEntry
            end
        end
    end
end

function SoldiersAppearances:ReadMeshVariationDatabaseMaterialIndexes(p_class)
    for _, l_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys[p_class]) do
        local s_skinnedMeshAsset = SkinnedMeshAsset(l_value.mesh)
        local s_skinnedMeshAssetNameParts = self:_Split(s_skinnedMeshAsset.name, '/')
        local s_skinnedMeshName = s_skinnedMeshAssetNameParts[#s_skinnedMeshAssetNameParts]:gsub('_Mesh', '')
        local s_meshMaterialIndexes = self.m_meshMaterialIndexes[s_skinnedMeshName]

        local s_indexes = {}
        -- searching MeshVariationDatabaseMaterial
        if s_meshMaterialIndexes ~= nil then
            for ll_key, ll_value in pairs(l_value.materials) do
                for _, lll_value in pairs(s_meshMaterialIndexes) do
                    if ll_value.material.instanceGuid == s_skinnedMeshAsset.materials[lll_value].instanceGuid then
                        table.insert(s_indexes, ll_key)
                    end
                end
            end
        end

        self.m_databaseEntryMaterialIndexes[p_class][l_value.instanceGuid:ToString('D')] = s_indexes
    end
end

function SoldiersAppearances:CreateInstances()
    self.m_registryContainer = RegistryContainer()

    for l_class, l_value in pairs(self.m_waitingInstances.appearanceUnlockAssets) do
        self.m_meshMaterialVariations[l_class] = {}
        self.m_variationDatabaseEntrys[l_class] = {}

        for _, ll_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys[l_class]) do
            self.m_meshMaterialVariations[l_class][ll_value.instanceGuid:ToString('D')] = {}
            self.m_variationDatabaseEntrys[l_class][ll_value.instanceGuid:ToString('D')] = {}
            for _, l_element in pairs(self.m_elementNames) do
                self.m_meshMaterialVariations[l_class][ll_value.instanceGuid:ToString('D')][l_element] = {}
                self.m_variationDatabaseEntrys[l_class][ll_value.instanceGuid:ToString('D')][l_element] = {}
            end
        end

        self.m_objectVariationAssets[l_class] = {}
        for _, ll_value in pairs(self.m_waitingInstances.objectVariationAssets[l_class]) do
            self.m_objectVariationAssets[l_class][ll_value.instanceGuid:ToString('D')] = {}
            for _, l_element in pairs(self.m_elementNames) do
                self.m_objectVariationAssets[l_class][ll_value.instanceGuid:ToString('D')][l_element] = {}
            end
        end

        self.m_blueprintvariationPairs[l_class] = {}
        for _, ll_value in pairs(self.m_waitingInstances.blueprintAndVariationPairs[l_class]) do
            self.m_blueprintvariationPairs[l_class][ll_value.instanceGuid:ToString('D')] = {}
            for _, l_element in pairs(self.m_elementNames) do
                self.m_blueprintvariationPairs[l_class][ll_value.instanceGuid:ToString('D')][l_element] = {}
            end
        end

        self.m_linkUnlockAssets[l_class] = {}
        for _, ll_value in pairs(self.m_waitingInstances.linkUnlockAssets[l_class]) do
            self.m_linkUnlockAssets[l_class][ll_value.instanceGuid:ToString('D')] = {}
            for _, l_element in pairs(self.m_elementNames) do
                self.m_linkUnlockAssets[l_class][ll_value.instanceGuid:ToString('D')][l_element] = {}
            end
        end

        self.m_appearanceUnlockAssets[l_value.instanceGuid:ToString('D')] = {}
        for _, l_element in pairs(self.m_elementNames) do
            self.m_appearanceUnlockAssets[l_value.instanceGuid:ToString('D')][l_element] = {}
        end
    end

    for l_class, _ in pairs(self.m_waitingInstances.appearanceUnlockAssets) do
        for _, l_element in pairs(self.m_elementNames) do
            -- processing MeshVariationDatabaseEntry
            for _, ll_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys[l_class]) do
                self:CreateMeshMaterialVariations(ll_value, l_class, l_element)
                self:CreateMeshVariationDatabaseEntrys(ll_value, l_class, l_element)
            end

            -- processing ObjectVariationAsset
            for _, ll_value in pairs(self.m_waitingInstances.objectVariationAssets[l_class]) do
                self:CreateObjectVariationAssets(ll_value, l_class, l_element)
            end

            -- processing BlueprintAndVariationPair
            for _, ll_value in pairs(self.m_waitingInstances.blueprintAndVariationPairs[l_class]) do
                self:CreateBlueprintAndVariationPairs(ll_value, l_class, l_element)
            end

            -- processing UnlockAsset
            for _, ll_value in pairs(self.m_waitingInstances.linkUnlockAssets[l_class]) do
                self:CreateLinkUnlockAssets(ll_value, l_class, l_element)
            end

            -- processing UnlockAsset
            for _, ll_value in pairs(self.m_waitingInstances.appearanceUnlockAssets) do
                self:CreateAppearanceUnlockAssets(ll_value, l_class, l_element)
            end
        end
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
        print('Created SkinnedSocketObjects: ' .. self:_Count(self.m_skinnedSocketObjects))
        print('Created DatabaseEntryIndexes: ' .. self:_Count(self.m_databaseEntryMaterialIndexes))
        print('Created MeshMaterialVariations: ' .. self:_Count(self.m_meshMaterialVariations))
        print('Created VariationDatabaseEntrys: ' .. self:_Count(self.m_variationDatabaseEntrys))
        print('Created ObjectVariationAssets: ' .. self:_Count(self.m_objectVariationAssets))
        print('Created BlueprintvariationPairs: ' .. self:_Count(self.m_blueprintvariationPairs))
        print('Created LinkUnlockAssets: ' .. self:_Count(self.m_linkUnlockAssets))
        print('Created AppearanceUnlockAssets: ' .. self:_Count(self.m_appearanceUnlockAssets))
        print('Created RegistryContainerAssets: ' .. self:_Count(self.m_registryContainer.assetRegistry))
        print('Created RegistryContainerEntities: ' .. self:_Count(self.m_registryContainer.entityRegistry))
        print('Created RegistryContainerBlueprints: ' .. self:_Count(self.m_registryContainer.blueprintRegistry))
    end
end

-- creating MeshMaterialVariation for MeshVariationDatabaseMaterial
function SoldiersAppearances:CreateMeshMaterialVariations(p_entry, p_class, p_element)
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_meshVariationDatabaseMaterialIndexes = self.m_databaseEntryMaterialIndexes[p_class][p_entry.instanceGuid:ToString('D')]

    local s_variations = {}

    for l_key, l_value in pairs(p_entry.materials) do
        for _, ll_value in pairs(s_meshVariationDatabaseMaterialIndexes) do
            if l_key == ll_value then
                local s_meshVariationDatabaseMaterial = MeshVariationDatabaseMaterial(l_value)

                local s_newMeshMaterialVariation = MeshMaterialVariation(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. l_key .. p_element))
                p_entry.partition:AddInstance(s_newMeshMaterialVariation)

                local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()

                local s_shaderGraph = ShaderGraph()
                s_shaderGraph.name = 'shaders/Root/CharacterRoot'

                local s_color = self.m_elementColors[p_element]

                local s_dirtColorParameter = VectorShaderParameter()
                s_dirtColorParameter.value = Vec4(s_color.x, s_color.y, s_color.z, 0)
                s_dirtColorParameter.parameterName = '_DirtColor'
                s_dirtColorParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

                local s_dirtScaleParameter = VectorShaderParameter()
                s_dirtScaleParameter.value = Vec4(10, 0, 0, 0)
                s_dirtScaleParameter.parameterName = '_DirtScaleMax'
                s_dirtScaleParameter.parameterType = ShaderParameterType.ShaderParameterType_Scalar

                s_surfaceShaderInstanceDataStruct.shader = s_shaderGraph
                s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_dirtColorParameter)
                s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_dirtScaleParameter)

                s_newMeshMaterialVariation.shader = s_surfaceShaderInstanceDataStruct

                s_variations[l_key] = s_newMeshMaterialVariation
            end
        end
    end

    self.m_meshMaterialVariations[p_class][p_entry.instanceGuid:ToString('D')][p_element] = s_variations
end

-- creating MeshVariationDatabaseEntry for ObjectVariationAsset
function SoldiersAppearances:CreateMeshVariationDatabaseEntrys(p_entry, p_class, p_element)
    if self.m_verbose >= 2 then
        print('Create MeshVariationDatabaseEntrys')
    end

    local s_newMeshVariationDatabaseEntry = self:_CloneInstance(p_entry, p_element)

    for l_key, l_value in pairs(self.m_meshMaterialVariations[p_class][p_entry.instanceGuid:ToString('D')][p_element]) do
        s_newMeshVariationDatabaseEntry.materials[l_key].materialVariation = l_value
    end

    s_newMeshVariationDatabaseEntry.variationAssetNameHash = MathUtils:FNVHash(p_entry.variationAssetNameHash .. p_element)

    self.m_waitingInstances.meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry)

    self.m_variationDatabaseEntrys[p_class][p_entry.instanceGuid:ToString('D')][p_element] = s_newMeshVariationDatabaseEntry
end

-- creating ObjectVariationAsset for BlueprintAndVariationPair
function SoldiersAppearances:CreateObjectVariationAssets(p_asset, p_class, p_element)
    if self.m_verbose >= 2 then
        print('Create ObjectVariationAssets')
    end

    local s_newObjectVariationAsset = self:_CloneInstance(p_asset, p_element)

    -- patching object properties
    s_newObjectVariationAsset.name = p_asset.nameHash .. p_element
    s_newObjectVariationAsset.nameHash = MathUtils:FNVHash(p_asset.nameHash .. p_element)

    local skinnedSocketObject = self.m_skinnedSocketObjects[p_class][p_asset.instanceGuid:ToString('D')]

    -- adding object guid
    if skinnedSocketObject.is1p then
        skinnedSocketObject.object.variation1pGuids:add(s_newObjectVariationAsset.instanceGuid)
    else
        skinnedSocketObject.object.variation3pGuids:add(s_newObjectVariationAsset.instanceGuid)
    end

    self.m_registryContainer.assetRegistry:add(s_newObjectVariationAsset)

    self.m_objectVariationAssets[p_class][p_asset.instanceGuid:ToString('D')][p_element] = s_newObjectVariationAsset
end

-- creating BlueprintAndVariationPair for Link UnlockAsset
function SoldiersAppearances:CreateBlueprintAndVariationPairs(p_data, p_class, p_element)
    if self.m_verbose >= 2 then
        print('Create BlueprintAndVariationPairs')
    end

    local s_newBlueprintAndVariationPair = self:_CloneInstance(p_data, p_element)

    -- patching pair properties
    s_newBlueprintAndVariationPair.variation = self.m_objectVariationAssets[p_class][s_newBlueprintAndVariationPair.variation.instanceGuid:ToString('D')][p_element]

    self.m_registryContainer.assetRegistry:add(s_newBlueprintAndVariationPair)

    self.m_blueprintvariationPairs[p_class][p_data.instanceGuid:ToString('D')][p_element] = s_newBlueprintAndVariationPair
end

-- creating link UnlockAsset for appearance UnlockAsset
function SoldiersAppearances:CreateLinkUnlockAssets(p_asset, p_class, p_element)
    if self.m_verbose >= 2 then
        print('Create LinkUnlockAssets')
    end

    local s_newLinkUnlockAsset = self:_CloneInstance(p_asset, p_element)

    for l_key, l_value in pairs(s_newLinkUnlockAsset.linkedTo) do
        if l_value:Is('BlueprintAndVariationPair') then
            local s_newBlueprintVariationPair = self.m_blueprintvariationPairs[p_class][l_value.instanceGuid:ToString('D')][p_element]

            s_newLinkUnlockAsset.linkedTo[l_key] = s_newBlueprintVariationPair
        end
    end

    self.m_registryContainer.assetRegistry:add(s_newLinkUnlockAsset)

    self.m_linkUnlockAssets[p_class][p_asset.instanceGuid:ToString('D')][p_element] = s_newLinkUnlockAsset
end

-- creating appearance UnlockAsset
function SoldiersAppearances:CreateAppearanceUnlockAssets(p_asset, p_class, p_element)
    if self.m_verbose >= 2 then
        print('Create AppearanceUnlockAssets')
    end

    local s_newAppearanceUnlockAsset = self:_CloneInstance(p_asset, p_element)

    for l_key, l_value in pairs(s_newAppearanceUnlockAsset.linkedTo) do
        if self.m_linkUnlockAssets[p_class][l_value.instanceGuid:ToString('D')] ~= nil then
            s_newAppearanceUnlockAsset.linkedTo[l_key] = self.m_linkUnlockAssets[p_class][l_value.instanceGuid:ToString('D')][p_element]
        end
    end

    self.m_registryContainer.assetRegistry:add(s_newAppearanceUnlockAsset)

    self.m_appearanceUnlockAssets[p_asset.instanceGuid:ToString('D')][p_element] = s_newAppearanceUnlockAsset
end

function SoldiersAppearances:ReplacePlayerAppearance(p_player, p_element)
    local s_assaultAppearanceUnlockAssetGuid = self.m_waitingInstances.appearanceUnlockAssets['assault'].instanceGuid:ToString('D')
    -- local s_engiAppearanceUnlockAssetGuid = self.m_waitingInstances.appearanceUnlockAssets['engi'].instanceGuid:ToString('D')

    local s_appearanceUnlockAsset = nil

    local s_appearanceUnlockAsset = self.m_appearanceUnlockAssets[s_assaultAppearanceUnlockAssetGuid][p_element]
    -- s_appearanceUnlockAsset = self.m_appearanceUnlockAssets[s_engiAppearanceUnlockAssetGuid][p_element]

	p_player:SelectUnlockAssets(p_player.customization, { s_appearanceUnlockAsset })
end

-- cloning the instance and adding to partition
function SoldiersAppearances:_CloneInstance(p_instance, p_variation)
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

-- splitting string
function SoldiersAppearances:_Split(p_string, p_separator)
    local s_parts = {}

    for str in string.gmatch(p_string, "([^" .. p_separator .. "]+)") do
        table.insert(s_parts, str)
    end

    return s_parts
end

return SoldiersAppearances