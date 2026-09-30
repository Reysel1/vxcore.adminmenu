VX.state = {
    noclip = false,
    invisible = false,
    godmode = false,
    spectating = nil,
    lastPosition = nil,
}

function VX.nui(route, fn)
    RegisterNUICallback(route, function(data, cb)
        local answered = false

        local function reply(response)
            if answered then return end
            answered = true
            cb(response or { ok = true })
        end

        CreateThread(function()
            local ok, response = pcall(fn, type(data) == 'table' and data or {}, reply)
            if not ok then
                print(('^1[VXCore]^7 Route "%s" failed: %s'):format(route, tostring(response)))
                reply({ ok = false, mensaje = VX.t('Something went wrong. Check the console (F8).') })
            elseif response ~= nil then
                reply(response)
            end
        end)
    end)
end

local groups = {}

function VX.actions(route)
    if groups[route] then return groups[route] end

    local handlers = {}
    groups[route] = handlers

    VX.nui(route, function(data, reply)
        local fn = handlers[tostring(data.accion or '')]
        if not fn then
            return { ok = false, mensaje = VX.t('Unknown action: {action}.', { action = tostring(data.accion) }) }
        end
        return fn(data, reply)
    end)

    return handlers
end

local pending = {}
local nextToken = 0

function VX.ask(name, data, onReply, timeoutMs)
    nextToken = nextToken + 1
    local token = nextToken
    pending[token] = onReply

    TriggerServerEvent('vxcore:request:' .. name, token, data or {})

    SetTimeout(timeoutMs or 8000, function()
        local waiting = pending[token]
        if not waiting then return end
        pending[token] = nil
        waiting({ ok = false, error = 'NO_RESPONSE', mensaje = VX.t("The server didn't respond in time.") })
    end)
end

RegisterNetEvent('vxcore:response', function(token, response)
    local onReply = pending[token]
    if not onReply then return end
    pending[token] = nil
    CreateThread(function()
        onReply(response or { ok = true })
    end)
end)

function VX.currentVehicle()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return nil end
    return vehicle
end

function VX.noVehicle()
    return { ok = false, mensaje = VX.t("You're not in a vehicle.") }
end

function VX.loadModel(hash)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)

    local limit = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < limit do
        Wait(50)
    end

    return HasModelLoaded(hash)
end

function VX.requestControl(entity, timeoutMs)
    if not NetworkGetEntityIsNetworked(entity) then return true end
    NetworkRequestControlOfEntity(entity)

    local limit = GetGameTimer() + (timeoutMs or 1000)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < limit do
        Wait(0)
        NetworkRequestControlOfEntity(entity)
    end

    return NetworkHasControlOfEntity(entity)
end

function VX.remove(entity)
    if not entity or not DoesEntityExist(entity) then return false end

    VX.requestControl(entity)
    SetEntityAsMissionEntity(entity, true, true)

    if IsEntityAVehicle(entity) then
        DeleteVehicle(entity)
    elseif IsEntityAPed(entity) then
        DeletePed(entity)
    else
        DeleteEntity(entity)
    end

    return not DoesEntityExist(entity)
end

local function fade(to, ms)
    if to == 'out' then DoScreenFadeOut(ms) else DoScreenFadeIn(ms) end

    local limit = GetGameTimer() + ms + 500
    while GetGameTimer() < limit do
        if (to == 'out' and IsScreenFadedOut()) or (to ~= 'out' and IsScreenFadedIn()) then return end
        Wait(0)
    end
end

function VX.teleport(x, y, z, remember)
    local ped = PlayerPedId()
    if remember ~= false then VX.state.lastPosition = GetEntityCoords(ped) end

    local vehicle = VX.currentVehicle()
    local entity = (vehicle and GetPedInVehicleSeat(vehicle, -1) == ped) and vehicle or ped

    fade('out', 250)
    FreezeEntityPosition(entity, true)

    local found = true
    if z and z > 0.0 then
        RequestCollisionAtCoord(x, y, z)
        SetEntityCoordsNoOffset(entity, x, y, z, false, false, false)
        local limit = GetGameTimer() + 2000
        while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < limit do Wait(0) end
    else
        found = false
        local ground = 0.0
        for height = 0, 1000, 50 do
            SetEntityCoordsNoOffset(entity, x, y, height + 0.0, false, false, false)
            RequestCollisionAtCoord(x, y, height + 0.0)
            local limit = GetGameTimer() + 250
            while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < limit do Wait(0) end

            found, ground = GetGroundZFor_3dCoord(x, y, height + 0.0, false)
            if found then break end
        end
        SetEntityCoordsNoOffset(entity, x, y, (found and ground or 100.0) + 1.0, false, false, false)
    end

    FreezeEntityPosition(entity, false)
    fade('in', 250)
    return found
end
