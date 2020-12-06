local SoldiersAppearances = class('SoldiersAppearances')

local ElementalConfig = require('__shared/elemental-config')
local InstanceWait = require('__shared/utils/wait')
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

    self.m_kitAppearanceGuids = {
        USAssault = 'F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4',
        USEngineer = 'F2ADB1BC-466F-4B51-90D1-E8F8670C7BE7',
        USRecon = '4BE86DA1-0229-448D-A5E2-934E5490E11C',
        USSupport = '23CFF61F-F1E2-4306-AECE-2819E35484D2',

        RUAssault = 'A7A90928-FA6A-4013-96BA-AE559BA8B74F',
        RUEngineer = '0A020AB7-E777-4B6D-BFDB-F842D0BCF33B',
        RURecon = 'F3211E83-7C35-497A-A1C8-57F5FC1D3AE8',
        RUSupport = '6BD15FC4-1451-4F0B-9902-73E53582DE95'
    }

    self.m_currentLevel = nil

    self.m_waitingGuids = {
        CharacterSocketListAsset = {'1F5CC239-BE4F-4D03-B0B5-A0FF89976036', '8F1A9F10-6BF8-442A-909F-AF0D9F8E1608'},

        --
        -- Gameplay Kits
        --

        MP_US_Assault_Appearance01 = {'6252040E-A16A-11E0-AAC3-854900935C42', 'F2ECBAB2-F00A-47CA-66DC-0F89C6A138D4'},
        MP_US_Engi_Appearance_Wood01 = {'FA825024-20C0-4207-9037-CE25CC5FBA38', 'F2ADB1BC-466F-4B51-90D1-E8F8670C7BE7'},
        MP_US_Recon_Appearance_Wood01 = {'E3BE172B-C32F-4ECF-A85C-E9F9796610FF', '4BE86DA1-0229-448D-A5E2-934E5490E11C'},
        MP_US_Support_Appearance_Wood01 = {'9D8C49AB-0E01-4FA6-9127-5FCCDB110B2C', '23CFF61F-F1E2-4306-AECE-2819E35484D2'},

        MP_RU_Assault_Appearance01 = {'92002FDC-62A7-41A7-A95C-15AC0DE28F3A', 'A7A90928-FA6A-4013-96BA-AE559BA8B74F'},
        MP_RU_Engi_Appearance01 = {'34390157-EEAB-408A-8F3C-08134B10E9CA', '0A020AB7-E777-4B6D-BFDB-F842D0BCF33B'},
        MP_RU_Recon_Appearance01 = {'56AE38F7-6ED1-4C3E-99BC-D4163596D37F', 'F3211E83-7C35-497A-A1C8-57F5FC1D3AE8'},
        MP_RU_Support_Appearance01 = {'AB37855A-3F3A-4A35-AF7C-B16FAFA944EF', '6BD15FC4-1451-4F0B-9902-73E53582DE95'},

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

    self.m_meshMaterialIndexes = {
        USAssault = {
            us_helmet09 = { 1 },
            us_upperbody04 = { 1 },
            us_lb03 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 }
        },
        USEngineer = {
            us_cap03 = { 1 },
            us_upperbody06 = { 1 },
            us_lowerbody01 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 }
        },
        USRecon = {
            shemagh02 = { 3 },
            us_upperbody08 = { 1 },
            us_lowerbody02 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 }
        },
        USSupport = {
            us_helmet07 = { 1 },
            us_upperbody07 = { 1 },
            us_lowerbody04 = { 1 },
            arms1p_bareglove03 = { 1, 2, 4 }
        },

        RUAssault = {
            ru_helmet05 = { 1 },
            us_lb03 = { 1 },
            ru_upperbody01 = { 1 },
            arms1p_rus = { 1, 2, 4 }
        },
        RUEngineer = {
            gasmask02 = { 1 },
            ru_upperbody04 = { 1 },
            us_lowerbody01 = { 1 },
            arms1p_rus = { 1, 2, 4 }
        },
        RURecon = {
            ru_beanie02 = { 3 },
            ru_upperbody02 = { 1 },
            us_lowerbody02 = { 1 },
            arms1p_rus = { 1, 2, 4 }
        },
        RUSupport = {
            ru_helmet04 = { 1 },
            ru_upperbody03 = { 1 },
            us_lowerbody04 = { 1 },
            arms1p_rus = { 1, 2, 4 }
        }
    }

    self.m_waitingInstances = {
        meshVariationDatabase = nil, -- MeshVariationDatabase
        characterSocketListAsset = nil, -- CharacterSocketListAsset
        appearanceUnlockAssets = {}, -- UnlockAsset
        linkUnlockAssets = {}, -- UnlockAsset
        blueprintAndVariationPairs = {}, -- BlueprintAndVariationPair
        objectVariationAssets = {}, -- ObjectVariationAsset
        meshVariationDatabaseEntrys = {} -- MeshVariationDatabaseEntry
    }

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
    -- waiting variation database
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

    -- reading instances before level loads
    Events:Subscribe('Level:LoadResources', function(p_level, p_mode, p_dedicated)
        if self.m_currentLevel == nil then
            self:RegisterWait()
        else
            self:ReloadInstances()
        end

        self.m_currentLevel = p_level
    end)
