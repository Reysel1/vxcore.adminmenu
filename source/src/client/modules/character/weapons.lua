local Weapon = VX.actions('arma')

local function weaponName(text)
    local name = VX.trim(text):upper():gsub('%s+', '')
    if name == '' then return nil end
    if not name:match('^WEAPON_') then name = 'WEAPON_' .. name end
    return name
end

Weapon['dar'] = function(data, reply)
    local weapon = weaponName(data.nombre)
    if not weapon then return { ok = false, mensaje = VX.t('Choose or type a weapon.') } end

    local hash = GetHashKey(weapon)
    if not IsWeaponValid(hash) then
        return { ok = false, mensaje = VX.t('There\'s no weapon called "{weapon}".', { weapon = weapon }) }
    end

    VX.ask('giveWeapon', { weapon = weapon }, function(response)
        if not response.ok then return reply(response) end

        local label = weapon:gsub('^WEAPON_', '')
        if response.throughInventory then
            return reply({ ok = true, mensaje = VX.t('{label} added to your inventory.', { label = label }) })
        end

        GiveWeaponToPed(PlayerPedId(), hash, 250, false, true)
        reply({ ok = true, mensaje = VX.t('You have a {label}.', { label = label }) })
    end)
end

Weapon['municion'] = function()
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)

    if weapon == GetHashKey('WEAPON_UNARMED') then
        return { ok = false, mensaje = VX.t("You're not holding a weapon.") }
    end

    local _, maximum = GetMaxAmmo(ped, weapon)
    SetPedAmmo(ped, weapon, (maximum and maximum > 0) and maximum or 9999)
    return { ok = true, mensaje = VX.t('Ammo maxed out.') }
end

Weapon['quitar'] = function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    return { ok = true, mensaje = VX.t('You have no weapons now.') }
end
