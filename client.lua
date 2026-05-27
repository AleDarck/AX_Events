-- ============================================================
--  AX_Looting - client.lua
--  Framework: New ESX 1.13.4 | lua54
-- ============================================================

local ESX = exports['es_extended']:getSharedObject()

-- ============================================================
--  ESTADO LOCAL
-- ============================================================

local isUIOpen    = false
local isSearching = false
local nearbyBody  = nil       -- { entity, netId, lootType, isAnimal }
local activeNetId = nil       -- netId del cuerpo que el jugador tiene abierto
local carriedBagId  = nil   -- bagId que el jugador lleva en la mano
local carriedObject = nil   -- entidad del prop que lleva

-- ============================================================
--  HELPERS
-- ============================================================

local function getModelName(entity)
    local hash = GetEntityModel(entity)
    for k, _ in pairs(Config.LootByModel) do
        if GetHashKey(k) == hash then
            return k
        end
    end
    return nil
end

local function isAnimalModel(entity)
    -- IsPedHuman devuelve false para animales
    return not IsPedHuman(entity)
end

local function getLootType(entity)
    local modelName = getModelName(entity)
    if modelName and Config.LootByModel[modelName] then
        return Config.LootByModel[modelName]
    end
    if isAnimalModel(entity) then
        return 'animal_default'
    end
    return 'zombie_default'
end

-- ============================================================
--  FADE OUT Y ELIMINAR PED
-- ============================================================

local function fadeAndDeletePed(netId)
    -- Intentamos obtener la entidad local desde el netId
    local entity = NetToEnt(netId)
    if not entity or not DoesEntityExist(entity) then return end

    -- Fade out suave: reducir opacidad gradualmente
    CreateThread(function()
        local steps   = 20
        local delay   = 60   -- ms por step => ~1.2 segundos total
        local initial = GetEntityAlpha(entity)
        if initial <= 0 then initial = 255 end

        for i = 1, steps do
            if not DoesEntityExist(entity) then break end
            local alpha = math.floor(initial * (1 - i / steps))
            SetEntityAlpha(entity, alpha, false)
            Wait(delay)
        end

        if DoesEntityExist(entity) then
            SetEntityAlpha(entity, 0, false)
            Wait(100)
            DeleteEntity(entity)
        end
    end)
end

-- ============================================================
--  ABRIR / CERRAR UI
-- ============================================================

local function openUI(loot, netId)
    isUIOpen    = true
    activeNetId = netId
    SetNuiFocus(true, true)
    SendNUIMessage({
        action      = 'openLoot',
        items       = loot,
        imagePath   = Config.InventoryImagePath,
        revealDelay = Config.CardRevealDelay,
    })
end

local function closeUI(notifyServer)
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeLoot' })

    -- Liberar bloqueo del cuerpo en el servidor
    if notifyServer and activeNetId then
        TriggerServerEvent('AX_Looting:server:leaveBody', activeNetId)
    end
    activeNetId = nil
end

-- ============================================================
--  NUI CALLBACKS
-- ============================================================

-- Cerrar con ESC o boton cerrar (deja items disponibles para otro)
RegisterNUICallback('closeUI', function(_, cb)
    closeUI(true)
    cb('ok')
end)

-- Recoger un item individual
RegisterNUICallback('collectItem', function(data, cb)
    if data and data.name and data.count and activeNetId then
        if type(activeNetId) == 'string' and activeNetId:sub(1, 5) == 'prop_' then
            local propKey = activeNetId:sub(6)
            TriggerServerEvent('AX_Looting:server:collectPropItem', propKey, data.name, data.count)
        else
            TriggerServerEvent('AX_Looting:server:collectItem', activeNetId, data.name, data.count)
        end
    end
    cb('ok')
end)

