local Action = VX.actions('accion')

Action['curar'] = function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    return { ok = true, mensaje = VX.t('Health maxed out.') }
end

Action['blindaje'] = function()
    SetPedArmour(PlayerPedId(), 100)
    return { ok = true, mensaje = VX.t('Armour at 100%.') }
end

function VX.revive()
    local ped = PlayerPedId()
    local dead = IsEntityDead(ped) or IsPedFatallyInjured(ped)

    if not VX.Bridge.revive() and dead then
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
        ped = PlayerPedId()
        ClearPedTasksImmediately(ped)
    end

    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
end

Action['revivir'] = function()
    VX.revive()
    return { ok = true, mensaje = VX.t('Back on your feet.') }
end

Action['limpiar'] = function()
    local ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
    ClearPedEnvDirt(ped)
    ResetPedVisibleDamage(ped)
    return { ok = true, mensaje = VX.t('Clothes cleaned.') }
end

Action['invisible'] = function()
    VX.state.invisible = not VX.state.invisible
    SetEntityVisible(PlayerPedId(), not VX.state.invisible and not VX.state.noclip, false)

    return {
        ok = true,
        activo = VX.state.invisible,
        mensaje = VX.state.invisible and VX.t("You're now invisible.") or VX.t("You're visible again."),
    }
end

Action['invencible'] = function()
    VX.state.godmode = not VX.state.godmode
    SetEntityInvincible(PlayerPedId(), VX.state.godmode or VX.state.noclip)

    return {
        ok = true,
        activo = VX.state.godmode,
        mensaje = VX.state.godmode and VX.t('Godmode on.') or VX.t('Godmode off.'),
    }
end
