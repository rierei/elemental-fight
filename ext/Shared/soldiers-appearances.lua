local SoldiersAppearances = class('SoldiersAppearances')

local Uuid = require('__shared/utils/uuid')
local InstanceWait = require('__shared/utils/wait')

function SoldiersAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function SoldiersAppearances:RegisterVars()
    self.m_elementNames = {'water', 'grass', 'fire'}
    self.m_classNames = {'assault', 'engi', 'recon', 'support'}

    self.m_elementColors = {
        water = Vec3(0, 0.6, 1),
        grass = Vec3(0.2, 0.6, 0.1),
        fire = Vec3(1, 0.3, 0)
    }

    self.m_appearanceGuids = {
        USAssault = 'F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4',
        USEngineer = 'F2ADB1BC-466F-4B51-90D1-E8F8670C7BE7',
        USSupport = '4BE86DA1-0229-448D-A5E2-934E5490E11C',
        USRecon = '23CFF61F-F1E2-4306-AECE-2819E35484D2'
    }

    self.m_waitingGuids = {
        CharacterSocketListAsset = {'1F5CC239-BE4F-4D03-B0B5-A0FF89976036', '8F1A9F10-6BF8-442A-909F-AF0D9F8E1608'},
        MP_US_Assault_Appearance01 = {'6252040E-A16A-11E0-AAC3-854900935C42', 'F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4'},
        MP_US_Engi_Appearance_Wood01 = {'FA825024-20C0-4207-9037-CE25CC5FBA38', 'F2ADB1BC-466F-4B51-90D1-E8F8670C7BE7'},
        MP_US_Recon_Appearance_Wood01 = {'E3BE172B-C32F-4ECF-A85C-E9F9796610FF', '4BE86DA1-0229-448D-A5E2-934E5490E11C'},
        MP_US_Support_Appearance_Wood01 = {'9D8C49AB-0E01-4FA6-9127-5FCCDB110B2C', '23CFF61F-F1E2-4306-AECE-2819E35484D2'},

        _US_Helmet09_Desert02 = {'5A980D3E-19B7-4E1F-95D8-8F6E8D0D5139', 'C9FA0036-B75C-4D70-8CBB-736627C93D77'},
        _US_Upperbody04_Desert = {'CDEF869B-959A-11E0-86C2-B30910735269', 'C9F07E77-DA10-1781-CA13-715928514D59'},
        _RU_LB03_Desert = {'59966EFA-3C5D-4115-ADB9-7013A94D4F85', 'AAD994DE-5C6D-49A9-9844-788CDCECEBED'},

        _US_Cap03_Wood01 = {'6F4D0143-B7B9-4BAA-8E0D-3A87F53E9E9E', 'FE865E0C-778F-414A-9C7B-851A8040FCE0'},
        _US_Upperbody06_Wood01 = {'266E865B-7CA2-47A3-9E17-421C3766B664', 'BA5D71CE-D53B-44CC-81F4-2B16F850E24A'},
        _US_Lowerbody01_Wood01 = {'5CB7C07C-7366-4C3D-9F24-3599F0AA8568', '07C001B1-741A-4428-8618-D89EAB25794B'},

        _Shemagh02_Para = {'69A0369F-35A9-4781-ADD2-B088E8BA98DE', '08D775AC-F36D-494A-A19E-02347A1FE03F'},
        _US_Upperbody08_Wood01 = {'D10B9D0C-CE69-4100-A9AC-3602201FCCF2', 'D2A44FF7-D279-4FEA-8B18-52E820EEBCCD'},
        _US_Lowerbody02_Wood01 = {'A2EC519D-2412-4D84-9B64-EAE5B40E03EB', '24447F29-6EB8-4C30-88B2-B151B9F3F664'},

        _US_Helmet07_Wood01 = {'05FD662F-79FC-4A7F-9575-807194D55CBB', 'D522146F-9506-4E4D-845A-B386025B1D90'},
        _US_Upperbody07_Wood01 = {'7EAF31A7-3E60-4F59-8166-3446750B14C8', 'D135952A-C832-42C0-8164-840453146926'},
        _US_Lowerbody04_Wood01 = {'A31F3463-71B0-4B52-B471-37D62D81C2C2', '77C332BB-93D4-435B-A3B8-706EE73CCA31'},

        _Arms1P_BareGlove03_Afro = {'2871BA93-D577-11E0-A7F0-894741C432F0', '67A32FD0-AEE3-61D0-7041-D6B811C9BFE6'},
        _Arms1P_BareGlove03_Wood01 = {'EDEAC49D-D498-11E0-B43C-843E507B97C8', 'A0B1B8BF-7A51-003D-C299-9D06B4394C12'},

        _RU_Helmet05_Navy = {'706BF6C9-0EAD-4382-A986-39D571DBFA77', '53828D27-7C4A-415A-892D-8D410136E1B6'}
    }

    self.m_meshMaterialIndexes = {
        assault = {
            us_helmet09 = { 1 },
            us_upperbody04 = { 1 },
            us_lb03 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 }
        },
        engi = {
            us_cap03 = { 1 },
            us_upperbody06 = { 1 },
            us_lowerbody01 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 }
        },
        recon = {
            shemagh02 = { 3 },
            us_upperbody08 = { 1 },
            us_lowerbody02 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 }
        },
        support = {
            us_helmet07 = { 1 },
            us_upperbody07 = { 1 },
            us_lowerbody04 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 }
        }
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

    self.m_isInstancesLoaded = false

    self.m_registryContainer = nil -- RegistryContainer
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedSocketObjects = {} -- SkinnedSocketObject
    self.m_databaseEntryMaterialIndexes = {} -- MeshVariationDatabaseEntry.materials
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintVariationPairs = {} -- BlueprintAndVariationPair
    self.m_linkUnlockAssets = {} -- UnlockAsset
    self.m_appearanceUnlockAssets = {} -- UnlockAsset

    self.m_verbose = 1 -- prints debug information
