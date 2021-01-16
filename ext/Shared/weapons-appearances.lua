local WeaponsAppearances = class('WeaponsAppearances')

local LoadedInstances = require('__shared/loaded-instances')
local ElementalConfig = require('__shared/elemental-config')
local InstanceWait = require('__shared/utils/wait')
local InstanceUtils = require('__shared/utils/instances')

function WeaponsAppearances:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function WeaponsAppearances:RegisterVars()
    self.m_currentLevel = nil
    self.m_currentMode = nil

    self.m_waitingGuids = {
        WeaponPresetShadowFP = {'1155325D-8138-4D3C-A3D1-AB5A1D520289', '1AFD6691-9CB6-4195-A4D1-6C925C0C3C2B'},

        _CharacterSocketListAsset = {'1F5CC239-BE4F-4D03-B0B5-A0FF89976036', '8F1A9F10-6BF8-442A-909F-AF0D9F8E1608'},
        _CharacterRoot = {'869C6675-54E6-11DE-AB3A-E7780EA0F1FE', 'A8810763-C259-138B-E17F-1F9C69ACE87B'},

        --
        -- Object Variations
        --

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

        _RU_Helmet05_Desert = {'AAB12F24-95C9-11E0-B23E-855EFEEC204F', '573A9402-E760-7B0B-4DCF-1831242E998F'},
        -- _RU_LB03_Desert = {'59966EFA-3C5D-4115-ADB9-7013A94D4F85', 'AAD994DE-5C6D-49A9-9844-788CDCECEBED'},
        _RU_Upperbody01_Desert = {'C835A476-95C0-11E0-B23E-855EFEEC204F', '8CDE9129-D9BE-C6A4-5F6D-975C111EEAA9'},

        _Gasmask02_Desert = {'9A62A548-95D0-11E0-B23E-855EFEEC204F', '07DC6312-7A34-A1DF-AB5A-23FB91EE5575'},
        _RU_Upperbody04_Desert = {'CDEF869B-959A-11E0-86C2-B30910735269', 'C9F07E77-DA10-1781-CA13-715928514D59'},
        _RU_Lowerbody01_Desert = {'90F9636A-9212-4B77-BAB1-355C9C9DA7AF', '50200AFD-094C-4578-BE21-C25B8225FC3A'},

        _RU_Beanie02_Desert = {'62720141-9663-11E0-828D-AD4BD8DF7BC4', '8AB1EC58-DBA4-02F1-F029-98DA3958F619'},
        _RU_Upperbody02_Desert = {'377C1E36-95C7-11E0-B23E-855EFEEC204F', 'A8F16801-B10E-625C-EC91-AEA6962BEACA'},
        _RU_Lowerbody02_Desert = {'0A6DB2C2-2B2E-4CFF-A63E-BBF225618336', 'FA9605D8-8B98-4A64-91F4-EC8647719A65'},

        _RU_Helmet04_Desert = {'1B01B55F-95D6-11E0-B23E-855EFEEC204F', 'E61C15EC-3F94-8C12-B6D6-0B9401BDFD1A'},
        _RU_Upperbody03_Desert = {'30167C66-95D5-11E0-B23E-855EFEEC204F', '0484D00C-B494-2946-E111-B02A8D7BB311'},
        _RU_Lowerbody04_Desert = {'A950188A-FAF3-4B41-BB92-51E75390EE47', 'BE547232-DAD1-45D3-8610-25F35DC8E478'},

        _Arms1P_RUS_Default = {'9A71F809-0459-4E87-9291-7C0CA927B6EA', 'BB1209DB-B3B8-452A-B113-C5F0E167404C'},

        --
        -- Link UnlockAssets
        --

        _MP_US_Assault_Helmet01 = {'45B47A2D-9F0E-4A20-B37F-FF9066A3C8E4', 'CB7204EC-D4FA-4722-A540-9D4643D0BDBF'},
        _MP_US_Assault_Head01 = {'9B54E4CA-6207-4DA4-9E4D-A09F11893844', 'B5C8DFEC-7503-4771-8BCB-5F75DE529D89'},
        _MP_US_Assault_UpperBody01 = {'CBEBACDB-6158-416D-8D1C-665539F65CDD', '9E49E623-0F88-4D50-88ED-AE9EA0139156'},
        _MP_US_Assault_LowerBody01 = {'C4FBCFC7-416F-42D2-99B3-2DCF1840FCFD', '98187809-F0CD-4F9B-8D9C-23729FC366C7'},

        _MP_US_Engi_Cap01_Wood01 = {'99212B4D-6FE0-404A-81EF-595C25AC7A31', '15F330AE-322A-41A1-892F-4D2902B8E2F9'},
        _MP_US_Engi_Head01 = {'CCC88822-E9E8-42FE-8FAB-ED92E797DD18', 'A2B386A1-710F-4B0A-B2DE-B059A8E20D12'},
        _MP_US_Engi_UpperBody01_Wood01 = {'756B6776-B14E-463D-BC2C-DC3A5AA6C16F', 'B4A1F1F1-A4DF-492B-8C1A-3C98836A7E99'},
        _MP_US_Engi_LowerBody01_Wood01 = {'67BDFCC5-79BA-4125-99D5-6FE943BC947C', 'B19E00A9-F888-444E-805C-59737AD3FE96'},

        _MP_US_Recon_Shemagh01_Para = {'EB4A1F39-1D3C-4AAA-A4E1-685473BF0F4F', '1FC7E6CD-84C2-4302-925E-7AA3DA927378'},
        _MP_US_Recon_UpperBody01_Wood01 = {'D4036010-97F7-4D15-B996-AC64347FCA66', '2EF96073-6E22-4C6A-AAFF-2382EBD52B04'},
        _MP_US_Recon_LowerBody01_Wood01 = {'19B607D6-46BA-427C-95DD-AFABDA06CFE6', '52EDAE28-D031-4129-9F6C-7014B15EB47D'},

        _MP_US_Support_Helmet01_Wood01 = {'A01AE85F-3B19-4A3A-8C2D-EDF7C2CE5303', 'C20070EB-5A83-477A-B412-EC3ABB72F0C6'},
        _MP_US_Support_Head01 = {'618925F4-72F0-4108-BF78-8EE0149DC4C8', 'F3706CF0-C48D-43B2-916F-8369FB738F37'},
        _MP_US_Support_UpperBody01_Wood01 = {'4AA63208-518D-4223-A646-12C6E3038DB7', '557E13E3-62B3-4CA0-8604-7C84B64052C7'},
        _MP_US_Support_LowerBody01_Wood01 = {'3F5D4AD1-ED48-44BB-BFA5-1FA4A19F5891', '9C5F18BE-149B-4EC4-A94E-8CC64235A4E7'},

        _MP_RU_Assault_Helmet01 = {'4438583D-F7A7-4AF2-8158-C256B44C6E5E', 'FE8E28B6-ED7E-436A-85BB-05BF7F36D568'},
        _MP_RU_Assault_LowerBody01 = {'EFA9A3EC-6592-4289-93A5-466A5B5BE42A', '5652EDE2-057D-4A97-A3A5-95FCAC23CE25'},
        _MP_RU_Assault_UpperBody01 = {'96C63B59-97E3-4281-81A4-273AB6E7CE53', 'AA45CCE2-738A-47BC-B9A5-5A6C00C7A66D'},

        _MP_RU_Engi_Helmet01 = {'E0CAA3F6-58B3-4CCC-A5B1-9A69118A715A', 'B2B83F26-04F1-458C-B8E6-E39E300ED80A'},
        _MP_RU_Engi_UpperBody01 = {'73F24F09-8825-47A9-ACD8-2E2D24C1C616', '9DB9FECE-5C60-4D34-BC9F-7F1E994B01FE'},
        _MP_RU_Engi_LowerBody01 = {'6AFF604F-B722-4E3D-B2B0-2CE6562432E2', 'EA0709FC-BE6C-40E4-90A4-6E7CD0FE7FE3'},

        _MP_RU_Recon_Helmet01 = {'769A9E4A-55A0-4916-9DAF-EB855282B705', '21C16140-1CE9-4627-87DE-64067D4B0E15'},
        _MP_RU_Recon_UpperBody01 = {'988678F2-7D35-4A0E-A46A-6773FABDBE63', '661BC858-09A9-40B5-BCB3-44102D3A5886'},
        _MP_RU_Recon_LowerBody01 = {'18906494-C17C-4B6C-AB37-74203F003010', 'FBA4F39F-6646-401E-89F3-A1985041DB8B'},

        _MP_RU_Support_Helmet01 = {'646BE266-3CE7-4169-B0F0-CB361F7125DD', '54FBFD32-5EF4-4E77-AD9F-146FEE0B80DE'},
        _MP_RU_Support_UpperBody01 = {'B97D66B8-466B-4175-AB07-B28825BDA525', '786F3073-C32E-4B76-9B19-DEAAEC6AFB95'},
        _MP_RU_Support_LowerBody01 = {'8CF95E90-FC5F-4FE9-90F4-2C80DC0ECA01', '90DE83D4-89D3-4596-8A12-3BEBE5D4F3FA'},

        _RU_Helmet05_Navy = {'706BF6C9-0EAD-4382-A986-39D571DBFA77', '53828D27-7C4A-415A-892D-8D410136E1B6'}
    }

    self.m_waitingInstances = {
        meshVariationDatabase = nil, -- MeshVariationDatabase
        weaponEntities = {}, -- SoldierWeaponData
        weaponShader = nil -- ShaderGraph
    }

    self.m_registryContainer = nil -- RegistryContainer
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedMeshAsset1pWeaponGuids = {} -- WeaponStateData.mesh1p
    self.m_skinnedMeshAsset3pWeaponGuids = {} -- WeaponStateData.mesh3p
    self.m_meshVariationDatabaseEntrys1p = {} -- MeshVariationDatabaseEntry
    self.m_meshVariationDatabaseEntrys3p = {} -- MeshVariationDatabaseEntry
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint

    self.m_surfaceShaderStructs = {} -- SurfaceShaderInstanceDataStruct
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintVariationPairs = {} -- BlueprintAndVariationPair
    self.m_unlockAssets = {} -- UnlockAsset

    self.m_verbose = 1 -- prints debug information
