local VehiclesBlueprints = class('VehiclesBlueprints')

local LoadedInstances = require('__shared/loaded-instances')
local ElementalConfig = require('__shared/elemental-config')
local InstanceWait = require('__shared/utils/wait')
local InstanceUtils = require('__shared/utils/instances')

local MaterialPairs = require('__shared/utils/consts').materialPairs

function VehiclesBlueprints:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function VehiclesBlueprints:RegisterVars()
    self.m_materialPropertyEffects = {
        [77] = 'minigun', -- BulletDamage
        [78] = 'medium', -- ShellDamage
        [82] = 'small', -- HMG
        [83] = 'small', -- HMG
        [86] = 'large', -- TankShell
        [87] = 'large', -- Missile
        [105] = 'minigun', -- AA
        [114] = 'minigun', -- Minigun
        [-117] = 'medium' -- DUD
    }

    self.m_waitingGuids = {

        MaterialContainer = {'B50615C2-4743-4919-9A40-A738150DEBE9', '89492CD4-F004-42B9-97FB-07FD3D436205'}, -- materialContainerAsset

        FX_Impact_Generic_01_S = {'AC35EF6C-108A-11DE-8A96-D77516A45310', 'AC35EF6D-108A-11DE-8A96-D77516A45310'},
        FX_Impact_Generic_01_M = {'9C0B1F3F-0FE4-11DE-8BFA-867F957FF326', '9C0B1F40-0FE4-11DE-8BFA-867F957FF326'},
        FX_Impact_Generic_01_L = {'6E9014B2-2E7A-11DE-A05D-865C3DEDD497', '6E9014B3-2E7A-11DE-A05D-865C3DEDD497'},
        FX_Impact_Generic_01_Minigun = {'E8F51840-FA68-4901-A25F-4A65FC69E7A2', '1B8DD11E-D714-4C46-9159-E5BF70C7D3B7'},

        VehiclePreset_Mud = {'A0300659-01B5-4DF5-8895-98AD28C984C2', 'FA58EF71-AD00-427B-8AA1-3B8FAD051EEF'},
        VehiclePreset_Jet = {'C2DCC7D1-BCC6-4047-8A2B-8170E57B07B8', '6B0CDFF7-3EB6-4177-9BA0-FD686F10DF8C'},

        Em_Impact_Generic_S_Sparks_01 = {'1F6B1EB2-86E3-473C-8E25-A24989538600', '1A0C5373-3DC4-4967-89A3-A6D53AD8A58F'}, -- dummyPolynomialColor

        _MP_Pilot_Gear_Heli_US = {'75CF71E3-AD39-11E0-99FA-8D9FD57D29B3', 'D75008EB-B9B4-B977-6478-04787EEFB185'}
    }

    self.m_waitingInstances = {
        vehicleJetShader = nil,
        vehicleMudShader = nil,

        meshAssets = {},
        meshVariationDatabaseEntrys = {},

        dummyPolynomialColor = nil, -- PolynomialColorInterpData
        effectBlueprints = {},

        vehicleProjectileEntities = {},
        vehicleProjectileBlueprints = {},

        weaponComponents = {},

        vehicleBlueprints = {},
        vehicleEntities = {}
    }

    self.m_registryContainer = nil -- RegistryContainer
    self.m_materialContainerAsset = nil -- MaterialContainerAsset

    self.m_polynomialColorInterps = {} -- PolynomialColorInterpData
    self.m_emitterDocumentAssets = {} -- EmitterDocument
    self.m_emitterEntities = {} -- EmitterEntityData

    self.m_weaponComponentsIndexes = {}

    self.m_surfaceShaderStructs = {}

    self.m_meshAssets = {}
    self.m_meshMaterialVariations = {}
    self.m_meshVariationDatabaseEntrys = {}

    self.m_effectBlueprints = {}

    self.m_explosionEntities = {}
    self.m_projectileEntities = {}
    self.m_projectileBlueprints = {}

    self.m_weaponFirings = {}
    self.m_weaponComponents = {}

    self.m_vehicleEntities = {}
    self.m_vehicleBlueprints = {}

    self.m_instanceCreateFunctions = {
        emitterDocumentAssets = self._CreateEmitterDocumentAssets,
        emitterEntities = self._CreateEmitterEntity
    }

    self.m_verbose = 1
