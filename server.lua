-- ============================================================
--  AX_Events | server.lua
--  Framework : New ESX 1.13.4
--  DB        : oxmysql
--  Lua54     : yes
-- ============================================================

local ESX = exports['es_extended']:getSharedObject()

-- ============================================================
--  CALLBACK | Obtener profesión del jugador desde la BD
-- ============================================================

ESX.RegisterServerCallback('AX_Events:getProfession', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb('') return end

    local identifier = xPlayer.getIdentifier()

    local result = MySQL.scalar.await(
        'SELECT profession FROM users WHERE identifier = ?',
        { identifier }
    )

    cb(result or '')
end)

-- ============================================================
--  SERVER EVENT | Quitar item del inventario del médico
-- ============================================================

RegisterNetEvent('AX_Events:removeItem', function(itemName, amount)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    exports['ox_inventory']:RemoveItem(src, itemName, amount)
end)

-- ============================================================
--  SERVER EVENT | Revivir al jugador objetivo
-- ============================================================

RegisterNetEvent('AX_Events:revivePlayer', function(targetServerId)
    local src = source

    local xMedic = ESX.GetPlayerFromId(src)
    if not xMedic then return end

    local xTarget = ESX.GetPlayerFromId(targetServerId)
    if not xTarget then
        TriggerClientEvent('ox_lib:notify', src, { title = 'AX Events', description = 'El jugador ya no está disponible.', type = 'error' })
        return
    end

    -- Doble check profesión
    local profession = MySQL.scalar.await('SELECT profession FROM users WHERE identifier = ?', { xMedic.getIdentifier() })
    if profession ~= Config.MedicProfession then
        TriggerClientEvent('ox_lib:notify', src, { title = 'AX Events', description = 'Acción no autorizada.', type = 'error' })
        return
    end

    -- Revivir: disparamos el evento cliente del ambulancejob directamente al target
    -- y actualizamos el estado de muerte en el servidor
    TriggerClientEvent('esx_ambulancejob:revive', targetServerId)
    Player(targetServerId).state:set('isDead', false, true)
    MySQL.update('UPDATE users SET is_dead = 0 WHERE identifier = ?', { xTarget.getIdentifier() })

    -- Notificar a médicos de ambulance que el jugador ya no está muerto
    local ambulance = ESX.GetExtendedPlayers('job', 'ambulance')
    for _, xPlayer in pairs(ambulance) do
        xPlayer.triggerEvent('esx_ambulancejob:PlayerNotDead', targetServerId)
    end

    print(string.format('[AX_Events] Médico %s (id:%d) revivió a id:%d', xMedic.getName(), src, targetServerId))
end)

-- ============================================================
--  COMANDOS | REFUGIO TP
-- ============================================================

local function isAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.getGroup() == Config.RefugioAdminGroup
end

local function tpToRefugio(targetId)
    TriggerClientEvent('AX_Events:tpRefugio', targetId, Config.RefugioCoords)
end

RegisterCommand('arefugio', function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'AX Events', description = 'Sin permisos.', type = 'error' })
        return
    end

    local target = args[1]

    if not target then
        TriggerClientEvent('ox_lib:notify', source, { title = 'AX Events', description = 'Uso: /arefugio [ID|me]', type = 'error' })
        return
    end

    if target == 'me' then
        tpToRefugio(source)
    else
        local targetId = tonumber(target)
        if not targetId or not ESX.GetPlayerFromId(targetId) then
            TriggerClientEvent('ox_lib:notify', source, { title = 'AX Events', description = 'Jugador no encontrado.', type = 'error' })
            return
        end
        tpToRefugio(targetId)
    end
end, false)

RegisterCommand('arefugioall', function(source)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'AX Events', description = 'Sin permisos.', type = 'error' })
        return
    end

    for _, xPlayer in pairs(ESX.GetPlayers()) do
        tpToRefugio(xPlayer)
    end

    TriggerClientEvent('ox_lib:notify', source, { title = 'AX Events', description = 'Todos los jugadores enviados al refugio.', type = 'success' })
end, false)