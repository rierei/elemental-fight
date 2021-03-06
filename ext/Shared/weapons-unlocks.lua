local WeaponsUnlocks = class('WeaponsUnlocks')

local LoadedInstances = require('__shared/loaded-instances')
local ElementalConfig = require('__shared/elemental-config')
local InstanceWait = require('__shared/utils/wait')
local InstanceUtils = require('__shared/utils/instances')

local MaterialPairs = require('__shared/utils/consts').materialPairs

function WeaponsUnlocks:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function WeaponsUnlocks:RegisterVars()
    self.m_soldierPropertyIndexes = {
        head = 66,
        body = 67,
        foot = 92,
        chest = 159
    }

    self.m_currentLevel = nil
    self.m_currentMode = nil

    self.m_shouldReload = false

    self.m_waitingCommonGuids = {
        MaterialContainer = {'B50615C2-4743-4919-9A40-A738150DEBE9', '89492CD4-F004-42B9-97FB-07FD3D436205'}, -- materialContainerAsset

        FX_Impact_Concrete_01_S = {'CE89593E-1D2F-11DE-A872-CA8439DC4744', 'CE89593F-1D2F-11DE-A872-CA8439DC4744'}, -- genericImpactEffectBlueprint
        FX_Grenade_Frag_01 = {'A6C980C2-1578-4169-81CB-C62AC369590E', 'FAFA506C-816A-4339-B108-3E957F48AE2D'}, -- genericExplodeEffectBlueprint

        Em_Impact_Generic_S_Sparks_01 = {'1F6B1EB2-86E3-473C-8E25-A24989538600', '1A0C5373-3DC4-4967-89A3-A6D53AD8A58F'}, -- dummyExplosionEntity
        M224_Projectile_Smoke = {'7C592ADA-6915-4969-BFF2-A875027A9962', 'A7E5A920-FA8C-4511-AA6C-CAF00C967C3E'}, -- dummyPolynomialColor

        FX_Grenade_Frag_01_Sound = {'A6C980C2-1578-4169-81CB-C62AC369590E', '41A352A8-783E-41E6-9B3E-989D473DB953'}, -- explodeSoundEffectEntity
        FX_40mm_Smoke = {'6A2C27D9-D455-458D-A542-C212C6F8F69C', '00C3D2F9-1346-47B8-956D-10CC23AD8B4D'}, -- smokeEffectBlueprint
        FX_Impact_Metal_01_M = {'67CBADED-34D0-11DE-A494-8B723B09CADF', '67CBADEE-34D0-11DE-A494-8B723B09CADF'} -- explodeEffectBlueprint
    }

    self.m_waitingInstances = {
        impactEffectBlueprints = {}, -- EffectBlueprint
        explodeEffectBlueprint = nil, -- EffectBlueprint
        smokeEffectBlueprint = nil, -- EffectBlueprint

        genericImpactEffectBlueprint = nil, -- EffectBlueprint

        dummyPolynomialColor = nil, -- PolynomialColorInterpData
        dummyExplosionEntity = nil, -- VeniceExplosionEntityData

        materialGridAsset = nil, -- MaterialGridData

        weaponUnlockAssets = {}, -- SoldierWeaponUnlockAsset
        weaponBlueprints = {}, -- SoldierWeaponBlueprint
        weaponEntities = {}, -- SoldierWeaponData

        projectileEntities = {}, -- MeshProjectileEntityData
        projectileBlueprints = {}, -- ProjectileBlueprint

        projectileModifiers = {}, -- WeaponProjectileModifier
        firingModifiers = {} -- WeaponFiringDataModifier
    }

    self.m_registryContainer = nil -- RegistryContainer
    self.m_materialContainerAsset = nil -- MaterialContainerAsset
    self.m_materialGridAsset = nil -- MaterialGridData

    self.m_soldierGridPropertyIndexes = {} -- MaterialGridData.materialIndexMap
    self.m_projectilePhysicsProperties = {} -- MaterialContainerPair.PhysicsPropertyIndex
    self.m_projectileMaterialRelationPenetrationData = nil -- MaterialRelationPenetrationData

    self.m_explodeSoundEffectEntity = nil -- SoundEffectEntityData

    self.m_polynomialColorInterps = {} -- PolynomialColorInterpData
    self.m_emitterDocumentAssets = {} -- EmitterDocument
    self.m_emitterEntities = {} -- EmitterEntityData

    self.m_impactEffectBlueprints = {} -- EffectBlueprint
    self.m_explodeEffectBlueprints = {} -- EffectBlueprint
    self.m_smokeEffectBlueprints = {} -- EffectBlueprint

    self.m_impactExplosionEntities = {} -- VeniceExplosionEntityData
    self.m_explodeExplosionEntities = {} -- VeniceExplosionEntityData

    self.m_projectileEntities = {} -- MeshProjectileEntityData
    self.m_projectileBlueprints = {} -- ProjectileBlueprint
    self.m_weaponFiringFunctions = {}
    self.m_weaponFirings = {}
    self.m_weaponProjectileModifiers = {} -- WeaponProjectileModifier
    self.m_weaponFiringModifiers = {} -- WeaponFiringDataModifier
    self.m_weaponEntities = {} -- SoldierWeaponData
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint
    self.m_weaponUnlockAssets = {} -- SoldierWeaponUnlockAsset

    self.m_instanceGuids = {
        weaponUnlockAssets = {}, -- SoldierWeaponUnlockAsset.instanceGuid
        weaponBlueprints = {}, -- SoldierWeaponBlueprint.instanceGuid
        projectileEntities = {} -- MeshProjectileEntityData.instanceGuid
    }

    self.m_instanceCreateFunctions = {
        emitterDocumentAssets = self._CreateEmitterDocumentAssets,
        emitterEntities = self._CreateEmitterEntity
    }

    self.m_verbose = 1 -- prints debug information
