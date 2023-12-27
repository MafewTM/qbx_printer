RegisterNetEvent('qbx_printer:client:useDocument', function(ItemData)
    local DocumentUrl = ItemData.info.url ~= nil and ItemData.info.url or false
    SendNUIMessage({
        action = "open",
        url = DocumentUrl
    })
    SetNuiFocus(true, false)
end)

RegisterNetEvent('qbx_printer:client:spawnPrinter', function()
    local playerPed = PlayerPedId()
    local coords    = GetEntityCoords(playerPed)
    local forward   = GetEntityForwardVector(playerPed)
    local x, y, z   = table.unpack(coords + forward * 1.0)

    local model = `prop_printer_01`
    RequestModel(model)
    while (not HasModelLoaded(model)) do
        Wait(1)
    end
    local obj = CreateObject(model, x, y, z, true, false, true)
    PlaceObjectOnGroundProperly(obj)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(obj)
end)

-- NUI

RegisterNUICallback('saveDocument', function(data, cb)
    if data.url then
        TriggerServerEvent('qbx_printer:server:SaveDocument', data.url)
    end
    cb('ok')
end)

RegisterNUICallback('closeDocument', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent('qbx_printer:printer',function()
    SendNUIMessage({
        action = "start"
    })
    SetNuiFocus(true, true)
end)

if Config.UseTarget then
    CreateThread(function()
        local options = {
            {
                  name = 'printer:print',
                  icon = 'fas fa-print',
                  label = Lang:t('info.use_printer'),
                  event = 'qbx_printer:printer',
              }
          }
          exports.ox_target:addModel(`prop_printer_01`, options)
    end)
else
    RegisterCommand('useprinter', function()
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local PrinterObject = GetClosestObjectOfType(pos.x, pos.y, pos.z, 1.5, `prop_printer_01`, false, false, false)
        if PrinterObject ~= 0 then
            SendNUIMessage({
                action = "start"
            })
            SetNuiFocus(true, true)
        end
    end)
end