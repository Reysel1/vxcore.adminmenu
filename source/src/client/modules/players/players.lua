local Player = VX.actions('jugador')

local RELAYED = {
    curar = 'heal',
    congelar = 'freeze',
    avisar = 'warn',
    echar = 'kick',
}

local previousPosition = nil

for id, action in pairs(RELAYED) do
    Player[id] = function(data, reply)
        VX.ask('player', {
            action = action,
            id = data.id,
            value = data.valor,
            message = data.mensaje,
            reason = data.motivo,
        }, reply)
    end
end

VX.nui('jugadores', function(_, reply)
    VX.ask('players', {}, function(response)
        if response.ok then SendNUIMessage({ action = 'players', players = response.players }) end
        reply(response)
    end)
end)

local function positionOf(id, onKnown)
    VX.ask('player', { action = 'position', id = id }, onKnown)
end

Player['ir'] = function(data, reply)
    positionOf(data.id, function(response)
        if not response.ok then return reply(response) end
        local position = response.position
        VX.teleport(position.x + 1.0, position.y, position.z, true)
        reply({ ok = true, mensaje = VX.t("You're next to them.") })
    end)
end

Player['traer'] = function(data, reply)
    local coords = GetEntityCoords(PlayerPedId())
    VX.ask('player', {
        action = 'bring',
        id = data.id,
        position = { x = coords.x, y = coords.y, z = coords.z },
    }, reply)
end

local function follow(id)
    CreateThread(function()
        while VX.state.spectating == id do
            local player = GetPlayerFromServerId(id)
            if player == -1 then
                VX.stopSpectating()
                VX.notify('VXCore', VX.t('The player left; you stop spectating.'), 'info')
                return
            end

            local coords = GetEntityCoords(GetPlayerPed(player))
            SetEntityCoordsNoOffset(PlayerPedId(), coords.x, coords.y, coords.z - 15.0, false, false, false)
            Wait(500)
        end
    end)
end

function VX.stopSpectating()
    local ped = PlayerPedId()
    VX.state.spectating = nil
    NetworkSetInSpectatorMode(false, ped)

    if previousPosition then
        SetEntityCoordsNoOffset(ped, previousPosition.x, previousPosition.y, previousPosition.z, false, false, false)
        previousPosition = nil
    end

    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, not VX.state.invisible and not VX.state.noclip, false)
end

local function waitForPed(id, ms)
    local limit = GetGameTimer() + ms

    while GetGameTimer() < limit do
        local player = GetPlayerFromServerId(id)
        if player ~= -1 and DoesEntityExist(GetPlayerPed(player)) then return GetPlayerPed(player) end
        Wait(100)
    end

    return nil
end

Player['espectar'] = function(data, reply)
    local id = tonumber(data.id)

    if VX.state.spectating == id then
        VX.stopSpectating()
        return { ok = true, activo = false, mensaje = VX.t('You stop spectating.') }
    end

    if VX.state.noclip then
        return { ok = false, mensaje = VX.t('Leave noclip before spectating.') }
    end

    if VX.state.spectating then VX.stopSpectating() end

    positionOf(id, function(response)
        if not response.ok then return reply(response) end

        local ped = PlayerPedId()
        previousPosition = GetEntityCoords(ped)
        local position = response.position

        SetEntityVisible(ped, false, false)
        SetEntityCollision(ped, false, false)
        FreezeEntityPosition(ped, true)
        RequestCollisionAtCoord(position.x, position.y, position.z)
        SetEntityCoordsNoOffset(ped, position.x, position.y, position.z - 15.0, false, false, false)

        local target = waitForPed(id, 3000)
        if not target then
            VX.stopSpectating()
            return reply({ ok = false, mensaje = VX.t("Couldn't load that player to spectate them.") })
        end

        NetworkSetInSpectatorMode(true, target)
        VX.state.spectating = id
        follow(id)
        reply({ ok = true, activo = true, mensaje = VX.t('Spectating. Press again to exit.') })
    end)
end

VX.nui('identificadores', function(data, reply)
    VX.ask('identifiers', { id = data.id }, function(response)
        if response.ok then SendNUIMessage({ action = 'ids', info = response.info }) end
        reply(response)
    end)
end)

VX.nui('banear', function(data, reply)
    VX.ask('ban', { id = data.id, reason = data.motivo, minutes = data.minutos }, reply, 15000)
end)

VX.nui('historial', function(data, reply)
    VX.ask('history', { id = data.id }, reply)
end)