end

function VehiclesBlueprints:RegisterEvents()
    InstanceWait(self.m_waitingGuids, function(p_instances)
        self.m_waitingInstances.meshVariationDatabase = LoadedInstances.m_loadedInstances.MeshVariationDatabase

        self.m_waitingInstances.vehicleProjectileEntities = LoadedInstances.m_loadedInstances.VehicleMeshProjectileEntityData
        self.m_waitingInstances.vehicleProjectileBlueprints = LoadedInstances.m_loadedInstances.VehicleProjectileBlueprint

        self.m_waitingInstances.vehicleEntities = LoadedInstances.m_loadedInstances.VehicleEntityData
        self.m_waitingInstances.vehicleBlueprints = LoadedInstances.m_loadedInstances.VehicleBlueprint

        self:ReadInstances(p_instances)
    end)
end

function VehiclesBlueprints:ReadInstances(p_instances)
    self.m_meshVariationDatabase = self.m_waitingInstances.meshVariationDatabase
    self.m_meshVariationDatabase:MakeWritable()

    self.m_materialContainerAsset = p_instances['MaterialContainer']

    self.m_waitingInstances.vehicleJetShader = p_instances['VehiclePreset_Mud']
    self.m_waitingInstances.vehicleMudShader = p_instances['VehiclePreset_Jet']

    self.m_waitingInstances.dummyPolynomialColor = p_instances['Em_Impact_Generic_S_Sparks_01']

    self.m_waitingInstances.effectBlueprints['small'] = p_instances['FX_Impact_Generic_01_S']
    self.m_waitingInstances.effectBlueprints['medium'] = p_instances['FX_Impact_Generic_01_M']
    self.m_waitingInstances.effectBlueprints['large'] = p_instances['FX_Impact_Generic_01_L']
    self.m_waitingInstances.effectBlueprints['minigun'] = p_instances['FX_Impact_Generic_01_Minigun']

    for _, l_entity in pairs(self.m_waitingInstances.vehicleEntities) do
        table.insert(self.m_waitingInstances.meshAssets, l_entity.mesh)

        self:ReadMeshVariationDatabaseEntrys(l_entity.mesh)
        self:ReadWeaponComponents(l_entity)
    end

    self:CreateInstances()
end

function VehiclesBlueprints:ReadMeshVariationDatabaseEntrys(p_asset)
    for _, l_value in pairs(self.m_meshVariationDatabase.entries) do
        if l_value.mesh.instanceGuid == p_asset.instanceGuid then
            self.m_waitingInstances.meshVariationDatabaseEntrys[p_asset.instanceGuid:ToString('D')] = l_value
        end
    end
end

function VehiclesBlueprints:ReadWeaponComponents(p_entity)
    self.m_weaponComponentsIndexes[p_entity.instanceGuid:ToString('D')] = {}

    -- copying table values
    local function cloneTable(p_table)
        local s_table = {}

        for l_key, l_value in pairs(p_table) do
            s_table[l_key] = l_value
        end

        return s_table
    end

    -- recursively reading weapon components
    local function readWeaponComponents(p_components, p_keys)
        if p_components == nil then
            return nil
        end

        -- reading all components
        for l_key, l_value in pairs(p_components) do
            if l_value:Is('WeaponComponentData') then
                local s_keys = cloneTable(p_keys)

                -- parsing current index
                table.insert(s_keys, l_key)

                table.insert(self.m_weaponComponentsIndexes[p_entity.instanceGuid:ToString('D')], s_keys)

                self.m_waitingInstances.weaponComponents[l_value.instanceGuid:ToString('D')] = WeaponComponentData(l_value)
            elseif l_value:Is('ComponentData') then
                local s_keys = cloneTable(p_keys)

                -- parsing current index
                table.insert(s_keys, l_key)

                readWeaponComponents(ComponentData(l_value).components, s_keys)
            end
        end
    end

    readWeaponComponents(p_entity.components, {})
