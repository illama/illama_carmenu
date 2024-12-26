fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Illama'
version '1.0.0'


shared_scripts {
    'config.lua',
    'locales/fr.lua'
}

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

server_scripts {
    '@ox_lib/init.lua', 
    '@oxmysql/lib/MySQL.lua', -- Retirez si non nécessaire
    'server/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'esx_cruisecontrol'
}
