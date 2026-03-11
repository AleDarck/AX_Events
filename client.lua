-- ============================================================
--  AX_Events | client.lua
--  Framework : New ESX 1.13.4
--  Inventory : ox_inventory
--  Lua54     : yes
-- ============================================================

local ESX = exports['es_extended']:getSharedObject()

-- ============================================================
--  UTILIDADES LOCALES
-- ============================================================

--- Carga un diccionario de animación de forma async
---@param dict string
local function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(100)
    end
end

--- Devuelve el handle del jugador abatido más cercano dentro de `maxDist`
--- Solo detecta jugadores en estado laststand / dead de esx_ambulancejob
---@param maxDist number
---@return number|nil  playerServerId, number|nil  playerPed
local function getNearestDownedPlayer(maxDist)
    local myPed    = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closest  = nil
    local closestDist = maxDist

    for _, playerId in ipairs(GetActivePlayers()) do
        local pid = GetPlayerServerId(playerId)
        if pid ~= GetPlayerServerId(PlayerId()) then
            local ped  = GetPlayerPed(playerId)
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist < closestDist then
                if Player(pid).state.isDead then
                    closestDist = dist
                    closest     = { serverId = pid, ped = ped }
                end
            end
        end
    end

    return closest
end

-- ============================================================
--  EVENTO 1 | MAPA
--  ox_inventory llama a este export desde el campo 'export' del item:
--  export = 'AX_Events.useMap'
-- ============================================================

local function useMap()
    CreateThread(function()
        SetNuiFocus(false, false)
        Wait(100)

        -- Cargar y reproducir animación de leer mapa
        local myPed = PlayerPedId()
        loadAnimDict('amb@world_human_tourist_map@male@idle_a')
        TaskPlayAnim(myPed, 'amb@world_human_tourist_map@male@idle_a', 'idle_a', 8.0, -8.0, -1, 49, 0, false, false, false)

        -- Crear y attachar el prop del mapa a la mano derecha
        local propHash = GetHashKey('prop_tourist_map_01')
        RequestModel(propHash)
        while not HasModelLoaded(propHash) do Wait(10) end

        local mapProp = CreateObject(propHash, 0, 0, 0, true, true, false)
        AttachEntityToEntity(mapProp, myPed, GetPedBoneIndex(myPed, 57005), -- mano derecha
            0.12, 0.03, 0.0,
            10.0, 170.0, 0.0,
            true, true, false, true, 1, true
        )

        ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_MP_PAUSE'), 0, -1)
        Wait(100)
        PauseMenuceptionGoDeeper(0)

        -- Loop para cerrar con ESC (tecla 200)
        while true do
            Wait(10)
            if IsControlJustPressed(0, 200) then
                SetFrontendActive(false)
                break
            end
        end

        -- Limpiar al cerrar
        StopAnimTask(myPed, 'amb@world_human_tourist_map@male@idle_a', 'idle_a', 1.0)
        DeleteObject(mapProp)
    end)
end

exports('useMap', useMap)

-- ============================================================
--  EVENTO 2 | MEDALLÓN DE PROTECCIÓN
--  Loop cada MedallonLoopDelay ms:
--  - Si tiene el medallón → addProtectionTime para mantener protección activa
--  - Si no lo tiene y estaba activo → setProtectionTime(0) para cortar
--  Ajusta MedallonRefreshSeconds en config para cuántos segundos agrega cada tick
-- ============================================================

local hasMedallon = false
local medallonItem = "medallon" -- Nombre del ítem en tu ox_inventory
local flareWeapon = "WEAPON_FLARE"
local zombieModel = "a_m_m_hillbilly_02" -- Modelo de zombie (puedes cambiarlo por otro si lo deseas)

-- Función para verificar si el jugador tiene el ítem Medallón usando ox_inventory
function checkMedallon()
    local count = exports.ox_inventory:Search('count', medallonItem)

    if count > 0 then
        if not hasMedallon then
            hasMedallon = true
            exports.hrs_zombies_V2:setProtectionTime(9999999) -- Protección indefinida
        end
    else
        if hasMedallon then
            hasMedallon = false
            exports.hrs_zombies_V2:setProtectionTime(0) -- Desactiva protección
        end
    end
end

-- Detecta cuando el jugador usa un flare para atraer zombies
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Corre en cada frame
        local playerPed = PlayerPedId()
        
        if IsPedShooting(playerPed) and GetSelectedPedWeapon(playerPed) == GetHashKey(flareWeapon) then
            local coords = GetEntityCoords(playerPed)
            -- Aumenta el "olor" del jugador para atraer zombies cercanos
            exports.hrs_zombies_V2:setExtraSmellTime(30, 50)
        end
    end
end)

-- Verificación constante del medallón
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Cada 5 segundos revisa si el jugador tiene el Medallón
        checkMedallon()
    end
end)

-- Comando para spawnear 5 zombies
RegisterCommand('spawnzombies', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    -- Spawnea 5 zombies alrededor del jugador
    for i = 1, 5 do
        local xOffset = math.random(-10, 10)
        local yOffset = math.random(-10, 10)
        local spawnCoords = vector3(coords.x + xOffset, coords.y + yOffset, coords.z)
        
        exports.hrs_zombies_V2:SpawnPed(zombieModel, spawnCoords, function(ped)
        end)
    end
end, false)