-- Recoger todos (el servidor mandara deletePed despues)
RegisterNUICallback('collectAll', function(data, cb)
    if data and data.items and activeNetId then
        if type(activeNetId) == 'string' and activeNetId:sub(1, 5) == 'prop_' then
            local propKey = activeNetId:sub(6)
            TriggerServerEvent('AX_Looting:server:collectAllProp', propKey, data.items)
        else
            TriggerServerEvent('AX_Looting:server:collectAll', activeNetId, data.items)
        end
    end
    cb('ok')
end)

-- ============================================================
--  EVENTOS DESDE SERVIDOR
-- ============================================================

-- Abrir la UI con el loot generado
RegisterNetEvent('AX_Looting:client:openLootUI', function(loot, netId)
    openUI(loot, netId)
end)

-- El cuerpo ya fue completamente saqueado
RegisterNetEvent('AX_Looting:client:bodyEmpty', function()
    ESX.ShowNotification('Este cuerpo ya fue saqueado completamente')
end)

-- El cuerpo esta siendo looteado por alguien mas en este momento
RegisterNetEvent('AX_Looting:client:bodyInUse', function()
    ESX.ShowNotification('Alguien mas esta revisando este cuerpo')
end)

-- No se genero nada de loot
RegisterNetEvent('AX_Looting:client:noLoot', function()
    ESX.ShowNotification('No encontraste nada')
end)

-- Servidor pide borrar el ped (cuerpo vacio)
RegisterNetEvent('AX_Looting:client:deletePed', function(netId)
    -- Primero cerramos la UI sin notificar al servidor (ya sabe que esta vacio)
    if isUIOpen then
        isUIOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeLoot' })
        activeNetId = nil
    end

    -- Pequena pausa para que la animacion de cierre de la UI termine
    CreateThread(function()
        Wait(400)
        fadeAndDeletePed(netId)
    end)
end)

-- Agregar junto a los demás RegisterNetEvent del cliente:
RegisterNetEvent('AX_Looting:client:closePropUI', function()
    if isUIOpen then
        isUIOpen    = false
        activeNetId = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeLoot' })
    end
end)

-- ============================================================
--  BUSQUEDA CON PROGRESS BAR
-- ============================================================

local function startSearch(body)
    if isSearching or isUIOpen then return end

    -- Verificar arma requerida para animales
    if body.isAnimal then
        local requiredWeapon = joaat(Config.AnimalLootWeapon)
        if not HasPedGotWeapon(PlayerPedId(), requiredWeapon, false) then
            ESX.ShowNotification('Necesitas una Knife para deshuesar el animal')
            return
        end
    end

    isSearching = true

    exports['AX_ProgressBar']:Progress({
        duration        = Config.ProgressBar.duration,
        label           = body.isAnimal and 'Desollando...' or Config.ProgressBar.label,
        useWhileDead    = false,
        canCancel       = true,
        controlDisables = {
            disableMovement    = true,
            disableCarMovement = true,
            disableMouse       = false,
            disableCombat      = true,
        },
        animation = {
            animDict = Config.ProgressBar.animDict,
            anim     = Config.ProgressBar.anim,
            flags    = Config.ProgressBar.flags,
        },
    }, function(cancelled)
        isSearching = false
        if cancelled then return end

        if not body or not DoesEntityExist(body.entity) then
            ESX.ShowNotification('El cuerpo ya no esta aqui')
            return
        end

        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(body.entity))
        if dist > Config.DrawDistance + 1.5 then
            ESX.ShowNotification('Te alejaste demasiado')
            return
        end

        TriggerServerEvent('AX_Looting:server:requestLoot', body.netId, body.lootType)
    end)
end

-- ============================================================
--  THREAD 1 - Deteccion de cuerpos cercanos (lento, cada 500ms)
-- ============================================================

