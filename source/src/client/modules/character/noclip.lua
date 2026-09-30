local Action = VX.actions('accion')

local CONTROLS = {
    forward = 32,
    back = 33,
    left = 34,
    right = 35,
    up = 44,
    down = 46,
    slower = 14,
    faster = 15,
    resetSpeed = 348,
    slow = 36,
    fast = 21,
    veryFast = 19,
    lookX = 220,
    lookY = 221,
    chat = 245,
}

local MAX_PITCH = 89.0
local SPEED_STEP = 0.5
local MIN_SPEED = 0.5

local camera = nil
local entity = nil
local inVehicle = false
local alpha = 51
local speed = 1.0

local function speedLabel()
    local value = math.floor(speed * 10 + 0.5) / 10
    local whole = math.tointeger(value)
    return whole and ('x%d'):format(whole) or ('x%.1f'):format(value)
end

local function showKeys()
    VX.showControls('noclip', VX.t('Noclip · {speed}', { speed = speedLabel() }), {
        {
            keys = {
                { control = CONTROLS.forward, key = 'W' },
                { control = CONTROLS.left, key = 'A' },
                { control = CONTROLS.back, key = 'S' },
                { control = CONTROLS.right, key = 'D' },
            },
            label = VX.t('Move'),
        },
        {
            keys = { { control = CONTROLS.up, key = 'Q' }, { control = CONTROLS.down, key = 'E' } },
            label = VX.t('Up / Down'),
        },
        { key = VX.t('Wheel'), label = VX.t('Speed') },
        {
            keys = { { control = CONTROLS.fast, key = 'Shift' }, { control = CONTROLS.veryFast, key = 'Alt' } },
            label = VX.t('Faster'),
        },
        { control = CONTROLS.slow, key = 'Ctrl', label = VX.t('Slow') },
    })
end

local function firstPerson()
    if inVehicle then return Config.Noclip.firstPersonInVehicle == true end
    return Config.Noclip.firstPerson == true
end

local function createCamera()
    local position = GetEntityCoords(entity)
    local rotation = GetEntityRotation(entity, 2)

    camera = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', position.x, position.y, position.z, 0.0, 0.0, rotation.z, 75.0, false, 2)
    SetCamActive(camera, true)
    RenderScriptCams(true, true, 1000, false, false)

    local close = firstPerson()
    if inVehicle then
        AttachCamToEntity(camera, entity, 0.0, close and 0.5 or -4.5, close and 1.0 or 2.0, true)
    else
        AttachCamToEntity(camera, entity, 0.0, close and 0.0 or -2.0, close and 1.0 or 0.5, true)
    end
end

local function destroyCamera()
    if not camera then return end
    SetGameplayCamRelativeHeading(0.0)
    RenderScriptCams(false, true, 500, true, true)
    SetCamActive(camera, false)
    DestroyCam(camera, true)
    camera = nil
end

local function turnCamera()
    local rotation = GetCamRot(camera, 2)
    local pitch = VX.clamp(rotation.x + GetControlNormal(0, CONTROLS.lookY) * -5.0, -MAX_PITCH, MAX_PITCH)
    local yaw = rotation.z + GetControlNormal(0, CONTROLS.lookX) * -10.0

    SetCamRot(camera, pitch, rotation.y, yaw, 2)
    SetEntityHeading(entity, yaw % 360)
end

local function held(group, control)
    return IsControlPressed(group, control) or IsDisabledControlPressed(group, control)
end

local function blockControls()
    HudWeaponWheelIgnoreSelection()
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    EnableControlAction(0, CONTROLS.lookX, true)
    EnableControlAction(0, CONTROLS.lookY, true)
    EnableControlAction(0, CONTROLS.chat, true)
end

local function multiplier()
    local fast = tonumber(Config.Noclip.fastMultiplier) or 4.0
    if held(0, CONTROLS.veryFast) then return fast end
    if held(0, CONTROLS.fast) then return fast / 2 end
    if held(0, CONTROLS.slow) then return 0.25 end
    return 1.0
end

local function adjustSpeed()
    local before = speed
    local maximum = tonumber(Config.Noclip.maxSpeed) or 16.0

    if held(2, CONTROLS.slower) then
        speed = math.max(MIN_SPEED, speed - SPEED_STEP)
    elseif held(2, CONTROLS.faster) then
        speed = math.min(maximum, speed + SPEED_STEP)
    elseif IsDisabledControlJustReleased(0, CONTROLS.resetSpeed) then
        speed = tonumber(Config.Noclip.speed) or 1.0
    end

    return speed ~= before
end

