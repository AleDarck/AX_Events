Config = {}

-- ============================================================
--  CONFIGURACION GENERAL
-- ============================================================

Config.DrawDistance        = 3.0          -- distancia maxima para interactuar con el cadaver (metros)
Config.SearchCooldown      = 0.5          -- segundos de espera entre deteccion de cuerpos
Config.LootedRespawnTime   = 300          -- segundos antes de que un cadaver looteado pueda volver a ser looteado (solo en memoria)

Config.ProgressBar = {
    duration = 3000,
    label    = 'Reparando...',
    animDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
    anim     = 'machinic_loop_mechandplayer',
    flags    = 1, -- Usamos 1 para que realice la animación de cuerpo completo agachado
}

Config.CardRevealDelay = 180  -- milisegundos entre aparicion de cada card en la UI

-- ============================================================
--  IMAGENES DEL INVENTARIO (ox_inventory)
-- ============================================================

Config.InventoryImagePath = 'nui://ox_inventory/web/images/'  -- ruta base para imagenes

-- ============================================================
--  TIPOS DE LOOT
--  fixedLoots      => siempre se otorgan al lootear
--  probabilityLoots => se eligen aleatoriamente segun probabilidad
--    loop    = cuantas veces se recorre la tabla de items
--    items   = lista de posibles drops
--      names       = lista de items posibles (se elige uno al azar del grupo)
--      minValue    = cantidad minima
--      maxValue    = cantidad maxima
--      probability = probabilidad en % (la suma NO puede superar 100)
-- ============================================================

Config.Types = {

    -- -------------------------------------------------------
    --  ZOMBIES
    -- -------------------------------------------------------
    ['zombie_default'] = {
        fixedLoots = {},
        probabilityLoots = {
            loop = 5,
            items = {
                { names = { 'card_id', 'bank_card', 'iphone', 'samsungphone', 'tablet', 'battery' },    minValue = 1, maxValue = 2, probability = 20 },
                { names = { 'card_bank', 'driver_license', 'laptop', 'phone', 'gps' },                  minValue = 1, maxValue = 2, probability = 20 },
                { names = { 'tela' },                                                                   minValue = 1, maxValue = 3, probability = 10 },
                { names = { 'map' },                                                                    minValue = 1, maxValue = 1, probability = 1  },
                { names = { 'black_money' },                                                            minValue = 1, maxValue = 20, probability = 15 },
            }
        },
    },

    ['zombie_boss'] = {
        fixedLoots = {
            { name = 'bandage', count = 1 },
        },
        probabilityLoots = {
            loop = 4,
            items = {
                { names = { 'bpminismg', 'bpsnspistol' },                  minValue = 1, maxValue = 1, probability = 10  },
                { names = { 'ammo-9', 'ammo-rifle', 'ammo-shotgun' },       minValue = 10, maxValue = 30, probability = 40 },
                { names = { 'money' },                                       minValue = 50, maxValue = 200, probability = 25 },
                { names = { 'bandage', 'medkit' },                           minValue = 1, maxValue = 2, probability = 25 },
            }
        },
    },

    -- -------------------------------------------------------
    --  ANIMALES
    -- -------------------------------------------------------
    ['animal_default'] = {
        fixedLoots = {},
        probabilityLoots = {
            loop = 2,
            items = {
                { names = { 'cuero_crudo', 'bonefragments' },  minValue = 1, maxValue = 2, probability = 35 },
                { names = { 'retales_de_cuero', 'fatanimal' }, minValue = 1, maxValue = 3, probability = 20 },
            }
        },
    },

    ['pig_loot'] = {
        fixedLoots = {
            { name = 'bearmeat', count = 1 },
        },
        probabilityLoots = {
            loop = 1,
            items = {
                { names = { 'cuero_crudo' }, minValue = 1, maxValue = 2, probability = 50 },
                { names = { 'fatanimal' },   minValue = 1, maxValue = 2, probability = 30 },
            }
        },
    },

    ['dog_loot'] = {
        fixedLoots = {
            { name = 'wolfmeat', count = 1 },
        },
        probabilityLoots = {
            loop = 1,
            items = {
                { names = { 'bonefragments' }, minValue = 1, maxValue = 2, probability = 40 },
            }
        },
    },

    ['bird_loot'] = {
        fixedLoots = {
            { name = 'horsemeatcooked', count = 1 },
        },
    },

    ['deer_loot'] = {
        fixedLoots = {
            { name = 'dearmeatcooked', count = 1 },
        },
        probabilityLoots = {
            loop = 1,
            items = {
                { names = { 'cuero_crudo', 'bonefragments' }, minValue = 1, maxValue = 3, probability = 60 },
            }
        },
    },

    ['cow_loot'] = {
        fixedLoots = {
            { name = 'dearmeatcooked', count = 2 },
        },
        probabilityLoots = {
            loop = 1,
            items = {
                { names = { 'cuero_crudo' }, minValue = 2, maxValue = 4, probability = 70 },
            }
        },
    },

    ['rabbit_loot'] = {
        fixedLoots = {
            { name = 'horsemeatcooked', count = 1 },
        },
    },

    ['rat_loot'] = {
        fixedLoots = {
            { name = 'horsemeatcooked', count = 1 },
        },
    },
}