end

function WeaponsUnlocks:RegisterEvents()
    Events:Subscribe('Level:Destroy', function()
        self.m_weaponUnlockAssets = {}
    end)

    -- reading instances after level load
    Events:Subscribe('Level:Loaded', function(p_level, p_mode)
        if self.m_shouldReload then
            self:ReloadInstances()
        else
            self.m_instanceGuids = {
                weaponUnlockAssets = {}, -- SoldierWeaponUnlockAsset.instanceGuid
                weaponBlueprints = {}, -- SoldierWeaponBlueprint.instanceGuid
                projectileEntities = {} -- MeshProjectileEntityData.instanceGuid
            }

            self:RegisterWait()
        end
    end)

    -- reading level state
    Events:Subscribe('Level:LoadResources', function(p_level, p_mode, p_dedicated)
        self.m_shouldReload = self.m_currentLevel == p_level and self.m_currentMode == p_mode

        self.m_currentLevel = p_level
        self.m_currentMode = p_mode
    end)

    -- reading instances before level loads
    Events:Subscribe('Level:LoadingInfo', function(p_screenInfo)
        if not self.m_shouldReload and p_screenInfo == 'Initializing entities for autoloaded sublevels' then
            self.m_waitingInstances.materialGridAsset = LoadedInstances.m_loadedInstances.MaterialGridData

            self.m_waitingInstances.weaponUnlockAssets = LoadedInstances:GetInstances('SoldierWeaponUnlockAsset')
            self.m_waitingInstances.weaponBlueprints = LoadedInstances:GetInstances('SoldierWeaponBlueprint')
            self.m_waitingInstances.weaponEntities = LoadedInstances:GetInstances('SoldierWeaponData')

            self.m_waitingInstances.projectileEntities = LoadedInstances:GetInstances('WeaponMeshProjectileEntityData')
            self.m_waitingInstances.projectileBlueprints = LoadedInstances:GetInstances('WeaponProjectileBlueprint')

            self.m_waitingInstances.projectileModifiers = LoadedInstances:GetInstances('WeaponProjectileModifier')
            self.m_waitingInstances.firingModifiers = LoadedInstances:GetInstances('WeaponFiringDataModifier')
        end
    end)
end

function WeaponsUnlocks:RegisterWait()
    -- waiting each impact effect
    for _, l_value in pairs(ElementalConfig.names) do
        local s_effectGuid = ElementalConfig.effects[l_value]
        if s_effectGuid ~= nil then
            local s_waitingGuids = {[l_value] = s_effectGuid}
            InstanceWait(s_waitingGuids, function(p_instances)
                self.m_waitingInstances.impactEffectBlueprints[l_value] = p_instances[l_value]
            end)
        end
    end

    -- waiting common instances
    InstanceWait(self.m_waitingCommonGuids, function(p_instances)
        self:ReadInstances(p_instances)
    end)
end

-- reloading created instances
function WeaponsUnlocks:ReloadInstances()
    if self.m_verbose >= 1 then
        print('Reloading Instances')
    end

    self.m_registryContainer = RegistryContainer()

    local function reloadInstances(p_guids, p_registry)
        local s_instances = {}

        for _, l_value in pairs(p_guids) do
            local s_elements = {}

            for _, l_element in pairs(ElementalConfig.names) do
                local s_guids = l_value[l_element]
                local instance = ResourceManager:FindInstanceByGuid(s_guids.partition, s_guids.instance)

                -- casting the instance
                local s_typeName = instance.typeInfo.name
                local s_type = _G[s_typeName]

                if s_type ~= nil then
                    instance = s_type(instance)
                end

                p_registry:add(instance)

                s_elements[l_element] = instance
            end

            s_instances[l_value._key] = s_elements
        end

        return s_instances
    end

    reloadInstances(self.m_instanceGuids.projectileEntities, self.m_registryContainer.entityRegistry)
    reloadInstances(self.m_instanceGuids.weaponBlueprints, self.m_registryContainer.blueprintRegistry)

    self.m_weaponUnlockAssets = reloadInstances(self.m_instanceGuids.weaponUnlockAssets, self.m_registryContainer.assetRegistry)

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
        print('Reloaded WeaponUnlockAssets: ' .. InstanceUtils:Count(self.m_weaponUnlockAssets))
        print('Reloaded RegistryContainerAssets: ' .. InstanceUtils:Count(self.m_registryContainer.assetRegistry))
        print('Reloaded RegistryContainerEntities: ' .. InstanceUtils:Count(self.m_registryContainer.entityRegistry))
        print('Reloaded RegistryContainerBlueprints: ' .. InstanceUtils:Count(self.m_registryContainer.blueprintRegistry))
    end

    self.m_registryContainer = nil
end

