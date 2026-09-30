local function grantAce()
    local ace = Config.Menu.ace
    local resource = GetCurrentResourceName()

    for _, group in ipairs(Config.Menu.groups) do
        ExecuteCommand(('add_ace %s %s allow'):format(group, ace))
    end

    local first = Config.Menu.groups[1]
    if first and not IsPrincipalAceAllowed(first, ace) then
        print(('^1[VXCore]^7 Could not grant %s to %s. Add this to server.cfg: ^3add_ace resource.%s command allow^7'):format(ace, first, resource))
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    grantAce()
    print(('^2[VXCore]^7 Admin menu ready. ACE: %s · Command: /%s'):format(Config.Menu.ace, Config.Menu.command))
end)
