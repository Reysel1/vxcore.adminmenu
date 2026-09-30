VX = VX or {}

function VX.trim(value)
    if value == nil then return '' end
    return (tostring(value):match('^%s*(.-)%s*$'))
end

function VX.clamp(n, min, max)
    if n < min then return min end
    if n > max then return max end
    return n
end

local function isArray(value)
    return type(value) == 'table' and value[1] ~= nil
end

local DEFAULTS = {
    Locale = 'en',
    Menu = {
        command = 'vxcore',
        aliases = { 'vxadmin' },
        key = 'F5',
        ace = 'vxcore.menu',
        groups = { 'group.admin', 'group.superadmin' },
    },
    Shortcuts = {
        enabled = true,
        max = 12,
    },
    Noclip = {
        speed = 1.0,
        maxSpeed = 16.0,
        fastMultiplier = 4.0,
        firstPerson = true,
        firstPersonInVehicle = false,
    },
    Vehicle = {
        plate = 'VXCORE',
    },
    Notifications = {
        system = 'vxcore',
        position = 'top-center',
        duration = 5000,
        soundVolume = 0.5,
    },
    Controls = {
        position = 'bottom-right',
    },
    Console = {
        allowed = { '^refresh$', '^restart [%w_%-]+$', '^ensure [%w_%-]+$', '^stop [%w_%-]+$' },
    },
}

local function fill(target, base)
    for key, value in pairs(base) do
        if target[key] == nil then
            target[key] = value
        elseif type(value) == 'table' and type(target[key]) == 'table' and not isArray(value) then
            fill(target[key], value)
        end
    end
end

Config = Config or {}
fill(Config, DEFAULTS)
