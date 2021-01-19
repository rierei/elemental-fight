local InstanceUtils = class('InstanceUtils')

local Uuid = require('__shared/utils/uuid')

function InstanceUtils:__init()
    self.m_verbose = 0
end

-- cloning the instance and adding to partition
function InstanceUtils:CloneInstance(p_instance, p_variation)
    if self.m_verbose >= 1 then
        print('Clone: ' .. p_instance.typeInfo.name)
    end

    local s_seed = p_instance.instanceGuid:ToString('D') .. p_variation
    local s_partition = p_instance.partition

    local s_newGuid = self:GenerateGuid(s_seed)
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
function InstanceUtils:GenerateGuid(p_seed)
    Uuid.randomseed(MathUtils:FNVHash(p_seed))
    return Guid(Uuid())
end

-- counting table elements
function InstanceUtils:Count(p_table)
    local s_count = 0

    for _, _ in pairs(p_table) do
        s_count = s_count + 1
    end

    return s_count
end

-- splitting string
function InstanceUtils:Split(p_string, p_separator)
    local s_parts = {}

    for l_part in string.gmatch(p_string, "([^" .. p_separator .. "]+)") do
        table.insert(s_parts, l_part)
    end

    return s_parts
end

-- merging tables
function InstanceUtils:MergeTables(p_source, p_merge)
    for _, l_value in pairs(p_merge) do
        table.insert(p_source, l_value)
    end

    return p_source
end

return InstanceUtils()