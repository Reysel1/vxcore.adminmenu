local Action = VX.actions('accion')
local Vehicle = VX.actions('vehiculo')

local TUNING_MODS = { 11, 12, 13, 15, 16 }
local TURBO_MOD = 18

local function modelLabel(hash, model)
    local label = GetLabelText(GetDisplayNameFromVehicleModel(hash))
    if label and label ~= '' and label ~= 'NULL' then return label end
    return model
end

VX.nui('spawnVehiculo', function(data)
    local model = VX.trim(data.modelo):gsub('%s+', '')
    local hash = GetHashKey(model)

    if model == '' or not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return { ok = false, mensaje = VX.t('There\'s no vehicle called "{model}".', { model = model }) }
    end

    if not VX.loadModel(hash) then
        return { ok = false, mensaje = VX.t("The model hasn't finished loading. Try again.") }
    end

    local ped = PlayerPedId()

    local previous = VX.currentVehicle()
    if previous and GetPedInVehicleSeat(previous, -1) == ped then VX.remove(previous) end

    local coords = GetEntityCoords(ped)
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    SetModelAsNoLongerNeeded(hash)

    if vehicle == 0 then
        return { ok = false, mensaje = VX.t("The game couldn't create the vehicle here.") }
    end

    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, Config.Vehicle.plate)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetVehicleEngineOn(vehicle, true, true, false)

    VX.Bridge.refuel(vehicle)
    VX.Bridge.giveKeys(vehicle)

    return { ok = true, mensaje = VX.t('You have a {model}.', { model = modelLabel(hash, model) }) }
end)

Action['reparar'] = function()
    local vehicle = VX.currentVehicle()
    if not vehicle then return VX.noVehicle() end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    return { ok = true, mensaje = VX.t('Vehicle repaired.') }
end

Action['repostar'] = function()
    local vehicle = VX.currentVehicle()
    if not vehicle then return VX.noVehicle() end

    VX.Bridge.refuel(vehicle)
    return { ok = true, mensaje = VX.t('Tank full.') }
end

Action['limpiar-vehiculo'] = function()
    local vehicle = VX.currentVehicle()
    if not vehicle then return VX.noVehicle() end

    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)
    return { ok = true, mensaje = VX.t('Vehicle cleaned.') }
end

Action['borrar-vehiculo'] = function()
    local ped = PlayerPedId()
    local vehicle = VX.currentVehicle()

    if not vehicle then
        local front = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.0)
        local probe = StartShapeTestCapsule(front.x, front.y, front.z, front.x, front.y, front.z, 4.0, 10, ped, 7)
        local _, hit, _, _, entity = GetShapeTestResult(probe)
        if hit == 1 and IsEntityAVehicle(entity) then vehicle = entity end
    end

    if not vehicle then
        return { ok = false, mensaje = VX.t("There's no vehicle here or in front of you.") }
    end

    if not VX.remove(vehicle) then
        return { ok = false, mensaje = VX.t("That vehicle belongs to another player and couldn't be deleted.") }
    end

    return { ok = true, mensaje = VX.t('Vehicle deleted.') }
end

Vehicle['motor'] = function()
    local vehicle = VX.currentVehicle()
    if not vehicle then return VX.noVehicle() end

    local running = GetIsVehicleEngineRunning(vehicle)
    SetVehicleEngineOn(vehicle, not running, false, true)
    return { ok = true, mensaje = running and VX.t('Engine off.') or VX.t('Engine on.') }
end

Vehicle['cerraduras'] = function()
    local vehicle = VX.currentVehicle()
    if not vehicle then return VX.noVehicle() end

    local locked = GetVehicleDoorLockStatus(vehicle) == 2
    SetVehicleDoorsLocked(vehicle, locked and 1 or 2)
    return { ok = true, mensaje = locked and VX.t('Vehicle unlocked.') or VX.t('Vehicle locked.') }
end

Vehicle['motor-mejorado'] = function()
    local vehicle = VX.currentVehicle()
    if not vehicle then return VX.noVehicle() end

    SetVehicleModKit(vehicle, 0)
    for _, kind in ipairs(TUNING_MODS) do
        local best = GetNumVehicleMods(vehicle, kind) - 1
        if best >= 0 then SetVehicleMod(vehicle, kind, best, false) end
    end
    ToggleVehicleMod(vehicle, TURBO_MOD, true)

    return { ok = true, mensaje = VX.t('Engine, brakes, transmission, suspension, armour and turbo maxed out.') }
end

Vehicle['color'] = function()
    local vehicle = VX.currentVehicle()
    if not vehicle then return VX.noVehicle() end

    SetVehicleColours(vehicle, math.random(0, 159), math.random(0, 159))
    return { ok = true, mensaje = VX.t('Colour changed.') }
end

Vehicle['matricula'] = function(data)
    local vehicle = VX.currentVehicle()
    if not vehicle then return VX.noVehicle() end

    local plate = VX.trim(data.texto):upper():sub(1, 8)
    if plate == '' then return { ok = false, mensaje = VX.t('Enter the plate.') } end

    SetVehicleNumberPlateText(vehicle, plate)
    return { ok = true, mensaje = VX.t('Plate set: {plate}.', { plate = plate }) }
end