-- reading waiting instances
function WeaponsUnlocks:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    self.m_materialGridAsset = MaterialGridData(self.m_waitingInstances.materialGridAsset)
    self.m_materialGridAsset:MakeWritable()

    self.m_projectileMaterialRelationPenetrationData = MaterialRelationPenetrationData()
    self.m_projectileMaterialRelationPenetrationData.neverPenetrate = true

    self.m_soldierGridPropertyIndexes = {
        head = self.m_materialGridAsset.materialIndexMap[self.m_soldierPropertyIndexes.head] + 1,
        body = self.m_materialGridAsset.materialIndexMap[self.m_soldierPropertyIndexes.body] + 1,
        foot = self.m_materialGridAsset.materialIndexMap[self.m_soldierPropertyIndexes.foot] + 1,
        chest = self.m_materialGridAsset.materialIndexMap[self.m_soldierPropertyIndexes.chest] + 1
    }

    self.m_materialContainerAsset = p_instances['MaterialContainer']

    self.m_waitingInstances.genericImpactEffectBlueprint = p_instances['FX_Impact_Concrete_01_S']

    self.m_waitingInstances.explodeEffectBlueprint = p_instances['FX_Impact_Metal_01_M']
    self.m_waitingInstances.smokeEffectBlueprint = p_instances['FX_40mm_Smoke']

    self.m_waitingInstances.dummyExplosionEntity = p_instances['M224_Projectile_Smoke']
    self.m_waitingInstances.dummyPolynomialColor = p_instances['Em_Impact_Generic_S_Sparks_01']

    self.m_explodeSoundEffectEntity = p_instances['FX_Grenade_Frag_01_Sound']

    for _, l_element in pairs(ElementalConfig.names) do
        if self.m_waitingInstances.impactEffectBlueprints[l_element] == nil then
            if self.m_verbose >= 1 then
                print('Apply GenericImpactEffectBlueprint')
            end

            self.m_waitingInstances.impactEffectBlueprints[l_element] = self.m_waitingInstances.genericImpactEffectBlueprint
        end
    end

    self:CreateInstances()

    local function getInstancesGuids(p_waiting, p_instances)
        local s_result = {}

        for _, l_value in pairs(p_waiting) do
            local s_elements = p_instances[l_value.instanceGuid:ToString('D')]

            local s_guids = {}
            s_guids['_key'] = l_value.instanceGuid:ToString('D')

            for _, l_element in pairs(ElementalConfig.names) do
                local s_instance = s_elements[l_element]

                s_guids[l_element] = {
                    partition = s_instance.partition.guid,
                    instance = s_instance.instanceGuid
                }
            end

            table.insert(s_result, s_guids)
        end

        return s_result
    end

    -- getting instances guids
    self.m_instanceGuids.projectileEntities = getInstancesGuids(self.m_waitingInstances.projectileEntities, self.m_projectileEntities)
    self.m_instanceGuids.weaponBlueprints = getInstancesGuids(self.m_waitingInstances.weaponBlueprints, self.m_weaponBlueprints)
    self.m_instanceGuids.weaponUnlockAssets = getInstancesGuids(self.m_waitingInstances.weaponUnlockAssets, self.m_weaponUnlockAssets)

    -- removing hanging references
    self.m_soldierGridPropertyIndexes = {} -- MaterialGridData.materialIndexMap
    self.m_projectilePhysicsProperties = {} -- MaterialContainerPair.PhysicsPropertyIndex
    self.m_projectileMaterialRelationPenetrationData = nil -- MaterialRelationPenetrationData

    -- removing hanging references
    self.m_waitingInstances = {
        impactEffectBlueprints = {}, -- EffectBlueprint
        explodeEffectBlueprint = nil, -- EffectBlueprint
        smokeEffectBlueprint = nil, -- EffectBlueprint

        genericImpactEffectBlueprint = nil, -- EffectBlueprint

        dummyPolynomialColor = nil, -- PolynomialColorInterpData
        dummyExplosionEntity = nil, -- VeniceExplosionEntityData

        materialGridAsset = nil, -- MaterialGridData

        weaponUnlockAssets = {}, -- SoldierWeaponUnlockAsset
        weaponBlueprints = {}, -- SoldierWeaponBlueprint
        weaponEntities = {}, -- SoldierWeaponData

        projectileEntities = {}, -- MeshProjectileEntityData
        projectileBlueprints = {}, -- ProjectileBlueprint

        projectileModifiers = {}, -- WeaponProjectileModifier
        firingModifiers = {} -- WeaponFiringDataModifier
    }

    -- removing hanging references
    self.m_registryContainer = nil
    self.m_materialContainerAsset = nil -- MaterialContainerAsset
    self.m_materialGridAsset = nil -- MaterialGridData

    self.m_explodeSoundEffectEntity = nil -- SoundEffectEntityData

    self.m_polynomialColorInterps = {} -- PolynomialColorInterpData
    self.m_emitterDocumentAssets = {} -- EmitterDocument
    self.m_emitterEntities = {} -- EmitterEntityData

    self.m_impactEffectBlueprints = {} -- EffectBlueprint
    self.m_explodeEffectBlueprints = {} -- EffectBlueprint
    self.m_smokeEffectBlueprints = {} -- EffectBlueprint

    self.m_impactExplosionEntities = {} -- VeniceExplosionEntityData
    self.m_explodeExplosionEntities = {} -- VeniceExplosionEntityData

    self.m_projectileEntities = {} -- MeshProjectileEntityData
    self.m_projectileBlueprints = {} -- ProjectileBlueprint
    self.m_weaponFiringFunctions = {}
    self.m_weaponFirings = {}
    self.m_weaponProjectileModifiers = {} -- WeaponProjectileModifier
    self.m_weaponFiringModifiers = {} -- WeaponFiringDataModifier
    self.m_weaponEntities = {} -- SoldierWeaponData
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint
end

