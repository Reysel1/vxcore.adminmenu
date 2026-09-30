local Action = VX.actions('accion')

local PLACES = {
    comisaria  = { name = VX.msg('Mission Row Police Station'), x = 425.1, y = -979.5, z = 30.7 },
    hospital   = { name = VX.msg('Pillbox Hospital'), x = 295.8, y = -1446.9, z = 29.9 },
    aeropuerto = { name = VX.msg('the airport'), x = -1037.7, y = -2737.6, z = 20.2 },
    puerto     = { name = VX.msg('the port'), x = 1208.9, y = -3116.5, z = 5.5 },
    montana    = { name = VX.msg('Mount Chiliad'), x = 501.9, y = 5604.5, z = 797.9 },
    cayo       = { name = VX.msg('Cayo Perico'), x = 4840.6, y = -5174.4, z = 2.5 },
}

Action['marcador'] = function()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        return { ok = false, mensaje = VX.t("There's no marker set on the map.") }
    end

    local target = GetBlipInfoIdCoord(blip)
    VX.teleport(target.x, target.y, nil, true)
    return { ok = true, mensaje = VX.t("You're at the marker.") }
end

Action['volver'] = function()
    local previous = VX.state.lastPosition
    if not previous then
        return { ok = false, mensaje = VX.t("You haven't teleported anywhere yet.") }
    end

    VX.teleport(previous.x, previous.y, previous.z, false)
    VX.state.lastPosition = nil
    return { ok = true, mensaje = VX.t('Back where you were.') }
end

VX.nui('sitio', function(data)
    local place = PLACES[tostring(data.sitio or '')]
    if not place then return { ok = false, mensaje = VX.t("That place isn't on the list.") } end

    VX.teleport(place.x, place.y, place.z, true)
    return { ok = true, mensaje = VX.t("You're at {place}.", { place = VX.t(place.name) }) }
end)

VX.nui('coordenadas', function(data)
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if not x or not y then
        return { ok = false, mensaje = VX.t('At least X and Y are needed.') }
    end

    VX.teleport(x, y, z, true)
    return { ok = true, mensaje = VX.t("You're at {x}, {y}.", { x = ('%.1f'):format(x), y = ('%.1f'):format(y) }) }
end)

VX.nui('donde', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return { ok = true, x = coords.x, y = coords.y, z = coords.z, h = GetEntityHeading(ped) }
end)
