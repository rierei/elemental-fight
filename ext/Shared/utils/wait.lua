local WaitRef = class('WaitRef')

function WaitRef:__init(p_partitionGuid, p_instanceGuid, p_callback)
    self:RegisterVars(p_partitionGuid, p_instanceGuid, p_callback)
end

function WaitRef:RegisterVars(p_partitionGuid, p_instanceGuid, p_callback)
    self.m_partitionGuid = Guid(p_partitionGuid) -- partition guid
    self.m_instanceGuid = Guid(p_instanceGuid) -- instance guid

    self.m_callback = p_callback -- callback function
    self.m_handler = nil
    self.m_isLoaded = false
end

-- registering callbacks and finding the instance
function WaitRef:FindInstance()
    local s_instance = ResourceManager:FindInstanceByGuid(self.m_partitionGuid, self.m_instanceGuid)
    if s_instance ~= nil then
        self.m_isLoaded = true
        self.m_callback(s_instance)
    else
        self:RegisterCallback()
    end
end

-- returning the loaded instance
function WaitRef:RegisterCallback()
    self.m_handler = ResourceManager:RegisterInstanceLoadHandlerOnce(self.m_partitionGuid, self.m_instanceGuid, function(p_instance)
        self.m_isLoaded = true
        self.m_callback(p_instance)
    end)
end

function WaitRef:DeregisterCallback()
    if not self.m_isLoaded then
        self.m_handler:Deregister()
    end
end

local InstanceWait = class('InstanceWait')

function InstanceWait:__init(p_guids, p_callback)
    self:RegisterVars(p_guids, p_callback)
    self:RegisterEvents()
    self:CreateRefs()
    self:FindInstances()
end

function InstanceWait:RegisterVars(p_guids, p_callback)
    self.m_guids = p_guids -- guids list
    self.m_callback = p_callback -- callback function
    self.m_event = nil

    self.m_instanceRefs = {} -- refs list
    self.m_instances = {} -- instances list

    self.m_waitingRefs = 0 -- waiting count
    self.m_totalRefs = 0 -- refs count

    self.m_shouldDestroy = SharedUtils:IsServerModule()
    self.m_verbose = 2 -- prints waiting state
end

-- resetings counters on level destroy
function InstanceWait:RegisterEvents()
    self.m_event = Events:Subscribe('Level:Destroy', function()
        if self.m_shouldDestroy then
            print('Level:Destroy')
            self:DeregisterWait()
        else
            -- skips joining event
            self.m_shouldDestroy = true
        end
    end)
end

function InstanceWait:DeregisterWait()
    if self.m_verbose >= 2 then
        print('Wait Done')
    end

    for l_key, l_value in pairs(self.m_instanceRefs) do
        l_value:DeregisterCallback()
    end

    self.m_instanceRefs = {} -- refs list
    self.m_instances = {} -- instances list

    self.m_waitingRefs = 0 -- waiting count
    self.m_totalRefs = 0 -- refs count

    self.m_event:Unsubscribe()
end

-- creating refs list and setting counters
function InstanceWait:CreateRefs()
    local s_refs = {}
    local s_counter = 0

    for l_key, l_guids in pairs(self.m_guids) do
        s_counter = s_counter + 1
        s_refs[l_key] = WaitRef(l_guids[1], l_guids[2], function(p_instance)
            self:ProcessRef(l_key, p_instance)
        end)
    end

    self.m_instanceRefs = s_refs
    self.m_totalRefs = s_counter
    self.m_waitingRefs = s_counter
end

-- starts finding the instances
function InstanceWait:FindInstances()
    for _, l_ref in pairs(self.m_instanceRefs) do
        l_ref:FindInstance()
    end
end

-- returning the loaded instances
function InstanceWait:ProcessRef(p_key, p_instance)
    if self.m_verbose >= 1 then
        print('Found: ' .. p_instance.typeInfo.name)
    end

    self:SaveInstance(p_key, p_instance)

    if self.m_waitingRefs ~= 0 then
        return
    end

    self.m_callback(self.m_instances)
    self:DeregisterWait()
end

-- saving the loaded instance and updating counters
function InstanceWait:SaveInstance(p_key, p_instance)
    self.m_waitingRefs = self.m_waitingRefs - 1

    if self.m_verbose >= 2 then
        print('Wait: ' .. self.m_waitingRefs)
    end

    -- casting the instance
    local s_typeName = p_instance.typeInfo.name
    local s_type = _G[s_typeName]

    if s_type ~= nil then
        p_instance = s_type(p_instance)
    end

    self.m_instances[p_key] = p_instance
end

return InstanceWait