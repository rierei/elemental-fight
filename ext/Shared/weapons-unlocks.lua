local WeaponsUnlocks = class('WeaponsUnlocks')

local MaterialPairs = require('__shared/utils/consts').materialPairs
local Uuid = require('__shared/utils/uuid')
local InstanceWait = require('__shared/utils/wait')

function WeaponsUnlocks:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function WeaponsUnlocks:RegisterVars()
    self.m_elementNames = {'water', 'grass', 'fire'}

    self.m_elementColors = {
        water = Vec3(0, 0.6, 1),
        grass = Vec3(0.2, 0.6, 0.1),
        fire = Vec3(1, 0.3, 0)
    }

    self.m_soldierPropertyIndexes = {
        head = 66,
        body = 67,
        foot = 92,
        chest = 159
    }

    self.m_soldierGridPropertyIndexes = {
        head = nil,
        body = nil,
        foot = nil,
        chest = nil
    }

    self.m_waitingImpactEffectGuids = {
        FX_Impact_Water_S = {'20B18CF1-F2F7-11DF-9BE8-9E0183D704DD', '23298636-5C6F-8CA0-F0EF-6097924181C3'},
        FX_Impact_Foliage_Generic_S_01 = {'6C1A14FF-83C9-410E-A7D0-4FD024EBE33A', '06E4F5D2-5883-46A0-B898-2A21E8BFEEDA'},
        FX_Impact_Metal_01_S = {'29C86406-1ED5-11DE-A58E-D687F51B0F2D', '29C86407-1ED5-11DE-A58E-D687F51B0F2D'}
    }

    self.m_waitingCommonGuids = {
        MaterialContainer = {'B50615C2-4743-4919-9A40-A738150DEBE9', '89492CD4-F004-42B9-97FB-07FD3D436205'}, -- materialContainerAsset

        FX_Impact_Concrete_01_S = {'CE89593E-1D2F-11DE-A872-CA8439DC4744', 'CE89593F-1D2F-11DE-A872-CA8439DC4744'}, -- genericImpactEffectBlueprint
        FX_Grenade_Frag_01 = {'A6C980C2-1578-4169-81CB-C62AC369590E', 'FAFA506C-816A-4339-B108-3E957F48AE2D'}, -- genericExplodeEffectBlueprint

        Em_Impact_Generic_S_Sparks_01 = {'1F6B1EB2-86E3-473C-8E25-A24989538600', '1A0C5373-3DC4-4967-89A3-A6D53AD8A58F'}, -- dummyExplosionEntity
        M224_Projectile_Smoke = {'7C592ADA-6915-4969-BFF2-A875027A9962', 'A7E5A920-FA8C-4511-AA6C-CAF00C967C3E'}, -- dummyPolynomialColor

        FX_Grenade_Frag_01_Sound = {'A6C980C2-1578-4169-81CB-C62AC369590E', '41A352A8-783E-41E6-9B3E-989D473DB953'}, -- explodeSoundEffectEntity
        FX_40mm_Smoke = {' 6A2C27D9-D455-458D-A542-C212C6F8F69C', '00C3D2F9-1346-47B8-956D-10CC23AD8B4D'}, -- smokeEffectBlueprint
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
        weaponUnlockAssets = {} -- SoldierWeaponUnlockAsset
    }

    self.m_registryContainer = nil -- RegistryContainer
    self.m_materialContainerAsset = nil -- MaterialContainerAsset
    self.m_materialGridAsset = nil -- MaterialGridData
    self.m_explodeSoundEffect = nil -- SoundEffectEntityData

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
    self.m_weaponProjectileModifiers = {} -- WeaponProjectileModifier
    self.m_weaponFiringModifiers = {} -- WeaponFiringDataModifier
    self.m_weaponEntities = {} -- SoldierWeaponData
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint
    self.m_weaponUnlockAssets = {} -- SoldierWeaponUnlockAsset

    self.m_projectilePhysicsProperties = {} -- MaterialContainerPair.PhysicsPropertyIndex
    self.m_projectileMaterialRelationPenetrationData = nil -- MaterialRelationPenetrationData

    self.m_currentLevel = nil
    self.m_currentMode = nil

    self.m_instanceCreateFunctions = {
        emitterDocumentAssets = self._CreateEmitterDocumentAssets,
        emitterEntities = self._CreateEmitterEntity,
        explodeExplosionEntities = self._CreateExplodeExplosionEntities,
        projectileEntities = self.CreateProjectileEntities,
        projectileBlueprints = self._CreateProjectileBlueprints,
        weaponProjectileModifiers = self._CreateWeaponProjectileModifiers,
        weaponFiringModifiers = self._CreateWeaponFiringModifiers
    }

    self.m_verbose = 1 -- prints debug information
