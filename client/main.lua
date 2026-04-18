local RSGCore = exports['rsg-core']:GetCoreObject()
local SpawnedBoxes = {}
local CurrentStashItems = {}
local CurrentBoxId = nil

-- Clean up all boxes when resource stops
AddEventHandler('onClientResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if Config.Debug then
        print('[LootBox] Client resource stopping - cleaning up props...')
    end
    
    for boxId, box in pairs(SpawnedBoxes) do
        -- Remove blip
        if box.blip then
            Citizen.InvokeNative(0x4F73376BF1C557D0, box.blip)
        end
        
        -- Delete prop if we have control
        if DoesEntityExist(box.entity) then
            -- Ensure we have network control before deleting
            if NetworkHasControlOfEntity(box.entity) then
                DeleteObject(box.entity)
            else
                -- Request network control
                NetworkRequestControlOfEntity(box.entity)
                local timeout = 0
                while not NetworkHasControlOfEntity(box.entity) and timeout < 50 do
                    Wait(100)
                    timeout = timeout + 1
                end
                
                if NetworkHasControlOfEntity(box.entity) then
                    DeleteObject(box.entity)
                end
            end
        end
    end
    
    SpawnedBoxes = {}
end)

-- Handle cleanup event from shared system
AddEventHandler('lootbox:cleanup:clientStop', function()
    for boxId, box in pairs(SpawnedBoxes) do
        if box.blip then
            Citizen.InvokeNative(0x4F73376BF1C557D0, box.blip)
        end
        
        if DoesEntityExist(box.entity) then
            if NetworkHasControlOfEntity(box.entity) then
                DeleteObject(box.entity)
            end
        end
    end
    
    SpawnedBoxes = {}
end)

-- Server requests prop cleanup (for orphaned props)
RegisterNetEvent('lootbox:client:cleanupProp', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    
    if entity and entity > 0 and DoesEntityExist(entity) then
        -- Request network control
        if not NetworkHasControlOfEntity(entity) then
            NetworkRequestControlOfEntity(entity)
            local timeout = 0
            while not NetworkHasControlOfEntity(entity) and timeout < 50 do
                Wait(100)
                timeout = timeout + 1
            end
        end
        
        if NetworkHasControlOfEntity(entity) then
            DeleteObject(entity)
            if Config.Debug then
                print(string.format('[LootBox] Cleaned up orphaned prop netId=%d', netId))
            end
        end
    end
end)

-- Register loot box models
CreateThread(function()
    for _, model in ipairs(Config.LootBoxModels) do
        local hash = joaat(model)
        if not IsModelInCdimage(hash) and Config.Debug then
            print('[LootBox] Warning: Model not found: ' .. model)
        end
    end
    
    -- Request player loaded event
    TriggerServerEvent('lootbox:server:playerLoaded')
end)

-- Spawn a loot box prop
RegisterNetEvent('lootbox:client:spawnBox', function(boxId, model, coords)
    if SpawnedBoxes[boxId] then return end
    
    local hash = joaat(model)
    
    -- Load model
    RequestModel(hash, false)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(hash) and Config.Debug then
        print('[LootBox] Failed to load model: ' .. model)
        return
    end
    
    -- Create prop as a networked entity
    local prop = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z -1, true, true, false)
    SetEntityAsMissionEntity(prop, true, true)
    PlaceObjectOnGroundProperly(prop)
    Wait(1000)
    FreezeEntityPosition(prop, true)
    
    -- Get network ID for tracking
    local netId = NetworkGetNetworkIdFromEntity(prop)
    
    -- Store spawned box
    SpawnedBoxes[boxId] = {
        entity = prop,
        netId = netId,
        model = model,
        coords = GetEntityCoords(prop),
        blip = nil
    }
    
    -- Report network ID to server for tracking
    TriggerServerEvent('lootbox:server:registerPropNetId', boxId, netId)
    
    -- Create blip if enabled
    if Config.Settings.ShowBlips then
        local blip = BlipAddForCoords(1664425300, coords.x, coords.y, coords.z)
        SetBlipSprite(blip, joaat(Config.Settings.BlipSprite), true)
        SetBlipScale(blip, Config.Settings.BlipScale)
        SetBlipName(blip, 'Loot Box')
        
        SpawnedBoxes[boxId].blip = blip
    end
    
    -- Add ox_target interaction
    AddTargetInteraction(boxId, prop)
    if Config.Debug then
        print(string.format('[LootBox] Spawned box %s at %s (netId=%d)', boxId, tostring(coords), netId))
    end
end)

-- Add ox_target interaction for a loot box
function AddTargetInteraction(boxId, entity)
    exports.ox_target:addLocalEntity(entity, {
        {
            name = 'lootbox_open_' .. boxId,
            label = 'Open Loot Box',
            icon = 'fa-solid fa-box-open',
            distance = Config.Settings.InteractDistance,
            onSelect = function(data)
                OpenLootBox(boxId)
            end
        },
        {
            name = 'lootbox_examine_' .. boxId,
            label = 'Examine',
            icon = 'fa-solid fa-magnifying-glass',
            distance = Config.Settings.InteractDistance * 1.5,
            onSelect = function(data)
                ExamineBox(boxId)
            end
        }
    })
end

