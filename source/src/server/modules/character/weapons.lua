VX.request('giveWeapon', function(src, data)
    local weapon = VX.trim(data.weapon):upper()
    if not weapon:match('^WEAPON_[%w_]+$') then
        return { ok = false, mensaje = VX.t("That weapon name isn't valid.") }
    end

    local given, reason = VX.Bridge.giveWeapon(src, weapon)
    if given == nil then return { ok = true, throughInventory = false } end
    if not given then return { ok = false, mensaje = reason } end

    VX.log(src, VX.t('gave themselves {weapon}', { weapon = weapon }))
    return { ok = true, throughInventory = true }
end)
