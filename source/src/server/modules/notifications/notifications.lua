function VX.notify(target, title, body, kind, duration)
    local id = tonumber(target)
    if not id then
        print(('^3[VXCore]^7 notify: invalid target (%s); nothing sent.'):format(tostring(target)))
        return
    end

    local notification = type(title) == 'table' and title
        or { title = title, description = body, type = kind, duration = duration }

    TriggerClientEvent('vxcore:notify', id, notification)
end

exports('notify', VX.notify)
