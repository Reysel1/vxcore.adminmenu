Config = {}

Config.Locale = 'en'

Config.Menu = {
    command = 'vxcore',
    aliases = { 'vxadmin' },
    key = 'F5',
    ace = 'vxcore.menu',
    groups = { 'group.admin', 'group.superadmin' },
}

Config.Shortcuts = {
    enabled = true,
    max = 12,
}

Config.Noclip = {
    speed = 1.0,
    maxSpeed = 16.0,
    fastMultiplier = 4.0,
    firstPerson = true,
    firstPersonInVehicle = false,
}

Config.Vehicle = {
    plate = 'VXCORE',
}

Config.Notifications = {
    system = 'vxcore',
    position = 'top-center',
    duration = 5000,
    soundVolume = 0.5,
}

Config.Controls = {
    position = 'bottom-right',
}

Config.Console = {
    allowed = {
        '^refresh$',
        '^restart [%w_%-]+$',
        '^ensure [%w_%-]+$',
        '^stop [%w_%-]+$',
    },
}
