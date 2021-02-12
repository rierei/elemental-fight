local VehiclesAppearances = class('VehiclesAppearances')

local LoadedInstances = require('__shared/loaded-instances')
local ElementalConfig = require('__shared/elemental-config')
local InstanceUtils = require('__shared/utils/instances')

function VehiclesAppearances:__init()
    if not ElementalConfig.vehicles then
        return
    end

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
        ['vehicles/kornet/kornet'] = true
    }

    self.m_waitingInstances = {
        meshVariationDatabase = nil,
        vehicleEntities = {},

        colorSwatch = nil,

        meshAssets = {},
        meshVariationDatabaseEntrys = {},
    }

    self.m_meshVariationDatabase = nil

    self.m_surfaceShaderStructs = {}

    self.m_meshAssets = {}
    self.m_meshMaterials = {}
    self.m_meshVariationDatabaseEntrys = {}

    self.m_verbose = 1
end

function VehiclesAppearances:RegisterEvents()
    Events:Subscribe('Level:Destroy', function()
        self.m_meshAssets = {}
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

    local s_colorSwatch = TextureAsset()
    s_colorSwatch.name = 'Characters/shared/ColorSwatches/white'

    self.m_waitingInstances.colorSwatch = s_colorSwatch

    for _, l_entity in pairs(self.m_waitingInstances.vehicleEntities) do
        if not self.m_filteredPartitions[l_entity.partition.name] then
            table.insert(self.m_waitingInstances.meshAssets, l_entity.mesh)

            self:ReadMeshVariationDatabaseEntrys(l_entity.mesh)
        end
    end

    self:CreateInstances()

    self.m_waitingInstances = {
        meshVariationDatabase = nil,
        vehicleEntities = {},

        colorSwatch = nil,

        meshAssets = {},
        meshVariationDatabaseEntrys = {},
    }

    self.m_meshVariationDatabase = nil

    self.m_surfaceShaderStructs = {}

    -- self.m_meshAssets = {}
    self.m_meshMaterials = {}
    self.m_meshVariationDatabaseEntrys = {}
end

function VehiclesAppearances:ReadMeshVariationDatabaseEntrys(p_asset)
    for _, l_value in pairs(self.m_meshVariationDatabase.entries) do
        if l_value.mesh.instanceGuid:ToString('D') == p_asset.instanceGuid:ToString('D') then
            self.m_waitingInstances.meshVariationDatabaseEntrys[p_asset.instanceGuid:ToString('D')] = l_value
        end
    end
end

function VehiclesAppearances:CreateInstances()
    if self.m_verbose >= 1 then
        print('Creating Instances')
    end

    self:CreateSurfaceShaderStructs('Vehicles/Shaders/VehiclePreset_Jet')
    self:CreateSurfaceShaderStructs('Vehicles/Shaders/VehiclePreset_Mud')

    for _, l_asset in pairs(self.m_waitingInstances.meshAssets) do
        self:CreateMeshMaterials(l_asset)
        self:CreateMeshAssets(l_asset)
    end

    for _, l_entry in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys) do
        self:CreateMeshVariationDatabaseEntrys(l_entry, self.m_waitingInstances.colorSwatch)
    end

    if self.m_verbose >= 1 then
        print('Created SurfaceShaderStructs: ' .. InstanceUtils:Count(self.m_surfaceShaderStructs))
        print('Created MeshAssets: ' .. InstanceUtils:Count(self.m_meshAssets))
        print('Created MeshMaterials: ' .. InstanceUtils:Count(self.m_meshMaterials))
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
        local s_newMeshAsset = CompositeMeshAsset()

        s_newMeshAsset.name = p_asset.name
        s_newMeshAsset.nameHash = MathUtils:FNVHash(p_asset.name .. l_element)

        s_elements[l_element] = s_newMeshAsset
    end

    self.m_meshAssets[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating SurfaceShaderInstanceDataStruct
function VehiclesAppearances:CreateSurfaceShaderStructs(p_name)
    local s_elements = {}

    for _, l_element in pairs(ElementalConfig.names) do
        local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()

        local s_color = ElementalConfig.colors[l_element]

        local s_shaderGraph = ShaderGraph()
        s_shaderGraph.name = p_name

        local s_camoDarkeningParameter = VectorShaderParameter()
        s_camoDarkeningParameter.value = Vec4(s_color.x, s_color.y, s_color.z, 0)
        s_camoDarkeningParameter.parameterName = 'CamoBrightness'
        s_camoDarkeningParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        s_surfaceShaderInstanceDataStruct.shader = s_shaderGraph
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_camoDarkeningParameter)

        s_elements[l_element] = s_surfaceShaderInstanceDataStruct
    end

    self.m_surfaceShaderStructs[p_name] = s_elements
end

-- creating MeshMaterial
function VehiclesAppearances:CreateMeshMaterials(p_asset)
    if self.m_verbose >= 2 then
        print('Create MeshMaterials')
    end

    local s_elements = {}

    for _, l_element in pairs(ElementalConfig.names) do
        local s_meshMaterials = {}

        for l_key, l_value in pairs(p_asset.materials) do
            local s_isJet = false
            local s_isMud = false

            local s_shaderGraph = l_value.shader.shader
            if s_shaderGraph ~= nil then
                s_isJet = s_shaderGraph.name == 'Vehicles/Shaders/VehiclePreset_Jet'
                s_isMud = s_shaderGraph.name == 'Vehicles/Shaders/VehiclePreset_Mud'
            end

            if s_isJet or s_isMud then
                local s_newMeshMaterial = MeshMaterial(l_value:Clone())
                s_newMeshMaterial.shader = self.m_surfaceShaderStructs[s_shaderGraph.name][l_element]

                s_meshMaterials[l_key] = s_newMeshMaterial
            end
        end

        s_elements[l_element] = s_meshMaterials
    end

    self.m_meshMaterials[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshVariationDatabaseEntry
function VehiclesAppearances:CreateMeshVariationDatabaseEntrys(p_entry, p_texture)
    if self.m_verbose >= 2 then
        print('Create MeshVariationEntrys')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_entry

    local s_meshMaterials = self.m_meshMaterials[p_entry.mesh.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshVariationDatabaseEntry = MeshVariationDatabaseEntry()

        for l_key, l_value in pairs(p_entry.materials) do
            local s_material = l_value
            if s_meshMaterials[l_element][l_key] then
                s_material = MeshVariationDatabaseMaterial(l_value:Clone())
                s_material.material = s_meshMaterials[l_element][l_key]
            end

            s_newMeshVariationDatabaseEntry.materials:add(s_material)
        end

        s_newMeshVariationDatabaseEntry.mesh = self.m_meshAssets[p_entry.mesh.instanceGuid:ToString('D')][l_element]

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

return VehiclesAppearances()