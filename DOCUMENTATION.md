# Lunar Plasma Documentation

Lunar Plasma provides a Lua interface for controlling KDE Plasma. The public API is loaded from a single file and organized into modules.

> [!NOTE]
> Lunar Plasma does not have a standardized way to add user modules yet. Feel free to experiment with them, but they may break in future versions.

This documentation is preliminary. Although its content is accurate, its presentation could be improved by a lot!

## Contents

- [Getting started](#getting-started)
- [Return values](#return-values)
- [Sound](#sound)
- [Notifications](#notifications)
- [Power](#power)
- [Keyboard](#keyboard)
- [Desktop](#desktop)
- [Wi-Fi](#wi-fi)
- [Bluetooth](#bluetooth)
- [General examples](#general-examples)

## Getting started

> [!CAUTION]
> Only run scripts from trusted sources. Lunar Plasma does not provide security restrictions for scripts from untrusted sources.

Load the public entry point with `dofile`, using the path to `lunar-plasma.lua` that is correct for your script. The library resolves its internal Lua modules and backend scripts automatically. Lua does not expand `~`, so a script using the default installation should load it through `HOME`:

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
```

Scripts in the project `examples` directory locate `lunar-plasma.lua` in their parent directory, so they can be executed from the project root or from inside `examples` without installing Lunar Plasma first.

The installed version is available through `plasma.version`:

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

print(plasma.version)
```

The currently available modules are:

| Module | Purpose |
|---|---|
| `plasma.sound` | Control the default audio output. |
| `plasma.notification` | Send desktop notifications. |
| `plasma.power` | Inspect battery and power-source state, control power profiles and system power actions, and adjust display brightness. |
| `plasma.keyboard` | Read and change keyboard layouts. |
| `plasma.desktop` | Inspect displays and control general desktop settings. |
| `plasma.wifi` | Inspect and control Wi-Fi state. |
| `plasma.bluetooth` | Inspect the Bluetooth adapter and devices, and control the adapter state. |

## Return values

Functions that change state return:

```lua
true
```

If an operation fails, they return:

```lua
nil, error_message
```

Functions that read state return the requested value as their first result. On failure, they also return `nil, error_message`.

Display and keyboard layout indexes start at `1` in the Lua API.

## Sound

The sound module controls the default audio output. Volume values are integer percentages from `0` to `100`.

### `plasma.sound.set_volume(value)`

Sets the volume of the default audio output to an absolute percentage. It changes the current level directly instead of increasing or decreasing it.

| Parameter | Type | Description |
|---|---|---|
| `value` | integer | Volume percentage from `0` to `100`. |

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.set_volume(50) then
    print("Volume set to 50%")
end
```

### `plasma.sound.get_volume()`

Reads the current volume of the default audio output. The returned percentage is independent of the mute state.

**Returns:** An integer from `0` to `100`.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local volume = plasma.sound.get_volume()

print(volume)
```

### `plasma.sound.mute()`

Mutes the default audio output without changing its stored volume level. Unmuting restores playback at the previous level.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.mute() then
    print("Sound muted")
end
```

### `plasma.sound.unmute()`

Unmutes the default audio output. The existing volume level is preserved.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.unmute() then
    print("Sound unmuted")
end
```

### `plasma.sound.is_muted()`

Reads the mute state of the default audio output without changing it. The result is a Lua boolean.

**Returns:** `true` when muted or `false` when unmuted.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local muted = plasma.sound.is_muted()

print(muted)
```

### `plasma.sound.toggle_mute()`

Switches the default audio output to the opposite mute state. The stored volume level is not changed.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.toggle_mute() then
    print("Mute state changed")
end
```

### `plasma.sound.increase_volume(amount)`

Reads the current volume and increases it by the requested number of percentage points. The final value is capped at `100`.

| Parameter | Type | Description |
|---|---|---|
| `amount` | integer | Percentage points to add, from `0` to `100`. |

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.increase_volume(10) then
    print("Volume increased")
end
```

### `plasma.sound.decrease_volume(amount)`

Reads the current volume and decreases it by the requested number of percentage points. The final value is limited to `0`.

| Parameter | Type | Description |
|---|---|---|
| `amount` | integer | Percentage points to subtract, from `0` to `100`. |

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.decrease_volume(10) then
    print("Volume decreased")
end
```

## Notifications

The notifications module sends messages through the desktop notification service.

### `plasma.notification.send(options)`

Sends one notification through the current desktop notification server. Only `title` and `text` are required, and the remaining options control its presentation.

| Option | Type | Required | Default | Description |
|---|---|:---:|---|---|
| `title` | string | Yes | N/A | Notification title. |
| `text` | string | Yes | N/A | Notification body. |
| `icon` | string | No | Type-specific icon | Icon name or file path. |
| `sound` | string | No | No sound | Sound theme name or sound file path. |
| `timeout` | integer | No | `-1` | Visibility time in milliseconds. `-1` uses the notification server default. |
| `type` | string | No | `"info"` | One of `"info"`, `"warning"`, `"error"`, or `"success"`. |

The notification type selects the default icon and urgency. A custom `icon` overrides the default icon.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.notification.send({
    title = "Download complete",
    text = "Your files are ready",
    type = "info",
})
```

## Power

The power module inspects battery and power-source state, controls system power profiles and session power actions, and adjusts display brightness.

> [!IMPORTANT]
> `shutdown()`, `reboot()`, and `suspend()` act on the current system. The desktop or operating system may request authorization before completing the action.

### `plasma.power.set_profile(profile)`

Selects the active system power profile when profile management is available. The requested profile must also be supported by the current hardware and operating system.

| Parameter | Type | Description |
|---|---|---|
| `profile` | string | `"saving"`, `"normal"`, or `"performance"`. |

The aliases `"power-saver"` and `"balanced"` are also accepted.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.set_profile("saving") then
    print("Power saving enabled")
end
```

### `plasma.power.get_profile()`

Reads the active system power profile and converts the backend profile name to the corresponding Lunar Plasma name.

**Returns:** `"saving"`, `"normal"`, or `"performance"`.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local profile = plasma.power.get_profile()

print(profile)
```

### Battery status values

Battery status functions use the aggregate system battery reported by UPower. Peripheral batteries, such as those in Bluetooth headphones or input devices, are not included.

`get_battery_status()` returns a table with the following structure when a system battery is present:

```lua
{
    present = true,
    percentage = 73.4,
    state = "discharging",
    source = "battery",
    time_remaining = 7200,
    warning_level = "none",
}
```

| Field | Type | Description |
|---|---|---|
| `present` | boolean | Whether UPower reports a system battery. |
| `percentage` | number or nil | Current charge from `0` to `100`, or `nil` when no battery is present. |
| `state` | string | Battery state such as `"charging"`, `"discharging"`, or `"fully-charged"`. |
| `source` | string | Active source: `"battery"`, `"ac"`, or `"unknown"`. |
| `time_remaining` | integer or nil | Relevant charge or discharge estimate in seconds, when available. |
| `warning_level` | string | UPower warning level, such as `"none"`, `"low"`, or `"critical"`. |

Possible battery states are `"unknown"`, `"charging"`, `"discharging"`, `"empty"`, `"fully-charged"`, `"pending-charge"`, and `"pending-discharge"`.

Possible warning levels are `"unknown"`, `"none"`, `"discharging"`, `"low"`, `"critical"`, and `"action"`.

### `plasma.power.get_battery_status()`

Reads the complete aggregate battery and power-source state. The absence of a system battery is represented by `present = false` and is not considered an error.

**Returns:** A battery status table.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local battery = plasma.power.get_battery_status()

if battery.present then
    print(battery.percentage, battery.state)
else
    print("No system battery")
end
```

### `plasma.power.is_battery_present()`

Checks whether UPower reports an aggregate system battery.

**Returns:** `true` when a battery is present or `false` otherwise.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local present = plasma.power.is_battery_present()

print(present)
```

### `plasma.power.get_battery_percentage()`

Reads the current aggregate battery charge.

**Returns:** A number from `0` to `100`, or `nil, error_message` when no system battery is available.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local percentage = plasma.power.get_battery_percentage()

print(percentage)
```

### `plasma.power.get_battery_state()`

Reads the current aggregate battery state.

**Returns:** A battery state string, or `nil, error_message` when no system battery is available.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local state = plasma.power.get_battery_state()

print(state)
```

### `plasma.power.is_battery_charging()`

Checks whether the aggregate system battery is currently charging. A system without a battery returns `false`.

**Returns:** `true` when charging or `false` otherwise.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local charging, err = plasma.power.is_battery_charging()

assert(charging ~= nil, err)
print(charging)
```

### `plasma.power.get_battery_time_remaining()`

Reads the relevant UPower time estimate. While charging, this is the estimated time until full; while discharging, it is the estimated time until empty.

**Returns:** An integer number of seconds, or `nil, error_message` when no battery or estimate is available.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local seconds = plasma.power.get_battery_time_remaining()

print(seconds)
```

### `plasma.power.get_battery_warning_level()`

Reads the current UPower warning level for the aggregate system battery.

**Returns:** A warning-level string, or `nil, error_message` when no system battery is available.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local warning = plasma.power.get_battery_warning_level()

print(warning)
```

### `plasma.power.get_power_source()`

Reads the active system power source. This function also works on systems without a battery.

**Returns:** `"battery"`, `"ac"`, or `"unknown"`.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local source = plasma.power.get_power_source()

print(source)
```

### `plasma.power.is_on_battery()`

Checks whether the system is currently drawing power from its battery.

**Returns:** `true` when using battery power or `false` otherwise.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.is_on_battery() then
    print("Running on battery")
end
```

### `plasma.power.is_ac_connected()`

Checks whether the system is connected to AC power.

**Returns:** `true` when connected to AC power or `false` otherwise.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.is_ac_connected() then
    print("Connected to AC power")
end
```

### `plasma.power.suspend()`

Requests a system suspend through the available power management service. Execution normally continues after the system resumes.

**Returns:** `true` when the suspend request is accepted.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.suspend() then
    print("System resumed")
end
```

### `plasma.power.shutdown()`

Requests a complete system shutdown through the available power management service. The request may require authorization from the current user.

**Returns:** `true` when the shutdown request is accepted.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.shutdown() then
    print("Shutdown requested")
end
```

### `plasma.power.reboot()`

Requests a system restart through the available power management service. The request may require authorization from the current user.

**Returns:** `true` when the reboot request is accepted.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.reboot() then
    print("Reboot requested")
end
```

### `plasma.power.set_brightness(display, value)`

Sets the brightness of one selected display to an absolute percentage. Display numbers are one-based, so `1` refers to the first display reported by Plasma.

| Parameter | Type | Description |
|---|---|---|
| `display` | string or integer | Display name, ID, label, or one-based monitor number. |
| `value` | integer | Brightness percentage from `0` to `100`. |

Examples of valid display selectors include `1`, `"monitor 1"`, `"screen 2"`, and a connector name such as `"HDMI-A-1"` when available.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.set_brightness("HDMI-A-1", 75) then
    print("Brightness set to 75%")
end
```

### `plasma.power.get_brightness(display)`

Reads the current brightness of one selected display as a normalized percentage. Display numbers are one-based, so `1` refers to the first display reported by Plasma.

| Parameter | Type | Description |
|---|---|---|
| `display` | string or integer | Display name, ID, label, or one-based monitor number. |

**Returns:** An integer from `0` to `100`.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1
local brightness = plasma.power.get_brightness(first_display)

print(brightness)
```

## Keyboard

The keyboard module reads and changes the layouts configured in the current Plasma session.

### Layout values

Functions that return a layout use the following table:

```lua
{
    index = 1,
    id = "latam",
    variant = "",
    name = "Spanish (Latin American)",
}
```

| Field | Type | Description |
|---|---|---|
| `index` | integer | One-based position in the configured layout list. |
| `id` | string | XKB layout identifier. |
| `variant` | string | XKB variant identifier. An empty string means no variant. |
| `name` | string | Human-readable layout name. |

### `plasma.keyboard.list_layouts()`

Reads every keyboard layout configured in the current Plasma session. The returned array follows the same order shown by the desktop layout switcher.

**Returns:** An array of layout tables.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local layouts = plasma.keyboard.list_layouts()

for _, layout in ipairs(layouts) do
    print(layout.index, layout.name)
end
```

### `plasma.keyboard.get_active_layout()`

Reads the keyboard layout currently selected in Plasma. The returned table includes its position, identifier, variant, and human-readable name.

**Returns:** A layout table.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local layout = plasma.keyboard.get_active_layout()

print(layout.name)
```

### `plasma.keyboard.set_layout(layout, variant)`

Selects one of the keyboard layouts already configured in Plasma. The layout can be identified by ID, name, position, or a table returned by this module.

| Parameter | Type | Required | Description |
|---|---|:---:|---|
| `layout` | string, integer, or table | Yes | Layout ID, human-readable name, one-based index, or a layout table returned by this module. |
| `variant` | string | No | Variant used to distinguish layouts with the same ID. |

When `layout` is a table, its `id` and `variant` fields are used. If `id` is missing, `index` is used.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.keyboard.set_layout("latam") then
    print("Keyboard layout changed")
end
```

### `plasma.keyboard.select_next_layout()`

Moves to the next layout in the configured order. After the last layout, Plasma returns to the first one.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.keyboard.select_next_layout() then
    print("Switched to the next layout")
end
```

### `plasma.keyboard.select_previous_layout()`

Moves to the previous layout in the configured order. From the first layout, Plasma continues with the last one.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.keyboard.select_previous_layout() then
    print("Switched to the previous layout")
end
```

## Desktop

The desktop module inspects displays associated with the current Plasma session and controls general desktop settings, including wallpapers.

### Display values

Functions that return display information use the following table:

```lua
{
    index = 1,
    id = 1,
    name = "HDMI-A-1",
    uuid = "7d578311-88c3-4a7b-9d97-63edb6c52725",
    enabled = true,
    connected = true,
    primary = true,
    priority = 1,
    position = {
        x = 0,
        y = 0,
    },
    size = {
        width = 1920,
        height = 1080,
    },
    scale = 1,
    rotation = "normal",
    mode = {
        id = "2",
        width = 1920,
        height = 1080,
        refresh_rate = 144,
    },
}
```

| Field | Type | Description |
|---|---|---|
| `index` | integer | One-based position in the list returned by KScreen. |
| `id` | integer | KScreen output identifier. |
| `name` | string | Connector name, such as `"HDMI-A-1"` or `"eDP-1"`. |
| `uuid` | string | KScreen output UUID. |
| `enabled` | boolean | Whether the output is part of the active desktop configuration. |
| `connected` | boolean | Whether the display is physically connected. |
| `primary` | boolean | Whether the display is the primary enabled output. |
| `priority` | integer | KScreen output priority. |
| `position` | table | Desktop coordinates in the `x` and `y` fields. |
| `size` | table | Configured width and height in pixels. |
| `scale` | number | Current display scale. |
| `rotation` | string | Normalized rotation name. |
| `mode` | table or nil | Active mode, or `nil` when the display has no active mode. |

A connected display may be disabled. `connected` describes the physical connection, while `enabled` describes whether Plasma currently uses the output.

### `plasma.desktop.list_displays()`

Reads every display reported by KScreen, including connected displays that are currently disabled.

**Returns:** An array of display tables ordered by their KScreen output position.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local displays = plasma.desktop.list_displays()

for _, display in ipairs(displays) do
    print(display.name, display.connected, display.enabled)
end
```

### `plasma.desktop.get_display(name)`

Reads one display by its exact connector name.

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Connector name such as `"HDMI-A-1"`. |

**Returns:** A display table.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local display = plasma.desktop.get_display("HDMI-A-1")

print(display.name, display.connected, display.enabled)
```

### `plasma.desktop.get_primary_display()`

Reads the primary enabled display in the current KScreen configuration.

**Returns:** A display table, or `nil, error_message` when no primary display is available.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local display = plasma.desktop.get_primary_display()

print(display.name)
```

### Display mode values

`list_display_modes()` returns mode tables with the following fields:

```lua
{
    id = "2",
    width = 1920,
    height = 1080,
    refresh_rate = 144,
    preferred = false,
    current = true,
}
```

| Field | Type | Description |
|---|---|---|
| `id` | string | KScreen mode identifier. |
| `width` | integer | Horizontal resolution in pixels. |
| `height` | integer | Vertical resolution in pixels. |
| `refresh_rate` | number | Refresh rate in hertz. |
| `preferred` | boolean | Whether the display reports this as a preferred mode. |
| `current` | boolean | Whether this mode is currently active. |

### `plasma.desktop.list_display_modes(display)`

Reads every mode supported by a display returned by this module.

| Parameter | Type | Description |
|---|---|---|
| `display` | table | Display table returned by `list_displays()`, `get_display()`, or `get_primary_display()`. |

**Returns:** An array of display mode tables.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local display = plasma.desktop.get_primary_display()
local modes = plasma.desktop.list_display_modes(display)

for _, mode in ipairs(modes) do
    print(mode.width, mode.height, mode.refresh_rate, mode.current)
end
```

### Wallpaper values

Functions that return wallpaper information use the following table:

```lua
{
    display = 1,
    plugin = "org.kde.image",
    uri = "file:///home/user/Pictures/wallpaper.png",
    path = "/home/user/Pictures/wallpaper.png",
}
```

| Field | Type | Description |
|---|---|---|
| `display` | integer | One-based display number. |
| `plugin` | string | Plasma wallpaper plugin currently in use. |
| `uri` | string or nil | Complete wallpaper URI reported by Plasma, or `nil` when Plasma uses its default without an explicit image. |
| `path` | string or nil | Wallpaper URI with the `file://` prefix removed, or `nil` when no explicit image is configured. |

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1
local wallpaper = plasma.desktop.get_wallpaper(first_display)

print(wallpaper.display, wallpaper.plugin, wallpaper.path)
```

### `plasma.desktop.list_wallpapers()`

Reads the current wallpaper configuration for every display managed by Plasma.

The returned array contains one wallpaper table per display, ordered by display number. Each entry includes the one-based display number, wallpaper plugin, complete URI, and local path when the wallpaper uses a `file://` URI. The URI and path are `nil` when Plasma uses its default wallpaper without storing an explicit image.

```lua
{
    {
        display = 1,
        plugin = "org.kde.image",
        uri = "file:///home/user/Pictures/left.png",
        path = "/home/user/Pictures/left.png",
    },
    {
        display = 2,
        plugin = "org.kde.image",
        uri = "file:///home/user/Pictures/right.png",
        path = "/home/user/Pictures/right.png",
    },
}
```

**Returns:** An array of wallpaper tables, or `nil, error_message` when the state cannot be read.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local wallpapers = plasma.desktop.list_wallpapers()

for _, wallpaper in ipairs(wallpapers) do
    print(wallpaper.display, wallpaper.path)
end
```

### `plasma.desktop.get_wallpaper(display)`

Reads the wallpaper currently assigned to one display. If no display is provided, the first display is used.

| Parameter | Type | Required | Default | Description |
|---|---|:---:|---|---|
| `display` | integer | No | `1` | One-based display number. |

**Returns:** A wallpaper table.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1
local wallpaper = plasma.desktop.get_wallpaper(first_display)

print(wallpaper.path)
```

### `plasma.desktop.set_wallpaper(path, options)`

Sets an image as wallpaper on every display by default. A connector name, display number, or options table can limit the change to one display.

| Parameter | Type | Required | Description |
|---|---|:---:|---|
| `path` | string | Yes | Local image path or `file://` URI. |
| `options` | table, string, or integer | No | Wallpaper options, a connector name, or a display number shorthand. |

Available options:

| Option | Type | Default | Description |
|---|---|---|---|
| `display` | string or integer | All displays | Connector name or one-based Plasma screen number. |
| `plugin` | string | `"org.kde.image"` | Plasma wallpaper plugin. This is mainly useful when restoring a previously read wallpaper. |

Passing a connector name directly targets that display without relying on display enumeration order:

```lua
plasma.desktop.set_wallpaper("/path/to/wallpaper.png", "DVI-D-1")
```

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local display = "DVI-D-1"

if plasma.desktop.set_wallpaper("/home/user/Pictures/wallpaper.png", display) then
    print("Wallpaper changed")
end
```

## Wi-Fi

The Wi-Fi module inspects and controls the NetworkManager Wi-Fi radio and active connection.

### Wi-Fi status values

`get_status()` returns the following table:

```lua
{
    enabled = true,
    connected = true,
    network = "Lunar Network",
}
```

| Field | Type | Description |
|---|---|---|
| `enabled` | boolean | Whether the Wi-Fi radio is enabled. |
| `connected` | boolean | Whether a Wi-Fi connection is active. |
| `network` | string or nil | Active network SSID, or `nil` when disconnected. |

### `plasma.wifi.get_status()`

Reads the complete Wi-Fi radio and connection state.

**Returns:** A Wi-Fi status table.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local wifi = plasma.wifi.get_status()

if wifi.connected then
    print("Connected to " .. wifi.network)
end
```

### `plasma.wifi.is_enabled()`

Checks whether the Wi-Fi radio is enabled.

**Returns:** `true` when enabled or `false` otherwise.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

print(plasma.wifi.is_enabled())
```

### `plasma.wifi.is_connected()`

Checks whether a Wi-Fi connection is active.

**Returns:** `true` when connected or `false` otherwise.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

print(plasma.wifi.is_connected())
```

### `plasma.wifi.get_active_network()`

Reads the SSID of the active Wi-Fi network.

**Returns:** The active SSID, or `nil, error_message` when Wi-Fi is not connected.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local network = plasma.wifi.get_active_network()

print(network)
```

### `plasma.wifi.enable()`

Enables the Wi-Fi radio through NetworkManager.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.wifi.enable()
```

### `plasma.wifi.disable()`

Disables the Wi-Fi radio through NetworkManager. This disconnects any active Wi-Fi connection.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.wifi.disable()
```

### `plasma.wifi.toggle()`

Switches the Wi-Fi radio to the opposite enabled state.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.wifi.toggle()
```

## Bluetooth

The Bluetooth module inspects the default BlueZ adapter and its known devices. This version controls the adapter radio but does not pair, trust, connect, disconnect, or remove devices.

### Bluetooth status values

`get_status()` returns the following adapter table:

```lua
{
    enabled = true,
    discoverable = false,
    discovering = false,
    address = "AA:BB:CC:DD:EE:FF",
    name = "Lunar Adapter",
}
```

| Field | Type | Description |
|---|---|---|
| `enabled` | boolean | Whether the default Bluetooth adapter is powered. |
| `discoverable` | boolean | Whether other devices can currently discover the adapter. |
| `discovering` | boolean | Whether the adapter is currently scanning for devices. |
| `address` | string | Bluetooth address of the default adapter. |
| `name` | string | Human-readable adapter name. |

### Bluetooth device values

Functions that return devices use the following table:

```lua
{
    address = "11:22:33:44:55:66",
    name = "Lunar Headphones",
    paired = true,
    trusted = true,
    connected = true,
    blocked = false,
}
```

| Field | Type | Description |
|---|---|---|
| `address` | string | Bluetooth device address. |
| `name` | string | Human-readable device name. |
| `paired` | boolean | Whether the device is paired. |
| `trusted` | boolean | Whether BlueZ considers the device trusted. |
| `connected` | boolean | Whether the device is currently connected. |
| `blocked` | boolean | Whether the device is blocked. |

### `plasma.bluetooth.get_status()`

Reads the state of the default Bluetooth adapter.

**Returns:** A Bluetooth adapter status table.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local bluetooth = plasma.bluetooth.get_status()

print(bluetooth.enabled, bluetooth.name)
```

### `plasma.bluetooth.is_enabled()`

Checks whether the default Bluetooth adapter is enabled.

**Returns:** `true` when enabled or `false` otherwise.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

print(plasma.bluetooth.is_enabled())
```

### `plasma.bluetooth.enable()`

Enables the default Bluetooth adapter.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.bluetooth.enable()
```

### `plasma.bluetooth.disable()`

Disables the default Bluetooth adapter. Connected Bluetooth devices will be disconnected.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.bluetooth.disable()
```

### `plasma.bluetooth.toggle()`

Switches the default Bluetooth adapter to the opposite enabled state.

**Returns:** `true` on success.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.bluetooth.toggle()
```

### `plasma.bluetooth.list_known_devices()`

Reads every device known by the default Bluetooth adapter. An adapter with no known devices returns an empty array.

**Returns:** An array of Bluetooth device tables.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local devices = plasma.bluetooth.list_known_devices()

for _, device in ipairs(devices) do
    print(device.name, device.address)
end
```

### `plasma.bluetooth.list_connected_devices()`

Reads every currently connected device known by the default Bluetooth adapter. No active connections produce an empty array.

**Returns:** An array of Bluetooth device tables.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local devices = plasma.bluetooth.list_connected_devices()

for _, device in ipairs(devices) do
    print(device.name, device.address)
end
```

### `plasma.bluetooth.get_device(device)`

Reads one known Bluetooth device. The selector may be its Bluetooth address or a device table previously returned by this module.

| Parameter | Type | Description |
|---|---|---|
| `device` | string or table | Bluetooth address or Bluetooth device table. |

**Returns:** A Bluetooth device table.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local device = plasma.bluetooth.get_device("11:22:33:44:55:66")

print(device.name, device.connected)
```

### `plasma.bluetooth.is_connected(device)`

Checks whether one known Bluetooth device is connected. It accepts the same selectors as `get_device()`.

| Parameter | Type | Description |
|---|---|---|
| `device` | string or table | Bluetooth address or Bluetooth device table. |

**Returns:** `true` when connected or `false` otherwise.

#### Quick example

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local device = plasma.bluetooth.get_device("11:22:33:44:55:66")

print(plasma.bluetooth.is_connected(device))
```

## General examples

These examples combine multiple modules into small desktop automations.

### Apply a work setup

Prepare the desktop for a work session with one script.

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1

plasma.sound.set_volume(35)
plasma.power.set_profile("normal")
plasma.power.set_brightness(first_display, 70)
plasma.keyboard.set_layout("us")
plasma.desktop.set_wallpaper(home .. "/Pictures/workspace.png")
plasma.notification.send({
    title = "Work setup",
    text = "Your desktop is ready",
    type = "success",
})
```

### Respond to a low battery event

Check the current battery state and apply power-saving settings when the charge is low and the system is not charging.

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1
local present, present_err = plasma.power.is_battery_present()

assert(present ~= nil, present_err)

if present then
    local charging, charging_err = plasma.power.is_battery_charging()
    local percentage, percentage_err = plasma.power.get_battery_percentage()

    assert(charging ~= nil, charging_err)
    assert(percentage, percentage_err)

    if not charging and percentage <= 20 then
        plasma.power.set_profile("saving")
        plasma.power.set_brightness(first_display, 35)
        plasma.notification.send({
            title = "Low battery",
            text = "Power saving settings have been applied",
            type = "warning",
        })
    end
end
```

### Adjust the desktop by time of day

Use a lighter setup during the day and a quieter one at night.

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local hour = tonumber(os.date("%H"))

if hour >= 7 and hour < 19 then
    plasma.desktop.set_wallpaper(home .. "/Pictures/day.png")
    plasma.power.set_profile("normal")
    plasma.sound.set_volume(40)
else
    plasma.desktop.set_wallpaper(home .. "/Pictures/night.png")
    plasma.power.set_profile("saving")
    plasma.sound.set_volume(20)
end
```

### Show the active keyboard layout

Move to the next configured layout and display its name.

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.keyboard.select_next_layout()
local layout = plasma.keyboard.get_active_layout()

        plasma.notification.send({
    title = "Keyboard layout",
    text = layout.name,
})
```

### Show connected hardware

Display the active Wi-Fi network, connected Bluetooth devices, and connected screens.

```lua
local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")
local wifi = plasma.wifi.get_status()

if wifi.connected then
    print("Wi-Fi:", wifi.network)
else
    print("Wi-Fi: not connected")
end

for _, device in ipairs(plasma.bluetooth.list_connected_devices()) do
    print("Bluetooth:", device.name)
end

for _, display in ipairs(plasma.desktop.list_displays()) do
    if display.connected then
        print("Display:", display.name)
    end
end
```