end

function WeaponsAppearances:RegisterEvents()
    Events:Subscribe('Level:Destroy', function()
        self.m_unlockAssets = {}
        self.m_registryContainer = nil
    end)

    -- reading instances before level loads
    Events:Subscribe('Level:LoadResources', function(p_level, p_mode, p_dedicated)
        self:RegisterWait()
    end)
end

function WeaponsAppearances:RegisterWait()
    -- waiting instances
    InstanceWait(self.m_waitingGuids, function(p_instances)
        self:ReadInstances(p_instances)
    end)
end

function WeaponsAppearances:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    self.m_waitingInstances.meshVariationDatabase = LoadedInstances.m_loadedInstances.MeshVariationDatabase
    self.m_waitingInstances.weaponEntities = LoadedInstances:GetInstances('SoldierWeaponData')

    self.m_meshVariationDatabase = self.m_waitingInstances.meshVariationDatabase
    self.m_meshVariationDatabase:MakeWritable()

    self.m_waitingInstances.weaponShader = p_instances['WeaponPresetShadowFP']

    -- reading weapon entities
    for _, l_value in pairs(self.m_waitingInstances.weaponEntities) do
        local s_weaponEntity = l_value

        self.m_skinnedMeshAsset1pWeaponGuids[s_weaponEntity.weaponStates[1].mesh1p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')
        self.m_skinnedMeshAsset3pWeaponGuids[s_weaponEntity.weaponStates[1].mesh3p.instanceGuid:ToString('D')] = s_weaponEntity.instanceGuid:ToString('D')

        self.m_weaponBlueprints[s_weaponEntity.instanceGuid:ToString('D')] = s_weaponEntity.soldierWeaponBlueprint
    end

    -- reading mesh variations
    for _, l_value in pairs(self.m_meshVariationDatabase.entries) do
        local s_meshVariationDatabaseEntry = l_value
        local s_skinnedMeshAsset1pWeaponGuid = self.m_skinnedMeshAsset1pWeaponGuids[s_meshVariationDatabaseEntry.mesh.instanceGuid:ToString('D')]
        local s_skinnedMeshAsset3pWeaponGuid = self.m_skinnedMeshAsset3pWeaponGuids[s_meshVariationDatabaseEntry.mesh.instanceGuid:ToString('D')]

        if s_meshVariationDatabaseEntry.variationAssetNameHash == 0 then
            if s_skinnedMeshAsset1pWeaponGuid ~= nil then
                self.m_meshVariationDatabaseEntrys1p[s_skinnedMeshAsset1pWeaponGuid] = s_meshVariationDatabaseEntry
            end

            if s_skinnedMeshAsset3pWeaponGuid ~= nil then
                self.m_meshVariationDatabaseEntrys3p[s_skinnedMeshAsset3pWeaponGuid] = s_meshVariationDatabaseEntry
            end
        end
    end

    if InstanceUtils:Count(self.m_meshVariationDatabaseEntrys1p) == 0 and SharedUtils:IsClientModule() then
        ResourceManager:DestroyDynamicCompartment(ResourceCompartment.ResourceCompartment_Game)
    else
        self:CreateInstances()
    end

    -- removing hanging references
    self.m_waitingInstances = {
        meshVariationDatabase = nil, -- MeshVariationDatabase
        weaponEntities = {}, -- SoldierWeaponData
        weaponShader = nil -- ShaderGraph
    }

    -- removing hanging references
    self.m_meshVariationDatabase = nil -- MeshVariationDatabase
    self.m_skinnedMeshAsset1pWeaponGuids = {} -- WeaponStateData.mesh1p
    self.m_skinnedMeshAsset3pWeaponGuids = {} -- WeaponStateData.mesh3p
    self.m_meshVariationDatabaseEntrys1p = {} -- MeshVariationDatabaseEntry
    self.m_meshVariationDatabaseEntrys3p = {} -- MeshVariationDatabaseEntry
    self.m_weaponBlueprints = {} -- SoldierWeaponBlueprint

    self.m_surfaceShaderStructs = {} -- SurfaceShaderInstanceDataStruct
    self.m_meshMaterialVariations = {} -- MeshMaterialVariation
    self.m_meshVariationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    self.m_objectVariationAssets = {} -- ObjectVariationAsset
    self.m_blueprintVariationPairs = {} -- BlueprintAndVariationPair
end

function WeaponsAppearances:CreateInstances()
    if self.m_verbose >= 1 then
        print('Creating Instances')
    end

    self.m_registryContainer = RegistryContainer()

    self:CreateSurfaceShaderStructs(self.m_waitingInstances.weaponShader)

    for _, l_value in pairs(self.m_waitingInstances.weaponEntities) do
        local s_weaponEntity = l_value
        local s_meshVariationDatabaseEntry = self.m_meshVariationDatabaseEntrys1p[s_weaponEntity.instanceGuid:ToString('D')]

        if s_meshVariationDatabaseEntry ~= nil then
            self:CreateMeshMaterialVariations(s_meshVariationDatabaseEntry)
            self:CreateMeshVariationDatabaseEntrys(s_meshVariationDatabaseEntry)
            self:CreateObjectVariationAssets(s_meshVariationDatabaseEntry)
            self:CreateBlueprintAndVariationPairs(s_meshVariationDatabaseEntry)
            self:CreateUnlockAssets(s_meshVariationDatabaseEntry)
        end
    end

    ResourceManager:AddRegistry(self.m_registryContainer, ResourceCompartment.ResourceCompartment_Game)

    if self.m_verbose >= 1 then
        print('Created SurfaceShaderStructs: ' .. InstanceUtils:Count(self.m_surfaceShaderStructs))
        print('Created MeshMaterialVariations: ' .. InstanceUtils:Count(self.m_meshMaterialVariations))
        print('Created VariationDatabaseEntrys: ' .. InstanceUtils:Count(self.m_meshVariationDatabaseEntrys))
        print('Created ObjectVariationAssets: ' .. InstanceUtils:Count(self.m_objectVariationAssets))
        print('Created BlueprintVariationPairs: ' .. InstanceUtils:Count(self.m_blueprintVariationPairs))
        print('Created UnlockAssets: ' .. InstanceUtils:Count(self.m_unlockAssets))
        print('Created RegistryContainerAssets: ' .. InstanceUtils:Count(self.m_registryContainer.assetRegistry))
        print('Created RegistryContainerEntities: ' .. InstanceUtils:Count(self.m_registryContainer.entityRegistry))
        print('Created RegistryContainerBlueprints: ' .. InstanceUtils:Count(self.m_registryContainer.blueprintRegistry))
    end
end

-- creating SurfaceShaderInstanceDataStruct for MeshMaterialVariation
function WeaponsAppearances:CreateSurfaceShaderStructs(p_asset)
    local s_elements = {}

    for _, l_element in pairs(ElementalConfig.names) do
        local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()

        local s_color = ElementalConfig.colors[l_element]

        local s_camoDarkeningParameter = VectorShaderParameter()
        s_camoDarkeningParameter.value = Vec4(s_color.x, s_color.y, s_color.z, 0)
        s_camoDarkeningParameter.parameterName = 'CamoDarkening'
        s_camoDarkeningParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        local s_emissiveParameter = VectorShaderParameter()
        s_emissiveParameter.value = Vec4(1, 1, 1, 1)
        s_emissiveParameter.parameterName = 'Emissive'
        s_emissiveParameter.parameterType = ShaderParameterType.ShaderParameterType_Color

        s_surfaceShaderInstanceDataStruct.shader = p_asset
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_camoDarkeningParameter)
        s_surfaceShaderInstanceDataStruct.vectorParameters:add(s_emissiveParameter)

        s_elements[l_element] = s_surfaceShaderInstanceDataStruct
    end

    self.m_surfaceShaderStructs = s_elements