end

function WeaponsUnlocks:RegisterEvents()
    -- waiting weapon unlocks
    Events:Subscribe('Partition:Loaded', function(p_partition)
        for _, l_instance in pairs(p_partition.instances) do
            if l_instance:Is('SoldierWeaponUnlockAsset') then
                if self.m_verbose >= 2 then
                    print('Found WeaponUnlockAsset')
                end

                table.insert(self.m_waitingInstances.weaponUnlockAssets, l_instance)
            end
        end
    end)

    -- waiting material grid
    Events:Subscribe('Partition:Loaded', function(p_partition)
        for _, l_instance in pairs(p_partition.instances) do
            if l_instance:Is('MaterialGridData') then
                if self.m_verbose >= 1 then
                    print('Found MaterialGridData')
                end

                self.m_waitingInstances.materialGridAsset = l_instance
            end
        end
    end)

    -- reading instances after level load
    Events:Subscribe('Level:Loaded', function(p_level, p_mode)
        if self.m_verbose >= 1 then
            print('Level:Loaded')
        end

        if self.m_currentLevel == nil then
            self:RegisterWait()
        elseif self.m_currentLevel ~= p_level or self.m_currentMode ~= p_mode then
            self:ReloadInstances()
        else
            ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)
        end

        self.m_currentLevel = p_level
        self.m_currentMode = p_mode
    end)
end

function WeaponsUnlocks:RegisterWait()
    -- waiting impact effects
    InstanceWait(self.m_waitingImpactEffectGuids, function(p_instances)
        self.m_waitingInstances.impactEffectBlueprints['water'] = p_instances['FX_Impact_Water_S']
        self.m_waitingInstances.impactEffectBlueprints['grass'] = p_instances['FX_Impact_Foliage_Generic_S_01']
        self.m_waitingInstances.impactEffectBlueprints['fire'] = p_instances['FX_Impact_Metal_01_S']
    end)

    -- waiting common instances
    InstanceWait(self.m_waitingCommonGuids, function(p_instances)
        self:ReadInstances(p_instances)
    end)
end

-- reseting created instances
function WeaponsUnlocks:ReloadInstances()
    if self.m_verbose >= 1 then
        print('Reloading Instances')
    end

    self.m_registryContainer = nil -- RegistryContainer
    self.m_weaponUnlockAssets = {} -- SoldierWeaponUnlockAsset

    self:RegisterWait()
end

