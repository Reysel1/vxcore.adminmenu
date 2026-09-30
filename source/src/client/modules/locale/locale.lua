local function toMenu(locale)
    SendNUIMessage({ action = 'idioma', locale = locale })
end

local function use(locale)
    if not VX.isLocale(locale) then return end
    if VX.setLocale(locale) then toMenu(locale) end
end

use(GlobalState.vxcoreLocale)

AddStateBagChangeHandler('vxcoreLocale', 'global', function(_, _, value)
    use(value)
end)

VX.nui('idioma', function()
    return { locale = VX.locale() }
end)
