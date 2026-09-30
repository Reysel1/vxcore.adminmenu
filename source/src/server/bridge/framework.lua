VX.Bridge = VX.Bridge or {}

local function running(resource)
    return GetResourceState(resource) == 'started'
end

local function call(resource, fn, ...)
    local ok, result = pcall(function(...)
        return exports[resource][fn](exports[resource], ...)
    end, ...)

    if not ok then
        print(('^3[VXCore]^7 %s:%s failed: %s'):format(resource, fn, tostring(result)))
        return false
    end

    return true, result
end

function VX.Bridge.setTime(hour)
    if running('qb-weathersync') then
        return (call('qb-weathersync', 'setTime', hour, 0))
    end
    return false
end

function VX.Bridge.setWeather(weather)
    if running('qb-weathersync') then
        return (call('qb-weathersync', 'setWeather', weather))
    end
    return false
end

function VX.Bridge.giveWeapon(src, weapon)
    if running('ox_inventory') then
        local ok, given = call('ox_inventory', 'AddItem', src, weapon, 1)
        if ok and given then return true end
        return false, VX.t("The inventory didn't accept the weapon.")
    end

    if running('qb-core') then
        local ok, core = call('qb-core', 'GetCoreObject')
        local item = weapon:lower()

        if ok and core and core.Shared and core.Shared.Items and core.Shared.Items[item] then
            local player = core.Functions.GetPlayer(src)
            if player and player.Functions.AddItem(item, 1) then
                TriggerClientEvent('inventory:client:ItemBox', src, core.Shared.Items[item], 'add')
                return true
            end
            return false, VX.t("The inventory didn't accept the weapon.")
        end
    end

    return nil
end
