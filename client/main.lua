local config = require 'config.client'

RegisterNetEvent('qbx_printer:client:useDocument', function(data)
    local documentUrl = data.metadata.url ~= nil and data.metadata.url or false
    SendNUIMessage({
        action = 'open',
        url = documentUrl
    })
    SetNuiFocus(true, false)
end)

RegisterNetEvent('qbx_printer:client:spawnPrinter', function()
    local coords = GetEntityCoords(cache.ped)
    local forward = GetEntityForwardVector(cache.ped)
    local x, y, z = table.unpack(coords + forward * 1.0)

    local model = `prop_printer_01`
    lib.requestModel(model)
    local obj = CreateObject(model, x, y, z, false, false, false)
    PlaceObjectOnGroundProperly(obj)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(obj)
end)

-- NUI

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

RegisterNetEvent('qbx_printer:client:startPrinter',function()
    SendNUIMessage({
        action = 'start'
    })
    SetNuiFocus(true, true)
end)

if config.useTarget then
    CreateThread(function()
        local options = {
            {
                  name = 'printer:print',
                  icon = 'fas fa-print',
                  label = Lang:t('info.use_printer'),
                  event = 'qbx_printer:client:startPrinter',
              }
          }
          exports.ox_target:addModel(`prop_printer_01`, options)
    end)
else
    RegisterCommand('useprinter', function()
        local pos = GetEntityCoords(cache.ped)
        local printerObject = GetClosestObjectOfType(pos.x, pos.y, pos.z, 1.5, `prop_printer_01`, false, false, false)
        if printerObject ~= 0 then
            SendNUIMessage({
                action = 'start'
            })
            SetNuiFocus(true, true)
        end
    end)
end