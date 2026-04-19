fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'RexShack'
version '2.0.2'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/cleanup.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
    'server/versionchecker.lua',
}

dependencies {
    '/server:5840',
    '/onesync',
    'rsg-core',
    'rsg-inventory',
    'ox_lib',
    'ox_target',
}