-- ============================================================
--  MAPEO MODEL => TIPO DE LOOT
--  Si el modelo del ped/animal no esta aqui se usara el tipo
--  'zombie_default' para peds y 'animal_default' para animales
-- ============================================================

Config.LootByModel = {
    -- Zombies especiales
    ['nc_zombie_a']   = 'zombie_boss',

    -- Animales
    ['a_c_boar']      = 'pig_loot',
    ['a_c_pig']       = 'pig_loot',
    ['a_c_cat_01']    = 'dog_loot',
    ['a_c_chickenhawk'] = 'bird_loot',
    ['a_c_crow']      = 'bird_loot',
    ['a_c_pigeon']    = 'bird_loot',
    ['a_c_hen']       = 'bird_loot',
    ['a_c_seagull']   = 'bird_loot',
    ['a_c_chop']      = 'dog_loot',
    ['a_c_shepherd']  = 'dog_loot',
    ['a_c_coyote']    = 'dog_loot',
    ['a_c_husky']     = 'dog_loot',
    ['a_c_poodle']    = 'dog_loot',
    ['a_c_pug']       = 'dog_loot',
    ['a_c_retriever'] = 'dog_loot',
    ['a_c_westy']     = 'dog_loot',
    ['a_c_rottweiler'] = 'dog_loot',
    ['a_c_cow']       = 'cow_loot',
    ['a_c_deer']      = 'deer_loot',
    ['a_c_mtlion']    = 'deer_loot',
    ['a_c_rabbit_01'] = 'rabbit_loot',
    ['a_c_rat']       = 'rat_loot',
}

-- ============================================================
--  LOOT DE PROPS
-- ============================================================

