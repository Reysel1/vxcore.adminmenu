local wanted = type(Config.Locale) == 'string' and Config.Locale:lower() or 'en'

if not VX.isLocale(wanted) then
    local valid = {}
    for locale in pairs(VX.LOCALES) do valid[#valid + 1] = locale end
    table.sort(valid)

    print(('^3[VXCore]^7 Config.Locale = "%s" does not exist. Using "en". Valid: %s.')
        :format(tostring(Config.Locale), table.concat(valid, ', ')))

    wanted = 'en'
end

VX.setLocale(wanted)
GlobalState.vxcoreLocale = wanted
