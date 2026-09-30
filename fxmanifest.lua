fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vxcoreadminmenu'
author 'VXCore'
description 'In-game admin menu: players, sanctions, world, noclip and console'
version '1.0.0'

shared_scripts {
    'config.lua',
    'source/src/shared/utils.lua',
    'source/src/shared/locale.lua',
}

client_scripts {
    'source/src/client/utils.lua',
    'source/src/client/modules/locale/locale.lua',
    'source/src/client/bridge/framework.lua',
    'source/src/client/init.lua',
    'source/src/client/modules/notifications/notifications.lua',
    'source/src/client/modules/controls/controls.lua',
    'source/src/client/modules/menu/menu.lua',
    'source/src/client/modules/shortcuts/shortcuts.lua',
    'source/src/client/modules/character/health.lua',
    'source/src/client/modules/character/noclip.lua',
    'source/src/client/modules/character/weapons.lua',
    'source/src/client/modules/teleport/teleport.lua',
    'source/src/client/modules/vehicle/vehicle.lua',
    'source/src/client/modules/world/world.lua',
    'source/src/client/modules/players/players.lua',
    'source/src/client/modules/players/target.lua',
    'source/src/client/modules/server/summary.lua',
}

server_scripts {
    'source/src/server/utils.lua',
    'source/src/server/modules/locale/locale.lua',
    'source/src/server/bridge/framework.lua',
    'source/src/server/init.lua',
    'source/src/server/modules/notifications/notifications.lua',
    'source/src/server/modules/permissions/permissions.lua',
    'source/src/server/modules/players/bans.lua',
    'source/src/server/modules/players/players.lua',
    'source/src/server/modules/players/sanctions.lua',
    'source/src/server/modules/world/world.lua',
    'source/src/server/modules/character/weapons.lua',
    'source/src/server/modules/server/summary.lua',
}

ui_page 'source/nui/assets/index.html'

files {
    'source/nui/assets/**',
    'source/locales/*.json',
}
