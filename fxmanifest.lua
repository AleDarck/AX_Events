fx_version 'cerulean'
game 'gta5'
lua54 'yes'
description 'AX_Events - Multi-event system'
version '1.0.0'
author 'AX Scripts'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'esx_ambulancejob',
    'pure-minigames',
    'AX_ProgressBar',
    'hrs_zombies_V2',
}