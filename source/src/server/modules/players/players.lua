local pending = {}

VX.request('players', function(src)
    local list = {}

    for _, id in ipairs(GetPlayers()) do
        local number = tonumber(id)
        list[#list + 1] = {
            id = number,
            nombre = GetPlayerName(id),
            ping = GetPlayerPing(id),
            yo = number == src,
        }
    end

    table.sort(list, function(a, b) return a.id < b.id end)
    return { ok = true, players = list }
end, { section = 'players' })

local function askPosition(src, targetId, reply)
    local key = ('%d:%d'):format(src, targetId)
    pending[key] = reply
    TriggerClientEvent('vxcore:whereAreYou', targetId, src)

    SetTimeout(5000, function()
        local waiting = pending[key]
        if not waiting then return end
        pending[key] = nil
        waiting({ ok = false, mensaje = VX.t("That player didn't report their location. Try again.") })
    end)
end

RegisterNetEvent('vxcore:hereIAm', function(asker, x, y, z)
    local key = ('%d:%d'):format(tonumber(asker) or 0, source)
    local reply = pending[key]
    if not reply then return end

    pending[key] = nil
    reply({ ok = true, position = { x = x + 0.0, y = y + 0.0, z = z + 0.0 } })
end)

local ACTIONS = {}

ACTIONS.position = function(src, id, _, _, reply)
    local position = VX.position(id)
    if position then return { ok = true, position = position } end
    askPosition(src, id, reply)
end

ACTIONS.bring = function(src, id, name, data)
    local target = VX.position(src) or data.position
    if type(target) ~= 'table' or not tonumber(target.x) then
        return { ok = false, mensaje = VX.t("Your location is unknown, so they can't be brought over.") }
    end

    VX.log(src, VX.t('brought {name}', { name = name }))
    TriggerClientEvent('vxcore:brought', id, target.x + 0.0, target.y + 0.0, target.z + 0.0)
    return { ok = true, mensaje = VX.t('You brought {name}.', { name = name }) }
end

ACTIONS.heal = function(src, id, name)
    VX.log(src, VX.t('healed {name}', { name = name }))
    TriggerClientEvent('vxcore:healed', id)
    return { ok = true, mensaje = VX.t('{name} healed.', { name = name }) }
end

ACTIONS.freeze = function(src, id, name, data)
    local frozen = data.value == true
    VX.log(src, ('%s %s'):format(frozen and VX.t('froze') or VX.t('unfroze'), name))
    TriggerClientEvent('vxcore:frozen', id, frozen)

    return {
        ok = true,
        activo = frozen,
        mensaje = frozen and VX.t('{name} frozen.', { name = name }) or VX.t('{name} can move again.', { name = name }),
    }
end

ACTIONS.warn = function(src, id, name, data)
    local text = VX.trim(data.message):sub(1, 300)
    if text == '' then return { ok = false, mensaje = VX.t('Enter the warning.') } end

    local by = VX.playerName(src) or ('#' .. tostring(src))
    VX.log(src, VX.t('warned {name}: {text}', { name = name, text = text }))
    VX.notify(id, {
        title = VX.t('Warning from {by}', { by = by }),
        description = text,
        type = 'warning',
        duration = 10000,
    })
    VX.recordSanction(VX.identity(id), { kind = 'aviso', reason = text, by = by })

    return { ok = true, mensaje = VX.t('Warning sent to {name}.', { name = name }) }
end

ACTIONS.kick = function(src, id, name, data)
    if id == src then return { ok = false, mensaje = VX.t("You can't kick yourself.") } end

    local reason = VX.trim(data.reason):sub(1, 200)
    if reason == '' then reason = VX.t('No reason given') end

    local by = VX.playerName(src) or ('#' .. tostring(src))
    VX.log(src, VX.t('kicked {name}: {reason}', { name = name, reason = reason }))
    VX.recordSanction(VX.identity(id), { kind = 'kick', reason = reason, by = by })
    DropPlayer(tostring(id), VX.t('Kicked by an admin.\nReason: {reason}', { reason = reason }))

    return { ok = true, mensaje = VX.t('{name} kicked.', { name = name }) }
end

VX.request('player', function(src, data, reply)
    local action = ACTIONS[data.action]
    if not action then
        return { ok = false, mensaje = VX.t('Unknown action: {action}.', { action = tostring(data.action) }) }
    end

    local id = tonumber(data.id)
    local name = VX.playerName(id)
    if not name then return VX.playerGone(data.id) end

    return action(src, id, name, data, reply)
end, { section = 'players' })

VX.request('identifiers', function(_, data)
    local id = tonumber(data.id)
    local name = VX.playerName(id)
    if not name then return VX.playerGone(data.id) end

    return {
        ok = true,
        info = { id = id, nombre = name, identificadores = VX.identity(id) },
    }
end, { section = 'players' })
