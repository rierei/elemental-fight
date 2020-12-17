local VehiclesBlueprints = class('VehiclesBlueprints')

local LoadedInstances = require('__shared/loaded-instances')
local ElementalConfig = require('__shared/elemental-config')
local InstanceWait = require('__shared/utils/wait')
local InstanceUtils = require('__shared/utils/instances')

function VehiclesBlueprints:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function VehiclesBlueprints:RegisterVars()
    self.m_waitingGuids = {
        FX_Impact_Generic_01_S = {'AC35EF6C-108A-11DE-8A96-D77516A45310', 'AC35EF6D-108A-11DE-8A96-D77516A45310'},
        FX_Impact_Generic_01_M = {'9C0B1F3F-0FE4-11DE-8BFA-867F957FF326', '9C0B1F40-0FE4-11DE-8BFA-867F957FF326'},
        FX_Impact_Generic_01_L = {'6E9014B2-2E7A-11DE-A05D-865C3DEDD497', '6E9014B3-2E7A-11DE-A05D-865C3DEDD497'},
        FX_Impact_Generic_01_Minigun = {'E8F51840-FA68-4901-A25F-4A65FC69E7A2', '1B8DD11E-D714-4C46-9159-E5BF70C7D3B7'}
    }

    self.m_waitingInstances = {
        meshAssets = {},
        meshVariationDatabaseEntrys = {},

        effectBlueprints = {},

        vehicleProjectileEntities = {},
        vehicleProjectileBlueprints = {},

        weaponComponents = {},

        vehicleBlueprints = {},
        vehicleEntities = {}
    }

    self.m_registryContainer = nil -- RegistryContainer

    self.m_weaponComponentsIndexes = {}

    self.m_meshAssets = {}
    self.m_meshMaterialVariations = {}
    self.m_meshVariationDatabaseEntrys = {}

    self.m_effectBlueprints = {}

    self.m_explosionEntities = {}
    self.m_projectileEntities = {}
    self.m_projectileBlueprints = {}

    self.m_weaponComponents = {}

    self.m_vehicleEntities = {}
    self.m_vehicleBlueprints = {}
end

function VehiclesBlueprints:RegisterEvents()
    Events:Subscribe('Level:LoadingInfo', function(p_screenInfo)
        if p_screenInfo == 'Initializing entities for autoloaded sublevels' then
            self.m_waitingInstances.meshVariationDatabase = LoadedInstances.m_loadedInstances.MeshVariationDatabase
            self.m_waitingInstances.vehicleEntities = LoadedInstances.m_loadedInstances.VehicleEntityData
        end
    end)

    Events:Subscribe('Level:Loaded', function(p_level, p_mode)
        InstanceWait(self.m_waitingGuids, function(p_instances)
            self:ReadInstances(p_instances)
        end)
    end)
end

function VehiclesBlueprints:ReadInstances(p_instances)
    self.m_meshVariationDatabase = self.m_waitingInstances.meshVariationDatabase
    self.m_meshVariationDatabase:MakeWritable()

    self.m_effectBlueprints['small'] = p_instances['FX_Impact_Generic_01_S']
    self.m_effectBlueprints['medium'] = p_instances['FX_Impact_Generic_01_M']
    self.m_effectBlueprints['large'] = p_instances['FX_Impact_Generic_01_L']
    self.m_effectBlueprints['minigun'] = p_instances['FX_Impact_Generic_01_Minigun']

    for _, l_entity in pairs(self.m_waitingInstances.vehicleEntities) do
        table.insert(self.m_waitingInstances.meshAssets, l_entity.mesh)

        self:ReadMeshVariationDatabaseEntrys(l_entity.mesh)
        self:ReadWeaponComponents(l_entity)
    end
end

function VehiclesBlueprints:ReadMeshVariationDatabaseEntrys(p_asset)
    for _, l_value in pairs(self.m_meshVariationDatabase.entries) do
        if l_value.mesh == p_asset then
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
            if l_value:Is('ComponentData') then
                local s_keys = cloneTable(p_keys)

                -- parsing current index
                table.insert(s_keys, l_key)

                readWeaponComponents(ComponentData(l_value).components, s_keys)
            elseif l_value:Is('WeaponComponentData') then
                local s_keys = cloneTable(p_keys)

                -- parsing current index
                table.insert(s_keys, l_key)

                table.insert(self.m_weaponComponentsIndexes[p_entity.instanceGuid:ToString('D')], s_keys)

                self.m_waitingInstances.weaponComponents[l_value.instanceGuid:ToString('D')] = WeaponComponentData(l_value)
            end
        end
    end

    readWeaponComponents(p_entity.components, {})
end

