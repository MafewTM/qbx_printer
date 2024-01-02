local config = require "config.client"

local createdEntities = {}
local previewObjects = {}
local previewInfo = {
    velocity = 0,
    yAxis = 0,
    customHeading = 0
}
local model = config.printerProp

-- This keybind is for controlling the preview prop
local keybind = lib.addKeybind({
    name = "printer",
    description = "Operates printer",
    defaultKey = config.keyToUsePrinter,
    onReleased = function()
    local pos = GetEntityCoords(cache.ped)
    local printerObject = GetClosestObjectOfType(pos.x, pos.y, pos.z, 1.5, config.printerProp, false, false, false)
    if printerObject ~= 0 then
        TriggerEvent("qbx_printer:printer")
    elseif config.debug then
        print("Button pressed")
    end
end})

-- Open document event
RegisterNetEvent("qbx_printer:client:useDocument",function(data)
    local documentUrl = data.metadata.url ~= nil and data.metadata.url or false
    SetNuiFocus(true, true)
    SendNUIMessage({action = "openDocument", url = documentUrl})
    if config.debug then print("Using document") end
end)

local randomPrinterID = 0 
    -- Printer event
RegisterNetEvent("qbx_printer:printer",function()
    randomPrinterID = randomPrinterID -- This gets the ID of the current printer created
    local hasPaper = exports.ox_inventory:Search('count', 'water')
    local printerHasInk = lib.callback.await('qbx_printer:server:hasPrinterGotInk', source, randomPrinterID)
    print(printerHasInk)
    if not printerHasInk then
        exports.qbx_core.Notify(nil, "You printer is currently low on ink", "error")
        return 
    end
    if not hasPaper or not printerHasInk then 
        exports.qbx_core.Notify(nil, "You don't have paper on you unfortunately", "error")
        return 
    end
    exports.qbx_core.Notify(nil, "Inserted paper into printer", "info")
    SetNuiFocus(true, true)
    SendNUIMessage({action = "startPrinting"})
    if config.debug then print("Using printer") end
end)

-- Spawn printer event
RegisterNetEvent("qbx_printer:client:spawnPrinter",function()
CreateThread(function()
        local placeObjectOnGround = true
        lib.requestModel(model)
        local pos = GetEntityCoords(cache.ped)
        local heading = GetEntityHeading(cache.ped)
        previewObject = CreateObject(model, pos.x, pos.y, pos.z, true, false, false)
        SetEntityHeading(previewObject, heading)
        SetEntityAlpha(previewObject, 150, true)
        table.insert(previewObjects, previewObject)
        keybind:disable(true) -- enables the keybind
        local isChoosingSpawn = true
        lib.showTextUI(table.concat(config.initialOptionsText))
        while isChoosingSpawn do
            Wait(0)
            local optionsText = {
                "____Printer Options____  \n",
                "[E] Place Printer  \n",
                "[Right Click] Cancel  \n",
                "[←→] Move around  \n",
                "[⇅] Height  \n",
                -- "[] Height \n",
                not placeObjectOnGround and "[H] Object spawn on ground: YES" or placeObjectOnGround and "[H] Object spawn on ground: NO",
            }

            local fwdVector = GetEntityForwardVector(cache.ped)
            local x, y, z = table.unpack(GetEntityCoords(cache.ped))
            local previewOffset = 1.0 -- Adjust this value based on the desired distance from the player
            local previewPos = vector3(x + fwdVector.x * previewOffset + previewInfo.yAxis, y + fwdVector.y * previewOffset, z + fwdVector.z * previewOffset + previewInfo.velocity)
            local entityRotation = previewInfo.customHeading
            SetEntityCoords(previewObject, previewPos.x, previewPos.y, previewPos.z, true, false, false, true)
            SetEntityHeading(previewObject, entityRotation)
            SetEntityCanBeDamaged(previewObject, false)
            SetEntityCollision(previewObject, true, false)
            SetEntityNoCollisionEntity(previewObject, cache.ped, true)
            if config.drawPreviewOutline then
                SetEntityDrawOutline(previewObject, true)
                local previewColour = config.previewOutlineColour
                SetEntityDrawOutlineColor(previewColour.R, previewColour.G, previewColour.B, previewColour.A)
            end

            if IsDisabledControlPressed(0, 38) then -- Change this control to the desired key (38 is E key)
                isChoosingSpawn = false
                local obj = CreateObject(model, previewPos.x, previewPos.y, previewPos.z, false, false, false)
                SetEntityLocallyInvisible(previewObject)
                FreezeEntityPosition(obj, true)
                SetEntityHeading(model, entityRotation)
                SetModelAsNoLongerNeeded(model)
                SetEntityAsMissionEntity(obj)
                table.remove(previewObjects)
                table.insert(createdEntities, obj)
                lib.hideTextUI()
                exports.qbx_core.Notify("Success", "You placed a printer down", "success")
                randomPrinterID = math.random(1, 99900)
                TriggerServerEvent("qbx_printer:server:createPrinter", randomPrinterID, vector3(previewPos.x, previewPos.y, previewPos.z))
                print("Triggering server event ",randomPrinterID)
                if GetEntityHeightAboveGround(obj) < 0.5 or placeObjectOnGround then PlaceObjectOnGroundProperly(obj) end
                if not config.useTarget then -- Create box zone if not using target
                    function onEnter()
                        lib.showTextUI("[" .. config.keyToUsePrinter .. "] Use Printer")
                        keybind:disable(false) -- enables the keybind
                    end

                    function onExit()
                        lib.hideTextUI()
                        keybind:disable(true) -- disables the keybind
                    end

                    Wait(1000)
                    lib.showTextUI("[" .. config.keyToUsePrinter .. "] Use Printer")
                    keybind:disable(false) -- enables the keybind
                    lib.zones.box(
                        {
                            coords = vec3(x, y, z),
                            size = vec3(1.5, 1.5, 1.5),
                            rotation = 1,
                            debug = config.debug,
                            onEnter = onEnter,
                            onExit = onExit
                        }
                    )
                end
            elseif IsDisabledControlPressed(0, 175) then
                -- Right
                local rightVector = vector3(-fwdVector.y, fwdVector.x, fwdVector.z) -- Perpendicular vector for right movement
                previewInfo.yAxis = previewInfo.yAxis + 0.01
                previewPos = vector3(previewPos.x + rightVector.x * 0.01, previewPos.y + rightVector.y * 0.01, previewPos.z + rightVector.z * 0.01)
            elseif IsDisabledControlPressed(0, 174) then
                -- Left
                local leftVector = vector3(fwdVector.y, -fwdVector.x, fwdVector.z) -- Perpendicular vector for left movement
                previewInfo.yAxis = previewInfo.yAxis - 0.01
                previewPos = vector3(previewPos.x + leftVector.x * 0.01, previewPos.y + leftVector.y * 0.01, previewPos.z + leftVector.z * 0.01)
            elseif IsDisabledControlPressed(0, 172) then
                -- Up
                previewInfo.velocity = previewInfo.velocity + 0.01
            elseif IsDisabledControlPressed(0, 173) then
                -- Down
                previewInfo.velocity = previewInfo.velocity - 0.01
            elseif IsDisabledControlJustPressed(0, 74) then
                -- H
                lib.hideTextUI()
                placeObjectOnGround = not placeObjectOnGround
                lib.showTextUI(table.concat(optionsText))
            elseif IsDisabledControlPressed(
                -- z = GetGroundZFor3dCoord(previewPos.x, previewPos.y, previewPos.z, previewPos.z, false)
                0,
                14
            ) then
                -- Scroll wheel up
                previewInfo.customHeading = previewInfo.customHeading + 5
            elseif IsDisabledControlPressed(0, 15) then
                -- Scroll wheel down
                previewInfo.customHeading = previewInfo.customHeading - 5
            elseif IsDisabledControlJustPressed(0, 25) then
                -- Right click
                DeleteEntity(previewObject)
                isChoosingSpawn = false -- Cancels loop
                exports.qbx_core.Notify("Error", "You cancelled putting down a printer", "error")
                pos = nil
                heading = nil
                previewObject = nil
                lib.hideTextUI()
            end
        end
        DeleteEntity(previewObject)
    end)
end)


