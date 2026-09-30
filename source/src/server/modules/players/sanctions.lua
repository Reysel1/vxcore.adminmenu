VX.request('ban', function(src, data)
    local id = tonumber(data.id)
    local name = VX.playerName(id)
    if not name then return VX.playerGone(data.id) end
    if id == src then return { ok = false, mensaje = VX.t("You can't ban yourself.") } end

    local reason = VX.trim(data.reason):sub(1, 300)
    if reason == '' then return { ok = false, mensaje = VX.t('Enter the ban reason.') } end

    local minutes = math.max(0, math.floor(tonumber(data.minutes) or 0))
    local identity = VX.identity(id)
    local by = VX.playerName(src) or ('#' .. tostring(src))

    if not identity.license and #(identity.tokens or {}) == 0 then
        DropPlayer(tostring(id), VX.t('Kicked.\nReason: {reason}', { reason = reason }))
        VX.log(src, VX.t('kicked {name} ({id}) without being able to record the ban: {reason}', {
            name = name, id = id, reason = reason,
        }))
        return {
            ok = false,
            mensaje = VX.t('{name} kicked, but the ban could not be recorded: no stable identifiers.', { name = name }),
        }
    end

    VX.ban(identity, { name = name, reason = reason, minutes = minutes, by = by })
    VX.recordSanction(identity, { kind = 'ban', reason = reason, minutes = minutes, by = by })

    VX.log(src, VX.t('banned {name} ({id}): {reason}', { name = name, id = id, reason = reason }))
    DropPlayer(tostring(id), VX.t('Banned.\nReason: {reason}', { reason = reason }))

    return {
        ok = true,
        mensaje = minutes > 0
            and VX.t('{name} banned for {minutes} minutes.', { name = name, minutes = tostring(minutes) })
            or VX.t('{name} banned permanently.', { name = name }),
    }
end, { section = 'sanctions' })

VX.request('history', function(_, data)
    local id = tonumber(data.id)
    if not VX.playerName(id) then return VX.playerGone(data.id) end

    return { ok = true, sanciones = VX.historyOf(VX.identity(id)) }
end, { section = 'players' })

RegisterCommand('vxcore_unban', function(src, args)
    if src ~= 0 and not VX.allowed(src, { section = 'sanctions' }) then return end

    local license = args[1]
    if not license or license == '' then
        print('^3[VXCore]^7 Usage: vxcore_unban <license>   (without the "license:" prefix)')
        return
    end

    license = license:gsub('^license:', '')

    if VX.unban({ license = license, tokens = {} }) then
        print(('^2[VXCore]^7 Ban lifted: %s'):format(license))
    else
        print(('^3[VXCore]^7 No ban found for that license: %s'):format(license))
    end
end, false)