end

function SoldiersAppearances:RegisterEvents()
    self:RegisterWait()

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

    -- reloading instances
    Events:Subscribe('Level:LoadResources', function(p_level, p_mode, p_dedicated)
        if self.m_isInstancesLoaded then
            self:ReloadInstances()
        end
    end)
end

function SoldiersAppearances:RegisterWait()
    -- waiting instances
    InstanceWait(self.m_waitingGuids, function(p_instances)
        if not self.m_isInstancesLoaded then
            self:ReadInstances(p_instances)
        end
    end)
end

-- reseting created instances
function SoldiersAppearances:ReloadInstances()
    if self.m_verbose >= 1 then
        print('Reloading Instances')
    end

    self.m_appearanceUnlockAssets = {} -- UnlockAsset
    self.m_isInstancesLoaded = false

    self:RegisterWait()
end

-- reading waiting instances
function SoldiersAppearances:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    self.m_isInstancesLoaded = true

    self.m_meshVariationDatabase = MeshVariationDatabase(self.m_waitingInstances.meshVariationDatabase)
    self.m_meshVariationDatabase:MakeWritable()

    self.m_waitingInstances.characterSocketListAsset = p_instances['CharacterSocketListAsset']

    self.m_waitingInstances.appearanceUnlockAssets['assault'] = p_instances['MP_US_Assault_Appearance01']
    self.m_waitingInstances.appearanceUnlockAssets['engi'] = p_instances['MP_US_Engi_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['recon'] = p_instances['MP_US_Recon_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['support'] = p_instances['MP_US_Support_Appearance_Wood01']

    for _, l_class in pairs(self.m_classNames) do
        self.m_waitingInstances.linkUnlockAssets[l_class] = {}
        self.m_waitingInstances.blueprintAndVariationPairs[l_class] = {}
        self.m_waitingInstances.objectVariationAssets[l_class] = {}
        self.m_waitingInstances.meshVariationDatabaseEntrys[l_class] = {}

        self:ReadLinkUnlockAssets(l_class)
        self:ReadBlueprintAndVariationPairs(l_class)
        self:ReadObjectVariationAssets(l_class)
        self:ReadSkinnedSocketObjects(l_class)
        self:ReadMeshVariationDatabaseEntrys(l_class)
        self:ReadMeshVariationDatabaseMaterialIndexes(l_class)
    end

    self:CreateInstances()

    -- removing hanging references
    self.m_waitingInstances = {
        meshVariationDatabase = nil,
        characterSocketListAsset = nil,
        appearanceUnlockAssets = {},
        linkUnlockAssets = {},
        blueprintAndVariationPairs = {},
        objectVariationAssets = {},
        meshVariationDatabaseEntrys = {}
    }

    -- removing hanging references
    self.m_registryContainer = nil -- RegistryContainer
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedSocketObjects = {} -- SkinnedSocketObject
    self.m_databaseEntryMaterialIndexes = {} -- MeshVariationDatabaseEntry.materials
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintVariationPairs = {} -- BlueprintAndVariationPair
    self.m_linkUnlockAssets = {} -- UnlockAsset
end

-- reading link UnlockAssets for BlueprintAndVariationPairs
function SoldiersAppearances:ReadLinkUnlockAssets(p_class)
    for _, l_value in pairs(self.m_waitingInstances.appearanceUnlockAssets[p_class].linkedTo) do
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

-- reading MeshVariationDatabaseEntry for MeshVariationDatabaseMaterial
function SoldiersAppearances:ReadMeshVariationDatabaseEntrys(p_class)
    for _, l_value in pairs(self.m_meshVariationDatabase.entries) do
        local s_meshVariationDatabaseEntry = MeshVariationDatabaseEntry(l_value)
        for _, ll_value in pairs(self.m_waitingInstances.objectVariationAssets[p_class]) do
            if s_meshVariationDatabaseEntry.variationAssetNameHash == ll_value.nameHash then
                self.m_waitingInstances.meshVariationDatabaseEntrys[p_class][s_meshVariationDatabaseEntry.instanceGuid:ToString('D')] = s_meshVariationDatabaseEntry
            end
        end
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
                        self.m_skinnedSocketObjects[l_value.instanceGuid:ToString('D')] = { is1p = true, object = s_skinnedSocketObject}
                        s_skinnedSocketObject:MakeWritable()
                    end
                end

                for _, llll_value in pairs(s_skinnedSocketObject.variation3pGuids) do
                    if l_value.instanceGuid == llll_value then
                        self.m_skinnedSocketObjects[l_value.instanceGuid:ToString('D')] = { is1p = false, object = s_skinnedSocketObject}
                        s_skinnedSocketObject:MakeWritable()
                    end
                end
            end
        end
    end
end

-- reading MeshVariationDatabaseMaterial
function SoldiersAppearances:ReadMeshVariationDatabaseMaterialIndexes(p_class)
    for _, l_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys[p_class]) do
        local s_indexes = {}
        if self.m_meshMaterialIndexes[p_class] ~= nil then
            local s_skinnedMeshAsset = SkinnedMeshAsset(l_value.mesh)
            local s_skinnedMeshAssetNameParts = self:_Split(s_skinnedMeshAsset.name, '/')
            local s_skinnedMeshName = s_skinnedMeshAssetNameParts[#s_skinnedMeshAssetNameParts]:gsub('_Mesh', '')
            local s_meshMaterialIndexes = self.m_meshMaterialIndexes[p_class][s_skinnedMeshName]

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
        end

        self.m_databaseEntryMaterialIndexes[l_value.instanceGuid:ToString('D')] = s_indexes
    end
end

function SoldiersAppearances:CreateInstances()
    if self.m_verbose >= 1 then
        print('Creating Instances')
    end

    self.m_registryContainer = RegistryContainer()

    for _, l_class in pairs(self.m_classNames) do
        -- processing MeshVariationDatabaseEntry
        for _, ll_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys[l_class]) do
            self:CreateMeshMaterialVariations(ll_value)
            self:CreateMeshVariationDatabaseEntrys(ll_value)
        end

        -- processing ObjectVariationAsset
        for _, ll_value in pairs(self.m_waitingInstances.objectVariationAssets[l_class]) do
            self:CreateObjectVariationAssets(ll_value)
        end

        -- processing BlueprintAndVariationPair
        for _, ll_value in pairs(self.m_waitingInstances.blueprintAndVariationPairs[l_class]) do
            self:CreateBlueprintAndVariationPairs(ll_value)
        end

        -- processing UnlockAsset
        for _, ll_value in pairs(self.m_waitingInstances.linkUnlockAssets[l_class]) do
            self:CreateLinkUnlockAssets(ll_value)
        end

        -- processing UnlockAsset
        self:CreateAppearanceUnlockAssets(self.m_waitingInstances.appearanceUnlockAssets[l_class])
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
        print('Created SkinnedSocketObjects: ' .. self:_Count(self.m_skinnedSocketObjects))
        print('Created DatabaseEntryMaterialIndexes: ' .. self:_Count(self.m_databaseEntryMaterialIndexes))
        print('Created MeshMaterialVariations: ' .. self:_Count(self.m_meshMaterialVariations))
        print('Created VariationDatabaseEntrys: ' .. self:_Count(self.m_meshVariationDatabaseEntrys))
        print('Created ObjectVariationAssets: ' .. self:_Count(self.m_objectVariationAssets))
        print('Created BlueprintVariationPairs: ' .. self:_Count(self.m_blueprintVariationPairs))
        print('Created LinkUnlockAssets: ' .. self:_Count(self.m_linkUnlockAssets))
        print('Created AppearanceUnlockAssets: ' .. self:_Count(self.m_appearanceUnlockAssets))
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

    local s_elements = {}
    -- s_elements['neutral'] = p_entry.materials -- hanging instance

    local s_meshVariationDatabaseMaterialIndexes = self.m_databaseEntryMaterialIndexes[p_entry.instanceGuid:ToString('D')]
    for _, l_element in pairs(self.m_elementNames) do
        local s_variations = {}
        for _, ll_value in pairs(s_meshVariationDatabaseMaterialIndexes) do
            local s_newMeshMaterialVariation = MeshMaterialVariation(self:_GenerateGuid(p_entry.instanceGuid:ToString('D') .. ll_value .. l_element))
            p_entry.partition:AddInstance(s_newMeshMaterialVariation)

            local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()

            local s_shaderGraph = ShaderGraph()
            s_shaderGraph.name = 'shaders/Root/CharacterRoot'

            local s_color = self.m_elementColors[l_element]

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

            s_variations[ll_value] = s_newMeshMaterialVariation
        end

        s_elements[l_element] = s_variations
    end

    self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshVariationDatabaseEntry for ObjectVariationAsset
