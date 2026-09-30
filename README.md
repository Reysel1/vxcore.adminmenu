# VXCore Admin Menu

Players, sanctions, world and console in one in-game window. **Standalone**: no
database, no oxmysql, no ox_lib, nothing hosted outside your server. Unzip it,
add two lines to `server.cfg` and it works.

- **Command:** `/vxcore` (alias `/vxadmin`) · **Key:** `F5`
- **Permissions:** FiveM ACEs, with one ACE per section so you can split ranks
- **Languages:** English, Spanish, Portuguese, French, German
- **Framework:** none required. Integrates with ESX/QBCore scripts if present

---

## Install

1. Drop the `vxcoreadminmenu` folder into `resources/`.
2. In your `server.cfg`:

```cfg
ensure vxcoreadminmenu

# Lets the resource grant its own ACE to the groups in config.lua at startup.
# Without this line nobody will be able to open the menu.
add_ace resource.vxcoreadminmenu command allow

# Who administers. If you already have your own group.admin, this is done.
add_principal identifier.license:YOUR_LICENSE_HERE group.admin
```

3. Restart. The console should print:

```
[VXCore] Admin menu ready. ACE: vxcore.menu · Command: /vxcore
```

If you get a red warning instead, the `add_ace resource.vxcoreadminmenu command
allow` line is missing.

### Finding your license

Connect to the server and look at the console: FiveM prints every player's
identifiers on join. They are also in the menu → **Players** → expand your row →
**IDs**, with one click to copy each one.

---

## Permissions

The general ACE opens the whole menu:

```cfg
add_ace group.admin vxcore.menu allow
```

There is one ACE per section for splitting ranks. Anyone holding one can open
the menu and sees only that part:

| ACE                     | Grants                                        |
| ----------------------- | --------------------------------------------- |
| `vxcore.menu`           | The whole menu                                |
| `vxcore.menu.players`   | Player list, go/bring, spectate, IDs…         |
| `vxcore.menu.sanctions` | Ban and kick                                  |
| `vxcore.menu.console`   | Run commands in the server console            |

```cfg
# A moderator who can moderate people but not touch the server.
add_ace group.moderator vxcore.menu.players   allow
add_ace group.moderator vxcore.menu.sanctions allow
```

Everything else (world, vehicle, noclip, teleport, shortcuts) needs the general
ACE.

> Every action is checked **on the server**, never in the menu. A button you
> cannot see stops nothing — the menu runs on the player's machine. Anyone
> without permission gets a "no" even if they fire the event by hand.

---

## What it does

**Commands** — heal, armour, revive, clean clothes, weapons and ammo, noclip,
invisible, godmode, teleport (to the map marker, to coordinates, to a place from
a searchable list), spawn vehicles by name, repair, refuel, tune, plate, time,
weather, announcements and area cleanup. With search and favourites.

**Players** — who is connected and their ping, and for each one: go to, bring,
heal, freeze, spectate, view identifiers, warn, kick and ban. Expanding a row
shows their sanction history.

**Sanctions** — permanent or timed bans, stored by the resource itself in
`bans.json` and checked on every connection. They are recorded by **license and
by hardware tokens**: switching Rockstar account is not enough to come back.
`history.json` also keeps kicks and warnings after they expire, which is what you
actually need in order to decide the next one.

To lift a ban, from the server console:

```
vxcore_unban <license>
```

**Keyboard shortcuts** — each staff member binds the actions they use to a key
and triggers them with the menu closed. Stored on their machine.

**Server status** — players, capacity, started resources, active bans, uptime and
OneSync.

---

## Compatibility

No framework is required, but when a script already owns something, VXCore asks
that script instead of fighting it: a bare native gets undone a second later —
the tank is empty again, or the car you just spawned will not start because you
have no keys. Detected automatically, nothing to configure:

| Resource            | Used for                        |
| ------------------- | ------------------------------- |
| `esx_ambulancejob`  | Revive and heal                 |
| `qb-ambulancejob`   | Revive and heal                 |
| `qb-vehiclekeys`    | Keys for the spawned vehicle    |
| `qb-core`           | Weapons into the inventory      |
| `ox_inventory`      | Weapons into the inventory      |
| `ox_fuel`           | Refuel                          |
| `qb-weathersync`    | Time and weather                |
| `ox_lib`            | Drawing notifications, if you prefer |

None of them is required. Without them the game natives are used.

---