end

function VehiclesBlueprints:CreateInstances()
    if self.m_verbose >= 1 then
        print('Creating Instances')
    end

    self.m_registryContainer = RegistryContainer()

    for _, l_asset in pairs(self.m_waitingInstances.meshAssets) do
        self:CreateMeshAssets(l_asset)
    end

    self:CreateSurfaceShaderStructs(self.m_waitingInstances.vehicleMudShader)
    self:CreateSurfaceShaderStructs(self.m_waitingInstances.vehicleJetShader)

    for _, l_entry in pairs(self.m_waitingInstances.meshVariationDatabaseEntrys) do
        self:CreateMeshMaterialVariations(l_entry)
        self:CreateMeshVariationDatabaseEntrys(l_entry)
    end

    self:CreatePolynomialColorInterps(self.m_waitingInstances.dummyPolynomialColor)

    self:CreateEffectBlueprints(self.m_waitingInstances.effectBlueprints)

    for _, l_entity in pairs(self.m_waitingInstances.vehicleProjectileEntities) do
        self:CreateExplosionEntities(l_entity)
    end

    for _, l_entity in pairs(self.m_waitingInstances.vehicleProjectileEntities) do
        self:CreateProjectileEntities(l_entity)
    end

    for _, l_blueprint in pairs(self.m_waitingInstances.vehicleProjectileBlueprints) do
        self:CreateProjectileBlueprints(l_blueprint)
    end

    for _, l_component in pairs(self.m_waitingInstances.weaponComponents) do
        self:CreateWeaponFirings(l_component.weaponFiring)
        self:CreateWeaponsComponents(l_component)
    end

    for _, l_entity in pairs(self.m_waitingInstances.vehicleEntities) do
        self:CreateVehicleEntities(l_entity)
    end

    for _, l_blueprint in pairs(self.m_waitingInstances.vehicleBlueprints) do
        self:CreateVehicleBlueprints(l_blueprint)
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Dynamic_Begin_)

    if self.m_verbose >= 1 then
        print('Created WeaponComponentsIndexes: ' .. InstanceUtils:Count(self.m_weaponComponentsIndexes))
        print('Created SurfaceShaderStructs: ' .. InstanceUtils:Count(self.m_surfaceShaderStructs))
        print('Created MeshAssets: ' .. InstanceUtils:Count(self.m_meshAssets))
        print('Created MeshMaterialVariations: ' .. InstanceUtils:Count(self.m_meshMaterialVariations))
        print('Created MeshVariationDatabaseEntrys: ' .. InstanceUtils:Count(self.m_meshVariationDatabaseEntrys))
        print('Created PolynomialColorInterps: ' .. InstanceUtils:Count(self.m_polynomialColorInterps))
        print('Created EmitterDocumentAssets: ' .. InstanceUtils:Count(self.m_emitterDocumentAssets))
        print('Created EmitterEntities: ' .. InstanceUtils:Count(self.m_emitterEntities))
        print('Created EffectBlueprints: ' .. InstanceUtils:Count(self.m_effectBlueprints))
        print('Created ExplosionEntities: ' .. InstanceUtils:Count(self.m_explosionEntities))
        print('Created ProjectileEntities: ' .. InstanceUtils:Count(self.m_projectileEntities))
        print('Created ProjectileBlueprints: ' .. InstanceUtils:Count(self.m_projectileBlueprints))
        print('Created WeaponFirings: ' .. InstanceUtils:Count(self.m_weaponFirings))
        print('Created WeaponComponents: ' .. InstanceUtils:Count(self.m_weaponComponents))
        print('Created VehicleEntities: ' .. InstanceUtils:Count(self.m_vehicleEntities))
        print('Created VehicleBlueprints: ' .. InstanceUtils:Count(self.m_vehicleBlueprints))
        print('Created RegistryContainerAssets: ' .. InstanceUtils:Count(self.m_registryContainer.assetRegistry))
        print('Created RegistryContainerEntities: ' .. InstanceUtils:Count(self.m_registryContainer.entityRegistry))
        print('Created RegistryContainerBlueprints: ' .. InstanceUtils:Count(self.m_registryContainer.blueprintRegistry))
    end