-- reading waiting instances
function WeaponsUnlocks:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    self.m_materialGridAsset = MaterialGridData(self.m_waitingInstances.materialGridAsset)
    self.m_materialGridAsset:MakeWritable()

    local s_shotgunGridPropertyIndex = self.m_materialGridAsset.materialIndexMap[89] + 1
    local s_headGridPropertyIndex = self.m_materialGridAsset.materialIndexMap[66] + 1

    -- finding MaterialRelationPenetrationData from shotgun
    local s_shotgunMaterialInteractionGridRow = self.m_materialGridAsset.interactionGrid[s_shotgunGridPropertyIndex].items[s_headGridPropertyIndex]
    for _, l_value in pairs(s_shotgunMaterialInteractionGridRow.physicsPropertyProperties) do
        if l_value:Is('MaterialRelationPenetrationData') then
            self.m_projectileMaterialRelationPenetrationData = MaterialRelationPenetrationData(l_value)
        end
    end

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

    for _, l_element in pairs(self.m_elementNames) do
        if self.m_waitingInstances.impactEffectBlueprints[l_element] == nil then
            if self.m_verbose >= 1 then
                print('Apply GenericImpactEffectBlueprint')
            end

            self.m_waitingInstances.impactEffectBlueprints[l_element] = self.m_waitingInstances.genericImpactEffectBlueprint
        end
    end

    self:CreateInstances()

    -- removing hanging references
    self.m_waitingInstances = {
        impactEffectBlueprints = {}, -- EffectBlueprint
        explodeEffectBlueprint = nil, -- EffectBlueprint
        smokeEffectBlueprint = nil, -- EffectBlueprint

        genericImpactEffectBlueprint = nil, -- EffectBlueprint

        dummyPolynomialColor = nil, -- PolynomialColorInterpData
        dummyExplosionEntity = nil, -- VeniceExplosionEntityData

        materialGridAsset = nil, -- MaterialGridData
        weaponUnlockAssets = {} -- SoldierWeaponUnlockAsset
    }

    -- removing hanging references
    self.m_explodeSoundEffect = nil -- SoundEffectEntityData
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
    self.m_weaponProjectileModifiers = {} -- WeaponProjectileModifier
    self.m_weaponFiringModifiers = {} -- WeaponFiringDataModifier
    self.m_weaponEntities = {} -- SoldierWeaponData
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint

    self.m_projectilePhysicsProperties = {} -- MaterialContainerPair.PhysicsPropertyIndex
    self.m_projectileMaterialRelationPenetrationData = nil -- MaterialRelationPenetrationData
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

    for _, l_asset in pairs(self.m_waitingInstances.weaponUnlockAssets) do
        local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(l_asset)
        local s_weaponBlueprint = SoldierWeaponBlueprint(s_weaponUnlockAsset.weapon)
        local s_weaponEntity = SoldierWeaponData(s_weaponBlueprint.object)
        local s_projectileEntity = ProjectileEntityData(s_weaponEntity.weaponFiring.primaryFire.shot.projectileData)

        self:CreateProjectileEntities(s_projectileEntity)
        self:CreateWeaponEntities(s_weaponEntity)
        self:CreateWeaponBlueprints(s_weaponBlueprint)
        self:CreateWeaponUnlockAssets(s_weaponUnlockAsset)
    end

    for l_key, _ in pairs(self.m_projectilePhysicsProperties) do
        self:UpdateProjectilePhysicsPropertys(l_key)
    end

    for _, l_asset in pairs(self.m_waitingInstances.weaponUnlockAssets) do
        local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(l_asset)
        local s_weaponBlueprint = SoldierWeaponBlueprint(s_weaponUnlockAsset.weapon)
        local s_weaponEntity = SoldierWeaponData(s_weaponBlueprint.object)

        self:UpdateWeaponUnlockAssets(s_weaponEntity)
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
        print('Created PolynomialColorInterps: ' .. self:_Count(self.m_polynomialColorInterps))
        print('Created EmitterDocumentAssets: ' .. self:_Count(self.m_emitterDocumentAssets))
        print('Created EmitterEntities: ' .. self:_Count(self.m_emitterEntities))
        print('Created ImpactEffectBlueprints: ' .. self:_Count(self.m_impactEffectBlueprints))
        print('Created ExplodeEffectBlueprints: ' .. self:_Count(self.m_explodeEffectBlueprints))
        print('Created ImpactExplosionEntities: ' .. self:_Count(self.m_impactExplosionEntities))
        print('Created ExplodeExplosionEntities: ' .. self:_Count(self.m_explodeExplosionEntities))
        print('Created ProjectileEntities: ' .. self:_Count(self.m_projectileEntities))
        print('Created ProjectileBlueprints: ' .. self:_Count(self.m_projectileBlueprints))
        print('Created WeaponProjectileModifiers: ' .. self:_Count(self.m_weaponProjectileModifiers))
        print('Created WeaponFiringModifiers: ' .. self:_Count(self.m_weaponFiringModifiers))
        print('Created WeaponEntities: ' .. self:_Count(self.m_weaponEntities))
        print('Created WeaponBlueprints: ' .. self:_Count(self.m_weaponBlueprints))
        print('Created WeaponUnlockAssets: ' .. self:_Count(self.m_weaponUnlockAssets))
        print('Created RegistryContainerAssets: ' .. self:_Count(self.m_registryContainer.assetRegistry))
        print('Created RegistryContainerEntities: ' .. self:_Count(self.m_registryContainer.entityRegistry))
        print('Created RegistryContainerBlueprints: ' .. self:_Count(self.m_registryContainer.blueprintRegistry))
    end
