RegisterNetEvent('vxcore:canOpen', function(open)
    local src = source
    TriggerClientEvent('vxcore:permission', src, VX.allowed(src), open == true)
end)
