local TYPES = {
    success = 'success', error = 'error', warning = 'warning', info = 'info', inform = 'info',
}

local MIN_DURATION, MAX_DURATION = 1000, 60000

local OX_LIB_POSITION = {
    ['top-center'] = 'top', ['bottom-center'] = 'bottom',
    ['top-left'] = 'top-left', ['top-right'] = 'top-right',
    ['bottom-left'] = 'bottom-left', ['bottom-right'] = 'bottom-right',
}

local CHAT_COLOUR = {
    success = { 120, 220, 150 }, error = { 255, 120, 120 }, warning = { 255, 190, 60 }, info = { 200, 200, 200 },
}

local function text(value)
    local trimmed = VX.trim(value)
    return trimmed ~= '' and trimmed or nil
end

local function normalise(title, body, kind, duration)
    local sound = false

    if type(title) == 'table' then
        local input = title
        title, body = input.title, input.description or input.message
        kind, duration = input.type, input.duration
        sound = input.sound == true
    end

    local notification = {
        title = text(title),
        body = text(body),
        kind = TYPES[tostring(kind or ''):lower()] or 'info',
        duration = VX.clamp(math.floor(tonumber(duration) or Config.Notifications.duration), MIN_DURATION, MAX_DURATION),
        sound = sound,
    }

    if not notification.title and not notification.body then return nil end
    return notification
end

local nuiReady = false
local queue = {}

local function chime()
    local volume = tonumber(Config.Notifications.soundVolume) or 0
    if volume <= 0 or not nuiReady then return end
    SendNUIMessage({ action = 'sonido', volumen = VX.clamp(volume, 0, 1) })
end

local function withVXCore(notification)
    if not nuiReady then
        queue[#queue + 1] = notification
        return
    end

    SendNUIMessage({
        action = 'notificar',
        titulo = notification.title,
        texto = notification.body,
        tipo = notification.kind,
        duracion = notification.duration,
    })
end

local function withOxLib(notification)
    TriggerEvent('ox_lib:notify', {
        title = notification.title,
        description = notification.body,
        type = notification.kind == 'info' and 'inform' or notification.kind,
        duration = notification.duration,
        position = OX_LIB_POSITION[Config.Notifications.position],
    })
end

local function withChat(notification)
    TriggerEvent('chat:addMessage', {
        color = CHAT_COLOUR[notification.kind],
        args = { ('[%s]'):format(notification.title or 'VXCore'), notification.body or '' },
    })
end

local warnedAboutOxLib = false

function VX.notify(...)
    local notification = normalise(...)
    if not notification then return end
    if notification.sound then chime() end

    local system = Config.Notifications.system

    if system == 'ox_lib' then
        if GetResourceState('ox_lib') == 'started' then return withOxLib(notification) end
        if not warnedAboutOxLib then
            warnedAboutOxLib = true
            print('^3[VXCore]^7 Config.Notifications.system is "ox_lib" but ox_lib is not running: using the built-in notifications.')
        end
    elseif system == 'chat' then
        return withChat(notification)
    end

    withVXCore(notification)
end

exports('notify', VX.notify)

RegisterNetEvent('vxcore:notify', function(...)
    VX.notify(...)
end)

VX.nui('avisos', function()
    if not nuiReady then
        nuiReady = true
        local waiting = queue
        queue = {}
        SetTimeout(100, function()
            for _, notification in ipairs(waiting) do withVXCore(notification) end
        end)
    end

    return { posicion = Config.Notifications.position, duracion = Config.Notifications.duration }
end)
