local function forward(route, request)
    VX.nui(route, function(data, reply)
        VX.ask(request, data, reply)
    end)
end

forward('mundo', 'world')
forward('anuncio', 'announce')
forward('consola', 'console')

RegisterNetEvent('vxcore:applyWorld', function(kind, value)
    if kind == 'time' then
        NetworkOverrideClockTime(tonumber(value) or 12, 0, 0)
    elseif kind == 'weather' then
        local weather = tostring(value)
        SetWeatherTypeOverTime(weather, 5.0)
        SetTimeout(5500, function() SetWeatherTypePersist(weather) end)
    end
end)

local function removable(centre, radius)
    local ownPed = PlayerPedId()
    local ownVehicle = VX.currentVehicle()
    local list = {}

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if vehicle ~= ownVehicle and #(GetEntityCoords(vehicle) - centre) <= radius then
            local driver = GetPedInVehicleSeat(vehicle, -1)
            if driver == 0 or not IsPedAPlayer(driver) then
                list[#list + 1] = vehicle
            end
        end
    end

    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= ownPed and not IsPedAPlayer(ped) and #(GetEntityCoords(ped) - centre) <= radius then
            list[#list + 1] = ped
        end
    end

    return list
end

VX.nui('limpiarZona', function(data)
    local radius = VX.clamp(tonumber(data.radio) or 100.0, 5.0, 1000.0)
    local list = removable(GetEntityCoords(PlayerPedId()), radius)

    for _, entity in ipairs(list) do NetworkRequestControlOfEntity(entity) end
    Wait(500)

    local vehicles, peds = 0, 0
    for _, entity in ipairs(list) do
        local isVehicle = IsEntityAVehicle(entity)
        if VX.remove(entity) then
            if isVehicle then vehicles = vehicles + 1 else peds = peds + 1 end
        end
    end

    return {
        ok = true,
        mensaje = VX.t('Removed {vehicles} vehicles and {peds} pedestrians within {radius} m.', {
            vehicles = vehicles,
            peds = peds,
            radius = math.floor(radius),
        }),
    }
end)