RegisterNetEvent("qbx_printer:client:spawnPlacedPrinters",function(placedPrinterCoords)
    CreateThread(function()
    print(placedPrinterCoords)
    lib.requestModel(model)
    local obj = CreateObject(model, placedPrinterCoords.x, placedPrinterCoords.y, placedPrinterCoords.z, false, false, false)
                table.insert(createdEntities, obj)
                FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(obj)
    PlaceObjectOnGroundProperly(obj)
    end)
end)

local printerHasInk = true
-- Main thread
CreateThread(function()
    if config.useTarget then
        local options = {
            {
                name = "printer:print",
                icon = "fas fa-print",
                label = Lang:t("info.use_printer"),
                event = "qbx_printer:printer",
                distance = 1.0,
            }
        }
        exports.ox_target:addModel(config.printerProp, options)
    end
    if config.useCommand then
        RegisterCommand("useprinter",function()
            local pos = GetEntityCoords(cache.ped)
            local printerObject = GetClosestObjectOfType(pos.x, pos.y, pos.z, 1.5, config.printerProp, false, false, false)
            if printerObject ~= 0 then
                SetNuiFocus(true, true)
                SendNUIMessage({action = "startPrinting"})
            end
        end)
    end
end)

-- NUI Callbacks
RegisterNUICallback("saveDocument",function(data, cb)
    if data.url then TriggerServerEvent("qbx_printer:server:saveDocument", data.url) end
    cb("ok")
end)

RegisterNUICallback("openedDocument", function(_, cb)
    Wait(500)
    exports.qbx_core.Notify(nil, "You have opened this document", "success")
end)

RegisterNUICallback("closeDocument", function(data, cb)
    SetNuiFocus(false, false)
    print(data.url)
    if data.url == nil then return end
    Wait(500)
    exports.qbx_core.Notify(nil, "You have closed this document", "error")
end)

AddEventHandler("onResourceStop",function(resourceName)
    if GetCurrentResourceName() == resourceName then
        lib.hideTextUI() -- Hides any text on screen
        keybind:disable(true) -- Disables keybind 


   
        for _, entity in pairs(createdEntities) do
            if DoesEntityExist(entity) then DeleteEntity(entity) end
        end

        for _, entity in pairs(previewObjects) do
            if DoesEntityExist(entity) then DeleteEntity(entity) end
        end
    end
end)

