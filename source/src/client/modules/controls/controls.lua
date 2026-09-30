local groups = {}
local order = {}

local function labelFor(control, fallback)
    if type(control) == 'number' then
        local ok, button = pcall(GetControlInstructionalButton, 0, control, true)
        if ok and type(button) == 'string' then
            local name = button:match('^t_(.+)$')
            if name and name ~= '' then return name end
        end
    end

    local trimmed = VX.trim(fallback)
    return trimmed ~= '' and trimmed or '?'
end

local function row(entry)
    if type(entry) ~= 'table' then return nil end

    local keys = {}
    if type(entry.keys) == 'table' then
        for _, key in ipairs(entry.keys) do
            if type(key) == 'table' then
                keys[#keys + 1] = labelFor(key.control, key.key)
            elseif key ~= nil then
                keys[#keys + 1] = labelFor(nil, key)
            end
        end
    else
        keys[1] = labelFor(entry.control, entry.key)
    end

    local label = VX.trim(entry.label)
    if #keys == 0 or label == '' then return nil end
    return { teclas = keys, texto = label }
end

local function visible()
    local out = {}
    for _, id in ipairs(order) do
        local group = groups[id]
        if group then out[#out + 1] = { id = id, titulo = group.title, teclas = group.rows } end
    end
    return out
end

local function push()
    SendNUIMessage({ action = 'controles', grupos = visible() })
end

function VX.showControls(id, title, keys)
    id = VX.trim(id)
    if id == '' or type(keys) ~= 'table' then
        print('^3[VXCore]^7 showControls needs an id and a list of keys.')
        return
    end

    local rows = {}
    for _, entry in ipairs(keys) do
        local built = row(entry)
        if built then rows[#rows + 1] = built end
    end

    if #rows == 0 then return VX.hideControls(id) end

    if not groups[id] then order[#order + 1] = id end

    local title_ = VX.trim(title)
    groups[id] = {
        title = title_ ~= '' and title_ or nil,
        rows = rows,
        owner = GetInvokingResource(),
    }

    push()
end

function VX.hideControls(id)
    if id == nil then
        groups, order = {}, {}
    else
        id = VX.trim(id)
        if not groups[id] then return end
        groups[id] = nil

        for index, current in ipairs(order) do
            if current == id then
                table.remove(order, index)
                break
            end
        end
    end

    push()
end

exports('showControls', VX.showControls)
exports('hideControls', VX.hideControls)

VX.nui('controles', function()
    return { grupos = visible(), posicion = Config.Controls.position }
end)

AddEventHandler('onClientResourceStop', function(resource)
    local removed = false

    for id, group in pairs(groups) do
        if group.owner == resource then
            groups[id] = nil
            removed = true
        end
    end

    if not removed then return end

    local remaining = {}
    for _, id in ipairs(order) do
        if groups[id] then remaining[#remaining + 1] = id end
    end

    order = remaining
    push()
end)
