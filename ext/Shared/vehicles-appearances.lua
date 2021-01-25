local VehiclesAppearances = class('VehiclesAppearances')

local LoadedInstances = require('__shared/loaded-instances')
local ElementalConfig = require('__shared/elemental-config')
local InstanceWait = require('__shared/utils/wait')
local InstanceUtils = require('__shared/utils/instances')

function VehiclesAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function VehiclesAppearances:RegisterVars()
    self.m_filteredPartitions = {
        ['vehicles/common/weapondata/coax_hmg_firing'] = true,
        ['vehicles/common/weapondata/laserdesignator_firing'] = true,
        ['vehicles/common/weapondata/agm-144_hellfire_tv'] = true,

        ['vehicles/centurion_c-ram/centurion_c-ram'] = true,
        ['vehicles/centurion_c-ram/centurion_c-ram_carrier'] = true,
        ['vehicles/pantsir/pantsir-s1'] = true,
        ['vehicles/tow2/tow2'] = true,
        ['vehicles/kornet/kornet'] = true,
    }

    self.m_optionalGuids = {
        VehiclePreset_Jet = {'C2DCC7D1-BCC6-4047-8A2B-8170E57B07B8', '6B0CDFF7-3EB6-4177-9BA0-FD686F10DF8C'},
    }

    self.m_waitingInstances = {
        vehicleJetShader = nil,
        vehicleMudShader = nil,

        meshAssets = {},
        meshVariationDatabaseEntrys = {},

        vehicleEntities = {}
    }

    self.m_meshVariationDatabase = nil

    self.m_surfaceShaderStructs = {}

    self.m_meshAssets = {}
    self.m_meshMaterialVariations = {}
    self.m_meshVariationDatabaseEntrys = {}

    self.m_verbose = 1
end

function VehiclesAppearances:RegisterEvents()
    Events:Subscribe('Level:Destroy', function()
        self.m_meshAssets = {}
    end)

    InstanceWait(self.m_optionalGuids, function(p_instances)
        self.m_waitingInstances.vehicleJetShader = p_instances['VehiclePreset_Jet']
    end)

    Events:Subscribe('LoadedInstances:MeshVariationDatabase', function(p_instances)
        self:ReadInstances(p_instances)
    end)
end

function VehiclesAppearances:ReadInstances(p_instances)
    self.m_waitingInstances.meshVariationDatabase = LoadedInstances.m_loadedInstances.MeshVariationDatabase
    self.m_waitingInstances.vehicleEntities = LoadedInstances:GetInstances('VehicleEntityData')

    self.m_meshVariationDatabase = self.m_waitingInstances.meshVariationDatabase
    self.m_meshVariationDatabase:MakeWritable()

    self.m_waitingInstances.vehicleMudShader = p_instances['VehiclePreset_Mud']
    self.m_waitingInstances.colorSwatch = p_instances['ColorSwatchesWhite']

    for _, l_entity in pairs(self.m_waitingInstances.vehicleEntities) do
        if not self.m_filteredPartitions[l_entity.partition.name] then
            table.insert(self.m_waitingInstances.meshAssets, l_entity.mesh)

            self:ReadMeshVariationDatabaseEntrys(l_entity.mesh)
        end
    end

    self:CreateInstances()

    self.m_waitingInstances = {
        vehicleJetShader = nil,
        vehicleMudShader = nil,

        meshAssets = {},
        meshVariationDatabaseEntrys = {},

        vehicleEntities = {}
    }

    self.m_meshVariationDatabase = nil

    self.m_surfaceShaderStructs = {}

    -- self.m_meshAssets = {}
    self.m_meshMaterialVariations = {}
    self.m_meshVariationDatabaseEntrys = {}
end

function VehiclesAppearances:ReadMeshVariationDatabaseEntrys(p_asset)
    for _, l_value in pairs(self.m_meshVariationDatabase.entries) do
        if l_value.mesh.instanceGuid == p_asset.instanceGuid then
            self.m_waitingInstances.meshVariationDatabaseEntrys[p_asset.instanceGuid:ToString('D')] = l_value
        end
    end
end

