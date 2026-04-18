local ActiveBoxes = {}
local LocationCooldowns = {}
local StashItems = {}

-- Initialize RSG Core
local RSGCore = nil
local isRSGReady = false

CreateThread(function()
    while GetResourceState('rsg-core') ~= 'started' do
        Wait(500)
    end
    
    RSGCore = exports['rsg-core']:GetCoreObject()
    isRSGReady = true
    
    -- Start spawn loop
    StartSpawnLoop()
end)

-- Client reports prop network ID for tracking
RegisterNetEvent('lootbox:server:registerPropNetId', function(boxId, netId)
    local src = source
    local box = ActiveBoxes[boxId]
    
    if not box and Config.Debug then
        print(string.format('[LootBox] Warning: Received netId for unknown box %s', boxId))
        return
    end
    
    -- Store the network ID
    box.netId = netId
    
    -- Track in cleanup system
    CleanupSystem:TrackProp(netId, boxId, box.model, box.coords)
    
    if Config.Debug then
        print(string.format('[LootBox] Registered prop netId=%d for box %s', netId, boxId))
    end
end)

-- Get random loot box model
local function GetRandomModel()
    return Config.LootBoxModels[math.random(1, #Config.LootBoxModels)]
end

-- Get random spawn location (respecting cooldowns)
local function GetRandomLocation()
    local availableLocations = {}
    local currentTime = GetGameTimer()
    
    for i, location in ipairs(Config.SpawnLocations) do
        if not LocationCooldowns[i] or currentTime >= LocationCooldowns[i] then
            availableLocations[#availableLocations + 1] = { index = i, coords = location.coords }
        end
    end
    
    if #availableLocations > 0 then
        return availableLocations[math.random(1, #availableLocations)]
    end
    
    return nil
end

-- Select loot pool based on configured tier chances
local function SelectLootPool()
    local roll = math.random(1, 100)
    local cumulative = 0
    
    for _, tier in ipairs(Config.LootTiers) do
        cumulative = cumulative + tier.chance
        if roll <= cumulative then
            return tier.pool
        end
    end
    
    return 'common'
end

-- Get item label from RSG items table
local function GetItemLabel(itemName)
    if RSGCore and RSGCore.Shared and RSGCore.Shared.Items then
        local itemData = RSGCore.Shared.Items[itemName]
        if itemData and itemData.label then
            return itemData.label
        end
    end
    return itemName
end

-- Generate random loot items from a pool
local function GenerateLootItems(poolName)
    local pool = Config.ItemPools[poolName]
    if not pool then return {} end
    
    local items = {}
    local totalWeight = 0
    
    -- Calculate total weight
    for _, item in ipairs(pool) do
        totalWeight = totalWeight + item.weight
    end
    
    -- Select random items (pick 2-4 items from pool)
    local numItems = math.random(2, 4)
    local selectedItems = {}
    
    for i = 1, numItems do
        local roll = math.random(1, totalWeight)
        local cumulative = 0
        local selectedItem = nil
        
        for _, item in ipairs(pool) do
            cumulative = cumulative + item.weight
            if roll <= cumulative then
                selectedItem = item
                break
            end
        end
        
        if selectedItem then
            local amount = math.random(selectedItem.minAmount, selectedItem.maxAmount)
            items[#items + 1] = {
                name = selectedItem.item,
                label = GetItemLabel(selectedItem.item),
                amount = amount
            }
        end
    end
    
    return items
end

-- Create a new loot box
local function CreateLootBox()
    if not isRSGReady then return nil end
    
    -- Check max active boxes
    local activeCount = 0
    for _ in pairs(ActiveBoxes) do
        activeCount = activeCount + 1
    end
    
    if activeCount >= Config.Settings.MaxActiveBoxes then
        return nil
    end
    
    local location = GetRandomLocation()
    if not location then
        return nil
    end
    
    local boxId = Config.Stash.Prefix .. tostring(GetGameTimer())
    local model = GetRandomModel()
    local lootPool = SelectLootPool()
    local items = GenerateLootItems(lootPool)
    
    -- Store box data
    ActiveBoxes[boxId] = {
        id = boxId,
        model = model,
        coords = location.coords,
        locationIndex = location.index,
        items = items,
        createdAt = GetGameTimer(),
        netId = nil,
        opened = false
    }
    
    -- Store stash items
    StashItems[boxId] = items
    
    -- Set cooldown for this location
    LocationCooldowns[location.index] = GetGameTimer() + (Config.Settings.RespawnTime * 1000)
    
    -- Notify clients to spawn the prop
    TriggerClientEvent('lootbox:client:spawnBox', -1, boxId, model, location.coords)

    if Config.Debug then
        print(string.format('[LootBox] Created box %s at location %d with %d items', boxId, location.index, #items))
    end
    
    return boxId
end

-- Remove a loot box
local function RemoveLootBox(boxId, reason)
    local box = ActiveBoxes[boxId]
    if not box then return end
    
    -- Untrack from cleanup system
    if box.netId then
        CleanupSystem:UntrackProp(box.netId)
    end
    
    -- Notify clients to remove the prop
    TriggerClientEvent('lootbox:client:removeBox', -1, boxId)
    
    -- Clean up stash items
    StashItems[boxId] = nil
    
    -- Remove from active boxes
    ActiveBoxes[boxId] = nil

    if Config.Debug then
        print(string.format('[LootBox] Removed box %s (reason: %s)', boxId, reason or 'unknown'))
    end
end

-- Check if stash is empty
local function IsStashEmpty(boxId)
    local items = StashItems[boxId]
    if not items then return true end
    
    return #items == 0
end

-- Spawn loop
function StartSpawnLoop()
    CreateThread(function()
        while true do
            Wait(5000) -- Check every 5 seconds
            
            -- Try to spawn a new box
            CreateLootBox()
            
            -- Check for expired boxes
            local currentTime = GetGameTimer()
            for boxId, box in pairs(ActiveBoxes) do
                if currentTime >= (box.createdAt + (Config.Settings.BoxTimeout * 1000)) then
                    RemoveLootBox(boxId, 'timeout')
                elseif box.opened and IsStashEmpty(boxId) then
                    -- Remove empty boxes after being opened
                    Wait(2000) -- Give a moment for transfer to complete
                    if IsStashEmpty(boxId) then
                        RemoveLootBox(boxId, 'emptied')
                    end
                end
            end
        end
    end)
end

-- Get stash contents
RegisterNetEvent('lootbox:server:getStashItems', function(boxId)
    local src = source
    
    if not ActiveBoxes[boxId] then
        TriggerClientEvent('lootbox:client:notify', src, 'Box not found', 'error')
        return
    end
    
    local items = StashItems[boxId] or {}
    TriggerClientEvent('lootbox:client:receiveStashItems', src, boxId, items)
end)

-- Open loot box (creates stash access)
RegisterNetEvent('lootbox:server:openBox', function(boxId)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    
    if not player then
        TriggerClientEvent('lootbox:client:notify', src, 'Cannot identify player', 'error')
        return
    end
    
    local box = ActiveBoxes[boxId]
    if not box then
        TriggerClientEvent('lootbox:client:notify', src, 'Box not found', 'error')
        return
    end
    
    -- Check distance (server-side validation)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local distance = #(playerCoords - box.coords)
    
    if distance > Config.Settings.InteractDistance + 1.0 then
        TriggerClientEvent('lootbox:client:notify', src, 'Too far from box', 'error')
        return
    end
    
    -- Mark as opened
    box.opened = true
    
    -- Open stash via RSG inventory
    -- Try to open stash through inventory export
    TriggerClientEvent('lootbox:client:openStash', src, boxId, Config.Stash.MaxSlots)
    
    -- Send stash items to client for display
    local items = StashItems[boxId] or {}
    TriggerClientEvent('lootbox:client:receiveStashItems', src, boxId, items)
end)

-- Transfer item from stash to player inventory
RegisterNetEvent('lootbox:server:transferItem', function(boxId, itemName, amount)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    
    if not player then
        TriggerClientEvent('lootbox:client:notify', src, 'Cannot identify player', 'error')
        return
    end
    
    local box = ActiveBoxes[boxId]
    if not box then
        TriggerClientEvent('lootbox:client:notify', src, 'Box not found', 'error')
        return
    end
    
    -- Validate amount
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('lootbox:client:notify', src, 'Invalid amount', 'error')
        return
    end
    
    -- Check if item exists in stash
    local stashItems = StashItems[boxId]
    local itemIndex = nil
    local availableAmount = 0
    
    for i, item in ipairs(stashItems) do
        if item.name == itemName then
            itemIndex = i
            availableAmount = item.amount
            break
        end
    end
    
    if not itemIndex then
        TriggerClientEvent('lootbox:client:notify', src, 'Item not in box', 'error')
        return
    end
    
    -- Clamp amount to available
    amount = math.min(amount, availableAmount)
    
    -- Check if player can carry item
    local canCarry = exports['rsg-inventory']:CanAddItem(src, itemName, amount)
    if not canCarry then
        TriggerClientEvent('lootbox:client:notify', src, 'Cannot carry that many items', 'error')
        return
    end
    
    -- Add item to player inventory
    local success = player.Functions.AddItem(itemName, amount)
    if not success then
        TriggerClientEvent('lootbox:client:notify', src, 'Failed to add item to inventory', 'error')
        return
    end
    
    -- Update stash
    stashItems[itemIndex].amount = stashItems[itemIndex].amount - amount
    
    -- Store label before potential removal
    local itemLabel = stashItems[itemIndex].label or GetItemLabel(itemName)
    
    -- Remove item from stash if depleted
    if stashItems[itemIndex].amount <= 0 then
        table.remove(stashItems, itemIndex)
    end
    
    -- Sync updated stash to all clients viewing this box
    TriggerClientEvent('lootbox:client:receiveStashItems', -1, boxId, stashItems)
    
    -- Notify player
    TriggerClientEvent('lootbox:client:notify', src, string.format('Transferred %dx %s', amount, itemLabel), 'success')
    
    -- Log transfer
    if Config.Debug then
        print(string.format('[LootBox] Player %s transferred %dx %s from box %s', GetPlayerName(src) or tostring(src), amount, itemName, boxId))
    end
end)

-- Take all items from stash
RegisterNetEvent('lootbox:server:takeAll', function(boxId)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    
    if not player then
        TriggerClientEvent('lootbox:client:notify', src, 'Cannot identify player', 'error')
        return
    end
    
    local box = ActiveBoxes[boxId]
    if not box then
        TriggerClientEvent('lootbox:client:notify', src, 'Box not found', 'error')
        return
    end
    
    local stashItems = StashItems[boxId]
    if not stashItems or #stashItems == 0 then
        TriggerClientEvent('lootbox:client:notify', src, 'Box is empty', 'error')
        return
    end
    
    -- Transfer all items
    local transferredCount = 0
    
    for i = #stashItems, 1, -1 do
        local item = stashItems[i]
        local canCarry = exports['rsg-inventory']:CanAddItem(src, item.name, item.amount)
        
        if canCarry then
            local success = player.Functions.AddItem(item.name, item.amount)
            if success then
                transferredCount = transferredCount + item.amount
                table.remove(stashItems, i)
            end
        end
    end
    
    -- Sync updated stash
    TriggerClientEvent('lootbox:client:receiveStashItems', -1, boxId, stashItems)
    
    if transferredCount > 0 then
        TriggerClientEvent('lootbox:client:notify', src, string.format('Transferred %d items', transferredCount), 'success')
    else
        TriggerClientEvent('lootbox:client:notify', src, 'Inventory full', 'error')
    end
end)

-- Client loaded - sync existing boxes
RegisterNetEvent('lootbox:server:playerLoaded', function()
    local src = source
    
    -- Send all active boxes to the new player
    for boxId, box in pairs(ActiveBoxes) do
        TriggerClientEvent('lootbox:client:spawnBox', src, boxId, box.model, box.coords)
    end
end)

-- Export for external resources to check active boxes
exports('GetActiveBoxes', function()
    return ActiveBoxes
end)

exports('GetStashItems', function(boxId)
    return StashItems[boxId] or {}
end)

-- Admin command to force cleanup all props
RegisterCommand('lootboxcleanup', function(source, args, rawCommand)
    local cleaned = CleanupSystem:ForceCleanup()
    
    -- Clear all active boxes as well
    ActiveBoxes = {}
    StashItems = {}
    LocationCooldowns = {}
    
    if source == 0 then
        print(string.format('[LootBox] Cleanup complete. Removed %d props.', cleaned))
    else
        TriggerClientEvent('lootbox:client:notify', source, string.format('Cleaned up %d orphaned props', cleaned), 'success')
    end
end, false)

-- Export for external resources to force cleanup
exports('ForceCleanup', function()
    return CleanupSystem:ForceCleanup()
end)

-- Export to get cleanup system stats
exports('GetCleanupStats', function()
    return {
        trackedProps = CleanupSystem:GetPropCount(),
        activeBoxes = #ActiveBoxes
    }
end)