-- Remove a loot box
RegisterNetEvent('lootbox:client:removeBox', function(boxId)
    local box = SpawnedBoxes[boxId]
    if not box then return end
    
    -- Remove target interaction
    exports.ox_target:removeLocalEntity(box.entity, { 'lootbox_open_' .. boxId, 'lootbox_examine_' .. boxId })
    
    -- Delete prop with network control verification
    if DoesEntityExist(box.entity) then
        -- Ensure we have network control before deleting
        if not NetworkHasControlOfEntity(box.entity) then
            NetworkRequestControlOfEntity(box.entity)
            local timeout = 0
            while not NetworkHasControlOfEntity(box.entity) and timeout < 50 do
                Wait(100)
                timeout = timeout + 1
            end
        end
        
        if NetworkHasControlOfEntity(box.entity) then
            DeleteObject(box.entity)
        end
    end
    
    -- Remove blip
    if box.blip then
        Citizen.InvokeNative(0x4F73376BF1C557D0, box.blip) -- RemoveBlip
    end
    
    -- Clean up
    SpawnedBoxes[boxId] = nil
    
    -- Close stash UI if viewing this box
    if CurrentBoxId == boxId then
        lib.hideContext(false)
        CurrentBoxId = nil
        CurrentStashItems = {}
    end
    if Config.Debug then
        print('[LootBox] Removed box: ' .. boxId)
    end
end)

-- Open loot box with progress animation
function OpenLootBox(boxId)
    if lib.progressActive() then return end
    
    -- Progress bar animation
    local success = lib.progressBar({
        duration = 2000,
        label = 'Opening loot box...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            scenario = 'WORLD_HUMAN_CROUCH_DOWN'
        },
        disable = {
            move = true,
            combat = true
        }
    })
    
    if not success then
        lib.notify({ title = 'Cancelled', type = 'error' })
        return
    end
    
    -- Request to open box on server
    TriggerServerEvent('lootbox:server:openBox', boxId)
end

-- Examine box (shows basic info)
function ExamineBox(boxId)
    lib.notify({
        title = 'Loot Box',
        description = 'A mysterious box containing various items. Open it to see what\'s inside!',
        type = 'inform',
        duration = 3000
    })
end

-- Open stash UI
RegisterNetEvent('lootbox:client:openStash', function(boxId, maxSlots)
    CurrentBoxId = boxId
    
    -- Request stash items
    TriggerServerEvent('lootbox:server:getStashItems', boxId)
end)

-- Receive stash items and display menu
RegisterNetEvent('lootbox:client:receiveStashItems', function(boxId, items)
    CurrentStashItems = items
    CurrentBoxId = boxId
    
    -- Build context menu options
    local options = {}
    
    -- Add take all option at top
    if #items > 0 then
        options[#options + 1] = {
            title = '📦 Take All',
            description = 'Transfer all items to your inventory',
            icon = 'fa-solid fa-boxes-stacked',
            iconColor = '#4CAF50',
            onSelect = function()
                TriggerServerEvent('lootbox:server:takeAll', boxId)
            end
        }
        
        -- Add separator
        options[#options + 1] = {
            title = '--- Items ---',
            disabled = true
        }
        
        -- Add each item
        for i, item in ipairs(items) do
            options[#options + 1] = {
                title = string.format('%s (x%d)', item.label or item.name, item.amount),
                description = 'Click to transfer this item',
                icon = "nui://"..Config.Image..RSGCore.Shared.Items[tostring(item.name)].image,
                metadata = {
                    { label = 'Amount', value = item.amount }
                },
                onSelect = function()
                    ShowTransferDialog(boxId, item.name, item.amount)
                end
            }
        end
    else
        options[#options + 1] = {
            title = 'Empty Box',
            description = 'This box has been emptied',
            icon = 'fa-solid fa-box-open',
            disabled = true
        }
    end
    
    -- Register and show context menu
    lib.registerContext({
        id = 'lootbox_stash_' .. boxId,
        title = 'Loot Box Stash',
        options = options,
        onExit = function()
            CurrentBoxId = nil
            CurrentStashItems = {}
        end
    })
    
    lib.showContext('lootbox_stash_' .. boxId)
end)

-- Show dialog for transferring specific amount
function ShowTransferDialog(boxId, itemName, maxAmount)
    local input = lib.inputDialog('Transfer Item', {
        {
            type = 'number',
            label = 'Amount to transfer',
            placeholder = 'Enter amount',
            default = maxAmount,
            min = 1,
            max = maxAmount,
            icon = 'hashtag'
        }
    })
    
    if not input then return end
    
    local amount = tonumber(input[1])
    if not amount or amount <= 0 then
        lib.notify({ title = 'Invalid amount', type = 'error' })
        return
    end
    
    -- Progress animation for transfer
    local success = lib.progressBar({
        duration = 1500,
        label = 'Transferring items...',
        useWhileDead = false,
        canCancel = false,
        anim = {
            scenario = 'WORLD_HUMAN_CROUCH_DOWN'
        },
        disable = {
            move = true
        }
    })
    
    if success then
        TriggerServerEvent('lootbox:server:transferItem', boxId, itemName, amount)
    end
end

-- Handle notifications from server
RegisterNetEvent('lootbox:client:notify', function(message, notifyType)
    lib.notify({
        title = 'Loot Box',
        description = message,
        type = notifyType or 'inform',
        duration = 3000
    })
end)

-- Command to show nearby boxes (debug)
RegisterCommand('lootboxdebug', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearbyBoxes = {}
    
    for boxId, box in pairs(SpawnedBoxes) do
        local distance = #(playerCoords - box.coords)
        nearbyBoxes[#nearbyBoxes + 1] = {
            id = boxId,
            distance = distance,
            coords = box.coords
        }
    end
    
    -- Sort by distance
    table.sort(nearbyBoxes, function(a, b) return a.distance < b.distance end)
    
    print('[LootBox Debug] Nearby boxes:')
    for _, box in ipairs(nearbyBoxes) do
        print(string.format('  %s - Distance: %.2f', box.id, box.distance))
    end
    
    lib.notify({
        title = 'Loot Box Debug',
        description = string.format('Found %d nearby boxes. Check console for details.', #nearbyBoxes),
        type = 'inform'
    })
end, false)