function VehiclesAppearances:CreateInstances()
    if self.m_verbose >= 1 then
        print('Creating Instances')
    end

    for _, l_asset in pairs(self.m_waitingInstances.meshAssets) do
        self:CreateMeshAssets(l_asset)
    end

    self:CreateSurfaceShaderStructs(self.m_waitingInstances.vehicleMudShader)

    if self.m_waitingInstances.vehicleJetShader ~= nil then
        self:CreateSurfaceShaderStructs(self.m_waitingInstances.vehicleJetShader)
    end

    for _, l_entry in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys) do
        self:CreateMeshMaterialVariations(l_entry)
        self:CreateMeshVariationDatabaseEntrys(l_entry, self.m_waitingInstances.colorSwatch)
    end

    if self.m_verbose >= 1 then
        print('Created SurfaceShaderStructs: ' .. InstanceUtils:Count(self.m_surfaceShaderStructs))
        print('Created MeshAssets: ' .. InstanceUtils:Count(self.m_meshAssets))
        print('Created MeshMaterialVariations: ' .. InstanceUtils:Count(self.m_meshMaterialVariations))
        print('Created MeshVariationDatabaseEntrys: ' .. InstanceUtils:Count(self.m_meshVariationDatabaseEntrys))
    end
end

-- creating MeshAsset
function VehiclesAppearances:CreateMeshAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create MeshAssets')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_asset

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshAsset = InstanceUtils:CloneInstance(p_asset, l_element)

        s_newMeshAsset.nameHash = MathUtils:FNVHash(s_newMeshAsset.name .. l_element)

        s_elements[l_element] = s_newMeshAsset
    end

    self.m_meshAssets[p_asset.instanceGuid:ToString('D')] = s_elements
end


-- creating SurfaceShaderInstanceDataStruct
function VehiclesAppearances:CreateSurfaceShaderStructs(p_asset)
    local s_elements = {}

    for _, l_element in pairs(ElementalConfig.names) do
        local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()

        local s_color = ElementalConfig.colors[l_element]

        local s_camoDarkeningParameter = VectorShaderParameter()
        s_camoDarkeningParameter.value = Vec4(s_color.x, s_color.y, s_color.z, 0)
        s_camoDarkeningParameter.parameterName = 'CamoBrightness'
        s_camoDarkeningParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        s_surfaceShaderInstanceDataStruct.shader = p_asset
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_camoDarkeningParameter)

        s_elements[l_element] = s_surfaceShaderInstanceDataStruct
    end

    self.m_surfaceShaderStructs[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshMaterialVariation
function VehiclesAppearances:CreateMeshMaterialVariations(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_entry.materials[1]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_databaseEntryMaterials = {}

        for ll_key, ll_value in pairs(p_entry.materials) do
            local s_isJet = false
            local s_isMud = false

            local s_shaderGraph = ll_value.material.shader.shader
            if s_shaderGraph ~= nil then
                s_isJet = ll_value.material.shader.shader.name == 'Vehicles/Shaders/VehiclePreset_Jet'
                s_isMud = ll_value.material.shader.shader.name == 'Vehicles/Shaders/VehiclePreset_Mud'
            end

            if s_isJet or s_isMud then
                local s_newMeshMaterialVariation = MeshMaterialVariation(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'MeshMaterialVariation' .. l_element .. ll_key))
                p_entry.partition:AddInstance(s_newMeshMaterialVariation)

                s_newMeshMaterialVariation.shader = self.m_surfaceShaderStructs[s_shaderGraph.instanceGuid:ToString('D')][l_element]

                s_databaseEntryMaterials[ll_key] = s_newMeshMaterialVariation
            end
        end

        s_elements[l_element] = s_databaseEntryMaterials
    end

    self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshVariationDatabaseEntry
function VehiclesAppearances:CreateMeshVariationDatabaseEntrys(p_entry, p_texture)
    if self.m_verbose >= 2 then
        print('Create MeshVariationEntrys')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_entry

    local s_meshMaterialVariations = self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshVariationDatabaseEntry = InstanceUtils:CloneInstance(p_entry, l_element)

        s_newMeshVariationDatabaseEntry.mesh = self.m_meshAssets[s_newMeshVariationDatabaseEntry.mesh.instanceGuid:ToString('D')][l_element]

        for ll_key, ll_value in pairs(s_meshMaterialVariations[l_element]) do
            s_newMeshVariationDatabaseEntry.materials[ll_key].materialVariation = ll_value
        end

        for key, value in pairs(s_newMeshVariationDatabaseEntry.materials) do
            for k, v in pairs(value.textureParameters) do
                if v.parameterName == 'Camo' then
                    s_newMeshVariationDatabaseEntry.materials[key].textureParameters[k].value = p_texture
                end
            end
        end

        self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry)

        s_elements[l_element] = s_newMeshVariationDatabaseEntry
    end

    self.m_meshVariationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] = s_elements
end

return VehiclesAppearances