-- ============================================================
--  EVENTO 3 | MÉDICO CON IFAKS
--  ox_inventory llama a este export desde el campo 'export' del item:
--  export = 'AX_Events.useIfaks'
-- ============================================================

local isDoingRCP = false

local function useIfaks()
    if isDoingRCP then return end
    isDoingRCP = true

    Citizen.CreateThreadNow(function()
        print('[AX_Events DEBUG] useIfaks iniciado')

        local target = getNearestDownedPlayer(Config.ReviveDistance)
        print('[AX_Events DEBUG] Target: ' .. tostring(target))
        if not target then
            lib.notify({ title = 'AX Events', description = 'No hay ningún jugador abatido cerca.', type = 'error' })
            isDoingRCP = false
            return
        end
        print('[AX_Events DEBUG] Target serverId: ' .. tostring(target.serverId))

        ESX.TriggerServerCallback('AX_Events:getProfession', function(profession)
            print('[AX_Events DEBUG] Profesion recibida: ' .. tostring(profession))
            print('[AX_Events DEBUG] Profesion requerida: ' .. tostring(Config.MedicProfession))

            if profession ~= Config.MedicProfession then
                lib.notify({ title = 'AX Events', description = 'No tienes la profesión requerida.', type = 'error' })
                isDoingRCP = false
                return
            end

            CreateThread(function()
                -- Animación arrodillado
                local myPed = PlayerPedId()
                loadAnimDict('amb@medic@kneeling@tendtovictim@idle_a')
                TaskPlayAnim(myPed, 'amb@medic@kneeling@tendtovictim@idle_a', 'idle_a', 8.0, -8.0, -1, 49, 0, false, false, false)

                -- Minijuego
                local gameData = {
                    totalNumbers         = Config.MinigameData.totalNumbers,
                    seconds              = Config.MinigameData.seconds,
                    timesToChangeNumbers = Config.MinigameData.timesToChangeNumbers,
                    amountOfGames        = Config.MinigameData.amountOfGames,
                    incrementByAmount    = Config.MinigameData.incrementByAmount,
                }

                local result = exports['pure-minigames']:numberCounter(gameData)
                print('[AX_Events DEBUG] Resultado minijuego: ' .. tostring(result))
                StopAnimTask(myPed, 'amb@medic@kneeling@tendtovictim@idle_a', 'idle_a', 1.0)

                if not result then
                    lib.notify({ title = 'AX Events', description = 'Fallaste el minijuego.', type = 'error' })
                    isDoingRCP = false
                    return
                end

                TriggerServerEvent('AX_Events:removeItem', Config.IfaksItem, 1)

                loadAnimDict(Config.RCPAnim.dict)
                TaskPlayAnim(myPed, Config.RCPAnim.dict, Config.RCPAnim.anim, 8.0, -8.0, -1, Config.RCPAnim.flag, 0, false, false, false)

                print('[AX_Events DEBUG] Iniciando progressbar...')
                exports['AX_ProgressBar']:Progress({
                    duration     = Config.RCPProgressBar.duration,
                    label        = Config.RCPProgressBar.label,
                    useWhileDead = false,
                    canCancel    = true,
                    controlDisables = {
                        disableMovement    = true,
                        disableCarMovement = true,
                        disableMouse       = false,
                        disableCombat      = true,
                    },
                }, function(cancelled)
                    print('[AX_Events DEBUG] Progressbar terminada, cancelled: ' .. tostring(cancelled))
                    StopAnimTask(myPed, Config.RCPAnim.dict, Config.RCPAnim.anim, 1.0)
                    isDoingRCP = false

                    if not cancelled then
                        print('[AX_Events DEBUG] Enviando revive a serverId: ' .. tostring(target.serverId))
                        TriggerServerEvent('AX_Events:revivePlayer', target.serverId)
                        lib.notify({ title = 'AX Events', description = 'Paciente reanimado con éxito.', type = 'success' })
                    else
                        lib.notify({ title = 'AX Events', description = 'RCP cancelado.', type = 'error' })
                    end
                end)
            end)
        end)
    end)
end

exports('useIfaks', useIfaks)

-- ============================================================
--  NET EVENTS (cliente)
-- ============================================================

-- Recibir orden de revivir a este cliente (cuando otro médico nos revive)
RegisterNetEvent('AX_Events:reviveMe', function()
    local myPed = PlayerPedId()
    -- Compatibilidad con esx_ambulancejob: disparamos su evento de revivir
    TriggerEvent('esx_ambulancejob:revive')

    -- Forzar estado físico por si acaso
    NetworkResurrectLocalPlayer(
        GetEntityCoords(myPed),
        GetEntityHeading(myPed),
        true, true
    )
    SetEntityHealth(myPed, 200)
    lib.notify({ title = 'AX Events', description = 'Un médico te ha reanimado.', type = 'success' })
end)

RegisterNetEvent('AX_Events:tpRefugio', function(coords)
    local myPed = PlayerPedId()
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(myPed, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(myPed, coords.w)
    Wait(300)
    DoScreenFadeIn(500)
    lib.notify({ title = 'AX Events', description = 'Bienvenido al refugio.', type = 'success' })
end)