end

-- creating MeshAsset
function VehiclesBlueprints:CreateMeshAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create MeshAssets')
    end

    local s_elements = {}
    s_elements['neutral'] = p_asset

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshAsset = InstanceUtils:CloneInstance(p_asset, l_element)

        s_newMeshAsset.nameHash = MathUtils:FNVHash(s_newMeshAsset.name .. l_element)

        s_elements[l_element] = s_newMeshAsset
    end

    self.m_meshAssets[p_asset.instanceGuid:ToString('D')] = s_elements
end


-- creating SurfaceShaderInstanceDataStruct
function VehiclesBlueprints:CreateSurfaceShaderStructs(p_asset)
    local s_elements = {}

    for _, l_element in pairs(ElementalConfig.names) do
        local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()

        local s_color = ElementalConfig.colors[l_element]

        local s_camoDarkeningParameter = VectorShaderParameter()
        s_camoDarkeningParameter.value = Vec4(s_color.x * 10, s_color.y * 10, s_color.z * 10, 0)
        s_camoDarkeningParameter.parameterName = 'CamoBrightness'
        s_camoDarkeningParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        s_surfaceShaderInstanceDataStruct.shader = p_asset
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_camoDarkeningParameter)

        s_elements[l_element] = s_surfaceShaderInstanceDataStruct
    end

    self.m_surfaceShaderStructs[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshMaterialVariation
function VehiclesBlueprints:CreateMeshMaterialVariations(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry.materials[1]

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
function VehiclesBlueprints:CreateMeshVariationDatabaseEntrys(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshVariationEntrys')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry

    local s_meshMaterialVariations = self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshVariationDatabaseEntry = InstanceUtils:CloneInstance(p_entry, l_element)

        s_newMeshVariationDatabaseEntry.mesh = self.m_meshAssets[s_newMeshVariationDatabaseEntry.mesh.instanceGuid:ToString('D')][l_element]

        for ll_key, ll_value in pairs(s_meshMaterialVariations[l_element]) do
            s_newMeshVariationDatabaseEntry.materials[ll_key].materialVariation = ll_value
        end

        self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry)

        s_elements[l_element] = s_newMeshVariationDatabaseEntry
    end

    self.m_meshVariationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating PolynomialColorInterpData for EmitterDocument
function VehiclesBlueprints:CreatePolynomialColorInterps(p_data)
    if self.m_verbose >= 2 then
        print('Create PolynomialColorInterps')
    end

    local s_elements = {}
    s_elements['neutral'] = p_data

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newPolynomialColor = InstanceUtils:CloneInstance(p_data, l_element)

        s_newPolynomialColor.color0 = ElementalConfig.colors[l_element]
        s_newPolynomialColor.color1 = ElementalConfig.colors[l_element]

        s_elements[l_element] = s_newPolynomialColor
    end

    self.m_polynomialColorInterps = s_elements
end

-- creating EmitterDocument for EmitterEntityData
function VehiclesBlueprints:_CreateEmitterDocumentAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create EmitterDocumentAsset')
    end

    local s_elements = {}
    s_elements['neutral'] = p_asset

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newEmitterDocumentAsset = InstanceUtils:CloneInstance(p_asset, l_element)
        local s_newTemplateData = InstanceUtils:CloneInstance(p_asset.templateData, l_element)

        local s_updateColor = nil
        local function createProcessorData(p_data)
            local s_newProcessorData = p_data:Clone()

            if s_newProcessorData.nextProcessor ~= nil then
                s_newProcessorData.nextProcessor = createProcessorData(s_newProcessorData.nextProcessor)
            end

            if s_newProcessorData.pre ~= nil then
                s_newProcessorData.pre = createProcessorData(s_newProcessorData.pre)
            end

            if s_newProcessorData:Is('UpdateColorData') then
                local s_color = ElementalConfig.colors[l_element]

                -- increment color visibility
                s_color = Vec3(s_color.x * 8, s_color.y * 8, s_color.z * 8)

                local polynomialColorInterp = nil

                -- dont use incremented visibility for smoke
                if s_newProcessorData.pre ~= nil and not s_newEmitterDocumentAsset.name:lower():match('smoke') then
                    polynomialColorInterp = PolynomialColorInterpData(s_newProcessorData.pre)
                    polynomialColorInterp:MakeWritable()

                    polynomialColorInterp.color0 = s_color
                    polynomialColorInterp.color1 = s_color
                else
                    polynomialColorInterp = self.m_polynomialColorInterps[l_element]
                end

                s_newProcessorData.pre = polynomialColorInterp
            end

            return s_newProcessorData
        end

        -- creating processor with recursion
        local s_newTemplateRootProcessor = createProcessorData(s_newTemplateData.rootProcessor)
        local s_newDocumentRootProcessor = s_newTemplateRootProcessor

        -- low graphics processor
        if not s_newEmitterDocumentAsset.rootProcessor:Eq(s_newTemplateData.rootProcessor) then
            s_newDocumentRootProcessor = createProcessorData(s_newEmitterDocumentAsset.rootProcessor)
        end

        -- non emissive smoke
        local s_emissive = true
        if s_newTemplateData.name:lower():match('smoke') then
            s_emissive = false
        end

        -- patching template properties
        s_newTemplateData.name = s_newTemplateData.name .. l_element
        s_newTemplateData.rootProcessor = s_newTemplateRootProcessor
        s_newTemplateData.emissive = s_emissive
        s_newTemplateData.actAsPointLight = true
        s_newTemplateData.pointLightRadius = 10
        s_newTemplateData.pointLightColor = ElementalConfig.colors[l_element]
        s_newTemplateData.maxSpawnDistance = 0
        s_newTemplateData.repeatParticleSpawning = false

        -- patching document properties
        s_newEmitterDocumentAsset.name = s_newEmitterDocumentAsset.name .. l_element
        s_newEmitterDocumentAsset.rootProcessor = s_newDocumentRootProcessor
        s_newEmitterDocumentAsset.templateData = s_newTemplateData

        s_elements[l_element] = s_newEmitterDocumentAsset
    end

    self.m_emitterDocumentAssets[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating EmitterEntityData for EffectBlueprint
function VehiclesBlueprints:_CreateEmitterEntity(p_entity)
    if self.m_verbose >= 2 then
        print('Create EmitterEntity')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    local emitterDocumentAsset = self:_GetInstance(p_entity.emitter, 'emitterDocumentAssets')

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newEmitterEntity = InstanceUtils:CloneInstance(p_entity, l_element)

        -- patching emitter properties
        s_newEmitterEntity.emitter = emitterDocumentAsset[l_element]

        s_elements[l_element] = s_newEmitterEntity
    end

    self.m_emitterEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

function VehiclesBlueprints:CreateEffectBlueprints(p_blueprints)
    for l_key, l_blueprint in pairs(p_blueprints) do
        local s_elements = {}
        s_elements['neutral'] = l_blueprint

        for _, l_element in pairs(ElementalConfig.names) do
            local s_newEffectBlueprint = InstanceUtils:CloneInstance(l_blueprint, l_element)
            local s_newEffectEntity = InstanceUtils:CloneInstance(s_newEffectBlueprint.object, l_element)

            for l_k, l_v in pairs(s_newEffectEntity.components) do
                if l_v:Is('EmitterEntityData') then
                    -- patching effect components
                    s_newEffectEntity.components[l_k] = self:_GetInstance(l_v, 'emitterEntities')[l_element]
                end
            end

            -- patching blueprint properties
            s_newEffectBlueprint.object = s_newEffectEntity

            s_elements[l_element] = s_newEffectBlueprint
        end

        self.m_effectBlueprints[l_key] = s_elements
    end
end

-- creating VeniceExplosionEntityData
function VehiclesBlueprints:CreateExplosionEntities(p_entity)
    if self.m_verbose >= 2 then
        print('Create ExplosionEntities')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    local s_materialPropertyEffect = nil
    if p_entity.materialPair ~= nil then
        local s_physicsPropertyIndex = MaterialContainerPair(p_entity.materialPair).physicsPropertyIndex
        s_materialPropertyEffect = self.m_materialPropertyEffects[s_physicsPropertyIndex]
    end

    if s_materialPropertyEffect == nil then
        s_materialPropertyEffect = 'small'
    end

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newExplosionEntity = nil
        if p_entity.explosion == nil then
            s_newExplosionEntity = VeniceExplosionEntityData(InstanceUtils:GenerateGuid(p_entity.instanceGuid:ToString('D') .. l_element))
            s_newExplosionEntity.blastDamage = 0
            s_newExplosionEntity.shockwaveDamage = 0
        else
            s_newExplosionEntity = InstanceUtils:CloneInstance(p_entity.explosion, l_element)
        end

        if s_newExplosionEntity.materialPair ~= nil then
            local s_physicsPropertyIndex = MaterialContainerPair(s_newExplosionEntity.materialPair).physicsPropertyIndex
            local s_materialContainerPairIndex = MaterialPairs[s_physicsPropertyIndex]

            s_newExplosionEntity.materialPair = self.m_materialContainerAsset.materialPairs[s_materialContainerPairIndex]
        end

        -- patching explosion entity
        s_newExplosionEntity.detonationEffect = self.m_effectBlueprints[s_materialPropertyEffect][l_element]

        s_elements[l_element] = s_newExplosionEntity
    end

    self.m_explosionEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshProjectileEntityData
function VehiclesBlueprints:CreateProjectileEntities(p_entity)
    if self.m_verbose >= 2 then
        print('Create ProjectileEntities')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newProjectileEntity = InstanceUtils:CloneInstance(p_entity, l_element)

        if s_newProjectileEntity.materialPair ~= nil then
            local s_physicsPropertyIndex = MaterialContainerPair(p_entity.materialPair).physicsPropertyIndex
            local s_materialContainerPairIndex = MaterialPairs[s_physicsPropertyIndex]

            s_newProjectileEntity.materialPair = self.m_materialContainerAsset.materialPairs[s_materialContainerPairIndex]
        end

        -- patching projectile entity
        s_newProjectileEntity.explosion = self.m_explosionEntities[p_entity.instanceGuid:ToString('D')][l_element]

        self.m_registryContainer.entityRegistry:add(s_newProjectileEntity)

        s_elements[l_element] = s_newProjectileEntity
    end

    self.m_projectileEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

-- creating ProjectileBlueprint
function VehiclesBlueprints:CreateProjectileBlueprints(p_blueprint)
    if self.m_verbose >= 2 then
        print('Create ProjectileBlueprints')
    end

    local s_elements = {}
    s_elements['neutral'] = p_blueprint

    local s_projectileEntity = self.m_projectileEntities[p_blueprint.object.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newProjectileBlueprint = InstanceUtils:CloneInstance(p_blueprint, l_element)

        -- patching projectile blueprint
        s_newProjectileBlueprint.object = s_projectileEntity[l_element]

        self.m_registryContainer.blueprintRegistry:add(s_newProjectileBlueprint)

        s_elements[l_element] = s_newProjectileBlueprint
    end

    self.m_projectileBlueprints[p_blueprint.instanceGuid:ToString('D')] = s_elements
end

-- creating FiringData
function VehiclesBlueprints:CreateWeaponFirings(p_data)
    if self.m_weaponFirings[p_data.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create FiringDatas')
    end

    local s_elements = {}
    s_elements['neutral'] = p_data

    local s_firingFunction = p_data.primaryFire

    local s_projectileEntity = self.m_projectileEntities[s_firingFunction.shot.projectileData.instanceGuid:ToString('D')]

    local s_projectileBlueprint = nil
    if s_firingFunction.shot.projectile ~= nil then
        s_projectileBlueprint = self.m_projectileBlueprints[s_firingFunction.shot.projectile.instanceGuid:ToString('D')]
    end

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newFiringFunction = InstanceUtils:CloneInstance(s_firingFunction, l_element)
        local s_newFiringData = InstanceUtils:CloneInstance(p_data, l_element)

        -- patching firing function
        if s_projectileEntity ~= nil then
            s_newFiringFunction.shot.projectileData = s_projectileEntity[l_element]
        end

        if s_projectileBlueprint ~= nil then
            s_newFiringFunction.shot.projectile = s_projectileBlueprint[l_element]
        end

        -- patching firing data
        s_newFiringData.primaryFire = s_newFiringFunction

        s_elements[l_element] = s_newFiringData
    end

    self.m_weaponFirings[p_data.instanceGuid:ToString('D')] = s_elements
end

-- creating WeaponComponentData
function VehiclesBlueprints:CreateWeaponsComponents(p_component)
    if self.m_verbose >= 2 then
        print('Create WeaponComponents')
    end

    local s_elements = {}
    s_elements['neutral'] = p_component

    local s_weaponFiring = self.m_weaponFirings[p_component.weaponFiring.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newWeaponComponent = InstanceUtils:CloneInstance(p_component, l_element)

        -- patching weapon component
        s_newWeaponComponent.weaponFiring = s_weaponFiring[l_element]

        s_elements[l_element] = s_newWeaponComponent
    end

    self.m_weaponComponents[p_component.instanceGuid:ToString('D')] = s_elements
end

-- creating VehicleEntityData
function VehiclesBlueprints:CreateVehicleEntities(p_entity)
    if self.m_verbose >= 2 then
        print('Create VehicleEntities')
    end

    -- copying table values
    local function cloneTable(p_table)
        local s_table = {}

        for l_key, l_value in pairs(p_table) do
            s_table[l_key] = l_value
        end

        return s_table
    end

    -- updating components recursively
    local function updateComponents(p_component, p_indexes, p_element)
        p_indexes = cloneTable(p_indexes)

        local s_nextIndex = p_indexes[1]

        local s_currComponent = nil
        local s_nextComponent = nil

        -- casting current component
        if p_component:Is('VehicleEntityData') then
            s_currComponent = p_component
        else
            s_currComponent = ComponentData(p_component)
        end

        s_nextComponent = s_currComponent.components[s_nextIndex]

        if #p_indexes > 1 then
            local s_newComponentData = s_nextComponent:Clone()

            -- replacing components until the end
            s_currComponent.components[s_nextIndex] = s_newComponentData

            --shifting indexes array
            table.remove(p_indexes, 1)

            updateComponents(s_newComponentData, p_indexes, p_element)
        else
            -- replacing the weapon component
            s_currComponent.components[s_nextIndex] = self.m_weaponComponents[s_nextComponent.instanceGuid:ToString('D')][p_element]
        end
    end

    local weaponComponentsIndexes = self.m_weaponComponentsIndexes[p_entity.instanceGuid:ToString('D')]

    local s_elements = {}
    s_elements['neutral'] = p_entity

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newVehicleEntity = InstanceUtils:CloneInstance(p_entity, l_element)

        -- replacing weapon components
        for _, l_value in pairs(weaponComponentsIndexes) do
            updateComponents(s_newVehicleEntity, l_value, l_element)
        end

        s_newVehicleEntity.mesh = self.m_meshAssets[s_newVehicleEntity.mesh.instanceGuid:ToString('D')][l_element]

        self.m_registryContainer.entityRegistry:add(s_newVehicleEntity)

        s_elements[l_element] = s_newVehicleEntity
    end

    self.m_vehicleEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

-- creating VehicleBlueprint
function VehiclesBlueprints:CreateVehicleBlueprints(p_blueprint)
    if self.m_verbose >= 2 then
        print('Create VehicleBlueprints')
    end

    -- searching and replacing connections
    local function updateConnections(p_connections, p_search, p_replace)
        for _, l_connection in pairs(p_connections) do
            if l_connection.source ~= nil then
                if l_connection.source == p_search then
                    l_connection.source = p_replace
                end
            end

            if l_connection.target ~= nil then
                if l_connection.target == p_search then
                    l_connection.target = p_replace
                end
            end
        end
    end

    -- replacing weapon connections
    local function updateWeaponConnections(p_connections, p_element)
        for _, l_connection in pairs(p_connections) do
            if l_connection.source ~= nil then
                local s_sourceGuid = l_connection.source.instanceGuid:ToString('D')
                if self.m_weaponComponents[s_sourceGuid] ~= nil then
                    l_connection.source = self.m_weaponComponents[s_sourceGuid][p_element]
                end
            end

            if l_connection.target ~= nil then
                local s_targetGuid = l_connection.target.instanceGuid:ToString('D')
                if self.m_weaponComponents[s_targetGuid] ~= nil then
                    l_connection.target = self.m_weaponComponents[s_targetGuid][p_element]
                end
            end
        end
    end

    local s_elements = {}
    s_elements['neutral'] = p_blueprint

    local s_entityGuid = p_blueprint.object.instanceGuid:ToString('D')
    for _, l_element in pairs(ElementalConfig.names) do
        local s_newVehicleBlueprint = InstanceUtils:CloneInstance(p_blueprint, l_element)

        -- patching blueprint properties
        s_newVehicleBlueprint.object = self.m_vehicleEntities[s_entityGuid][l_element]
        s_newVehicleBlueprint.name = s_newVehicleBlueprint.name .. l_element

        -- updating entity connections
        updateConnections(s_newVehicleBlueprint.propertyConnections, p_blueprint.object, s_newVehicleBlueprint.object)
        updateConnections(s_newVehicleBlueprint.linkConnections, p_blueprint.object, s_newVehicleBlueprint.object)
        updateConnections(s_newVehicleBlueprint.eventConnections, p_blueprint.object, s_newVehicleBlueprint.object)

        -- updating weapon connections
        updateWeaponConnections(s_newVehicleBlueprint.propertyConnections, l_element)
        updateWeaponConnections(s_newVehicleBlueprint.linkConnections, l_element)
        updateWeaponConnections(s_newVehicleBlueprint.eventConnections, l_element)

        self.m_registryContainer.blueprintRegistry:add(s_newVehicleBlueprint)

        s_elements[l_element] = s_newVehicleBlueprint
    end

    self.m_vehicleBlueprints[p_blueprint.instanceGuid:ToString('D')] = s_elements
end

-- creating missing instances
function VehiclesBlueprints:_GetInstance(p_instance, p_type)
    if p_instance == nil then
        return nil
    end

    if self['m_' .. p_type][p_instance.instanceGuid:ToString('D')] == nil then
        if self.m_verbose >= 2 then
            print('Missing Instance: ' .. p_type)
        end

        -- casting the instance
        local s_typeName = p_instance.typeInfo.name
        local s_type = _G[s_typeName]

        if s_type ~= nil then
            p_instance = s_type(p_instance)
        end

        self.m_instanceCreateFunctions[p_type](self, p_instance)
    end

    return self['m_' .. p_type][p_instance.instanceGuid:ToString('D')]
end

return VehiclesBlueprints