CreateThread(function()
    while true do
        if isUIOpen or isSearching then
            nearbyBody = nil
            Wait(500)
        else
            local playerPed    = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local found        = nil

            local peds = GetGamePool('CPed')
            for _, ped in ipairs(peds) do
                if ped ~= playerPed
                    and IsPedDeadOrDying(ped, true)
                    and not IsPedAPlayer(ped)
                    and GetEntityAlpha(ped) > 10
                then
                    local pedCoords = GetEntityCoords(ped)
                    local dist      = #(playerCoords - pedCoords)
                    if dist <= Config.DrawDistance then
                        local netId = NetworkGetNetworkIdFromEntity(ped)
                        if netId and netId ~= 0 then
                            found = {
                                entity   = ped,
                                netId    = netId,
                                lootType = getLootType(ped),
                                isAnimal = isAnimalModel(ped),
                            }
                            break
                        end
                    end
                end
            end

            nearbyBody = found
            Wait(500)
        end
    end
end)

-- ============================================================
--  THREAD 2 - Mostrar notificacion y capturar tecla (rapido)
--  Solo corre a 0ms cuando hay un cuerpo cerca
-- ============================================================

CreateThread(function()
    while true do
        if nearbyBody and not isUIOpen and not isSearching then
            local label = nearbyBody.isAnimal
                and '[E] para deshuesar el animal'
                or  '[E] para buscar en el cuerpo'

            ESX.ShowHelpNotification(label)

            if IsControlJustPressed(0, 38) then -- E
                startSearch(nearbyBody)
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ============================================================
--  CERRAR UI CON ESC
-- ============================================================

CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            if IsControlJustPressed(0, 200) then -- ESC
                closeUI(true)
            end
        else
            Wait(200)
        end
    end
end)

-- ============================================================
--  MALETIN DE JUGADOR ABATIDO
-- ============================================================

local spawnedBags = {}  -- bagId => { entity, ownerName }
local activeBagId = nil -- bagId que el jugador tiene abierto ahora

-- ============================================================
-- CAMBIO 1: spawnPlayerBag ahora crea objeto networked
-- y notifica al servidor el netId real del objeto
-- ============================================================
RegisterNetEvent('AX_Looting:client:spawnPlayerBag', function(bagId, ownerName, ownerId)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local model = Config.PlayerBag.prop
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    -- networked = true (tercer parametro de CreateObject)
    local bag = CreateObject(model, coords.x, coords.y, coords.z - 0.9, true, true, true)
    PlaceObjectOnGroundProperly(bag)
    FreezeEntityPosition(bag, true)
    SetEntityCollision(bag, false, false)

    -- Esperar NetworkId valido antes de notificar
    local attempts = 0
    while not NetworkGetEntityIsNetworked(bag) and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end

    local netId = NetworkGetNetworkIdFromEntity(bag)
    spawnedBags[bagId] = { entity = bag, ownerName = ownerName, ownerId = ownerId }

    -- Notificar al servidor con el netId para broadcast a otros jugadores
    TriggerServerEvent('AX_Looting:server:bagSpawned', bagId, ownerName, ownerId, netId)
end)

-- ============================================================
-- CAMBIO 2: registerBag ahora usa NetworkId directo
-- en vez de buscar por coords (que fallaba por timing)
-- ============================================================
RegisterNetEvent('AX_Looting:client:registerBagByNetId', function(bagId, ownerName, ownerId, netId)
    CreateThread(function()
        local entity  = nil
        local attempts = 0
        while attempts < 30 do
            entity = NetworkGetEntityFromNetworkId(netId)
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                break
            end
            Wait(200)
            attempts = attempts + 1
        end

        if entity and DoesEntityExist(entity) then
            spawnedBags[bagId] = { entity = entity, ownerName = ownerName, ownerId = ownerId }
        end
    end)
end)

-- Servidor pide eliminar el maletin (despawn por tiempo o vaciado)
RegisterNetEvent('AX_Looting:client:removeBag', function(bagId)
    local data = spawnedBags[bagId]
    if data and DoesEntityExist(data.entity) then
        DeleteEntity(data.entity)
    end
    spawnedBags[bagId] = nil
    if carriedBagId == bagId then carriedBagId = nil end
end)