function SoldiersAppearances:CreateMeshVariationDatabaseEntrys(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshVariationDatabaseEntrys')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_entry -- hanging instance

    for _, l_element in pairs(self.m_elementNames) do
        local s_newMeshVariationDatabaseEntry = self:_CloneInstance(p_entry, l_element)

        for l_key, l_value in pairs(self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')][l_element]) do
            s_newMeshVariationDatabaseEntry.materials[l_key].materialVariation = l_value
        end

        s_newMeshVariationDatabaseEntry.variationAssetNameHash = MathUtils:FNVHash(p_entry.variationAssetNameHash .. l_element)

        self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry)

        s_elements[l_element] = s_newMeshVariationDatabaseEntry
    end

    self.m_meshVariationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating ObjectVariationAsset for BlueprintAndVariationPair
function SoldiersAppearances:CreateObjectVariationAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create ObjectVariationAssets')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_asset -- hanging instance

    for _, l_element in pairs(self.m_elementNames) do
        local s_newObjectVariationAsset = self:_CloneInstance(p_asset, l_element)

        -- patching object variation properties
        s_newObjectVariationAsset.name = p_asset.nameHash .. l_element
        s_newObjectVariationAsset.nameHash = MathUtils:FNVHash(p_asset.nameHash .. l_element)

        local skinnedSocketObject = self.m_skinnedSocketObjects[p_asset.instanceGuid:ToString('D')]

        -- adding object variation guid
        if skinnedSocketObject.is1p then
            skinnedSocketObject.object.variation1pGuids:add(s_newObjectVariationAsset.instanceGuid)
        else
            skinnedSocketObject.object.variation3pGuids:add(s_newObjectVariationAsset.instanceGuid)
        end

        self.m_registryContainer.assetRegistry:add(s_newObjectVariationAsset)

        s_elements[l_element] = s_newObjectVariationAsset
    end

    self.m_objectVariationAssets[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating BlueprintAndVariationPair for Link UnlockAsset
function SoldiersAppearances:CreateBlueprintAndVariationPairs(p_data)
    if self.m_verbose >= 2 then
        print('Create BlueprintAndVariationPairs')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_data -- hanging instance

    for _, l_element in pairs(self.m_elementNames) do
        local s_newBlueprintAndVariationPair = self:_CloneInstance(p_data, l_element)

        -- patching pair properties
        s_newBlueprintAndVariationPair.name = s_newBlueprintAndVariationPair.name .. l_element
        s_newBlueprintAndVariationPair.variation = self.m_objectVariationAssets[s_newBlueprintAndVariationPair.variation.instanceGuid:ToString('D')][l_element]

        self.m_registryContainer.assetRegistry:add(s_newBlueprintAndVariationPair)

        s_elements[l_element] = s_newBlueprintAndVariationPair
    end

    self.m_blueprintVariationPairs[p_data.instanceGuid:ToString('D')] = s_elements
end

-- creating link UnlockAsset for appearance UnlockAsset
function SoldiersAppearances:CreateLinkUnlockAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create LinkUnlockAssets')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_asset -- hanging instance

    for _, l_element in pairs(self.m_elementNames) do
        local s_newLinkUnlockAsset = self:_CloneInstance(p_asset, l_element)
        s_newLinkUnlockAsset.name = s_newLinkUnlockAsset.name .. l_element

        for l_key, l_value in pairs(s_newLinkUnlockAsset.linkedTo) do
            if l_value:Is('BlueprintAndVariationPair') then
                local s_blueprintVariationPair = self.m_blueprintVariationPairs[l_value.instanceGuid:ToString('D')][l_element]

                s_newLinkUnlockAsset.linkedTo[l_key] = s_blueprintVariationPair
            end
        end

        self.m_registryContainer.assetRegistry:add(s_newLinkUnlockAsset)

        s_elements[l_element] = s_newLinkUnlockAsset
    end

    self.m_linkUnlockAssets[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating appearance UnlockAsset
function SoldiersAppearances:CreateAppearanceUnlockAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create AppearanceUnlockAssets')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_asset -- hanging instance

    for _, l_element in pairs(self.m_elementNames) do
        local s_newAppearanceUnlockAsset = self:_CloneInstance(p_asset, l_element)
        s_newAppearanceUnlockAsset.name = s_newAppearanceUnlockAsset.name .. l_element
        s_newAppearanceUnlockAsset.debugUnlockId = l_element

        for l_key, l_value in pairs(s_newAppearanceUnlockAsset.linkedTo) do
            if self.m_linkUnlockAssets[l_value.instanceGuid:ToString('D')] ~= nil then
                s_newAppearanceUnlockAsset.linkedTo[l_key] = self.m_linkUnlockAssets[l_value.instanceGuid:ToString('D')][l_element]
            end
        end

        self.m_registryContainer.assetRegistry:add(s_newAppearanceUnlockAsset)

        s_elements[l_element] = s_newAppearanceUnlockAsset
    end

    self.m_appearanceUnlockAssets[p_asset.instanceGuid:ToString('D')] = s_elements
end

function SoldiersAppearances:ReplacePlayerAppearance(p_player, p_element)
    if p_element == 'neutral' then
        return
    end

    local s_kitNameParts = self:_Split(p_player.customization.name, '/')
    local s_kitName = s_kitNameParts[#s_kitNameParts]
    local s_appearanceGuid = self.m_appearanceGuids[s_kitName]

    local s_appearanceUnlockAsset = self.m_appearanceUnlockAssets[s_appearanceGuid][p_element]
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

    for l_part in string.gmatch(p_string, "([^" .. p_separator .. "]+)") do
        table.insert(s_parts, l_part)
    end

    return s_parts
end

return SoldiersAppearances