end

-- creating MeshMaterialVariation for MeshVariationDatabaseMaterial
function WeaponsAppearances:CreateMeshMaterialVariations(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry.materials[1]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_databaseEntryMaterials = {}

        -- dont customize radio beacon and c4
        if not p_entry.mesh.name:match('radio_beacon') and not p_entry.mesh.name:match('c4') then
            for ll_key, ll_value in pairs(p_entry.materials) do
                local s_isNoCamo1p = false
                local s_isNoCamo3p = false
                local s_isPreset1p = false
                local s_isPreset3p = false
                local s_isShadow1p = false

                if ll_value.material.shader.shader ~= nil then
                    s_isNoCamo1p = ll_value.material.shader.shader.name:match('WeaponPresetShadowNoCamoFP')
                    s_isNoCamo3p = ll_value.material.shader.shader.name:match('WeaponPresetNoCamo3P')
                    s_isPreset1p = ll_value.material.shader.shader.name:match('WeaponPresetFP')
                    s_isPreset3p = ll_value.material.shader.shader.name:match('WeaponPreset3P')
                    s_isShadow1p = ll_value.material.shader.shader.name:match('WeaponPresetShadowFP')
                end

                if s_isNoCamo1p or s_isNoCamo3p or s_isPreset1p or s_isPreset3p or s_isShadow1p then
                    local s_newMeshMaterialVariation = MeshMaterialVariation(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'MeshMaterialVariation' .. l_element .. ll_key))
                    p_entry.partition:AddInstance(s_newMeshMaterialVariation)

                    s_newMeshMaterialVariation.shader = self.m_surfaceShaderStructs[l_element]

                    s_databaseEntryMaterials[ll_key] = s_newMeshMaterialVariation
                end
            end
        end

        s_elements[l_element] = s_databaseEntryMaterials
    end

    self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating MeshVariationDatabaseEntry for ObjectVariationAsset
