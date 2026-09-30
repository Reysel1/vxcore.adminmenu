local FAVOURITES_KEY = 'vxcore:favourites'

local open = false
local asking = false

local function setOpen(value)
    open = value
    SetNuiFocus(open, open)
    SendNUIMessage({ action = 'toggle', open = open })
end

local function toggle()
    if VX.canOpen then return setOpen(not open) end
    if asking then return end

    asking = true
    TriggerServerEvent('vxcore:canOpen', true)
    SetTimeout(10000, function() asking = false end)
end

function VX.onPermission(allowed, requestedByKey)
    if requestedByKey then
        asking = false
        if allowed then
            setOpen(true)
        else
            VX.notify('VXCore', VX.t("You don't have permission to open the menu."), 'error')
        end
    elseif not allowed and open then
        setOpen(false)
        VX.notify('VXCore', VX.t('You no longer have access to the VXCore menu.'), 'warning')
    end
end

RegisterCommand(Config.Menu.command, toggle, false)

for _, alias in ipairs(Config.Menu.aliases) do
    RegisterCommand(alias, toggle, false)
end

RegisterKeyMapping(Config.Menu.command, VX.t('Open the VXCore menu'), 'keyboard', Config.Menu.key)

VX.nui('close', function()
    open = false
    SetNuiFocus(false, false)
    return { ok = true }
end)

VX.nui('estado', function()
    return {
        noclip = VX.state.noclip,
        invisible = VX.state.invisible,
        invencible = VX.state.godmode,
    }
end)

VX.nui('favoritos', function(data)
    if type(data.guardar) == 'table' then
        SetResourceKvp(FAVOURITES_KEY, json.encode(data.guardar))
        return { ok = true }
    end

    local raw = GetResourceKvpString(FAVOURITES_KEY)
    if not raw or raw == '' then return { lista = {} } end

    local ok, list = pcall(json.decode, raw)
    return { lista = (ok and type(list) == 'table') and list or {} }
end)