end

-- creating PolynomialColorInterpData for EmitterDocument
function WeaponsUnlocks:CreatePolynomialColorInterps(p_data)
    if self.m_verbose >= 2 then
        print('Create PolynomialColorInterps')
    end

    local s_elements = {}
    s_elements['neutral'] = p_data

    for _, l_element in pairs(self.m_elementNames) do
        local s_newPolynomialColor = self:_CloneInstance(p_data, l_element)

        s_newPolynomialColor.color0 = self.m_elementColors[l_element]
        s_newPolynomialColor.color1 = self.m_elementColors[l_element]

        s_elements[l_element] = s_newPolynomialColor
    end

    self.m_polynomialColorInterps = s_elements
end

-- creating EmitterDocument for EmitterEntityData
function WeaponsUnlocks:_CreateEmitterDocumentAssets(p_asset)
    if self.m_verbose >= 2 then
        print('Create EmitterDocumentAsset')
    end

    local s_elements = {}
    s_elements['neutral'] = p_asset

    for _, l_element in pairs(self.m_elementNames) do
        local s_newEmitterDocumentAsset = self:_CloneInstance(p_asset, l_element)
        local s_newTemplateData = self:_CloneInstance(p_asset.templateData, l_element)

        local s_updateColor = nil
        local function createProcessorData(p_data)
            local s_newProcessorData = self:_CloneInstance(p_data, l_element)

            if s_newProcessorData.nextProcessor ~= nil then
                s_newProcessorData.nextProcessor = createProcessorData(s_newProcessorData.nextProcessor)
            end

            if s_newProcessorData.pre ~= nil then
                s_newProcessorData.pre = createProcessorData(s_newProcessorData.pre)
            end

            if s_newProcessorData:Is('UpdateColorData') then
                local s_color = self.m_elementColors[l_element]

                -- increment color visibility
                s_color = Vec3(s_color.x * 8, s_color.y * 8, s_color.z * 8)

                local polynomialColorInterp = nil

                -- dont use incremented visibility for smoke
                if s_newProcessorData.pre ~= nil and not s_newEmitterDocumentAsset.name:lower():match('smoke') then
                    polynomialColorInterp = PolynomialColorInterpData(s_newProcessorData.pre)

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
        if s_newEmitterDocumentAsset.rootProcessor ~= s_newTemplateRootProcessor then
            s_newDocumentRootProcessor = createProcessorData(s_newEmitterDocumentAsset.rootProcessor)
        end

        -- non emissive smoke
        local s_emissive = true
        if s_newTemplateData.name:lower():match('smoke') then
            s_emissive = false
        end

        -- explode light radius
        local s_pointLightRadius = 10
        if s_newTemplateData.name:match('Metal_Smoke_01_M') then
            s_pointLightRadius = 30
        end

        -- patching template properties
        s_newTemplateData.name = s_newTemplateData.name .. l_element
        s_newTemplateData.rootProcessor = s_newTemplateRootProcessor
        s_newTemplateData.emissive = s_emissive
        s_newTemplateData.actAsPointLight = true
        s_newTemplateData.pointLightRadius = s_pointLightRadius
        s_newTemplateData.pointLightColor = self.m_elementColors[l_element]
        s_newTemplateData.maxSpawnDistance = 0

        -- patching document properties
        s_newEmitterDocumentAsset.name = s_newEmitterDocumentAsset.name .. l_element
        s_newEmitterDocumentAsset.rootProcessor = s_newDocumentRootProcessor
        s_newEmitterDocumentAsset.templateData = s_newTemplateData

        self.m_registryContainer.assetRegistry:add(s_newEmitterDocumentAsset)

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

    for _, l_element in pairs(self.m_elementNames) do
        local s_newEmitterEntity = self:_CloneInstance(p_entity, l_element)

        -- disable water spray arm
        if s_newEmitterEntity.emitter.name:match('Em_Impact_Water_S_SprayArm') then
            s_newEmitterEntity.spawnProbability = 0
        end

        -- patching emitter properties
        s_newEmitterEntity.emitter = emitterDocumentAsset[l_element]

        self.m_registryContainer.entityRegistry:add(s_newEmitterEntity)

        s_elements[l_element] = s_newEmitterEntity
    end

    self.m_emitterEntities[p_entity.instanceGuid:ToString('D')] = s_elements