Config.PropLoot = {
    drawDistance = 2.5,       -- metros para detectar el prop
    cooldown     = 600,       -- segundos de cooldown global por prop (en memoria)

    progressBar = {
        duration = 4000,
        label    = 'Buscando objetos...',
        animDict = 'amb@prop_human_bum_bin@base',
        anim     = 'base',
        flags    = 49,
    },

    -- Mapeo modelo => tipo de loot
    -- El tipo de loot usa la misma estructura de Config.Types
    models = {
        -- Basura
        ['prop_dumpster_3a']          = 'prop_trash',
        ['prop_skip_05a']             = 'prop_trash',
        ['prop_dumpster_4b']          = 'prop_trash',
        ['prop_bin_14a']              = 'prop_trash',
        ['prop_dumpster_4a']          = 'prop_trash',
        ['prop_dumpster_01a']         = 'prop_trash',
        ['prop_dumpster_02a']         = 'prop_trash',
        ['prop_dumpster_02b']         = 'prop_trash',
        ['prop_rub_binbag_sd_01']     = 'prop_trash',
        ['prop_ld_rub_binbag_01']     = 'prop_trash',
        ['prop_rub_binbag_sd_02']     = 'prop_trash',
        ['prop_ld_binbag_01']         = 'prop_trash',
        ['prop_cs_rub_binbag_01']     = 'prop_trash',
        ['prop_cs_street_binbag_01']  = 'prop_trash',
        ['prop_rub_binbag_03b']       = 'prop_trash',
        ['prop_rub_binbag_04']        = 'prop_trash',
        ['prop_rub_binbag_01']        = 'prop_trash',
        ['prop_rub_binbag_08']        = 'prop_trash',
        ['prop_rub_binbag_05']        = 'prop_trash',
        ['prop_rub_binbag_06']        = 'prop_trash',
        ['prop_rub_binbag_03']        = 'prop_trash',
        ['prop_rub_binbag_01b']       = 'prop_trash',
        ['hei_prop_heist_binbag']     = 'prop_trash',
        ['ng_proc_binbag_01a']        = 'prop_trash',
        ['p_binbag_01_s']             = 'prop_trash',
        -- Autos destruidos
        ['prop_rub_carwreck_1']       = 'prop_carwreck',
        ['prop_rub_carwreck_2']       = 'prop_carwreck',
        ['prop_rub_carwreck_3']       = 'prop_carwreck',
        ['prop_rub_carwreck_5']       = 'prop_carwreck',
        ['prop_rub_carwreck_6']       = 'prop_carwreck',
        ['prop_rub_carwreck_7']       = 'prop_carwreck',
        ['prop_rub_carwreck_8']       = 'prop_carwreck',
        ['prop_rub_carwreck_9']       = 'prop_carwreck',
        ['prop_rub_carwreck_10']      = 'prop_carwreck',
        ['prop_rub_carwreck_11']      = 'prop_carwreck',
        ['prop_rub_carwreck_12']      = 'prop_carwreck',
        ['prop_rub_carwreck_13']      = 'prop_carwreck',
        ['prop_rub_carwreck_14']      = 'prop_carwreck',
        ['prop_rub_carwreck_15']      = 'prop_carwreck',
        ['prop_rub_carwreck_16']      = 'prop_carwreck',
        ['prop_rub_carwreck_17']      = 'prop_carwreck',
        ['prop_rub_carwreck_18']      = 'prop_carwreck',
        ['prop_rub_carwreck_19']      = 'prop_carwreck',
        ['prop_rub_carwreck_20']      = 'prop_carwreck',
        -- Cajas de municion
        ['prop_box_ammo01a']          = 'prop_ammobox',
        ['prop_box_ammo02a']          = 'prop_ammobox',
        ['prop_box_ammo04a']          = 'prop_ammobox',
        ['prop_box_ammo06a']          = 'prop_ammobox_big',
        ['hei_prop_hei_ammo_single']  = 'prop_ammobox_big',
        ['hei_prop_hei_ammo_pile']    = 'prop_ammobox_big',
        -- Cajas de pistolas
        ['prop_box_guncase_02a']      = 'prop_guncase',
        ['prop_box_guncase_01a']      = 'prop_guncase',
        ['prop_box_guncase_03a']      = 'prop_guncase',
        -- ATM
        ['prop_atm_01']               = 'prop_atm',
        ['prop_atm_02']               = 'prop_atm',
        ['prop_fleeca_atm']           = 'prop_atm',
    },
}

-- Tipos de loot de props (misma estructura que Config.Types)
Config.Types['prop_trash'] = {
    fixedLoots = {},
    probabilityLoots = {
        loop = 2,
        items = {
            { names = { 'tornillos', 'plastic' },   minValue = 1, maxValue = 2, probability = 40 },
            { names = { 'tela', 'rubber' },          minValue = 1, maxValue = 2, probability = 25 },
            { names = { 'metalscrap' },              minValue = 1, maxValue = 3, probability = 20 },
        }
    },
}

