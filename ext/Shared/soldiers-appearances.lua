local SoldiersAppearances = class('SoldiersAppearances')

local LoadedInstances = require('__shared/loaded-instances')
local ElementalConfig = require('__shared/elemental-config')
local InstanceUtils = require('__shared/utils/instances')

function SoldiersAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function SoldiersAppearances:RegisterVars()
    self.m_classNames = {
        'USAssault',
        'USEngineer',
        'USRecon',
        'USSupport',

        'RUAssault',
        'RUEngineer',
        'RURecon',
        'RUSupport'
    }

    self.m_appearanceBaseGuids = {
        USAssault = 'B3C3FB3F-0283-4AE2-B0BD-DF9C984364AE',
        USEngineer = 'F2ADB1BC-466F-4B51-90D1-E8F8670C7BE7',
        USRecon = '4BE86DA1-0229-448D-A5E2-934E5490E11C',
        USSupport = '23CFF61F-F1E2-4306-AECE-2819E35484D2',

        RUAssault = '8DBC539E-B7E4-4486-BB58-056A3EEB551F',
        RUEngineer = 'FDC67EE7-3DC8-411D-9E92-AD14DC9B9E09',
        RURecon = '220DDA48-89DA-4AE9-BCDA-54FC578FDB6F',
        RUSupport = '7AAAC9FD-0DB7-4766-B084-159E735942CA'
    }

    self.m_appearanceXp4Guids = {
        USAssault = '0C078E08-F658-48AD-A450-C50120EBD28A',
        USEngineer = 'D7952F77-2F1B-42FD-9C3B-24333E1B91AF',
        USRecon = '673D8B19-8B3E-4AE8-91D8-E8801D3E558B',
        USSupport = '81042258-9909-4DD1-AC33-50364E6CD73F',

        RUAssault = '7A72B71B-2A65-43EB-BA9E-77F0CCE26828',
        RUEngineer = '46F907B9-08C5-46DD-9C8B-4B69401E797E',
        RURecon = 'AEA00E34-8091-494F-8B0A-FCCB5ED45249',
        RUSupport = '72993D80-275F-444C-93DF-EE3384A86F72'
    }

    self.m_currentLevel = nil

    self.m_meshMaterialIndexes = {
        USAssault = {
            us_helmet09 = { 1 },
            us_upperbody04 = { 1 },
            us_lb03 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 },

            us_assault_ub = { 1 },
            us_assault_lb = { 2 }
        },
        USEngineer = {
            us_cap03 = { 1 },
            us_upperbody06 = { 1 },
            us_lowerbody01 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 },

            us_engineer_ub = { 2 },
            us_engineer_lb = { 3 }
        },
        USRecon = {
            shemagh02 = { 3 },
            us_upperbody08 = { 1 },
            us_lowerbody02 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 },

            us_recon = { 1 },
            us_recon_lb = { 1 }
        },
        USSupport = {
            us_helmet07 = { 1 },
            us_upperbody07 = { 1 },
            us_lowerbody04 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 },

            us_support_lb = { 1 },
            us_support_ub = { 1 }
        },

        RUAssault = {
            ru_helmet05 = { 1 },
            us_lb03 = { 1 },
            ru_upperbody01 = { 1 },
            arms1p_rus = { 1, 2, 4 },

            us_assault_lb = { 1 },
            ru_assault = { 1 },
        },
        RUEngineer = {
            gasmask02 = { 1 },
            ru_upperbody04 = { 1 },
            us_lowerbody01 = { 1 },
            arms1p_rus = { 1, 2, 4 },

            ru_engineer_lb = { 1 },
            ru_engineer = { 1 }
        },
        RURecon = {
            ru_beanie02 = { 1 },
            ru_upperbody02 = { 1 },
            us_lowerbody02 = { 1 },
            arms1p_rus = { 1, 2, 4 },

            ru_recon_ub = { 1 },
            us_recon_lb = { 1 },
        },
        RUSupport = {
            ru_helmet04 = { 1 },
            ru_upperbody03 = { 1 },
            us_lowerbody04 = { 1 },
            arms1p_rus = { 1, 2, 4 },

            us_support_lb = { 1 },
            ru_support_ub = { 1 }
        }
    }

    self.m_waitingInstances = {
        meshVariationDatabase = nil, -- MeshVariationDatabase
        characterSocketListAsset = nil, -- CharacterSocketListAsset
        appearanceUnlockAssets = {}, -- UnlockAsset
        linkUnlockAssets = {}, -- UnlockAsset
        blueprintAndVariationPairs = {}, -- BlueprintAndVariationPair
        objectVariationAssets = {}, -- ObjectVariationAsset
        meshVariationDatabaseEntrys = {}, -- MeshVariationDatabaseEntry
        characterShader = nil -- ShaderGraph
    }

    self.m_registryContainer = nil -- RegistryContainer
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase

    self.m_skinnedSocketObjects = {} -- SkinnedSocketObject
    self.m_surfaceShaderStructs = {} -- SurfaceShaderInstanceDataStruct
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
    Events:Subscribe('Level:Destroy', function()
        self.m_appearanceUnlockAssets = {}
    end)

    -- reading instances when MeshVariationDatabase loads
    Events:Subscribe('LoadedInstances:MeshVariationDatabase', function(p_instances)
        self:ReadInstances(p_instances)
    end)
