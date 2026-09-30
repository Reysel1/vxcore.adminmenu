VX = VX or {}

VX.LOCALES = { en = true, es = true, pt = true, fr = true, de = true }

local dictionaries = {}
local current = 'en'

local function load(locale)
    if locale == 'en' or dictionaries[locale] then return end

    local raw = LoadResourceFile(GetCurrentResourceName(), ('source/locales/%s.json'):format(locale))
    local ok, parsed = pcall(json.decode, raw or '')
    if not ok or type(parsed) ~= 'table' then
        print(('^3[VXCore]^7 Could not read the "%s" dictionary: text falls back to English.'):format(locale))
        parsed = {}
    end
    dictionaries[locale] = parsed
end

function VX.isLocale(value)
    return type(value) == 'string' and VX.LOCALES[value] == true
end

function VX.configLocale()
    local wanted = type(Config.Locale) == 'string' and Config.Locale:lower() or ''
    return VX.isLocale(wanted) and wanted or nil
end

function VX.locale()
    return current
end

function VX.setLocale(locale)
    if not VX.isLocale(locale) then return false end
    load(locale)
    if locale == current then return false end
    current = locale
    TriggerEvent('vxcore:localeChanged', locale)
    return true
end

function VX.t(text, params)
    text = tostring(text)
    local dictionary = dictionaries[current]
    local out = (dictionary and type(dictionary[text]) == 'string') and dictionary[text] or text

    if params then
        out = out:gsub('{([%w_]+)}', function(name)
            local value = params[name]
            if value == nil then return nil end
            return tostring(value)
        end)
    end

    return out
end

function VX.msg(text)
    return text
end

local fromConfig = VX.configLocale()
if fromConfig then VX.setLocale(fromConfig) end
