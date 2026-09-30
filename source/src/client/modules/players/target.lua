RegisterNetEvent('vxcore:healed', function()
    VX.revive()
    VX.notify('VXCore', VX.t('An admin healed you.'), 'success')
end)

RegisterNetEvent('vxcore:frozen', function(frozen)
    FreezeEntityPosition(PlayerPedId(), frozen == true)
    VX.notify(
        'VXCore',
        frozen and VX.t('An admin froze you.') or VX.t('You can move again.'),
        frozen and 'warning' or 'info'
    )
end)

RegisterNetEvent('vxcore:brought', function(x, y, z)
    VX.teleport(x + 1.0, y, z, true)
    VX.notify('VXCore', VX.t('An admin brought you over.'), 'info')
end)

RegisterNetEvent('vxcore:whereAreYou', function(asker)
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('vxcore:hereIAm', asker, coords.x, coords.y, coords.z)
end)
