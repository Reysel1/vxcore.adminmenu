local BANS_FILE = 'bans.json'
local HISTORY_FILE = 'history.json'
local MAX_HISTORY_PER_PERSON = 20

local bans = {}
local history = {}

local function write(file, data)
    SaveResourceFile(GetCurrentResourceName(), file, json.encode(data, { indent = true }), -1)
end

local function read(file)
    local raw = LoadResourceFile(GetCurrentResourceName(), file)
    if not raw or raw == '' then return nil end

    local ok, parsed = pcall(json.decode, raw)
    if ok and type(parsed) == 'table' then return parsed end

    print(('^1[VXCore]^7 %s is unreadable: starting with an empty registry.'):format(file))
    return nil
end

local function saveBans()
    write(BANS_FILE, bans)
end

local function expired(ban)
    return ban.expiresAt ~= nil and os.time() >= ban.expiresAt
end

local function find(identity)
    local keys = {}
    if identity.license then keys[#keys + 1] = 'license:' .. identity.license end
    for _, token in ipairs(identity.tokens or {}) do
        keys[#keys + 1] = 'token:' .. token
    end

    for _, key in ipairs(keys) do
        local ban = bans[key]
        if ban then
            if expired(ban) then
                bans[key] = nil
                saveBans()
            else
                return ban, key
            end
        end
    end

    return nil
end

local function kickMessage(ban)
    if not ban.expiresAt then
        return VX.t('You are banned from this server.\nReason: {reason}', { reason = ban.reason })
    end

    local left = math.max(0, ban.expiresAt - os.time())
    return VX.t('You are banned from this server.\nReason: {reason}\nTime left: {hours}h {minutes}m', {
        reason = ban.reason,
        hours = tostring(math.floor(left / 3600)),
        minutes = tostring(math.floor((left % 3600) / 60)),
    })
end

function VX.ban(identity, data)
    local ban = {
        id = ('%d-%04d'):format(os.time(), math.random(0, 9999)),
        name = data.name,
        reason = data.reason,
        by = data.by,
        at = os.time(),
        expiresAt = (data.minutes and data.minutes > 0) and (os.time() + data.minutes * 60) or nil,
    }

    if identity.license then bans['license:' .. identity.license] = ban end
    for _, token in ipairs(identity.tokens or {}) do
        bans['token:' .. token] = ban
    end

    saveBans()
    return ban
end

function VX.unban(identity)
    local removed = false

    if identity.license and bans['license:' .. identity.license] then
        bans['license:' .. identity.license] = nil
        removed = true
    end

    for _, token in ipairs(identity.tokens or {}) do
        if bans['token:' .. token] then
            bans['token:' .. token] = nil
            removed = true
        end
    end

    if removed then saveBans() end
    return removed
end

function VX.activeBans()
    local seen, total = {}, 0

    for key, ban in pairs(bans) do
        if not expired(ban) then
            local id = ban.id or key
            if not seen[id] then
                seen[id] = true
                total = total + 1
            end
        end
    end

    return total
end

local function historyKey(identity)
    if identity.license then return 'license:' .. identity.license end
    local token = (identity.tokens or {})[1]
    return token and ('token:' .. token) or nil
end

function VX.recordSanction(identity, sanction)
    local key = historyKey(identity)
    if not key then return end

    local list = history[key] or {}
    table.insert(list, 1, {
        tipo = sanction.kind,
        motivo = sanction.reason,
        por = sanction.by,
        minutos = sanction.minutes,
        cuando = os.time(),
    })

    while #list > MAX_HISTORY_PER_PERSON do table.remove(list) end

    history[key] = list
    write(HISTORY_FILE, history)
end

function VX.historyOf(identity)
    return history[historyKey(identity) or ''] or {}
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    local ban = find(VX.identity(src))
    if ban then
        deferrals.done(kickMessage(ban))
        return
    end

    deferrals.done()
end)

CreateThread(function()
    bans = read(BANS_FILE) or {}
    history = read(HISTORY_FILE) or {}

    local removed = 0
    for key, ban in pairs(bans) do
        if expired(ban) then
            bans[key] = nil
            removed = removed + 1
        end
    end

    if removed > 0 then saveBans() end
end)