-- creating instances of elements
function WeaponsUnlocks:CreateInstances()
    if self.m_verbose >= 1 then
        print('Creating Instances')
    end

    self.m_registryContainer = RegistryContainer()

    self:CreatePolynomialColorInterps(self.m_waitingInstances.dummyPolynomialColor)

    self:CreateImpactEffectBlueprints(self.m_waitingInstances.impactEffectBlueprints)
    self:CreateExplodeEffectBlueprints(self.m_waitingInstances.explodeEffectBlueprint)
    self:CreateSmokeEffectBlueprints(self.m_waitingInstances.smokeEffectBlueprint)

    self:CreateImpactExplosionEntities(self.m_waitingInstances.dummyExplosionEntity)
    self:CreateSmokeExplosionEntities(self.m_waitingInstances.dummyExplosionEntity)

    --
    -- creating projectiles
    --

    for _, l_entity in pairs(self.m_waitingInstances.projectileEntities) do
        if l_entity.explosion ~= nil then
            self:CreateExplodeExplosionEntities(l_entity.explosion)
        end

        if l_entity.dudExplosion ~= nil then
            self:CreateExplodeExplosionEntities(l_entity.dudExplosion)
        end

        self:CreateProjectileEntities(l_entity)
    end

    for _, l_blueprint in pairs(self.m_waitingInstances.projectileBlueprints) do
        self:CreateProjectileBlueprints(l_blueprint)
    end

    for l_key, _ in pairs(self.m_projectilePhysicsProperties) do
        self:UpdateProjectilePhysicsPropertys(l_key)
    end

    --
    -- creating modifiers
    --

    for _, l_data in pairs(self.m_waitingInstances.projectileModifiers) do
        self:CreateWeaponProjectileModifiers(l_data)
    end

    for _, l_data in pairs(self.m_waitingInstances.firingModifiers) do
        self:CreateWeaponFiringFunctions(l_data.weaponFiring.primaryFire)
        self:CreateWeaponFirings(l_data.weaponFiring)
        self:CreateWeaponFiringModifiers(l_data)
    end

    --
    -- creating weapons
    --

    for _, l_entity in pairs(self.m_waitingInstances.weaponEntities) do
        self:CreateWeaponFiringFunctions(l_entity.weaponFiring.primaryFire)
        self:CreateWeaponFirings(l_entity.weaponFiring)
        self:CreateWeaponEntities(l_entity)
    end

    for _, l_blueprint in pairs(self.m_waitingInstances.weaponBlueprints) do
        self:CreateWeaponBlueprints(l_blueprint)
    end

    for _, l_asset in pairs(self.m_waitingInstances.weaponUnlockAssets) do
        self:CreateWeaponUnlockAssets(l_asset)
    end

    for _, l_entity in pairs(self.m_waitingInstances.weaponEntities) do
        self:UpdateWeaponUnlockAssets(l_entity)
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
        print('Created PolynomialColorInterps: ' .. InstanceUtils:Count(self.m_polynomialColorInterps))
        print('Created EmitterDocumentAssets: ' .. InstanceUtils:Count(self.m_emitterDocumentAssets))
        print('Created EmitterEntities: ' .. InstanceUtils:Count(self.m_emitterEntities))
        print('Created ImpactEffectBlueprints: ' .. InstanceUtils:Count(self.m_impactEffectBlueprints))
        print('Created ExplodeEffectBlueprints: ' .. InstanceUtils:Count(self.m_explodeEffectBlueprints))
        print('Created ImpactExplosionEntities: ' .. InstanceUtils:Count(self.m_impactExplosionEntities))
        print('Created ExplodeExplosionEntities: ' .. InstanceUtils:Count(self.m_explodeExplosionEntities))
        print('Created ProjectileEntities: ' .. InstanceUtils:Count(self.m_projectileEntities))
        print('Created ProjectileBlueprints: ' .. InstanceUtils:Count(self.m_projectileBlueprints))
        print('Created WeaponFiringFunctions: ' .. InstanceUtils:Count(self.m_weaponFiringFunctions))
        print('Created WeaponFirings: ' .. InstanceUtils:Count(self.m_weaponFirings))
        print('Created WeaponProjectileModifiers: ' .. InstanceUtils:Count(self.m_weaponProjectileModifiers))
        print('Created WeaponFiringModifiers: ' .. InstanceUtils:Count(self.m_weaponFiringModifiers))
        print('Created WeaponEntities: ' .. InstanceUtils:Count(self.m_weaponEntities))
        print('Created WeaponBlueprints: ' .. InstanceUtils:Count(self.m_weaponBlueprints))
        print('Created WeaponUnlockAssets: ' .. InstanceUtils:Count(self.m_weaponUnlockAssets))
        print('Created RegistryContainerAssets: ' .. InstanceUtils:Count(self.m_registryContainer.assetRegistry))
        print('Created RegistryContainerEntities: ' .. InstanceUtils:Count(self.m_registryContainer.entityRegistry))
        print('Created RegistryContainerBlueprints: ' .. InstanceUtils:Count(self.m_registryContainer.blueprintRegistry))
    end
end