function WeaponsAppearances:CreateMeshVariationDatabaseEntrys(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshVariationDatabaseEntrys')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry

    local s_skinnedMeshAsset1pWeaponGuid = self.m_skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]
    local s_meshVariationDatabaseEntry3p = self.m_meshVariationDatabaseEntrys3p[s_skinnedMeshAsset1pWeaponGuid]
    local s_meshMaterialVariations = self.m_meshMaterialVariations[p_entry.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newMeshVariationDatabaseEntry1p = InstanceUtils:CloneInstance(p_entry, l_element)
        local s_newMeshVariationDatabaseEntry3p = InstanceUtils:CloneInstance(s_meshVariationDatabaseEntry3p, l_element)

        for ll_key, ll_value in pairs(s_meshMaterialVariations[l_element]) do
            s_newMeshVariationDatabaseEntry1p.materials[ll_key].materialVariation = ll_value
            s_newMeshVariationDatabaseEntry3p.materials[ll_key].materialVariation = ll_value
        end

        s_newMeshVariationDatabaseEntry1p.variationAssetNameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D') .. l_element)
        s_newMeshVariationDatabaseEntry3p.variationAssetNameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D') .. l_element)

        self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry1p)
        self.m_meshVariationDatabase.entries:add(s_newMeshVariationDatabaseEntry3p)

        s_elements[l_element] = s_newMeshVariationDatabaseEntry1p
    end

    self.m_meshVariationDatabaseEntrys[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating ObjectVariationAsset for BlueprintAndVariationPair
function WeaponsAppearances:CreateObjectVariationAssets(p_entry)
    if self.m_verbose >= 2 then
        print('Create ObjectVariationAssets')
    end

    local s_elements = {}
    s_elements['neutral'] = nil

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newObjectVariationAsset = ObjectVariation(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'ObjectVariationAsset' .. l_element))
        p_entry.partition:AddInstance(s_newObjectVariationAsset)

        s_newObjectVariationAsset.name = p_entry.instanceGuid:ToString('D') .. l_element
        s_newObjectVariationAsset.nameHash = MathUtils:FNVHash(p_entry.instanceGuid:ToString('D') .. l_element)

        s_elements[l_element] = s_newObjectVariationAsset
    end

    self.m_objectVariationAssets[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating BlueprintAndVariationPair for UnlockAsset
function WeaponsAppearances:CreateBlueprintAndVariationPairs(p_entry)
    if self.m_verbose >= 2 then
        print('Create BlueprintAndVariationPairs')
    end

    local s_elements = {}
    s_elements['neutral'] = nil

    local s_skinnedMeshAsset1pWeaponGuid = self.m_skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]
    local s_weaponBlueprint = self.m_weaponBlueprints[s_skinnedMeshAsset1pWeaponGuid]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newBlueprintAndVariationPair = BlueprintAndVariationPair(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'BlueprintAndVariationPair' .. l_element))
        p_entry.partition:AddInstance(s_newBlueprintAndVariationPair)

        s_newBlueprintAndVariationPair.name = p_entry.instanceGuid:ToString('D')
        s_newBlueprintAndVariationPair.baseAsset = s_weaponBlueprint
        s_newBlueprintAndVariationPair.variation = self.m_objectVariationAssets[p_entry.instanceGuid:ToString('D')][l_element]

        s_elements[l_element] = s_newBlueprintAndVariationPair
    end

    self.m_blueprintVariationPairs[p_entry.instanceGuid:ToString('D')] = s_elements
