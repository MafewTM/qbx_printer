local ITEMS = exports.ox_inventory:Items()
local validExtensions = {
    ['.png'] = true,
    ['.gif'] = true,
    ['.jpg'] = true,
    ['jpeg'] = true
}

local validExtensionsText = '.png, .gif, .jpg, .jpeg'

exports.qbx_core:CreateUseableItem('printerdocument', function(source, item)
    TriggerClientEvent('qbx_printer:client:useDocument', source, item)
end)

lib.command('spawnprinter', {help = Lang:t('command.spawn_printer'), restricted = 'group.admin'}, function(source)
    TriggerClientEvent('qbx_printer:client:spawnPrinter', source)
end)

RegisterNetEvent('qbx_printer:server:saveDocument', function(url)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local info = {}
    local extension = string.sub(url, -4)
    if url ~= nil then
        if validExtensions[extension] then
            info.url = url
            player.Functions.AddItem('printerdocument', 1, nil, info)
            exports.ox_inventory:AddItem(src, 'printerdocument', 1)
        else
            exports.qbx_core:Notify(src, Lang:t('error.invalid_ext', {fileext = validExtensionsText}), 'error')
        end
    end
end)