-- creating PolynomialColorInterpData for EmitterDocument
function WeaponsUnlocks:CreatePolynomialColorInterps(p_data)
    if self.m_verbose >= 2 then
        print('Create PolynomialColorInterps')
    end

    local s_elements = {}
    s_elements['neutral'] = p_data

    for _, l_element in pairs(ElementalConfig.names) do
        s_elements[l_element] = {}

        local s_newRegularPolynomialColor = InstanceUtils:CloneInstance(p_data, l_element .. 'regular')
        local s_newSaturatedPolynomialColor = InstanceUtils:CloneInstance(p_data, l_element .. 'saturated')

        local s_color = ElementalConfig.colors[l_element]
        local s_saturated = Vec3(s_color.x * 8, s_color.y * 8, s_color.z * 8)

        s_newRegularPolynomialColor.color0 = s_color
        s_newRegularPolynomialColor.color1 = s_color

        s_newSaturatedPolynomialColor.color0 = s_saturated
        s_newSaturatedPolynomialColor.color1 = s_saturated

        s_elements[l_element]['regular'] = s_newRegularPolynomialColor
        s_elements[l_element]['saturated'] = s_newSaturatedPolynomialColor
    end

    self.m_polynomialColorInterps = s_elements
end

-- creating EmitterDocument for EmitterEntityData
function WeaponsUnlocks:_CreateEmitterDocumentAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create EmitterDocumentAsset')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_asset

    local function createProcessorData(p_data, p_element, p_emissive)
        local s_newProcessorData = InstanceUtils:CloneInstance(p_data, p_element)

        if s_newProcessorData.nextProcessor ~= nil then
            s_newProcessorData.nextProcessor = createProcessorData(s_newProcessorData.nextProcessor, p_element, p_emissive)
        end

        if s_newProcessorData:Is('UpdateColorData') then
            local s_polynomialColorInterp = self.m_polynomialColorInterps[p_element]['regular']
            if p_emissive then
                s_polynomialColorInterp = self.m_polynomialColorInterps[p_element]['saturated']
            end

            s_newProcessorData.pre = s_polynomialColorInterp
        end

        return s_newProcessorData
    end

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newEmitterDocumentAsset = InstanceUtils:CloneInstance(p_asset, l_element)
        local s_newTemplateData = InstanceUtils:CloneInstance(p_asset.templateData, l_element)

        -- non emissive smoke
        local s_emissive = true
        if
            s_newTemplateData.name:lower():match('smoke')
        then
            s_emissive = false
        end

        local s_color = ElementalConfig.colors[l_element]

        -- explode light radius
        local s_pointLightRadius = 10
        if s_newTemplateData.name:match('Metal_Smoke_01_M') then
            s_pointLightRadius = 30
        end

        -- creating processor with recursion
        local s_newTemplateRootProcessor = createProcessorData(s_newTemplateData.rootProcessor, l_element, s_emissive)
        local s_newDocumentRootProcessor = s_newTemplateRootProcessor

        -- low graphics processor
        if not s_newEmitterDocumentAsset.rootProcessor:Eq(s_newTemplateData.rootProcessor) then
            s_newDocumentRootProcessor = createProcessorData(s_newEmitterDocumentAsset.rootProcessor, l_element, s_emissive)
        end

        -- patching template properties
        s_newTemplateData.name = s_newTemplateData.name .. l_element
        s_newTemplateData.rootProcessor = s_newTemplateRootProcessor
        s_newTemplateData.emissive = s_emissive
        s_newTemplateData.actAsPointLight = true
        s_newTemplateData.pointLightRadius = s_pointLightRadius
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
function WeaponsUnlocks:_CreateEmitterEntity(p_entity)
    if self.m_verbose >= 2 then
        print('Create EmitterEntity')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    local emitterDocumentAsset = self:_GetInstance(p_entity.emitter, 'emitterDocumentAssets')

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newEmitterEntity = InstanceUtils:CloneInstance(p_entity, l_element)

        -- disable water spray arm
        if s_newEmitterEntity.emitter.name:match('Em_Impact_Water_S_SprayArm') then
            s_newEmitterEntity.spawnProbability = 0
        end

        -- patching emitter properties
        s_newEmitterEntity.emitter = emitterDocumentAsset[l_element]

        s_elements[l_element] = s_newEmitterEntity
    end

    self.m_emitterEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

-- creating EffectBlueprint
function WeaponsUnlocks:_CreateEffectBlueprint(p_blueprint, p_element)
    if self.m_verbose >= 2 then
        print('Create EffectBlueprints')
    end

    local s_newEffectBlueprint = InstanceUtils:CloneInstance(p_blueprint, p_element)
    local s_newEffectEntity = InstanceUtils:CloneInstance(s_newEffectBlueprint.object, p_element)

    for l_key, l_value in pairs(s_newEffectEntity.components) do
        if l_value:Is('EmitterEntityData') then
            -- patching effect components
            s_newEffectEntity.components[l_key] = self:_GetInstance(l_value, 'emitterEntities')[p_element]
        end
    end

    -- patching entity properties
    s_newEffectEntity.cullDistance = 0

    -- patching blueprint properties
    s_newEffectBlueprint.object = s_newEffectEntity

    return s_newEffectBlueprint
end

-- creating EffectEntity for VeniceExplosionEntityData
function WeaponsUnlocks:CreateImpactEffectBlueprints(p_blueprints)
    if self.m_verbose >= 2 then
        print('Create ImpactEffectBlueprints')
    end

    for _, l_element in pairs(ElementalConfig.names) do
        local s_effectBlueprint = p_blueprints[l_element]
        local s_newEffectBlueprint = self:_CreateEffectBlueprint(s_effectBlueprint, l_element)

        self.m_impactEffectBlueprints[l_element] = s_newEffectBlueprint
    end
end

