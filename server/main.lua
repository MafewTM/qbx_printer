local validExtensionsText = '.png, .gif, .jpg, .jpeg'
local printerID = nil

local validExtensions = {
    [".png"] = true,
    [".gif"] = true,
    [".jpg"] = true,
    ["jpeg"] = true
}

RegisterNetEvent('qbx_printer:server:saveDocument', function(url)
    local src = source
    local info = {}
    local extension = string.sub(url, -4)
    if url ~= nil then
        if validExtensions[extension] then
            print(validExtensions[extension])
            info.url = url
            exports.ox_inventory:AddItem(src, 'printerdocument', 1, info)
        else
            exports.qbx_core:Notify(src, Lang:t('error.invalid_ext', {fileext = validExtensionsText}), 'error')
        end
    end
end)

RegisterNetEvent('qbx_printer:server:createPrinter', function(newPrinterID, printerCoords)
    local src = source
    printerID = newPrinterID
    print("Got printer ID ", printerID)
    -- Generate a random initial ink value between 90 and 100
    local initialInkValue = math.random(90, 100)

    -- Insert printer information into the database
    MySQL.Async.execute(
        'INSERT INTO printers (id, ink, coords) VALUES (?, ?, ?)',
        {printerID, initialInkValue, json.encode(printerCoords)},
        function(rowsAffected)
            if rowsAffected > 0 then
                -- Successful insertion
                print('Printer created successfully!')
            else
                -- Failed insertion
                print('Failed to create printer!')
            end
        end
    )
end)

lib.callback.register('qbx_printer:server:hasPrinterGotInk', function(source, printerID)
    -- Assuming MySQL.query.await returns a table with printer data
    local result = MySQL.query.await('SELECT * FROM printers WHERE id = ? AND ink > 0', {printerID}) -- Adjust the query based on your database schema

    if result and #result > 0 then
        local printerData = result[1] -- Assuming you want data from the first row (if there are multiple)
        -- print(printerData)
        return printerData.ink
    else
        print("Printer not found in the database or ink value is not 0.")
        return false
    end
end)

-- Define a function to update printer ink value
    local function updatePrinterInk(printerID)
        -- Assuming MySQL.query.await returns a table with printer data
        local result = MySQL.query.await('SELECT * FROM printers WHERE id = ? AND ink > 0', {printerID}) -- Adjust the query based on your database schema
    
        if result and #result > 0 then
            local currentInk = result[1].ink
    
            if currentInk then
                -- Update ink value (adjust the decrement amount as needed)
                local newInk = math.max(0, currentInk - 1)
    
                -- Update ink value in the database
                MySQL.query.await('UPDATE printers SET ink = ? WHERE id = ?', {newInk, printerID})
    
                print("Printer ink updated. New ink value:", newInk)
            else
                print("Printer is not active. Ink value not updated.")
            end
        else
            print("Printer not found in the database or ink value is not 0.")
        end
    end
    

-- -- Register a timer event to call the updatePrinterInk function for a specific printer ID every ten seconds
-- CreateThread(function()
--     while true do
--     printerID = printerID
--     Wait(7000)  -- Wait for 10 seconds
--     if printerID ~= nil then
--         print(printerID," isnt nil")
--             updatePrinterInk(printerID)
--             print("Updating printer ID ",printerID)
--             Wait(6000)
--         end
--     end
-- end)

exports.qbx_core:CreateUseableItem('printerdocument', function(source, item)
    TriggerClientEvent('qbx_printer:client:useDocument', source, item)
end)

exports.qbx_core:CreateUseableItem('printer', function(source, item)
    TriggerClientEvent('qbx_printer:client:spawnPrinter', source)
end)

lib.addCommand('spawnprinter', {help = Lang:t('command.spawn_printer'), restricted = 'group.admin'}, function(source)
    TriggerClientEvent('qbx_printer:client:spawnPrinter', source)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if printerID then
            -- printerID = nil
            -- Delete printer information from the database
            -- MySQL.Async.execute(
            --     'DELETE FROM printers WHERE id = ?',
            --     {printerID},
            --     function(rowsAffected)
            --         if rowsAffected > 0 then
            --             -- Successful deletion
            --             print('Printer data deleted successfully!')
            --         else
            --             -- Failed deletion
            --             print('Failed to delete printer data!')
            --         end
            --     end
            -- )
        end
    end
end)
local function createPrinterFromData(placedPrinterData)
    local printerID = placedPrinterData.id
    local printerCoords = json.decode(placedPrinterData.coords)
    if not printerCoords then
        print("Failed to decode coordinates JSON:", placedPrinterData.coords)
        return
    end
    print("Raw JSON Coordinates:", placedPrinterData.coords)
    local vector3Coords = vector3(printerCoords.x, printerCoords.y, printerCoords.z-1) 
    TriggerClientEvent("qbx_printer:client:spawnPlacedPrinters", -1,  vector3Coords)
end

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("Resource started")
        Wait(200)
        -- Query all printers from the database
        MySQL.Async.fetchAll('SELECT * FROM printers', {}, function(result)
            if result then
                for _, placedPrinterData in ipairs(result) do
                    -- Create printers based on retrieved data
                    createPrinterFromData(placedPrinterData)
                end
            else
                print('Failed to fetch printers from the database!')
            end
        end)
    end
end)