end

-- reading waiting instances
function SoldiersAppearances:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    self.m_waitingInstances.meshVariationDatabase = LoadedInstances.m_loadedInstances.MeshVariationDatabase

    self.m_meshVariationDatabase = self.m_waitingInstances.meshVariationDatabase
    self.m_meshVariationDatabase:MakeWritable()

    self.m_waitingInstances.characterShader = p_instances['CharacterRoot']
    self.m_waitingInstances.characterSocketListAsset = p_instances['CharacterSocketListAsset']

    self.m_waitingInstances.appearanceUnlockAssets['USAssault'] = p_instances['MP_US_Assault_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['USEngineer'] = p_instances['MP_US_Engi_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['USRecon'] = p_instances['MP_US_Recon_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['USSupport'] = p_instances['MP_US_Support_Appearance_Wood01']

    self.m_waitingInstances.appearanceUnlockAssets['RUAssault'] = p_instances['MP_RU_Assault_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['RUEngineer'] = p_instances['MP_RU_Engi_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['RURecon'] = p_instances['MP_RU_Recon_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['RUSupport'] = p_instances['MP_RU_Support_Appearance_Wood01']

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

    if InstanceUtils:Count(self.m_databaseEntryMaterialIndexes) == 0 and SharedUtils:IsClientModule() then
        ResourceManager:DestroyDynamicCompartment(ResourceCompartment.ResourceCompartment_Game)
    else
        self:CreateInstances()
    end

    -- removing hanging references
    self.m_waitingInstances = {
        meshVariationDatabase = nil, -- MeshVariationDatabase
        characterSocketListAsset = nil, -- CharacterSocketListAsset
        appearanceUnlockAssets = {}, -- UnlockAsset
        linkUnlockAssets = {}, -- UnlockAsset
        blueprintAndVariationPairs = {}, -- BlueprintAndVariationPair
        objectVariationAssets = {}, -- ObjectVariationAsset
        meshVariationDatabaseEntrys = {}, -- MeshVariationDatabaseEntry
        characterShader = nil -- ShaderGraph
    }

    -- removing hanging references
    self.m_registryContainer = nil
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase

    self.m_skinnedSocketObjects = {} -- SkinnedSocketObject
    self.m_surfaceShaderStructs = {} -- SurfaceShaderInstanceDataStruct
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
            print('Lazy LinkUnlockAsset ' .. l_value.instanceGuid:ToString('D'))
        else
            local s_linkUnlockAsset = UnlockAsset(l_value)
            table.insert(self.m_waitingInstances.linkUnlockAssets[p_class], s_linkUnlockAsset)
        end

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
        local s_objectVariationAsset = l_value.variation
        table.insert(self.m_waitingInstances.objectVariationAssets[p_class], s_objectVariationAsset)
    end
end

-- reading MeshVariationDatabaseEntry for MeshVariationDatabaseMaterial
function SoldiersAppearances:ReadMeshVariationDatabaseEntrys(p_class)
    for i = 1, LoadedInstances.m_variationDatabaseEntryCount, 1 do
        local l_value = self.m_meshVariationDatabase.entries[i]
        local s_meshVariationDatabaseEntry = l_value
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
            local s_socketData = ll_value

            for _, lll_value in pairs(s_socketData.availableObjects) do
                local s_skinnedSocketObject = SocketObjectData(lll_value)

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
            local s_skinnedMeshAsset = l_value.mesh
            local s_skinnedMeshAssetNameParts = InstanceUtils:Split(s_skinnedMeshAsset.name, '/')
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

    self:CreateSurfaceShaderStructs(self.m_waitingInstances.characterShader)

    for _, l_class in pairs(self.m_classNames) do
        -- processing MeshVariationDatabaseEntry
        for _, ll_value in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys[l_class]) do
            self:CreateMeshMaterialVariations(ll_value)
            self:CreateMeshVariationDatabaseEntrys(ll_value)
            self:UpdateMeshAssets(ll_value)
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
        print('Created SurfaceShaderStructs: ' .. InstanceUtils:Count(self.m_surfaceShaderStructs))
        print('Created SkinnedSocketObjects: ' .. InstanceUtils:Count(self.m_skinnedSocketObjects))
        print('Created DatabaseEntryMaterialIndexes: ' .. InstanceUtils:Count(self.m_databaseEntryMaterialIndexes))
        print('Created MeshMaterialVariations: ' .. InstanceUtils:Count(self.m_meshMaterialVariations))
        print('Created VariationDatabaseEntrys: ' .. InstanceUtils:Count(self.m_meshVariationDatabaseEntrys))
        print('Created ObjectVariationAssets: ' .. InstanceUtils:Count(self.m_objectVariationAssets))
        print('Created BlueprintVariationPairs: ' .. InstanceUtils:Count(self.m_blueprintVariationPairs))
        print('Created LinkUnlockAssets: ' .. InstanceUtils:Count(self.m_linkUnlockAssets))
        print('Created AppearanceUnlockAssets: ' .. InstanceUtils:Count(self.m_appearanceUnlockAssets))
        print('Created RegistryContainerAssets: ' .. InstanceUtils:Count(self.m_registryContainer.assetRegistry))
        print('Created RegistryContainerEntities: ' .. InstanceUtils:Count(self.m_registryContainer.entityRegistry))
        print('Created RegistryContainerBlueprints: ' .. InstanceUtils:Count(self.m_registryContainer.blueprintRegistry))
    end
end

-- creating SurfaceShaderInstanceDataStruct for MeshMaterialVariation
function SoldiersAppearances:CreateSurfaceShaderStructs(p_asset)
    local s_elements = {}

    for _, l_element in pairs(ElementalConfig.names) do
        local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()

        local s_color = ElementalConfig.colors[l_element]

        local s_dirtColorParameter = VectorShaderParameter()
        s_dirtColorParameter.value = Vec4(s_color.x, s_color.y, s_color.z, 0)
        s_dirtColorParameter.parameterName = '_DirtColor'
        s_dirtColorParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        local s_dirtScaleParameter = VectorShaderParameter()
        s_dirtScaleParameter.value = Vec4(10, 0, 0, 0)
        s_dirtScaleParameter.parameterName = '_DirtScaleMax'
        s_dirtScaleParameter.parameterType = ShaderParameterType.ShaderParameterType_Scalar

        s_surfaceShaderInstanceDataStruct.shader = p_asset
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_dirtColorParameter)
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_dirtScaleParameter)

        s_elements[l_element] = s_surfaceShaderInstanceDataStruct
    end

    self.m_surfaceShaderStructs = s_elements
end

-- creating MeshMaterialVariation for MeshVariationDatabaseMaterial
function SoldiersAppearances:CreateMeshMaterialVariations(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    if self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')] ~= nil then
        return
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry.materials

    local s_meshVariationDatabaseMaterialIndexes = self.m_databaseEntryMaterialIndexes[p_entry.instanceGuid:ToString('D')]
    for _, l_element in pairs(ElementalConfig.names) do
        local s_variations = {}
        for _, ll_value in pairs(s_meshVariationDatabaseMaterialIndexes) do
            local s_newMeshMaterialVariation = MeshMaterialVariation(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. ll_value .. l_element))
            p_entry.partition:AddInstance(s_newMeshMaterialVariation)

            s_newMeshMaterialVariation.shader = self.m_surfaceShaderStructs[l_element]

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

    if self.m_meshVariationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] ~= nil then
        return
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshVariationDatabaseEntry = InstanceUtils:CloneInstance(p_entry, l_element)

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

    if self.m_objectVariationAssets[p_asset.instanceGuid:ToString('D')] ~= nil then
        return
    end

    local s_elements = {}
    s_elements['neutral'] = p_asset

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newObjectVariationAsset = InstanceUtils:CloneInstance(p_asset, l_element)

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

    if self.m_blueprintVariationPairs[p_data.instanceGuid:ToString('D')] ~= nil then
        return
    end

    local s_elements = {}
    s_elements['neutral'] = p_data

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newBlueprintAndVariationPair = InstanceUtils:CloneInstance(p_data, l_element)

        -- patching pair properties
        s_newBlueprintAndVariationPair.name = s_newBlueprintAndVariationPair.name .. l_element
        s_newBlueprintAndVariationPair.variation = self.m_objectVariationAssets[s_newBlueprintAndVariationPair.variation.instanceGuid:ToString('D')][l_element]

        s_elements[l_element] = s_newBlueprintAndVariationPair
    end

    self.m_blueprintVariationPairs[p_data.instanceGuid:ToString('D')] = s_elements
