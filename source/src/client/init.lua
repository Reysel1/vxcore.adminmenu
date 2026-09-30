VX.canOpen = false

CreateThread(function()
    Wait(3000)
    TriggerServerEvent('vxcore:canOpen')
end)

RegisterNetEvent('vxcore:permission', function(allowed, open)
    VX.canOpen = allowed == true
    if VX.onPermission then VX.onPermission(VX.canOpen, open == true) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if VX.state.spectating and VX.stopSpectating then VX.stopSpectating() end

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    SetNuiFocus(false, false)
end)
