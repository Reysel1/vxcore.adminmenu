VX.SECTIONS = { 'players', 'sanctions', 'console' }

function VX.allowed(src, need)
    src = tonumber(src)
    if not src or src <= 0 then return false end

    if IsPlayerAceAllowed(src, Config.Menu.ace) then return true end

    local section = need and need.section
    if section then
        return IsPlayerAceAllowed(src, Config.Menu.ace .. '.' .. section)
    end

    for _, part in ipairs(VX.SECTIONS) do
        if IsPlayerAceAllowed(src, Config.Menu.ace .. '.' .. part) then return true end
    end

    return false
end

function VX.playerName(id)
    id = tonumber(id)
    if not id then return nil end

    local name = GetPlayerName(id)
    if not name or name == '' then return nil end
    return name
end

function VX.identity(src)
    local identity = { tokens = {} }

    for _, raw in ipairs(GetPlayerIdentifiers(src)) do
        local kind, value = raw:match('^(%w+):(.+)$')
        if kind and value then identity[kind] = value end
    end

    if GetNumPlayerTokens and GetPlayerToken then
        for index = 0, (GetNumPlayerTokens(src) or 0) - 1 do
            local token = GetPlayerToken(src, index)
            if token and token ~= '' then
                identity.tokens[#identity.tokens + 1] = token
            end
        end
    end

    return identity
end

function VX.position(id)
    local ped = GetPlayerPed(id)
    if not ped or ped == 0 then return nil end

    local coords = GetEntityCoords(ped)
    if not coords or (coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0) then return nil end
    return { x = coords.x, y = coords.y, z = coords.z }
end

function VX.log(src, text)
    local who = VX.playerName(src) or ('#' .. tostring(src))
    print(('^3[VXCore]^7 %s (%s): %s'):format(who, tostring(src), text))
end

function VX.request(name, fn, need)
    RegisterNetEvent('vxcore:request:' .. name, function(token, data)
        local src = source
        local answered = false

        local function reply(response)
            if answered then return end
            answered = true
            TriggerClientEvent('vxcore:response', src, token, response or { ok = true })
        end

        if not VX.allowed(src, need) then
            VX.log(src, ('ATTEMPT WITHOUT PERMISSION: %s'):format(name))
            local message = VX.allowed(src)
                and VX.t("Your VXCore rank doesn't allow this.")
                or VX.t("You don't have permission to use the VXCore menu.")
            reply({ ok = false, error = 'NO_PERMISSION', mensaje = message })
            return
        end

        local ok, response = pcall(fn, src, type(data) == 'table' and data or {}, reply)
        if not ok then
            print(('^1[VXCore]^7 Request "%s" failed: %s'):format(name, tostring(response)))
            reply({ ok = false, error = 'INTERNAL_ERROR', mensaje = VX.t('Something failed on the server. Check its console.') })
        elseif response ~= nil then
            reply(response)
        end
    end)
end

function VX.playerGone(id)
    return { ok = false, mensaje = VX.t('Nobody is connected with id {id}.', { id = tostring(id) }) }
end
