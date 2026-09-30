VX.Bridge = VX.Bridge or {}

local function running(resource)
    return GetResourceState(resource) == 'started'
end

local function call(resource, fn, ...)
    local ok, err = pcall(function(...)
        return exports[resource][fn](exports[resource], ...)
    end, ...)

    if not ok then
        print(('^3[VXCore]^7 %s:%s failed: %s'):format(resource, fn, tostring(err)))
    end

    return ok
end

local FUEL_RESOURCES = { 'LegacyFuel', 'ps-fuel', 'cdn-fuel', 'lj-fuel' }

function VX.Bridge.refuel(vehicle)
    SetVehicleFuelLevel(vehicle, 100.0)

    if running('ox_fuel') then
        Entity(vehicle).state:set('fuel', 100.0, true)
    end

    for _, resource in ipairs(FUEL_RESOURCES) do
        if running(resource) then call(resource, 'SetFuel', vehicle, 100.0) end
    end
end

function VX.Bridge.giveKeys(vehicle)
    if running('qb-vehiclekeys') then
        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(vehicle))
    end
end

function VX.Bridge.revive()
    if running('qb-ambulancejob') then
        TriggerEvent('hospital:client:Revive')
        return true
    end

    if running('esx_ambulancejob') then
        TriggerEvent('esx_ambulancejob:revive')
        return true
    end

    return false
end
