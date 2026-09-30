local STORAGE_KEY = 'vxcore:shortcuts'

local saved = { activos = true, lista = {} }
local lastFired = {}

local function text(value, max)
    if type(value) ~= 'string' then return nil end
    value = VX.trim(value)
    if value == '' or #value > max then return nil end
    return value
end

local function sanitise(input)
    local clean = { activos = true, lista = {} }
    if type(input) ~= 'table' then return clean end
    clean.activos = input.activos ~= false

    local seen = {}
    for _, entry in ipairs(type(input.lista) == 'table' and input.lista or {}) do
        if #clean.lista >= Config.Shortcuts.max then break end

        local control = type(entry) == 'table' and math.tointeger(entry.control)
        local id = type(entry) == 'table' and text(entry.id, 64)
        local command = type(entry) == 'table' and text(entry.comando, 64)
        local key = type(entry) == 'table' and text(entry.tecla, 32)
        local label = type(entry) == 'table' and text(entry.etiqueta, 16)

        if id and command and key and label and control and control >= 0 and control <= 400 and not seen[key] then
            seen[key] = true

            local values = nil
            if type(entry.valores) == 'table' then
                values = {}
                local count = 0
                for name, value in pairs(entry.valores) do
                    local kind = type(value)
                    if type(name) == 'string' and #name <= 32 and count < 10
                        and (kind == 'number' or kind == 'boolean' or (kind == 'string' and #value <= 128)) then
                        values[name] = value
                        count = count + 1
                    end
                end
            end

            clean.lista[#clean.lista + 1] = {
                id = id,
                comando = command,
                tecla = key,
                etiqueta = label,
                control = control,
                valores = values,
            }
        end
    end

    return clean
end

local function read()
    local raw = GetResourceKvpString(STORAGE_KEY)
    if not raw or raw == '' then return sanitise(nil) end

    local ok, data = pcall(json.decode, raw)
    return sanitise(ok and data or nil)
end

saved = read()

local function menuKey()
    local ok, button = pcall(GetControlInstructionalButton, 0, joaat(Config.Menu.command) | 0x80000000, true)
    if ok and type(button) == 'string' then
        local name = button:match('^t_(.+)$')
        if name and name ~= '' then return name end
    end
    return Config.Menu.key
end

VX.nui('atajos', function(data)
    if type(data.guardar) == 'table' then
        saved = sanitise(data.guardar)
        SetResourceKvp(STORAGE_KEY, json.encode(saved))
        return { ok = true }
    end

    return {
        activos = saved.activos,
        lista = saved.lista,
        maximo = Config.Shortcuts.max,
        teclaMenu = menuKey(),
        permitidos = Config.Shortcuts.enabled ~= false,
    }
end)

local function canFire()
    if IsNuiFocused() then return false end
    if IsPauseMenuActive() then return false end
    if UpdateOnscreenKeyboard() == 0 then return false end
    return true
end

CreateThread(function()
    while true do
        local list = saved.lista

        if Config.Shortcuts.enabled == false or not saved.activos or #list == 0 or not VX.canOpen then
            Wait(500)
        else
            Wait(0)
            if canFire() then
                local now = GetGameTimer()
                for index = 1, #list do
                    local shortcut = list[index]
                    if IsControlJustPressed(0, shortcut.control) or IsDisabledControlJustPressed(0, shortcut.control) then
                        if not lastFired[shortcut.id] or now - lastFired[shortcut.id] > 250 then
                            lastFired[shortcut.id] = now
                            SendNUIMessage({ action = 'atajo', id = shortcut.id })
                        end
                    end
                end
            end
        end
    end
end)