-- creating EffectEntity for VeniceExplosionEntityData
function WeaponsUnlocks:CreateExplodeEffectBlueprints(p_blueprint)
    if self.m_verbose >= 2 then
        print('Create ExplodeEffectBlueprints')
    end

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newEffectBlueprint = self:_CreateEffectBlueprint(p_blueprint, l_element)

        local soundEffectEntity = SoundEffectEntityData(self.m_explodeSoundEffectEntity)
        EffectEntityData(s_newEffectBlueprint.object).components:add(soundEffectEntity)

        self.m_explodeEffectBlueprints[l_element] = s_newEffectBlueprint
    end
end

-- creating EffectEntity for VeniceExplosionEntityData
function WeaponsUnlocks:CreateSmokeEffectBlueprints(p_blueprint)
    if self.m_verbose >= 2 then
        print('Create SmokeEffectBlueprints')
    end

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newEffectBlueprint = self:_CreateEffectBlueprint(p_blueprint, l_element)

        self.m_smokeEffectBlueprints[l_element] = s_newEffectBlueprint
    end
end

-- creating VeniceExplosionEntityData for MeshProjectileEntityData
function WeaponsUnlocks:CreateImpactExplosionEntities(p_entity)
    if self.m_verbose >= 2 then
        print('Create ImpactExplosionEntities')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newExplosionEntity = InstanceUtils:CloneInstance(p_entity, 'impact' .. l_element)

        -- patching explosion properties
        s_newExplosionEntity.detonationEffect = self.m_impactEffectBlueprints[l_element]
        s_newExplosionEntity.blastDamage = 0
        s_newExplosionEntity.blastImpulse = 0
        s_newExplosionEntity.shockwaveDamage = 0
        s_newExplosionEntity.shockwaveImpulse = 0

        s_elements[l_element] = s_newExplosionEntity
    end

    self.m_impactExplosionEntities = s_elements
end

-- creating VeniceExplosionEntityData for MeshProjectileEntityData
function WeaponsUnlocks:CreateExplodeExplosionEntities(p_entity)
    if self.m_verbose >= 2 then
        print('Create ExplodeExplosionEntities')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newExplosionEntity = InstanceUtils:CloneInstance(p_entity, l_element)

        if s_newExplosionEntity.materialPair ~= nil then
            local s_materialContainerPairIndex = MaterialPairs[MaterialContainerPair(s_newExplosionEntity.materialPair).physicsPropertyIndex]
            s_newExplosionEntity.materialPair = self.m_materialContainerAsset.materialPairs[s_materialContainerPairIndex]
        end

        -- patching explosion properties
        s_newExplosionEntity.detonationEffect = self.m_explodeEffectBlueprints[l_element]

        s_elements[l_element] = s_newExplosionEntity
    end

    self.m_explodeExplosionEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

-- creating VeniceExplosionEntityData for MeshProjectileEntityData
function WeaponsUnlocks:CreateSmokeExplosionEntities(p_entity)
    if self.m_verbose >= 2 then
        print('Create SmokeExplosionEntities')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newExplosionEntity = InstanceUtils:CloneInstance(p_entity, 'smoke' .. l_element)

        -- patching explosion properties
        s_newExplosionEntity.detonationEffect = self.m_smokeEffectBlueprints[l_element]

        s_elements[l_element] = s_newExplosionEntity
    end

    self.m_smokeExplosionEntities = s_elements
end