-- Maletin vaciado completamente: cerrar UI y borrar prop
RegisterNetEvent('AX_Looting:client:deleteBag', function(bagId)
    if isUIOpen and activeBagId == bagId then
        isUIOpen    = false
        activeBagId = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeLoot' })
    end

    CreateThread(function()
        Wait(400)
        local data = spawnedBags[bagId]
        if data and DoesEntityExist(data.entity) then
            -- Fade out suave
            for i = 1, 20 do
                if DoesEntityExist(data.entity) then
                    SetEntityAlpha(data.entity, math.floor(255 * (1 - i/20)), false)
                end
                Wait(60)
            end
            if DoesEntityExist(data.entity) then DeleteEntity(data.entity) end
        end
        spawnedBags[bagId] = nil
        if carriedBagId == bagId then carriedBagId = nil end
    end)
end)

-- Abrir UI del maletin
RegisterNetEvent('AX_Looting:client:openBagUI', function(items, bagId)
    activeBagId = bagId
    activeNetId = nil  -- aseguramos que no haya conflicto con loot de zombies
    isUIOpen    = true
    SetNuiFocus(true, true)

    local data     = spawnedBags[bagId]
    local bagTitle = data and ('MALETIN DE ' .. string.upper(data.ownerName)) or 'MALETIN'

    SendNUIMessage({
        action      = 'openBagUI',
        items       = items,
        imagePath   = Config.InventoryImagePath,
        revealDelay = Config.CardRevealDelay,
        title       = bagTitle,
    })
end)

-- NUI: cerrar maletin manualmente
RegisterNUICallback('closeBag', function(_, cb)
    if activeBagId then
        TriggerServerEvent('AX_Looting:server:leaveBag', activeBagId)
    end
    isUIOpen    = false
    activeBagId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeLoot' })
    cb('ok')
end)

-- NUI: recoger item del maletin
RegisterNUICallback('collectBagItem', function(data, cb)
    if activeBagId and data and data.name and data.count then
        TriggerServerEvent('AX_Looting:server:collectBagItem', activeBagId, data.name, data.count)
    end
    cb('ok')
end)

-- NUI: recoger todo del maletin
RegisterNUICallback('collectAllBag', function(data, cb)
    if activeBagId and data and data.items then
        TriggerServerEvent('AX_Looting:server:collectAllBag', activeBagId, data.items)
    end
    cb('ok')
end)

-- ============================================================
--  THREAD - Deteccion de maletines cercanos
-- ============================================================

local function isPlayerDowned()
    local ped = PlayerPedId()
    if IsPedDeadOrDying(ped, true) then return true end
    if LocalPlayer.state.dead then return true end
    -- esx_ambulancejob pone al jugador en esta animacion al abatirlo
    local dict = GetEntityAnimCurrentTime(ped, 'dead', 'dead_a')
    if dict > 0 then return true end
    -- Verificacion por estado de salud critico
    if GetEntityHealth(ped) <= 100 and not IsPedInAnyVehicle(ped, false) then
        local animDict = GetAnimCurrentTime(ped, 'amb@world_human_dead_lying@face_up@base', 'base')
        if animDict > 0 then return true end
    end
    return false
end

-- ============================================================
-- CAMBIO 3: confirmPickup y denyPickup declarados UNA SOLA VEZ
-- aqui, antes del thread. Eliminados del final del archivo.
-- confirmPickup NO asigna carriedBagId directamente: el thread
-- lo lee en el siguiente ciclo y hace el attach correctamente.
-- ============================================================
RegisterNetEvent('AX_Looting:client:confirmPickup', function(bagId)
    carriedBagId = bagId
end)

RegisterNetEvent('AX_Looting:client:denyPickup', function(reason)
    ESX.ShowNotification(reason)
end)