function VehiclesBlueprints:CreateInstances()
    for _, l_asset in pairs(self.m_waitingInstances.meshAssets) do
        self:CreateMeshAssets(l_asset)
        self:CreateMeshVariationDatabaseEntrys(l_asset)
    end

    self:CreateEffectBlueprints(self.m_waitingInstances.effectBlueprints)

    for _, l_entity in pairs(self.m_waitingInstances.vehicleProjectileEntities) do
        self:CreateExplosionEntities(l_entity)
        self:CreateProjectileEntities(l_entity)
    end

    for _, l_blueprint in pairs(self.m_waitingInstances.vehicleProjectileBlueprints) do
        self:CreateProjectileBleprints(l_blueprint)
    end

    for _, l_component in pairs(self.m_waitingInstances.weaponComponents) do
        self:CreateWeaponsComponents(l_component)
    end

    for _, l_entity in pairs(self.m_waitingInstances.vehicleEntities) do
        self:CreateVehicleEntities(l_entity)
    end

    for _, l_blueprint in pairs(self.m_waitingInstances.vehicleBlueprints) do
        self:CreateVehicleBlueprints(l_blueprint)
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

        -- TODO CUSTOM MESH

        s_elements[l_element] = s_newMeshAsset
    end

    self.m_meshAssets[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshMaterialVariation
function VehiclesBlueprints:CreateMeshMaterialVariations()
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_elements = {}

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshMaterialVariation = MeshMaterialVariation()

        -- TODO MATERIAL VARIATION

        s_elements[l_element] = s_newMeshMaterialVariation
    end

    self.m_meshMaterialVariations = s_elements
end

-- creating MeshVariationDatabaseEntry
function VehiclesBlueprints:CreateMeshVariationDatabaseEntrys(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshVariationEntrys')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshVariationDatabaseEntry = InstanceUtils:CloneInstance(p_entry, l_element)

        -- TODO MESH VARIATION

        s_elements[l_element] = s_newMeshVariationDatabaseEntry
    end

    self.m_meshVariationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] = s_elements
end

function VehiclesBlueprints:CreateEffectBlueprints(p_blueprints)
    for l_key, l_value in pairs(p_blueprints) do
        local s_elements = {}
        s_elements['neutral'] = l_value

        for _, l_element in pairs(ElementalConfig.names) do
            local s_newEffectBlueprint = InstanceUtils:CloneInstance(l_value, l_element)

            -- TODO CUSTOM EFFECT

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

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newExplosionEntity = VeniceExplosionEntityData(InstanceUtils:GenerateGuid('explosionBlueprint' .. l_element))

        -- TODO CUSTOM EXPLOSION

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

        if p_entity.physicsPropertyIndex == 77 then
            -- BulletDamage
        end

        if p_entity.physicsPropertyIndex == 83 then
            -- HMG
        end

        if p_entity.physicsPropertyIndex == 86 then
            -- TankShell
        end

        if p_entity.physicsPropertyIndex == 114 then
            -- Minigun
        end

        if p_entity.physicsPropertyIndex == 139 then
            -- DUD
        end

        -- TODO CUSTOM EXPLOSION

        s_elements[l_element] = s_newProjectileEntity
    end

    self.m_projectileEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

-- creating ProjectileBlueprint
function VehiclesBlueprints:CreateProjectileBleprints(p_blueprint)
    if self.m_verbose >= 2 then
        print('Create ProjectileBlueprints')
    end

    local s_elements = {}
    s_elements['neutral'] = p_blueprint

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newProjectileBlueprint = InstanceUtils:CloneInstance(p_blueprint, l_element)

        -- TODO PROJECTILE ENTITY

        s_elements[l_element] = s_newProjectileBlueprint
    end

    self.m_projectileBlueprints[p_blueprint.instanceGuid:ToString('D')] = s_elements
end

-- creating WeaponComponentData
function VehiclesBlueprints:CreateWeaponsComponents(p_component)
    if self.m_verbose >= 2 then
        print('Create WeaponComponents')
    end

    local s_elements = {}
    s_elements['neutral'] = p_component

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newWeaponComponent = InstanceUtils:CloneInstance(p_component, l_element)

        -- TODO WEAPON FIRING

        s_elements[l_element] = s_newWeaponComponent
    end

    self.m_weaponComponents[p_component.instanceGuid:ToString('D')] = s_elements
end

-- creating VehicleEntityData
function VehiclesBlueprints:CreateVehicleEntities(p_entity)
    if self.m_verbose >= 2 then
        print('Create VehicleEntities')
    end

    -- updating components recursively
    local function updateComponents(p_component, p_indexes, p_element)
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
            p_component.components[s_nextIndex] = self.m_weaponComponents[s_nextComponent.instanceGuid:ToString('D')][p_element]
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
            if l_connection.source == p_search then
                l_connection.source = p_replace
            end

            if l_connection.target == p_search then
                l_connection.target = p_replace
            end
        end
    end

    -- replacing weapon connections
    local function updateWeaponConnections(p_connections, p_element)
        for _, l_connection in pairs(p_connections) do
            local s_sourceGuid = l_connection.source.instanceGuid:ToString('D')
            if self.m_weaponComponents[s_sourceGuid] ~= nil then
                l_connection.source = self.m_weaponComponents[s_sourceGuid][p_element]
            end

            local s_targetGuid = l_connection.target.instanceGuid:ToString('D')
            if self.m_weaponComponents[s_targetGuid] ~= nil then
                l_connection.target = self.m_weaponComponents[s_targetGuid][p_element]
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

        -- updating entity connections
        updateConnections(s_newVehicleBlueprint.propertyConnections, p_blueprint.object, s_newVehicleBlueprint.object)
        updateConnections(s_newVehicleBlueprint.linkConnections, p_blueprint.object, s_newVehicleBlueprint.object)
        updateConnections(s_newVehicleBlueprint.eventConnections, p_blueprint.object, s_newVehicleBlueprint.object)

        -- updating weapon connections
        updateWeaponConnections(s_newVehicleBlueprint.propertyConnections, l_element)
        updateWeaponConnections(s_newVehicleBlueprint.linkConnections, l_element)
        updateWeaponConnections(s_newVehicleBlueprint.eventConnections, l_element)

        s_elements[l_element] = s_newVehicleBlueprint
    end

    self.m_vehicleEntities[p_blueprint.instanceGuid:ToString('D')] = s_elements
end

return VehiclesBlueprints