-- creating ProjectileEntityData for ShotData and WeaponProjectileModifier
function WeaponsUnlocks:CreateProjectileEntities(p_entity)
    if self.m_projectileEntities[p_entity.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create ProjectileEntities')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    local s_isSmoke = p_entity.explosion ~= nil and p_entity.explosion.detonationEffect ~= nil and p_entity.explosion.detonationEffect.name:match('FX_40mm_Smoke')

    local s_materialPair = nil
    if p_entity.materialPair ~= nil then
        local s_physicsPropertyIndex = MaterialContainerPair(p_entity.materialPair).physicsPropertyIndex
        local s_materialContainerPairIndex = MaterialPairs[s_physicsPropertyIndex]

        s_materialPair = self.m_materialContainerAsset.materialPairs[s_materialContainerPairIndex]

        self.m_projectilePhysicsProperties[s_physicsPropertyIndex] = true
    end

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newProjectileEntity = InstanceUtils:CloneInstance(p_entity, l_element)

        local s_projectileExplosionEntity = nil
        if s_newProjectileEntity.explosion ~= nil then
            s_projectileExplosionEntity = self.m_explodeExplosionEntities[s_newProjectileEntity.explosion.instanceGuid:ToString('D')]
        end

        local s_missileExplosionEntity = nil
        if s_newProjectileEntity.dudExplosion ~= nil then
            s_missileExplosionEntity = self.m_explodeExplosionEntities[s_newProjectileEntity.dudExplosion.instanceGuid:ToString('D')]
        end

        -- non-explosive projectile
        if s_projectileExplosionEntity == nil and s_missileExplosionEntity == nil then
            s_newProjectileEntity.explosion = self.m_impactExplosionEntities[l_element]
        end

        -- explosive projectile
        if s_projectileExplosionEntity ~= nil then
            s_newProjectileEntity.explosion = s_projectileExplosionEntity[l_element]
        end

        -- missile projectile
        if s_missileExplosionEntity ~= nil then
            s_newProjectileEntity.dudExplosion = s_missileExplosionEntity[l_element]
        end

        -- smoke projectile
        if s_isSmoke then
            s_newProjectileEntity.explosion = self.m_smokeExplosionEntities[l_element]
        end

        -- patching projectile entity
        s_newProjectileEntity.materialPair = s_materialPair

        self.m_registryContainer.entityRegistry:add(s_newProjectileEntity)

        s_elements[l_element] = s_newProjectileEntity
    end

    self.m_projectileEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

-- creating ProjectileBlueprint for ShotData
function WeaponsUnlocks:CreateProjectileBlueprints(p_blueprint)
    if self.m_projectileBlueprints[p_blueprint.instanceGuid:ToString('D')] ~= nil then
        return
    end

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

        s_elements[l_element] = s_newProjectileBlueprint
    end

    self.m_projectileBlueprints[p_blueprint.instanceGuid:ToString('D')] = s_elements
end

-- creating FiringFunctionData
function WeaponsUnlocks:CreateWeaponFiringFunctions(p_data)
    if self.m_weaponFiringFunctions[p_data.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create FiringFunctions')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_data

    local s_projectileEntity = self.m_projectileEntities[p_data.shot.projectileData.instanceGuid:ToString('D')]

    local s_projectileBlueprint = nil
    if p_data.shot.projectile ~= nil then
        s_projectileBlueprint = self.m_projectileBlueprints[p_data.shot.projectile.instanceGuid:ToString('D')]
    end

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newFiringFunction = InstanceUtils:CloneInstance(p_data, l_element)

        -- patching firing function
        if s_projectileEntity ~= nil then
            s_newFiringFunction.shot.projectileData = s_projectileEntity[l_element]
        end

        if s_projectileBlueprint ~= nil then
            s_newFiringFunction.shot.projectile = s_projectileBlueprint[l_element]
        end

        s_elements[l_element] = s_newFiringFunction
    end

    self.m_weaponFiringFunctions[p_data.instanceGuid:ToString('D')] = s_elements
end

-- creating FiringData
function WeaponsUnlocks:CreateWeaponFirings(p_data)
    if self.m_weaponFirings[p_data.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create FiringDatas')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_data

    local s_firingFunction = self.m_weaponFiringFunctions[p_data.primaryFire.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newFiringData = InstanceUtils:CloneInstance(p_data, l_element)

        -- patching firing data
        s_newFiringData.primaryFire = s_firingFunction[l_element]

        s_elements[l_element] = s_newFiringData
    end

    self.m_weaponFirings[p_data.instanceGuid:ToString('D')] = s_elements
end

-- creating WeaponProjectileModifier for SoldierWeaponEntity
function WeaponsUnlocks:CreateWeaponProjectileModifiers(p_data)
    if self.m_weaponProjectileModifiers[p_data.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create WeaponProjectileModifiers')
    end

    local s_elements = {}
    s_elements['neutral'] = p_data

    local s_projectileEntity = self.m_projectileEntities[p_data.projectileData.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newWeaponProjectileModifier = InstanceUtils:CloneInstance(p_data, l_element)

        -- patching projectile modifier
        s_newWeaponProjectileModifier.projectileData = s_projectileEntity[l_element]

        s_elements[l_element] = s_newWeaponProjectileModifier
    end

    self.m_weaponProjectileModifiers[p_data.instanceGuid:ToString('D')] = s_elements
end

-- creating WeaponFiringDataModifier for SoldierWeaponEntity
function WeaponsUnlocks:CreateWeaponFiringModifiers(p_data)
    if self.m_weaponFiringModifiers[p_data.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create WeaponFiringModifiers')
    end

    local s_elements = {}
    s_elements['neutral'] = p_data

    local s_weaponFiring = self.m_weaponFirings[p_data.weaponFiring.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newFiringModifier = InstanceUtils:CloneInstance(p_data, l_element)

        -- patching firing modifier
        s_newFiringModifier.weaponFiring = s_weaponFiring[l_element]

        s_elements[l_element] = s_newFiringModifier
    end

    self.m_weaponFiringModifiers[p_data.instanceGuid:ToString('D')] = s_elements
end

-- creating SoldierWeaponData for SoldierWeaponBlueprint
function WeaponsUnlocks:CreateWeaponEntities(p_entity)
    if self.m_weaponEntities[p_entity.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create WeaponEntities')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    local function patchModifiers(p_weaponEntity, p_element)
        for l_key, l_value in pairs(p_weaponEntity.weaponModifierData) do
            for ll_key, ll_value in pairs(l_value.modifiers) do
                if ll_value:Is('WeaponProjectileModifier') then
                    local s_weaponProjectileModifier = self.m_weaponProjectileModifiers[ll_value.instanceGuid:ToString('D')][p_element]
                    p_weaponEntity.weaponModifierData[l_key].modifiers[ll_key] = s_weaponProjectileModifier
                elseif ll_value:Is('WeaponFiringDataModifier') then
                    local s_weaponFiringModifier = self.m_weaponFiringModifiers[ll_value.instanceGuid:ToString('D')][p_element]
                    p_weaponEntity.weaponModifierData[l_key].modifiers[ll_key] = s_weaponFiringModifier
                end
            end
        end
    end

    local s_weaponFiring = self.m_weaponFirings[p_entity.weaponFiring.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newWeaponEntity = InstanceUtils:CloneInstance(p_entity, l_element)

        -- patching weapon modifiers
        patchModifiers(s_newWeaponEntity, l_element)

        -- patching weapon entity
        s_newWeaponEntity.weaponFiring = s_weaponFiring[l_element]
        s_newWeaponEntity.damageGiverName = l_element

        s_elements[l_element] = s_newWeaponEntity
    end

    self.m_weaponEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

-- creating SoldierWeaponBlueprint for SoldierWeaponUnlockAsset
function WeaponsUnlocks:CreateWeaponBlueprints(p_blueprint)
    if self.m_weaponBlueprints[p_blueprint.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create WeaponBlueprints')
    end

    local s_elements = {}
    s_elements['neutral'] = p_blueprint

    local s_entityGuid = p_blueprint.object.instanceGuid:ToString('D')
    for _, l_element in pairs(ElementalConfig.names) do
        local s_newWeaponBlueprint = InstanceUtils:CloneInstance(p_blueprint, l_element)

        -- patching weapon blueprint
        s_newWeaponBlueprint.object = self.m_weaponEntities[s_entityGuid][l_element]

        -- patching weapon entity
        self.m_weaponEntities[s_entityGuid][l_element].soldierWeaponBlueprint = s_newWeaponBlueprint

        self.m_registryContainer.blueprintRegistry:add(s_newWeaponBlueprint)

        s_elements[l_element] = s_newWeaponBlueprint
    end

    self.m_weaponBlueprints[p_blueprint.instanceGuid:ToString('D')] = s_elements
end

-- creating SoldierWeaponUnlockAsset
function WeaponsUnlocks:CreateWeaponUnlockAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create WeaponUnlockAssets')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_asset

    local s_blueprintGuid = p_asset.weapon.instanceGuid:ToString('D')
    for _, l_element in pairs(ElementalConfig.names) do
        local s_newWeaponUnlockAsset = InstanceUtils:CloneInstance(p_asset, l_element)

        -- patching unlock
        s_newWeaponUnlockAsset.name = s_newWeaponUnlockAsset.name .. l_element
        s_newWeaponUnlockAsset.weapon = self.m_weaponBlueprints[s_blueprintGuid][l_element]

        self.m_registryContainer.assetRegistry:add(s_newWeaponUnlockAsset)

        s_elements[l_element] = s_newWeaponUnlockAsset
    end

    self.m_weaponUnlockAssets[p_asset.instanceGuid:ToString('D')] = s_elements
end

-- replacing MaterialRelationPenetrationData
function WeaponsUnlocks:UpdateProjectilePhysicsPropertys(p_index)
    if self.m_verbose >= 2 then
        print('Update ProjectilePhysicsPropertys')
    end

    local s_propertyIndex = p_index + 1
    if s_propertyIndex < 0 then
        s_propertyIndex = 256 + s_propertyIndex
    end

    local s_gridPropertyIndex = self.m_materialGridAsset.materialIndexMap[s_propertyIndex] + 1
    local s_materialInteractionGridRow = self.m_materialGridAsset.interactionGrid[s_gridPropertyIndex]

    for _, l_value in pairs(self.m_soldierGridPropertyIndexes) do
        local s_materialRelationPropertyPair = s_materialInteractionGridRow.items[l_value]

        local s_hasRelationPenetration = false

        for ll_key, ll_value in pairs(s_materialRelationPropertyPair.physicsPropertyProperties) do
            if ll_value:Is('MaterialRelationPenetrationData') then
                if MaterialRelationPenetrationData(ll_value).neverPenetrate then
                    s_hasRelationPenetration = true
                else
                    s_materialRelationPropertyPair.physicsPropertyProperties:erase(ll_key)
                end
            end
        end

        if not s_hasRelationPenetration then
            s_materialRelationPropertyPair.physicsPropertyProperties:add(self.m_projectileMaterialRelationPenetrationData)
        end
    end
end

-- replacing WeaponUnlockAsset
function WeaponsUnlocks:UpdateWeaponUnlockAssets(p_entity)
    if self.m_verbose >= 2 then
        print('Update WeaponUnlockAssets')
    end

    local s_weaponEntityGuid = p_entity.instanceGuid:ToString('D')

    for l_key, l_value in pairs(p_entity.weaponModifierData) do
        if l_value.unlockAsset ~= nil and l_value.unlockAsset:Is('SoldierWeaponUnlockAsset') then
            local s_soldierWeaponUnlockGuid = l_value.unlockAsset.instanceGuid:ToString('D')
            for _, l_element in pairs(ElementalConfig.names) do
                local s_weaponUnlockAsset = self.m_weaponUnlockAssets[s_soldierWeaponUnlockGuid][l_element]
                self.m_weaponEntities[s_weaponEntityGuid][l_element].weaponModifierData[l_key].unlockAsset = s_weaponUnlockAsset
            end
        end
    end
end

-- getting custom unlocks
function WeaponsUnlocks:GetUnlockAssets(p_weapons, p_element, p_secondary)
    local s_unlocks = {}

    for l_key, l_value in pairs(p_weapons) do
        local s_unlockAsset = nil

        local s_element = p_element
        if l_key == 2 then
            s_element = p_secondary
        end

        if l_value ~= nil then
            local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(l_value)
            s_unlockAsset = self.m_weaponUnlockAssets[s_weaponUnlockAsset.instanceGuid:ToString('D')]

            if s_element == 'neutral' then
                s_unlockAsset = s_weaponUnlockAsset
            else
                s_unlockAsset = s_unlockAsset[s_element]
            end
        end

        s_unlocks[l_key] = s_unlockAsset
    end

    return s_unlocks
end

-- creating missing instances
function WeaponsUnlocks:_GetInstance(p_instance, p_type)
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

return WeaponsUnlocks