Config.Types['prop_carwreck'] = {
    fixedLoots = {},
    probabilityLoots = {
        loop = 3,
        items = {
            { names = { 'metalscrap' },                                                minValue = 1, maxValue = 4, probability = 35 },
            { names = { 'cables', 'rubber', 'steel' },                                 minValue = 1, maxValue = 2, probability = 25 },
            { names = { 'bombilla', 'batterycarox', 'freinox', 'exhaustox' },          minValue = 1, maxValue = 1, probability = 20 },
            { names = { 'tornillos', 'oxtuercas', 'oxresorte' },                       minValue = 1, maxValue = 3, probability = 15 },
        }
    },
}

Config.Types['prop_ammobox'] = {
    fixedLoots = {},
    probabilityLoots = {
        loop = 2,
        items = {
            { names = { 'ammo-9', 'ammo-45' },             minValue = 5,  maxValue = 15, probability = 40 },
            { names = { 'ammo-shotgun', 'ammo-rifle' },     minValue = 5,  maxValue = 10, probability = 30 },
            { names = { 'emptyammo9', 'emptyammo45' },      minValue = 5,  maxValue = 10, probability = 20 },
        }
    },
}

Config.Types['prop_ammobox_big'] = {
    fixedLoots = {},
    probabilityLoots = {
        loop = 4,
        items = {
            { names = { 'ammo-9', 'ammo-45' },             minValue = 10, maxValue = 30, probability = 35 },
            { names = { 'ammo-shotgun', 'ammo-rifle' },     minValue = 10, maxValue = 20, probability = 30 },
            { names = { 'ammo-sniper' },                    minValue = 5,  maxValue = 10, probability = 15 },
            { names = { 'emptyammo9', 'emptyammo5_56' },   minValue = 10, maxValue = 20, probability = 15 },
        }
    },
}

Config.Types['prop_guncase'] = {
    fixedLoots = {},
    probabilityLoots = {
        loop = 1,
        items = {
            { names = { 'bpsnspistol', 'appistol_part_1', 'appistol_part_2' }, minValue = 1, maxValue = 1, probability = 30 },
            { names = { 'ammo-9', 'ammo-45' },                                  minValue = 5, maxValue = 15, probability = 50 },
        }
    },
}

Config.Types['prop_atm'] = {
    fixedLoots = {},
    probabilityLoots = {
        loop = 1,
        items = {
            { names = { 'money' }, minValue = 50, maxValue = 300, probability = 80 },
        }
    },
}

-- ============================================================
--  MALETIN DE JUGADOR ABATIDO
-- ============================================================

Config.PlayerBag = {
    prop            = 'prop_cs_heist_bag_02',
    despawnMinutes  = 45,          -- minutos hasta que desaparece si nadie lo recoge
    protectedItems  = {           -- items que NUNCA caen al maletin
        'medallon',
    },
}

Config.AnimalLootWeapon = 'weapon_knife'  -- arma requerida para lootear animales

Config.DiscordWebhook = 'https://discord.com/api/webhooks/1478532917213794612/9fLQKjUXdYIz6xdC2_yKBg_OtKjTZOi0gmg7ZDzkM3pMwaFpnckFQ9BtmTgI8RYlZ1Dd'

for typeName, typeData in pairs(Config.Types) do
    if typeData.probabilityLoots and typeData.probabilityLoots.items then
        local total = 0
        for _, item in ipairs(typeData.probabilityLoots.items) do
            total = total + item.probability
        end
        if total > 100 then
            print(string.format('[^3AX_Looting^7] ADVERTENCIA: La suma de probabilidades en "%s" supera el 100%% (%d%%)', typeName, total))
        end
    end
end