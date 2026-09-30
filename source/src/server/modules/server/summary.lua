local function startedResources()
    local total = 0

    for index = 0, GetNumResources() - 1 do
        local name = GetResourceByFindIndex(index)
        if name and GetResourceState(name) == 'started' then total = total + 1 end
    end

    return total
end

local function serverName()
    local name = GetConvar('sv_projectName', '')
    if name == '' then name = GetConvar('sv_hostname', '') end
    return (name:gsub('%^%d', ''))
end

VX.request('summary', function()
    return {
        ok = true,
        datos = {
            jugadores = #GetPlayers(),
            maximo = GetConvarInt('sv_maxclients', 32),
            recursos = startedResources(),
            baneos = VX.activeBans(),
            arriba = math.floor(GetGameTimer() / 1000),
            servidor = serverName(),
            onesync = GetConvar('onesync', 'off'),
            version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '',
        },
    }
end)