CreateThread(function()
    while true do
        if isUIOpen then
            Wait(300)
        else
            local playerCoords = GetEntityCoords(PlayerPedId())
            local foundBag     = nil

            for bagId, data in pairs(spawnedBags) do
                if DoesEntityExist(data.entity) and bagId ~= carriedBagId then
                    local dist = #(playerCoords - GetEntityCoords(data.entity))
                    if dist <= Config.DrawDistance then
                        foundBag = { bagId = bagId, data = data }
                        break
                    end
                end
            end

            local myId   = GetPlayerServerId(PlayerId())
            local isDead = LocalPlayer.state.isDead or false
            local isMine = foundBag and foundBag.data.ownerId == myId

            if carriedBagId then
                local bagData = spawnedBags[carriedBagId]

                if not bagData or not DoesEntityExist(bagData.entity) then
                    carriedBagId = nil
                    Wait(0)
                else
                    local ped       = PlayerPedId()
                    local boneIndex = GetPedBoneIndex(ped, 57005)
                    AttachEntityToEntity(bagData.entity, ped, boneIndex,
                        0.18, -0.02, -0.03,
                        -87.16, 5.38, 75.64,
                        false, false, false, false, 2, true)

                    ESX.ShowNotification('Llevas la bolsa. Presiona (X) para soltarla')

                    if IsControlJustPressed(0, 73) then -- X
                        DetachEntity(bagData.entity, true, true)
                        FreezeEntityPosition(bagData.entity, true)
                        PlaceObjectOnGroundProperly(bagData.entity)
                        TriggerServerEvent('AX_Looting:server:dropBag', carriedBagId)
                        carriedBagId = nil
                    end

                    Wait(0)
                end

            elseif foundBag and not isSearching and (not isMine or not isDead) then
    local currentBagId = foundBag.bagId
    ESX.ShowHelpNotification('[E] para lootear el maletin')
    ESX.ShowHelpNotification('[G] para cargar el maletin')

    if IsControlJustPressed(0, 38) then -- E
        if isMine and isDead then
            ESX.ShowNotification('No puedes abrir tu maletin mientras estas abatido')
        else
            isSearching = true
            local bagResult = nil -- nil=esperando, false=cancelado, true=completado

            exports['AX_ProgressBar']:Progress({
                duration = Config.ProgressBar.duration,
                label    = 'Registrando maletin...',
                useWhileDead = false,
                canCancel    = true,
                controlDisables = {
                    disableMovement    = true,
                    disableCarMovement = true,
                    disableMouse       = false,
                    disableCombat      = true,
                },
                animation = {
                    animDict = Config.ProgressBar.animDict,
                    anim     = Config.ProgressBar.anim,
                    flags    = Config.ProgressBar.flags,
                },
            }, function(cancelled)
                bagResult = not cancelled -- true si completo, false si cancelado
            end)

            -- Esperar resultado en el thread principal
            CreateThread(function()
                while bagResult == nil do
                    Wait(50)
                end
                isSearching = false
                if bagResult then
                    TriggerServerEvent('AX_Looting:server:requestBagLoot', currentBagId)
                end
            end)
        end
    end

    if IsControlJustPressed(0, 47) then -- G
        if isMine and isDead then
            ESX.ShowNotification('No puedes tomar tu maletin mientras estas abatido')
        else
            TriggerServerEvent('AX_Looting:server:requestPickupBag', currentBagId)
        end
    end

    Wait(0)
            else
                Wait(500)
            end
        end
    end
end)

-- ============================================================
--  LOOT DE PROPS
-- ============================================================

local nearbyProp    = nil   -- { entity, hash, modelName, lootType, coords }
local isSearchingProp = false

-- Construye un lookup hash->modelName una sola vez al arrancar
local propHashLookup = {}
for modelName, _ in pairs(Config.PropLoot.models) do
    propHashLookup[GetHashKey(modelName)] = modelName