local function hold()
    local ped = PlayerPedId()
    local position = GetEntityCoords(entity)
    RequestCollisionAtCoord(position.x, position.y, position.z)

    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)
    SetEntityVisible(entity, false, false)
    SetEntityInvincible(entity, true)
    SetEntityAlpha(entity, alpha, false)

    if inVehicle then
        SetEntityVisible(ped, false, false)
        SetEntityInvincible(ped, true)
        SetEntityAlpha(ped, alpha, false)
    end

    SetLocalPlayerVisibleLocally(true)
    SetEveryoneIgnorePlayer(PlayerId(), true)
    SetPoliceIgnorePlayer(PlayerId(), true)
end

local function fly()
    CreateThread(function()
        while VX.state.noclip and camera do
            turnCamera()
            blockControls()
            if adjustSpeed() then showKeys() end

            local step = speed * multiplier() * GetFrameTime() * 60.0
            local pitch = GetCamRot(camera, 2).x / MAX_PITCH
            local x, y, z = 0.0, 0.0, 0.0

            if held(0, CONTROLS.forward) then
                y, z = 0.5 * step, pitch * step / 2
            elseif held(0, CONTROLS.back) then
                y, z = -0.5 * step, -pitch * step / 2
            end

            if held(0, CONTROLS.left) then
                x = -0.5 * step
            elseif held(0, CONTROLS.right) then
                x = 0.5 * step
            end

            if held(0, CONTROLS.up) then
                z = z + 0.5 * step
            elseif held(0, CONTROLS.down) then
                z = z - 0.5 * step
            end

            if x ~= 0.0 or y ~= 0.0 or z ~= 0.0 then
                local target = GetOffsetFromEntityInWorldCoords(entity, x, y, z)
                SetEntityCoordsNoOffset(entity, target.x, target.y, target.z, true, true, true)
            end

            hold()
            Wait(0)
        end
    end)
end

local function groundBelow(position)
    local probe = StartExpensiveSynchronousShapeTestLosProbe(position.x, position.y, position.z, position.x, position.y, position.z - 1000.0, 1, entity, 0)
    local _, hit, point = GetShapeTestResult(probe)
    if hit == 1 or hit == true then return point.z end

    local found, z = GetGroundZFor_3dCoord(position.x, position.y, position.z, false)
    if found then return z end
    return nil
end

local function restore()
    local ped = PlayerPedId()

    if entity and DoesEntityExist(entity) then
        FreezeEntityPosition(entity, false)
        SetEntityCollision(entity, true, true)
        ResetEntityAlpha(entity)
        if inVehicle then
            SetEntityVisible(entity, true, false)
            SetEntityInvincible(entity, false)
            SetVehicleEngineOn(entity, true, true, false)
        end
    end

    ResetEntityAlpha(ped)
    SetEntityVisible(ped, not VX.state.invisible, false)
    SetEntityInvincible(ped, VX.state.godmode)
    SetEveryoneIgnorePlayer(PlayerId(), false)
    SetPoliceIgnorePlayer(PlayerId(), false)
    SetUserRadioControlEnabled(true)
end

local function enter()
    local ped = PlayerPedId()
    local vehicle = VX.currentVehicle()

    inVehicle = vehicle ~= nil and GetPedInVehicleSeat(vehicle, -1) == ped
    entity = inVehicle and vehicle or ped
    alpha = firstPerson() and 0 or 51
    speed = tonumber(Config.Noclip.speed) or 1.0

    if inVehicle then
        SetVehicleEngineOn(entity, false, true, true)
    else
        ClearPedTasksImmediately(ped)
    end

    FreezeEntityPosition(entity, true)
    createCamera()
    SetUserRadioControlEnabled(false)
    PlaySoundFromEntity(-1, 'SELECT', ped, 'HUD_LIQUOR_STORE_SOUNDSET', false, 0)
    showKeys()
    fly()
end

local function leave()
    local ped = PlayerPedId()

    if entity and DoesEntityExist(entity) then
        local position = GetEntityCoords(entity)
        local ground = groundBelow(position)
        if ground then
            SetEntityCoordsNoOffset(entity, position.x, position.y, ground + 1.0, false, false, false)
            if inVehicle then SetVehicleOnGroundProperly(entity) end
        end
    end

    destroyCamera()
    restore()
    PlaySoundFromEntity(-1, 'CANCEL', ped, 'HUD_LIQUOR_STORE_SOUNDSET', false, 0)
    VX.hideControls('noclip')
    entity = nil
end

Action['noclip'] = function()
    if not VX.state.noclip and VX.state.spectating then
        return { ok = false, mensaje = VX.t('Stop spectating before turning on noclip.') }
    end

    VX.state.noclip = not VX.state.noclip
    if VX.state.noclip then enter() else leave() end

    return {
        ok = true,
        activo = VX.state.noclip,
        mensaje = VX.state.noclip and VX.t('Noclip on.') or VX.t('Noclip off.'),
    }
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() or not VX.state.noclip then return end
    VX.state.noclip = false
    destroyCamera()
    restore()
end)
