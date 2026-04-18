-- Prop Cleanup Utility System
-- Tracks spawned props via network IDs and handles cleanup on resource lifecycle events

CleanupSystem = {
    ResourceName = GetCurrentResourceName(),
    StorageFile = 'stored_props.json',
    TrackedProps = {},
    IsServer = IsDuplicityVersion()
}

-- Initialize cleanup system
function CleanupSystem:Initialize()
    if self.IsServer then
        -- Server: Load persisted props from file
        self:LoadPersistedProps()
        
        -- Register resource stop handler
        AddEventHandler('onResourceStop', function(resourceName)
            if resourceName == self.ResourceName then
                self:OnResourceStop()
            end
        end)
        
        -- Register resource start handler (for cleanup of old props)
        AddEventHandler('onResourceStart', function(resourceName)
            if resourceName == self.ResourceName then
                self:OnResourceStart()
            end
        end)
    else
        -- Client: Register resource stop handler
        AddEventHandler('onClientResourceStop', function(resourceName)
            if resourceName == self.ResourceName then
                self:OnClientResourceStop()
            end
        end)
    end
end

-- Track a new prop (server-side)
function CleanupSystem:TrackProp(netId, boxId, model, coords)
    if not self.IsServer then return end
    
    self.TrackedProps[netId] = {
        netId = netId,
        boxId = boxId,
        model = model,
        coords = coords,
        createdAt = os.time(),
        createdBy = self.ResourceName
    }
    
    self:PersistProps()
    
    print(string.format('[Cleanup] Tracking prop netId=%d boxId=%s', netId, boxId))
end

-- Untrack a prop (server-side)
function CleanupSystem:UntrackProp(netId)
    if not self.IsServer then return end
    
    if self.TrackedProps[netId] then
        local prop = self.TrackedProps[netId]
        self.TrackedProps[netId] = nil
        self:PersistProps()
        print(string.format('[Cleanup] Untracked prop netId=%d', netId))
    end
end

-- Get all tracked props (server-side)
function CleanupSystem:GetTrackedProps()
    return self.TrackedProps
end

-- Persist props to file (server-side)
function CleanupSystem:PersistProps()
    if not self.IsServer then return end
    
    local data = {
        resource = self.ResourceName,
        timestamp = os.time(),
        props = {}
    }
    
    for netId, prop in pairs(self.TrackedProps) do
        data.props[#data.props + 1] = {
            netId = netId,
            boxId = prop.boxId,
            model = prop.model,
            coords = prop.coords,
            createdAt = prop.createdAt
        }
    end
    
    local jsonData = json.encode(data)
    SaveResourceFile(self.ResourceName, self.StorageFile, jsonData, #jsonData)
end

-- Load persisted props from file (server-side)
function CleanupSystem:LoadPersistedProps()
    if not self.IsServer then return end
    
    local fileData = LoadResourceFile(self.ResourceName, self.StorageFile)
    if not fileData or fileData == '' then
        return
    end
    
    local data = json.decode(fileData)
    if not data or not data.props then
        return
    end
    
    -- Convert array back to table keyed by netId
    for _, prop in ipairs(data.props) do
        self.TrackedProps[prop.netId] = {
            netId = prop.netId,
            boxId = prop.boxId,
            model = prop.model,
            coords = prop.coords,
            createdAt = prop.createdAt
        }
    end
    
    print(string.format('[Cleanup] Loaded %d persisted props from file', #data.props))
end

-- Server-side resource start handler
function CleanupSystem:OnResourceStart()
    print('[Cleanup] Resource started - checking for orphaned props...')
    
    -- Clean up any props that were left from previous session
    CreateThread(function()
        Wait(1000) -- Wait for entities to sync
        
        local cleanedCount = 0
        
        for netId, prop in pairs(self.TrackedProps) do
            -- Check if entity exists
            local entity = NetworkGetEntityFromNetworkId(netId)
            
            if entity and entity > 0 and DoesEntityExist(entity) then
                -- Entity exists - delete it
                print(string.format('[Cleanup] Deleting orphaned prop netId=%d boxId=%s', netId, prop.boxId))
                DeleteEntity(entity)
                cleanedCount = cleanedCount + 1
            end
            
            -- Remove from tracking regardless
            self.TrackedProps[netId] = nil
        end
        
        if cleanedCount > 0 then
            print(string.format('[Cleanup] Cleaned up %d orphaned props', cleanedCount))
            self:PersistProps()
        else
            print('[Cleanup] No orphaned props found')
        end
    end)
end

-- Server-side resource stop handler
function CleanupSystem:OnResourceStop()
    print('[Cleanup] Resource stopping - cleaning up tracked props...')
    
    local cleanedCount = 0
    
    for netId, prop in pairs(self.TrackedProps) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        
        if entity and entity > 0 and DoesEntityExist(entity) then
            -- Delete the entity
            DeleteEntity(entity)
            cleanedCount = cleanedCount + 1
        end
    end
    
    -- Clear tracking
    self.TrackedProps = {}
    self:PersistProps()
    
    print(string.format('[Cleanup] Cleaned up %d props on resource stop', cleanedCount))
end

-- Client-side resource stop handler
function CleanupSystem:OnClientResourceStop()
    print('[Cleanup] Client resource stopping - cleaning up local props...')
    
    -- This will be extended by the client script
    -- to clean up locally spawned props
    TriggerEvent('lootbox:cleanup:clientStop')
end

-- Force cleanup all props (admin command)
function CleanupSystem:ForceCleanup()
    if not self.IsServer then return end
    
    print('[Cleanup] Force cleanup initiated...')
    
    local cleanedCount = 0
    
    for netId, prop in pairs(self.TrackedProps) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        
        if entity and entity > 0 and DoesEntityExist(entity) then
            DeleteEntity(entity)
            cleanedCount = cleanedCount + 1
        end
    end
    
    self.TrackedProps = {}
    self:PersistProps()
    
    print(string.format('[Cleanup] Force cleaned %d props', cleanedCount))
    
    return cleanedCount
end

-- Get count of tracked props
function CleanupSystem:GetPropCount()
    local count = 0
    for _ in pairs(self.TrackedProps) do
        count = count + 1
    end
    return count
end

-- Initialize on load
CleanupSystem:Initialize()