end

-- ============================================================
--  THREAD - Deteccion de props cercanos (cada 600ms)
-- ============================================================

CreateThread(function()
    while true do
        if isUIOpen or isSearching or isSearchingProp then
            nearbyProp = nil
            Wait(600)
        else
            local playerCoords = GetEntityCoords(PlayerPedId())
            local found        = nil

            local objects = GetGamePool('CObject')
            for _, obj in ipairs(objects) do
                local objCoords = GetEntityCoords(obj)
                local dist      = #(playerCoords - objCoords)
                if dist <= Config.PropLoot.drawDistance then
                    local hash      = GetEntityModel(obj)
                    local modelName = propHashLookup[hash]
                    if modelName then
                        found = {
                            entity    = obj,
                            hash      = hash,
                            modelName = modelName,
                            lootType  = Config.PropLoot.models[modelName],
                            coords    = objCoords,
                        }
                        break
                    end
                end
            end

            nearbyProp = found
            Wait(600)
        end
    end
end)

-- ============================================================
--  THREAD - Notificacion + tecla E para props
-- ============================================================

CreateThread(function()
    while true do
        if nearbyProp and not isUIOpen and not isSearching and not isSearchingProp then
            ESX.ShowHelpNotification('[E] para buscar en el objeto')

            if IsControlJustPressed(0, 38) then -- E
                local prop = nearbyProp
                isSearchingProp = true

                exports['AX_ProgressBar']:Progress({
                    duration        = Config.PropLoot.progressBar.duration,
                    label           = Config.PropLoot.progressBar.label,
                    useWhileDead    = false,
                    canCancel       = true,
                    controlDisables = {
                        disableMovement    = true,
                        disableCarMovement = true,
                        disableMouse       = false,
                        disableCombat      = true,
                    },
                    animation = {
                        animDict = Config.PropLoot.progressBar.animDict,
                        anim     = Config.PropLoot.progressBar.anim,
                        flags    = Config.PropLoot.progressBar.flags,
                    },
                }, function(cancelled)
                    isSearchingProp = false
                    if cancelled then return end

                    -- Verificar que el prop sigue cerca
                    if not DoesEntityExist(prop.entity) then return end
                    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(prop.entity))
                    if dist > Config.PropLoot.drawDistance + 1.0 then
                        ESX.ShowNotification('Te alejaste demasiado')
                        return
                    end

                    -- Usar coords como identificador unico del prop
                    local coords = GetEntityCoords(prop.entity)
                    TriggerServerEvent('AX_Looting:server:requestPropLoot',
                        prop.lootType,
                        coords.x, coords.y, coords.z,
                        prop.modelName
                    )
                end)
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ============================================================
--  EVENTO: abrir UI de prop (reutiliza la misma UI de zombies)
-- ============================================================

RegisterNetEvent('AX_Looting:client:openPropLootUI', function(loot, propKey)
    isUIOpen    = true
    activeNetId = 'prop_' .. propKey
    SetNuiFocus(true, true)
    SendNUIMessage({
        action      = 'openLoot',
        items       = loot,
        imagePath   = Config.InventoryImagePath,
        revealDelay = Config.CardRevealDelay,
        title       = 'OBJETOS ENCONTRADOS',
    })
end)

-- ============================================================
--  EVENTO: prop en cooldown
-- ============================================================

RegisterNetEvent('AX_Looting:client:propOnCooldown', function(secondsLeft)
    local mins = math.floor(secondsLeft / 60)
    local secs = secondsLeft % 60
    if mins > 0 then
        ESX.ShowNotification(string.format('Este objeto fue revisado recientemente. Vuelve en %d min %d seg', mins, secs))
    else
        ESX.ShowNotification(string.format('Este objeto fue revisado recientemente. Vuelve en %d seg', secs))
    end
end)