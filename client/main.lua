local config = require 'config.client'
local createdEntities = {}  -- Keep track of created entities

-- Keybind for operating the printer
local keybind = lib.addKeybind({
    name = 'printer',
    description = 'Operates printer',
    defaultKey = 'E',
    onReleased = function(self)
        local pos = GetEntityCoords(cache.ped)
        local printerObject = GetClosestObjectOfType(pos.x, pos.y, pos.z, 1.5, config.printerProp, false, false, false)
        
        if printerObject ~= 0 then
            TriggerEvent("qbx_printer:printer")
        elseif config.debug then
            print("Button pressed")
        end
    end
})

-- Open document event
RegisterNetEvent('qbx_printer:client:useDocument', function(data)
    local documentUrl = data.metadata.url ~= nil and data.metadata.url or false
    
    SendNUIMessage({
        action = 'open',
        url = documentUrl
    })
    
    SetNuiFocus(true, false)
    
    if config.debug then
        print("Using document")
    end
end)

-- Printer event
RegisterNetEvent('qbx_printer:printer', function()
    SendNUIMessage({
        action = 'start'
    })
    
    SetNuiFocus(true, true)
    
    if config.debug then
        print("Using printer")
    end
end)

-- Spawn printer event
RegisterNetEvent('qbx_printer:client:spawnPrinter', function()
    local coords = GetEntityCoords(cache.ped)
    local forward = GetEntityForwardVector(cache.ped)
    local x, y, z = table.unpack(coords + forward * 1.0)
    local model = config.printerProp
    
    lib.requestModel(model, 2000)
    
    local obj = CreateObject(model, x, y, z, false, false, false)
    PlaceObjectOnGroundProperly(obj)
    
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(obj)
    
    table.insert(createdEntities, obj)
    
    if not config.useTarget then
        function onEnter(self)
            lib.showTextUI("[E] Use Printer")
            keybind:disable(false) -- enables the keybind
        end
        
        function onExit(self)
            lib.hideTextUI()
            keybind:disable(true) -- disables the keybind
        end

        local box = lib.zones.box({
            coords = vec3(x, y, z),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 1,
            debug = config.debug,
            onEnter = onEnter,
            onExit = onExit
        })
    end
end)

-- Main thread
CreateThread(function()
    if config.useTarget then
        local options = {{
            name = 'printer:print',
            icon = 'fas fa-print',
            label = Lang:t('info.use_printer'),
            event = 'qbx_printer:printer',
        }}
        
        exports.ox_target:addModel(config.printerProp, options)
    end
    
    if config.useCommand then
        RegisterCommand('useprinter', function()
            local pos = GetEntityCoords(cache.ped)
            local printerObject = GetClosestObjectOfType(pos.x, pos.y, pos.z, 1.5, config.printerProp, false, false, false)
            
            if printerObject ~= 0 then
                SendNUIMessage({
                    action = 'start'
                })
                
                SetNuiFocus(true, true)
            end
        end)
    end
end)

-- NUI Callbacks
RegisterNUICallback('saveDocument', function(data, cb)
    if data.url then
        TriggerServerEvent('qbx_printer:server:saveDocument', data.url)
    end
    
    cb('ok')
end)

RegisterNUICallback('closeDocument', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Start printer event
RegisterNetEvent('qbx_printer:client:startPrinter', function()
    SendNUIMessage({
        action = 'start'
    })
    
    SetNuiFocus(true, true)
end)

-- On resource restart
local function deleteAllEntities()
    for _, entity in pairs(createdEntities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
            lib.hideTextUI()
            keybind:disable(true) -- disables the keybind
        end
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        deleteAllEntities()
    end
end)
