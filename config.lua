Config = {}

-- ============================================================
--  EVENTO 1 | MAPA
-- ============================================================
Config.MapItem = 'map'             -- Nombre exacto del item en ox_inventory

-- ============================================================
--  EVENTO 2 | MEDALLÓN DE PROTECCIÓN
-- ============================================================
Config.MedallonItem          = 'medallon'   -- Nombre exacto del item en ox_inventory
Config.MedallonLoopDelay     = 10000        -- ms entre cada check del loop (10 seg)
Config.MedallonRefreshSeconds = 20          -- segundos de protección que se agregan cada tick
                                            -- debe ser > MedallonLoopDelay/1000 para que no haya huecos

-- ============================================================
--  EVENTO 3 | MÉDICO CON IFAKS
-- ============================================================
Config.IfaksItem         = 'ifaks'      -- Nombre exacto del item en ox_inventory
Config.MedicProfession   = 'medico'     -- Valor exacto en la columna `profession` de users
Config.ReviveDistance    = 3.0          -- Distancia máxima para detectar al jugador abatido (metros)

Config.RCPProgressBar = {
    duration = 8000,
    label    = 'Realizando RCP...',
}

Config.MinigameData = {
    totalNumbers         = 15,
    seconds              = 20,
    timesToChangeNumbers = 4,
    amountOfGames        = 1,  -- era 2
    incrementByAmount    = 5,
}

-- Animación de RCP que se reproduce durante la progressbar
Config.RCPAnim = {
    dict   = 'mini@cpr@char_a@cpr_str',
    anim   = 'cpr_pumpchest',
    flag   = 33,
}

-- ============================================================
--  COMANDO | REFUGIO TP
-- ============================================================
Config.RefugioCoords = vector4(-569.6729, 5275.0112, 70.2600, 159.9754) -- x, y, z, heading
Config.RefugioAdminGroup = 'admin'