end

-- creating EffectBlueprint
function WeaponsUnlocks:_CreateEffectBlueprint(p_blueprint, p_element)
    if self.m_verbose >= 2 then
        print('Create EffectBlueprints')
    end

    local s_newEffectBlueprint = self:_CloneInstance(p_blueprint, p_element)
    local s_newEffectEntity = self:_CloneInstance(s_newEffectBlueprint.object, p_element)

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

    self.m_registryContainer.entityRegistry:add(s_newEffectEntity)
    self.m_registryContainer.blueprintRegistry:add(s_newEffectBlueprint)

    return s_newEffectBlueprint
end

-- creating EffectEntity for VeniceExplosionEntityData
function WeaponsUnlocks:CreateImpactEffectBlueprints(p_blueprints)
    if self.m_verbose >= 2 then
        print('Create ImpactEffectBlueprints')
    end

    for l_element, l_blueprint in pairs(p_blueprints) do
        local s_newEffectBlueprint = self:_CreateEffectBlueprint(l_blueprint, l_element)

        self.m_impactEffectBlueprints[l_element] = s_newEffectBlueprint
    end
end

-- creating EffectEntity for VeniceExplosionEntityData
function WeaponsUnlocks:CreateExplodeEffectBlueprints(p_blueprint)
    if self.m_verbose >= 2 then
        print('Create ExplodeEffectBlueprints')
    end

    for _, l_element in pairs(self.m_elementNames) do
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

    for _, l_element in pairs(self.m_elementNames) do
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

    for _, l_element in pairs(self.m_elementNames) do
        local s_newExplosionEntity = self:_CloneInstance(p_entity, 'impact' .. l_element)

        -- patching explosion properties
        s_newExplosionEntity.detonationEffect = self.m_impactEffectBlueprints[l_element]
        s_newExplosionEntity.blastDamage = 0
        s_newExplosionEntity.shockwaveDamage = 0

        self.m_registryContainer.entityRegistry:add(s_newExplosionEntity)

        s_elements[l_element] = s_newExplosionEntity
    end

    self.m_impactExplosionEntities = s_elements
end