end

-- creating link UnlockAsset for appearance UnlockAsset
function SoldiersAppearances:CreateLinkUnlockAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create LinkUnlockAssets')
    end

    if self.m_linkUnlockAssets[p_asset.instanceGuid:ToString('D')] ~= nil then
        return
    end

    local s_elements = {}
    s_elements['neutral'] = p_asset

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newLinkUnlockAsset = InstanceUtils:CloneInstance(p_asset, l_element)
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

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newAppearanceUnlockAsset = InstanceUtils:CloneInstance(p_asset, l_element)
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

-- replacing mesh lod
function SoldiersAppearances:UpdateMeshAssets(p_entry)
    local s_meshAsset = SkinnedMeshAsset(p_entry.mesh)

    s_meshAsset:MakeWritable()
    s_meshAsset.lodScale = 100
end

-- getting custom unlock
function SoldiersAppearances:GetUnlockAsset(p_player, p_element)
    local s_customization = VeniceSoldierCustomizationAsset(p_player.customization)
    local s_kitNameParts = InstanceUtils:Split(s_customization.name, '/')
    local s_kitName = s_kitNameParts[#s_kitNameParts]

    local s_appearanceGuids = self.m_appearanceBaseGuids
    if string.ends(s_kitName, 'XP4') then
        s_kitName = s_kitName:sub(0, -5)
        s_appearanceGuids = self.m_appearanceXp4Guids
    end

    if string.ends(s_kitName, 'GM') then
        s_kitName = s_kitName:sub(0, -4)
    end

    local s_appearanceGuid = s_appearanceGuids[s_kitName]
    local s_appearanceUnlockAsset = self.m_appearanceUnlockAssets[s_appearanceGuid][p_element]

    return s_appearanceUnlockAsset
end

return SoldiersAppearances()