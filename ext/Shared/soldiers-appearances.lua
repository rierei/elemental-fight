local SoldiersAppearances = class('SoldiersAppearances')

local Uuid = require('__shared/utils/uuid')
local InstanceWait = require('__shared/utils/wait')

function SoldiersAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function SoldiersAppearances:RegisterVars()
    self.m_elementNames = {'water', 'grass', 'fire'}
    self.m_classNames = {'assault', 'engi'}

    self.m_elementColors = {
        water = Vec3(0, 0.6, 1),
        grass = Vec3(0.2, 0.6, 0.1),
        fire = Vec3(1, 0.3, 0)
    }

    self.m_waitingGuids = {
        -- meshVariationDatabase = {'B056DEA3-8F11-D2FA-20FA-7A5C3F94A15E' ,'B056DEA3-8F11-D2FA-20FA-7A5C3F94A15E'}, -- MeshVariationDatabase
        characterSocketListAsset = {'1F5CC239-BE4F-4D03-B0B5-A0FF89976036', '8F1A9F10-6BF8-442A-909F-AF0D9F8E1608'}, -- CharacterSocketListAsset

        MP_US_Assault_Appearance01 = {'6252040E-A16A-11E0-AAC3-854900935C42', 'F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4'}, -- UnlockAsset
        MP_US_Assault_Helmet01 = {'45B47A2D-9F0E-4A20-B37F-FF9066A3C8E4', 'CB7204EC-D4FA-4722-A540-9D4643D0BDBF'}, -- link UnlockAsset
        MP_US_Assault_Head01 = {'9B54E4CA-6207-4DA4-9E4D-A09F11893844', 'B5C8DFEC-7503-4771-8BCB-5F75DE529D89'}, -- link UnlockAsset
        MP_US_Assault_UpperBody01 = {'CBEBACDB-6158-416D-8D1C-665539F65CDD', '9E49E623-0F88-4D50-88ED-AE9EA0139156'}, -- link UnlockAsset
        MP_US_Assault_LowerBody01 = {'C4FBCFC7-416F-42D2-99B3-2DCF1840FCFD', '98187809-F0CD-4F9B-8D9C-23729FC366C7'}, -- link UnlockAsset

        MP_US_Engi_Appearance_Wood01 = {'FA825024-20C0-4207-9037-CE25CC5FBA38', 'F2ADB1BC-466F-4B51-90D1-E8F8670C7BE7'}, -- UnlockAsset
        MP_US_Engi_Cap01_Wood01 = {'99212B4D-6FE0-404A-81EF-595C25AC7A31', '15F330AE-322A-41A1-892F-4D2902B8E2F9'}, -- link UnlockAsset
        MP_US_Engi_Head01 = {'CCC88822-E9E8-42FE-8FAB-ED92E797DD18', 'A2B386A1-710F-4B0A-B2DE-B059A8E20D12'}, -- link UnlockAsset
        MP_US_Engi_UpperBody01_Wood01 = {'756B6776-B14E-463D-BC2C-DC3A5AA6C16F', 'B4A1F1F1-A4DF-492B-8C1A-3C98836A7E99'}, -- link UnlockAsset
        MP_US_Engi_LowerBody01_Wood01 = {'67BDFCC5-79BA-4125-99D5-6FE943BC947C', 'B19E00A9-F888-444E-805C-59737AD3FE96'}, -- link UnlockAsset

        US_Helmet09_Desert = {'5B06C0E2-AFDC-455A-BDC4-11B77E1A8AFE', 'B1A0F507-D7F8-4301-8DE6-C6198364FE3B'}, -- variation UnlockAsset
        US_Upperbody04_Desert = {'CDEF869B-959A-11E0-86C2-B30910735269', 'C9F07E77-DA10-1781-CA13-715928514D59'}, -- variation UnlockAsset
        Arms1P_BareGlove03_Afro = {'2871BA93-D577-11E0-A7F0-894741C432F0', '67A32FD0-AEE3-61D0-7041-D6B811C9BFE6'}, -- variation UnlockAsset
        US_LB03_Desert = {'6149C356-959B-11E0-86C2-B30910735269', '494B07F4-4C11-1D87-E024-4FE4EB042055'}, -- variation UnlockAsset

        US_Cap03_Wood01 = {'6F4D0143-B7B9-4BAA-8E0D-3A87F53E9E9E', 'FE865E0C-778F-414A-9C7B-851A8040FCE0'}, -- variation UnlockAsset
        US_Upperbody06_Wood01 = {'266E865B-7CA2-47A3-9E17-421C3766B664', 'BA5D71CE-D53B-44CC-81F4-2B16F850E24A'}, -- variation UnlockAsset
        Arms1P_BareGlove03_Wood01 = {'EDEAC49D-D498-11E0-B43C-843E507B97C8', 'A0B1B8BF-7A51-003D-C299-9D06B4394C12'}, -- variation UnlockAsset
        US_Lowerbody01_Wood01 = {'5CB7C07C-7366-4C3D-9F24-3599F0AA8568', '07C001B1-741A-4428-8618-D89EAB25794B'}, -- variation UnlockAsset

        -- MP_US_Engi_Appearance01 = {'DD279859-1C83-4E2F-B8F4-36DD17024F2D', '915CE40B-0A8B-4423-A769-FBBE45C0D834'}, -- variation UnlockAsset
        -- US_Cap03_Desert = {'5090CBF1-959F-11E0-86C2-B30910735269', 'FA3E6AEB-B8AB-56B2-A54F-D15679697F85'}, -- variation UnlockAsset
        -- US_Upperbody06_Desert = {'212716EE-959E-11E0-86C2-B30910735269', '5EC450DD-7D00-8A29-0247-D29436AC1E69'}, -- variation UnlockAsset
        -- US_Lowerbody01_Desert = {'0D26F740-959F-11E0-86C2-B30910735269', '0D211E8E-8998-9CE9-5019-830E352121A5'}, -- variation UnlockAsset

        -- MP_US_Recon_Appearance01 = {'01D8C694-A16B-11E0-AAC3-854900935C42', '2A0397D6-59DA-3FF8-AD44-393FB92C4B8E'}, -- variation UnlockAsset
        -- Shemagh02_Desert = {'77B07832-95AB-11E0-B23E-855EFEEC204F', '4C7386EB-E271-5AA7-C74A-A41313E23C56'}, -- variation UnlockAsset
        -- US_Upperbody08_Desert = {'D7076033-959F-11E0-86C2-B30910735269', 'DCF386FD-977A-388A-9B48-D4FEB646B616'}, -- variation UnlockAsset
        -- US_Lowerbody02_Desert = {'04CD68B5-95AB-11E0-B23E-855EFEEC204F', '8B1E3C1F-7209-3B09-FC47-E1447C1E6D46'}, -- variation UnlockAsset
    }

    self.m_meshMaterialIndexes = {
        assault = {
            us_helmet09 = { 1 },
            us_upperbody04 = { 1, 3 },
            arms1p_bareglove03 = { 1, 2, 4 },
            us_lb03 = { 1 }
        },
        engi = {
            us_cap03 = { 1 },
            us_upperbody06 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 },
            us_lowerbody01 = { 1 }
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

    self.m_loaded = false

    self.m_registryContainer = nil -- RegistryContainer
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedSocketObjects = {} -- SkinnedSocketObject
    self.m_databaseEntryMaterialIndexes = {} -- MeshVariationDatabaseEntry.materials
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseMaterials = {} -- MeshVariationDatabaseMaterial
    self.m_variationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintVariationPairs = {} -- BlueprintAndVariationPair
    self.m_linkUnlockAssets = {} -- UnlockAsset
    self.m_appearanceUnlockAssets = {} -- UnlockAsset

    self.m_verbose = 1 -- prints information
end

function SoldiersAppearances:Reset()
    print('RESET')

    self.m_registryContainer = nil -- RegistryContainer
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedSocketObjects = {} -- SkinnedSocketObject
    self.m_databaseEntryMaterialIndexes = {} -- MeshVariationDatabaseEntry.materials
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseMaterials = {} -- MeshVariationDatabaseMaterial
    self.m_variationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintVariationPairs = {} -- BlueprintAndVariationPair
    self.m_linkUnlockAssets = {} -- UnlockAsset
    self.m_appearanceUnlockAssets = {} -- UnlockAsset

    self.m_loaded = false
end

function SoldiersAppearances:RegisterResources()
    print('RegisterResources')
    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    print(#self.m_meshVariationDatabase.entries)

    for _, l_value in pairs(self.m_variationDatabaseEntrys) do
        for _, ll_element in pairs(self.m_elementNames) do
            self.m_meshVariationDatabase.entries:add(l_value[ll_element])
        end
    end

    print(#self.m_meshVariationDatabase.entries)
end

function SoldiersAppearances:RegisterEvents()
    InstanceWait(self.m_waitingGuids, function(p_instances)
        if not self.m_loaded then
            print('ReadInstances')
            self:ReadInstances(p_instances)
        else
            self.m_meshVariationDatabase = MeshVariationDatabase(self.m_waitingInstances.meshVariationDatabase)
            self.m_meshVariationDatabase:MakeWritable()

            self:RegisterResources()
        end
    end)

    Events:Subscribe('Partition:Loaded', function(p_partition)
        for _, l_instance in pairs(p_partition.instances) do
            if l_instance:Is('MeshVariationDatabase') and Asset(l_instance).name:match('Levels') then
                if self.m_verbose >= 1 then
                    print('Found MeshVariationDatabase')
                end

                self.m_waitingInstances.meshVariationDatabase = l_instance
            end
        end
    end)
end

function SoldiersAppearances:ReadInstances(p_instances)
    self.m_loaded = true

    -- self.m_meshVariationDatabase = p_instances['meshVariationDatabase']
    -- self.m_meshVariationDatabase:MakeWritable()

    self.m_meshVariationDatabase = MeshVariationDatabase(self.m_waitingInstances.meshVariationDatabase)
    self.m_meshVariationDatabase:MakeWritable()

    self.m_waitingInstances.characterSocketListAsset = p_instances['characterSocketListAsset']

    self.m_waitingInstances.appearanceUnlockAssets['assault'] = p_instances['MP_US_Assault_Appearance01']
    self.m_waitingInstances.appearanceUnlockAssets['engi'] = p_instances['MP_US_Engi_Appearance_Wood01']
    -- self.m_waitingInstances.appearanceUnlockAssets['recon'] = p_instances['MP_US_Recon_Appearance01']

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

    self:RegisterResources()

    self.m_waitingInstances = {
        meshVariationDatabase = nil,
        characterSocketListAsset = nil,
        appearanceUnlockAssets = {},
        linkUnlockAssets = {},
        blueprintAndVariationPairs = {},
        objectVariationAssets = {},
        meshVariationDatabaseEntrys = {}
    }

    if self.m_verbose >= 1 then
        print('Created SkinnedSocketObjects: ' .. self:_Count(self.m_skinnedSocketObjects))
        print('Created DatabaseEntryMaterialIndexes: ' .. self:_Count(self.m_databaseEntryMaterialIndexes))
        print('Created MeshMaterialVariations: ' .. self:_Count(self.m_meshMaterialVariations))
        print('Created VariationDatabaseEntrys: ' .. self:_Count(self.m_variationDatabaseEntrys))
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
    s_elements['neutral'] = p_entry.materials

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
    s_elements['neutral'] = p_entry

    for _, l_element in pairs(self.m_elementNames) do
        local s_newMeshVariationDatabaseEntry = self:_CloneInstance(p_entry, l_element)

        for l_key, l_value in pairs(self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')][l_element]) do
            s_newMeshVariationDatabaseEntry.materials[l_key].materialVariation = l_value
        end

        s_newMeshVariationDatabaseEntry.variationAssetNameHash = MathUtils:FNVHash(p_entry.variationAssetNameHash .. l_element)

        s_elements[l_element] = s_newMeshVariationDatabaseEntry
    end

    self.m_variationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating ObjectVariationAsset for BlueprintAndVariationPair
function SoldiersAppearances:CreateObjectVariationAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create ObjectVariationAssets')
    end

    local s_elements = {}
    s_elements['neutral'] = p_asset

    for _, l_element in pairs(self.m_elementNames) do
        local s_newObjectVariationAsset = self:_CloneInstance(p_asset, l_element)

        -- patching object properties
        s_newObjectVariationAsset.name = p_asset.nameHash .. l_element
        s_newObjectVariationAsset.nameHash = MathUtils:FNVHash(p_asset.nameHash .. l_element)

        local skinnedSocketObject = self.m_skinnedSocketObjects[p_asset.instanceGuid:ToString('D')]

        -- adding object guid
        -- if skinnedSocketObject.is1p then
        --     skinnedSocketObject.object.variation1pGuids:add(s_newObjectVariationAsset.instanceGuid)
        -- else
        --     skinnedSocketObject.object.variation3pGuids:add(s_newObjectVariationAsset.instanceGuid)
        -- end

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
    s_elements['neutral'] = p_data

    for _, l_element in pairs(self.m_elementNames) do
        local s_newBlueprintAndVariationPair = self:_CloneInstance(p_data, l_element)
        s_newBlueprintAndVariationPair.name = s_newBlueprintAndVariationPair.name .. l_element

        -- patching pair properties
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
    s_elements['neutral'] = p_asset

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
    -- s_elements['neutral'] = p_asset

    for _, l_element in pairs(self.m_elementNames) do
        local s_newAppearanceUnlockAsset = self:_CloneInstance(p_asset, l_element)
        s_newAppearanceUnlockAsset.name = s_newAppearanceUnlockAsset.name .. l_element

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
    -- local s_assaultAppearanceUnlockAssetGuid = self.m_waitingInstances.appearanceUnlockAssets['assault'].instanceGuid:ToString('D')
    -- local s_engiAppearanceUnlockAssetGuid = self.m_waitingInstances.appearanceUnlockAssets['engi'].instanceGuid:ToString('D')

    local s_appearanceUnlockAsset = nil

    -- s_appearanceUnlockAsset = self.m_appearanceUnlockAssets[s_assaultAppearanceUnlockAssetGuid][p_element]
    s_appearanceUnlockAsset = self.m_appearanceUnlockAssets['F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4'][p_element]

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