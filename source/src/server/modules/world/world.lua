local WEATHER = {
    EXTRASUNNY = true, CLEAR = true, NEUTRAL = true, SMOG = true, FOGGY = true,
    OVERCAST = true, CLOUDS = true, CLEARING = true, RAIN = true, THUNDER = true,
    SNOW = true, BLIZZARD = true, SNOWLIGHT = true, XMAS = true, HALLOWEEN = true,
}

VX.request('world', function(src, data)
    if data.hora ~= nil then
        local hour = VX.clamp(math.floor(tonumber(data.hora) or 12), 0, 23)

        if not VX.Bridge.setTime(hour) then
            TriggerClientEvent('vxcore:applyWorld', -1, 'time', hour)
        end

        VX.log(src, VX.t('set the time to {time}', { time = ('%02d:00'):format(hour) }))
        return { ok = true, mensaje = VX.t("It's {time} for the whole server.", { time = ('%02d:00'):format(hour) }) }
    end

    if data.clima ~= nil then
        local weather = VX.trim(data.clima):upper()
        if not WEATHER[weather] then
            return { ok = false, mensaje = VX.t('The game has no "{weather}" weather.', { weather = weather }) }
        end

        if not VX.Bridge.setWeather(weather) then
            TriggerClientEvent('vxcore:applyWorld', -1, 'weather', weather)
        end

        VX.log(src, VX.t('set the weather to {weather}', { weather = weather }))
        return { ok = true, mensaje = VX.t('Weather changed for the whole server.') }
    end

    return { ok = false, mensaje = VX.t('Choose a time or a weather.') }
end)

VX.request('announce', function(src, data)
    local text = VX.trim(data.mensaje):sub(1, 400)
    if text == '' then return { ok = false, mensaje = VX.t('Enter the announcement.') } end

    VX.log(src, VX.t('announced: {text}', { text = text }))
    VX.notify(-1, { title = VX.t('Announcement'), description = text, type = 'info', duration = 10000 })

    return { ok = true, mensaje = VX.t('Announcement sent to the whole server.') }
end)

VX.request('console', function(src, data)
    local command = VX.trim(data.comando):gsub('%s+', ' ')
    if command == '' then return { ok = false, mensaje = VX.t('Enter a command.') } end

    local allowed = false
    for _, pattern in ipairs(Config.Console.allowed) do
        if command:match(pattern) then
            allowed = true
            break
        end
    end

    if not allowed then
        return { ok = false, mensaje = VX.t("That command isn't allowed from the menu.") }
    end

    VX.log(src, VX.t('ran in console: {command}', { command = command }))
    ExecuteCommand(command)

    return { ok = true, mensaje = VX.t('Ran: {command}', { command = command }) }
end, { section = 'console' })