## For other scripts

VXCore exposes its notifications and its on-screen key hints with the same shape
as ox_lib's `lib.notify`, so switching between them is changing the resource
name:

```lua
-- Client
exports.vxcoreadminmenu:notify('Garage', 'Your car is at the impound.', 'warning')
exports.vxcoreadminmenu:notify({ title = 'Garage', description = '…', type = 'error', duration = 8000 })

-- Server (-1 for everyone)
exports.vxcoreadminmenu:notify(source, 'Event', 'Starts in 5 minutes.', 'info')

-- On-screen keys, like the noclip ones
exports.vxcoreadminmenu:showControls('my-script', 'My minigame', {
    { control = 38, key = 'E', label = 'Pick up' },
    { keys = { { control = 174, key = '←' }, { control = 175, key = '→' } }, label = 'Switch' },
})
exports.vxcoreadminmenu:hideControls('my-script')
```

`Config.Notifications.system` decides who draws them: VXCore's own, ox_lib's (if
you have it) or the chat.

---

## Configuration

Everything lives in `config.lua`. Keep **your** copy when updating and replace
the rest; any option added by a newer version is filled in with its default.

| Option | Default | What it does |
| --- | --- | --- |
| `Locale` | `'en'` | Menu and notification language: `en`, `es`, `pt`, `fr`, `de`. |
| `Menu.command` | `'vxcore'` | Command that opens and closes the menu. |
| `Menu.aliases` | `{ 'vxadmin' }` | Extra command names. |
| `Menu.key` | `'F5'` | Default key. Each player can rebind it in Settings → Key Bindings → FiveM. |
| `Menu.ace` | `'vxcore.menu'` | ACE for the whole menu. Section ACEs are this name plus `.players`, `.sanctions`, `.console`. |
| `Menu.groups` | `{ 'group.admin', 'group.superadmin' }` | Groups granted the ACE at startup. |
| `Shortcuts.enabled` | `true` | Whether keyboard shortcuts fire at all. |
| `Shortcuts.max` | `12` | How many each staff member may bind. |
| `Noclip.speed` | `1.0` | Starting speed. The mouse wheel changes it; the wheel click resets it. |
| `Noclip.maxSpeed` | `16.0` | Ceiling for the wheel. |
| `Noclip.fastMultiplier` | `4.0` | Alt multiplies by this, Shift by half, Ctrl goes to a quarter. |
| `Noclip.firstPerson` | `true` | First-person camera when flying on foot. |
| `Noclip.firstPersonInVehicle` | `false` | Same, but flying in a vehicle. |
| `Vehicle.plate` | `'VXCORE'` | Plate for vehicles spawned from the menu. |
| `Notifications.system` | `'vxcore'` | Who draws notifications: `vxcore`, `ox_lib` or `chat`. |
| `Notifications.position` | `'top-center'` | `top-left`, `top-center`, `top-right`, `bottom-left`, `bottom-center` or `bottom-right`. |
| `Notifications.duration` | `5000` | Default lifetime in milliseconds. |
| `Notifications.soundVolume` | `0.5` | Chime volume, 0 to 1. Only notifications that ask for it (`sound = true`) play a sound. |
| `Controls.position` | `'bottom-right'` | Corner for the on-screen key hints. |
| `Console.allowed` | `refresh`, `restart`, `ensure`, `stop` | Lua patterns for the only commands the menu may run in the server console. Anything that does not match one of them never reaches `ExecuteCommand`. |

---

## FAQ

**The menu will not open.** Check that you have the ACE (`vxcore.menu` or a
section one) and that `server.cfg` has `add_ace resource.vxcoreadminmenu command
allow`. You do not need to reconnect after being granted an ACE: press the key
again.

**Do I need OneSync?** No, but with it the server knows player positions, so "go
to" and "bring" are instant. Without it the target client is asked, which takes a
moment longer.

**Can the key be changed?** Yes, per player in Settings → Key Bindings → FiveM.
`Config.Menu.key` only sets the default.

**How many bans can it hold?** `bans.json` is read in full at startup. A few
thousand is fine; for tens of thousands you want a real database, but then it
would no longer be drop-in.

**Can I modify the menu?** The interface ships compiled in `source/nui/assets`.
All the Lua is in `source/src`.

---

## Licence

Free to use and modify on your server, including commercial ones. Do not resell
it and do not re-release it as your own. Full terms in `LICENSE.md`.