-- creating VeniceExplosionEntityData for MeshProjectileEntityData
function WeaponsUnlocks:_CreateExplodeExplosionEntities(p_entity)
    if self.m_verbose >= 2 then
        print('Create ExplodeExplosionEntities')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entity

    for _, l_element in pairs(self.m_elementNames) do
        local s_newExplosionEntity = self:_CloneInstance(p_entity, l_element)

        if s_newExplosionEntity.materialPair ~= nil then
            local s_materialContainerPairIndex = MaterialPairs[MaterialContainerPair(s_newExplosionEntity.materialPair).physicsPropertyIndex]
            s_newExplosionEntity.materialPair = self.m_materialContainerAsset.materialPairs[s_materialContainerPairIndex]
        end

        -- patching explosion properties
        s_newExplosionEntity.detonationEffect = self.m_explodeEffectBlueprints[l_element]

        self.m_registryContainer.entityRegistry:add(s_newExplosionEntity)

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

    for _, l_element in pairs(self.m_elementNames) do
        local s_newExplosionEntity = self:_CloneInstance(p_entity, 'smoke' .. l_element)

        -- patching explosion properties
        s_newExplosionEntity.detonationEffect = self.m_smokeEffectBlueprints[l_element]

        self.m_registryContainer.entityRegistry:add(s_newExplosionEntity)

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

    for _, l_element in pairs(self.m_elementNames) do
        local s_newProjectileEntity = self:_CloneInstance(p_entity, l_element)

        local s_projectileExplosionEntity = self:_GetInstance(s_newProjectileEntity.explosion, 'explodeExplosionEntities')
        local s_missileExplosionEntity = self:_GetInstance(s_newProjectileEntity.dudExplosion, 'explodeExplosionEntities')

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
function WeaponsUnlocks:_CreateProjectileBlueprints(p_blueprint)
    if self.m_projectileBlueprints[p_blueprint.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create ProjectileBlueprints')
    end

    local s_elements = {}
    s_elements['neutral'] = p_blueprint

    local s_projectileEntity = self:_GetInstance(p_blueprint.object, 'projectileEntities')

    for _, l_element in pairs(self.m_elementNames) do
        local s_newProjectileBlueprint = self:_CloneInstance(p_blueprint, l_element)

        -- patching projectile blueprint
        s_newProjectileBlueprint.object = s_projectileEntity[l_element]

        self.m_registryContainer.blueprintRegistry:add(s_newProjectileBlueprint)

        s_elements[l_element] = s_newProjectileBlueprint
    end

    self.m_projectileBlueprints[p_blueprint.instanceGuid:ToString('D')] = s_elements
end

-- creating WeaponProjectileModifier for SoldierWeaponEntity
function WeaponsUnlocks:_CreateWeaponProjectileModifiers(p_data)
    if self.m_weaponProjectileModifiers[p_data.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create WeaponProjectileModifiers')
    end

    local s_elements = {}
    s_elements['neutral'] = p_data

    local s_projectileEntity = self:_GetInstance(p_data.projectileData, 'projectileEntities')

    for _, l_element in pairs(self.m_elementNames) do
        local s_newWeaponProjectileModifier = self:_CloneInstance(p_data, l_element)

        -- patching projectile modifier
        s_newWeaponProjectileModifier.projectileData = s_projectileEntity[l_element]

        s_elements[l_element] = s_newWeaponProjectileModifier
    end

    self.m_weaponProjectileModifiers[p_data.instanceGuid:ToString('D')] = s_elements
end

-- creating WeaponFiringDataModifier for SoldierWeaponEntity
function WeaponsUnlocks:_CreateWeaponFiringModifiers(p_data)
    if self.m_weaponFiringModifiers[p_data.instanceGuid:ToString('D')] ~= nil then
        return
    end

    if self.m_verbose >= 2 then
        print('Create WeaponFiringModifiers')
    end

    local s_elements = {}
    s_elements['neutral'] = p_data

    local s_firingFunction = p_data.weaponFiring.primaryFire
    local s_firingData = p_data.weaponFiring

    local s_projectileEntity = self:_GetInstance(s_firingFunction.shot.projectileData, 'projectileEntities')
    local s_projectileBlueprint = self:_GetInstance(s_firingFunction.shot.projectile, 'projectileBlueprints')
    for _, l_element in pairs(self.m_elementNames) do
        local s_newFiringFunction = self:_CloneInstance(s_firingFunction, l_element)
        local s_newModifierFiringData = self:_CloneInstance(s_firingData, l_element)
        local s_newFiringModifier = self:_CloneInstance(p_data, l_element)

        -- patching firing function
        s_newFiringFunction.shot.projectileData = s_projectileEntity[l_element]
        s_newFiringFunction.ammo.magazineCapacity = 100 -- TESTING

        if s_projectileBlueprint ~= nil then
            s_newFiringFunction.shot.projectile = s_projectileBlueprint[l_element]
        end

        -- patching firing data
        s_newModifierFiringData.primaryFire = s_newFiringFunction

        -- patching firing modifier
        s_newFiringModifier.weaponFiring = s_newModifierFiringData

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

    local s_firingFunction = p_entity.weaponFiring.primaryFire
    local s_firingData = p_entity.weaponFiring

    local s_elements = {}
    s_elements['neutral'] = p_entity

    local function patchModifiers(p_weaponEntity, p_element)
        for l_key, l_value in pairs(p_weaponEntity.weaponModifierData) do
            for ll_key, ll_value in pairs(l_value.modifiers) do
                if ll_value:Is('WeaponProjectileModifier') then
                    local s_weaponProjectileModifier = self:_GetInstance(ll_value, 'weaponProjectileModifiers')
                    p_weaponEntity.weaponModifierData[l_key].modifiers[ll_key] = s_weaponProjectileModifier[p_element]
                elseif ll_value:Is('WeaponFiringDataModifier') then
                    local s_weaponFiringModifier = self:_GetInstance(ll_value, 'weaponFiringModifiers')
                    p_weaponEntity.weaponModifierData[l_key].modifiers[ll_key] = s_weaponFiringModifier[p_element]
                end
            end
        end
    end

    local s_projectileBlueprint = self:_GetInstance(s_firingFunction.shot.projectile, 'projectileBlueprints')
    local s_projectileEntity = self.m_projectileEntities[p_entity.weaponFiring.primaryFire.shot.projectileData.instanceGuid:ToString('D')]
    for _, l_element in pairs(self.m_elementNames) do
        local s_newFiringFunction = self:_CloneInstance(s_firingFunction, l_element)
        local s_newFiringData = self:_CloneInstance(s_firingData, l_element)
        local s_newWeaponEntity = self:_CloneInstance(p_entity, l_element)

        -- patching FiringData
        s_newFiringFunction.shot.projectileData = s_projectileEntity[l_element]
        s_newFiringFunction.ammo.magazineCapacity = 100 -- TESTING

        if s_projectileBlueprint ~= nil then
            s_newFiringFunction.shot.projectile = s_projectileBlueprint[l_element]
        end

        -- patching weapon modifiers
        patchModifiers(s_newWeaponEntity, l_element)

        -- patching firing data
        s_newFiringData.primaryFire = s_newFiringFunction

        -- patching weapon entity
        s_newWeaponEntity.weaponFiring = s_newFiringData
        s_newWeaponEntity.damageGiverName = l_element

        self.m_registryContainer.entityRegistry:add(s_newWeaponEntity)

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
    for _, l_element in pairs(self.m_elementNames) do
        local s_newWeaponBlueprint = self:_CloneInstance(p_blueprint, l_element)

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

    local s_elementUnlocks = {}
    -- s_elementUnlocks['neutral'] = p_asset -- hanging instance

    local s_blueprintGuid = p_asset.weapon.instanceGuid:ToString('D')
    for _, l_element in pairs(self.m_elementNames) do
        local s_newWeaponUnlockAsset = self:_CloneInstance(p_asset, l_element)

        -- patching unlock
        s_newWeaponUnlockAsset.name = s_newWeaponUnlockAsset.name .. l_element
        s_newWeaponUnlockAsset.weapon = self.m_weaponBlueprints[s_blueprintGuid][l_element]

        self.m_registryContainer.assetRegistry:add(s_newWeaponUnlockAsset)

        s_elementUnlocks[l_element] = s_newWeaponUnlockAsset
    end

    self.m_weaponUnlockAssets[p_asset.instanceGuid:ToString('D')] = s_elementUnlocks
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
            for _, l_element in pairs(self.m_elementNames) do
                local s_weaponUnlockAsset = self.m_weaponUnlockAssets[s_soldierWeaponUnlockGuid][l_element]
                self.m_weaponEntities[s_weaponEntityGuid][l_element].weaponModifierData[l_key].unlockAsset = s_weaponUnlockAsset
            end
        end
    end
end

-- getting custom unlocks
function WeaponsUnlocks:GetUnlockAssets(p_player, p_element)
    local s_unlocks = {}

    for l_key, l_value in pairs(p_player.weapons) do
        local s_unlockAsset = nil

        if l_value ~= nil then
            local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(l_value)
            s_unlockAsset = self.m_weaponUnlockAssets[s_weaponUnlockAsset.instanceGuid:ToString('D')][p_element]
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

-- cloning the instance and adding to partition
function WeaponsUnlocks:_CloneInstance(p_instance, p_variation)
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
function WeaponsUnlocks:_GenerateGuid(p_seed)
    Uuid.randomseed(MathUtils:FNVHash(p_seed))
    return Guid(Uuid())
end

-- counting table elements
function WeaponsUnlocks:_Count(p_table)
    local s_count = 0

    for _, _ in pairs(p_table) do
        s_count = s_count + 1
    end

    return s_count
end

return WeaponsUnlocks