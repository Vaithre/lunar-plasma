# Lunar Plasma Documentation

Lunar Plasma provides a Lua interface for controlling KDE Plasma. The public API is loaded from a single file and organized into modules.

> [!NOTE]
> Lunar Plasma does not have a standardized way to add user modules yet. Feel free to experiment with them, but they may break in future versions.

## Contents

- [Getting started](#getting-started)
- [Return values](#return-values)
- [Sound](#sound)
- [Notifications](#notifications)
- [Power](#power)
- [Keyboard](#keyboard)
- [Desktop](#desktop)
- [General examples](#general-examples)

## Getting started

Load the public entry point with `dofile`:

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
```

Use the path to `lunar-plasma.lua` that is correct for your script. The library resolves its internal Lua modules and backend scripts automatically. Lua does not expand `~`, so a script using the default installation should load it through `HOME`:

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
```

The installed version is available through `plasma.version`:

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

print(plasma.version)
```

The currently available modules are:

| Module | Purpose |
|---|---|
| `plasma.sound` | Control the default audio output. |
| `plasma.notifications` | Send desktop notifications. |
| `plasma.power` | Control power profiles, system power actions, and display brightness. |
| `plasma.keyboard` | Read and change keyboard layouts. |
| `plasma.desktop` | Control general desktop settings. |

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

### `plasma.sound.set(value)`

Sets the volume of the default audio output to an absolute percentage. It changes the current level directly instead of increasing or decreasing it.

| Parameter | Type | Description |
|---|---|---|
| `value` | integer | Volume percentage from `0` to `100`. |

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.set(50) then
    print("Volume set to 50%")
end
```

### `plasma.sound.get()`

Reads the current volume of the default audio output. The returned percentage is independent of the mute state.

**Returns:** An integer from `0` to `100`.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local volume = plasma.sound.get()

print(volume)
```

### `plasma.sound.mute()`

Mutes the default audio output without changing its stored volume level. Unmuting restores playback at the previous level.

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.mute() then
    print("Sound muted")
end
```

### `plasma.sound.unmute()`

Unmutes the default audio output. The existing volume level is preserved.

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.unmute() then
    print("Sound unmuted")
end
```

### `plasma.sound.is_muted()`

Reads the mute state of the default audio output without changing it. The result is a Lua boolean.

**Returns:** `true` when muted or `false` when unmuted.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local muted = plasma.sound.is_muted()

print(muted)
```

### `plasma.sound.toggle_mute()`

Switches the default audio output to the opposite mute state. The stored volume level is not changed.

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.toggle_mute() then
    print("Mute state changed")
end
```

### `plasma.sound.increase(amount)`

Reads the current volume and increases it by the requested number of percentage points. The final value is capped at `100`.

| Parameter | Type | Description |
|---|---|---|
| `amount` | integer | Percentage points to add, from `0` to `100`. |

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.increase(10) then
    print("Volume increased")
end
```

### `plasma.sound.decrease(amount)`

Reads the current volume and decreases it by the requested number of percentage points. The final value is limited to `0`.

| Parameter | Type | Description |
|---|---|---|
| `amount` | integer | Percentage points to subtract, from `0` to `100`. |

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.sound.decrease(10) then
    print("Volume decreased")
end
```

## Notifications

The notifications module sends messages through the desktop notification service.

### `plasma.notifications.send(options)`

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
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.notifications.send({
    title = "Download complete",
    text = "Your files are ready",
    type = "info",
})
```

## Power

The power module controls system power profiles, session power actions, and display brightness.

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
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.set_profile("saving") then
    print("Power saving enabled")
end
```

### `plasma.power.suspend()`

Requests a system suspend through the available power management service. Execution normally continues after the system resumes.

**Returns:** `true` when the suspend request is accepted.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.suspend() then
    print("System resumed")
end
```

### `plasma.power.shutdown()`

Requests a complete system shutdown through the available power management service. The request may require authorization from the current user.

**Returns:** `true` when the shutdown request is accepted.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.shutdown() then
    print("Shutdown requested")
end
```

### `plasma.power.reboot()`

Requests a system restart through the available power management service. The request may require authorization from the current user.

**Returns:** `true` when the reboot request is accepted.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.reboot() then
    print("Reboot requested")
end
```

### `plasma.power.set_brightness(display, value)`

> [!WARNING]
> **EXPERIMENTAL**

Sets the brightness of one selected display to an absolute percentage. Display numbers are one-based, so `1` refers to the first display reported by Plasma.

| Parameter | Type | Description |
|---|---|---|
| `display` | string or integer | Display name, ID, label, or one-based monitor number. |
| `value` | integer | Brightness percentage from `0` to `100`. |

Examples of valid display selectors include `1`, `"monitor 1"`, `"screen 2"`, and a connector name such as `"HDMI-A-1"` when available.

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.set_brightness("HDMI-A-1", 75) then
    print("Brightness set to 75%")
end
```

### `plasma.power.get_brightness(display)`

> [!WARNING]
> **EXPERIMENTAL**


Reads the current brightness of one selected display as a normalized percentage. Display numbers are one-based, so `1` refers to the first display reported by Plasma.

| Parameter | Type | Description |
|---|---|---|
| `display` | string or integer | Display name, ID, label, or one-based monitor number. |

**Returns:** An integer from `0` to `100`.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
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
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local layouts = plasma.keyboard.list_layouts()

for _, layout in ipairs(layouts) do
    print(layout.index, layout.name)
end
```

### `plasma.keyboard.get_layout()`

Reads the keyboard layout currently selected in Plasma. The returned table includes its position, identifier, variant, and human-readable name.

**Returns:** A layout table.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local layout = plasma.keyboard.get_layout()

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
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.keyboard.set_layout("latam") then
    print("Keyboard layout changed")
end
```

### `plasma.keyboard.next_layout()`

Moves to the next layout in the configured order. After the last layout, Plasma returns to the first one.

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.keyboard.next_layout() then
    print("Switched to the next layout")
end
```

### `plasma.keyboard.previous_layout()`

Moves to the previous layout in the configured order. From the first layout, Plasma continues with the last one.

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.keyboard.previous_layout() then
    print("Switched to the previous layout")
end
```

## Desktop

The desktop module controls settings associated with the Plasma desktop. Wallpaper management is available under `plasma.desktop.wallpaper`.

### Wallpaper values

> [!WARNING]
> **EXPERIMENTAL**

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
| `uri` | string | Complete wallpaper URI reported by Plasma. |
| `path` | string | Wallpaper URI with the `file://` prefix removed. |

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1
local wallpaper = plasma.desktop.wallpaper.get(first_display)

print(wallpaper.display, wallpaper.plugin, wallpaper.path)
```

### `plasma.desktop.wallpaper.list()`

> [!WARNING]
> **EXPERIMENTAL**


Reads the current wallpaper configuration for every display managed by Plasma.

The returned array contains one wallpaper table per display, ordered by display number. Each entry includes the one-based display number, wallpaper plugin, complete URI, and local path when the wallpaper uses a `file://` URI.

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
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local wallpapers = plasma.desktop.wallpaper.list()

for _, wallpaper in ipairs(wallpapers) do
    print(wallpaper.display, wallpaper.path)
end
```

### `plasma.desktop.wallpaper.get(display)`

> [!WARNING]
> **EXPERIMENTAL**

Reads the wallpaper currently assigned to one display. If no display is provided, the first display is used.

| Parameter | Type | Required | Default | Description |
|---|---|:---:|---|---|
| `display` | integer | No | `1` | One-based display number. |

**Returns:** A wallpaper table.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1
local wallpaper = plasma.desktop.wallpaper.get(first_display)

print(wallpaper.path)
```

### `plasma.desktop.wallpaper.set(path, options)`

> [!WARNING]
> **EXPERIMENTAL**

Sets an image as wallpaper on every display by default. A display number or options table can limit the change to one display.

| Parameter | Type | Required | Description |
|---|---|:---:|---|
| `path` | string | Yes | Local image path or `file://` URI. |
| `options` | table or integer | No | Wallpaper options or a display number shorthand. |

Available options:

| Option | Type | Default | Description |
|---|---|---|---|
| `display` | integer | All displays | One-based display number. |
| `plugin` | string | `"org.kde.image"` | Plasma wallpaper plugin. This is mainly useful when restoring a previously read wallpaper. |

Passing a display number directly is equivalent to passing `{ display = number }`:

```lua
plasma.desktop.wallpaper.set("/path/to/wallpaper.png", 2)
```

**Returns:** `true` on success.

#### Quick example

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1

if plasma.desktop.wallpaper.set("/home/user/Pictures/wallpaper.png", first_display) then
    print("Wallpaper changed")
end
```

## General examples

These examples combine multiple modules into small desktop automations.

### Apply a work setup

Prepare the desktop for a work session with one script.

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1

plasma.sound.set(35)
plasma.power.set_profile("normal")
plasma.power.set_brightness(first_display, 70)
plasma.keyboard.set_layout("us")
plasma.desktop.wallpaper.set(home .. "/Pictures/workspace.png")
plasma.notifications.send({
    title = "Work setup",
    text = "Your desktop is ready",
    type = "success",
})
```

### Respond to a low battery event

This script can be called by an external battery monitor when the charge becomes low.

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local first_display = 1

plasma.power.set_profile("saving")
plasma.power.set_brightness(first_display, 35)
plasma.notifications.send({
    title = "Low battery",
    text = "Power saving settings have been applied",
    type = "warning",
})
```

### Adjust the desktop by time of day

Use a lighter setup during the day and a quieter one at night.

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")
local hour = tonumber(os.date("%H"))

if hour >= 7 and hour < 19 then
    plasma.desktop.wallpaper.set(home .. "/Pictures/day.png")
    plasma.power.set_profile("normal")
    plasma.sound.set(40)
else
    plasma.desktop.wallpaper.set(home .. "/Pictures/night.png")
    plasma.power.set_profile("saving")
    plasma.sound.set(20)
end
```

### Show the active keyboard layout

Move to the next configured layout and display its name.

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.keyboard.next_layout()
local layout = plasma.keyboard.get_layout()

plasma.notifications.send({
    title = "Keyboard layout",
    text = layout.name,
})
```