end

-- creating UnlockAsset
function WeaponsAppearances:CreateUnlockAssets(p_entry)
    if self.m_verbose >= 2 then
        print('Create UnlockAssets')
    end

    local s_elements = {}
    -- s_elements['neutral'] = p_entry.materials

    local s_skinnedMeshAsset1pWeaponGuid = self.m_skinnedMeshAsset1pWeaponGuids[p_entry.mesh.instanceGuid:ToString('D')]

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newUnlockAsset = UnlockAsset(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. 'UnlockAsset' .. l_element))
        p_entry.partition:AddInstance(s_newUnlockAsset)

        s_newUnlockAsset.name = p_entry.instanceGuid:ToString('D') .. l_element
        s_newUnlockAsset.linkedTo:add(self.m_blueprintVariationPairs[p_entry.instanceGuid:ToString('D')][l_element])

        self.m_registryContainer.assetRegistry:add(s_newUnlockAsset)

        s_elements[l_element] = s_newUnlockAsset
    end

    self.m_unlockAssets[s_skinnedMeshAsset1pWeaponGuid] = s_elements
end

-- getting custom unlocks
function WeaponsAppearances:GetUnlockAssets(p_weapons, p_element, p_secondary)
    local s_unlocks = {}

    for l_key, l_value in pairs(p_weapons) do
        local s_unlockAsset = nil

        local s_element = p_element
        if l_key == 2 then
            s_element = p_secondary
        end

        if l_value ~= nil then
            local s_weaponUnlockAsset = SoldierWeaponUnlockAsset(l_value)
            local s_weaponEntity = s_weaponUnlockAsset.weapon.object
            s_unlockAsset = self.m_unlockAssets[s_weaponEntity.instanceGuid:ToString('D')]

            if s_element == 'neutral' then
                s_unlockAsset = nil
            else
                s_unlockAsset = s_unlockAsset[s_element]
            end
        end

        s_unlocks[l_key] = s_unlockAsset
    end

    return s_unlocks
end

return WeaponsAppearances