end

function SoldiersAppearances:RegisterWait()
    -- waiting instances
    InstanceWait(self.m_waitingGuids, function(p_instances)
        self:ReadInstances(p_instances)
    end)
end

-- reseting created instances
function SoldiersAppearances:ReloadInstances()
    if self.m_verbose >= 1 then
        print('Reloading Instances')
    end

    self.m_appearanceUnlockAssets = {} -- UnlockAsset

    self:RegisterWait()
end

-- reading waiting instances
function SoldiersAppearances:ReadInstances(p_instances)
    if self.m_verbose >= 1 then
        print('Reading Instances')
    end

    self.m_meshVariationDatabase = MeshVariationDatabase(self.m_waitingInstances.meshVariationDatabase)
    self.m_meshVariationDatabase:MakeWritable()

    self.m_waitingInstances.characterSocketListAsset = p_instances['CharacterSocketListAsset']

    self.m_waitingInstances.appearanceUnlockAssets['USAssault'] = p_instances['MP_US_Assault_Appearance01']
    self.m_waitingInstances.appearanceUnlockAssets['USEngineer'] = p_instances['MP_US_Engi_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['USRecon'] = p_instances['MP_US_Recon_Appearance_Wood01']
    self.m_waitingInstances.appearanceUnlockAssets['USSupport'] = p_instances['MP_US_Support_Appearance_Wood01']

    self.m_waitingInstances.appearanceUnlockAssets['RUAssault'] = p_instances['MP_RU_Assault_Appearance01']
    self.m_waitingInstances.appearanceUnlockAssets['RUEngineer'] = p_instances['MP_RU_Engi_Appearance01']
    self.m_waitingInstances.appearanceUnlockAssets['RURecon'] = p_instances['MP_RU_Recon_Appearance01']
    self.m_waitingInstances.appearanceUnlockAssets['RUSupport'] = p_instances['MP_RU_Support_Appearance01']

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

-- creating MeshMaterialVariation for MeshVariationDatabaseMaterial
function SoldiersAppearances:CreateMeshMaterialVariations(p_entry)
    if self.m_verbose >= 2 then
        print('Create MeshMaterialVariations')
    end

    local s_elements = {}
    s_elements['neutral'] = p_entry.materials

    local s_meshVariationDatabaseMaterialIndexes = self.m_databaseEntryMaterialIndexes[p_entry.instanceGuid:ToString('D')]
    for _, l_element in pairs(ElementalConfig.names) do
        local s_variations = {}
        for _, ll_value in pairs(s_meshVariationDatabaseMaterialIndexes) do
            local s_newMeshMaterialVariation = MeshMaterialVariation(InstanceUtils:GenerateGuid(p_entry.instanceGuid:ToString('D') .. ll_value .. l_element))
            p_entry.partition:AddInstance(s_newMeshMaterialVariation)

            local s_surfaceShaderInstanceDataStruct = SurfaceShaderInstanceDataStruct()

            local s_shaderGraph = ShaderGraph()
            s_shaderGraph.name = 'shaders/Root/CharacterRoot'

            local s_color = ElementalConfig.colors[l_element]

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

    local s_elements = {}
    s_elements['neutral'] = p_data

    for _, l_element in pairs(ElementalConfig.names) do
        local s_newBlueprintAndVariationPair = InstanceUtils:CloneInstance(p_data, l_element)

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

-- getting custom unlock
function SoldiersAppearances:GetUnlockAsset(p_player, p_element)
    local s_customization = VeniceSoldierCustomizationAsset(p_player.customization)
    local s_kitNameParts = InstanceUtils:Split(s_customization.name, '/')
    local s_kitName = s_kitNameParts[#s_kitNameParts]
    local s_appearanceGuid = self.m_kitAppearanceGuids[s_kitName]
    local s_appearanceUnlockAsset = self.m_appearanceUnlockAssets[s_appearanceGuid][p_element]

    print(s_kitName)

    return s_appearanceUnlockAsset
end

return SoldiersAppearances