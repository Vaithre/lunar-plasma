<img src="resources/icon.svg" width="64" align="left" alt="Lunar Plasma">

# Lunar Plasma
Lua scripting interface for the KDE Plasma desktop

<br clear="left"/>

![License: LGPL v3](https://img.shields.io/badge/license-LGPL--3.0-blue)
![Status](https://img.shields.io/badge/status-early--development-red)

## Overview

Lunar Plasma lets you control and automate your [KDE Plasma](https://kde.org/plasma-desktop/) desktop through a [Lua](https://www.lua.org/about.html) interface. Its goal is to make it easy to write scripts that modify your desktop in real time, either reacting to events as they happen or running on-demand whenever you need them. Inspired by the hacky, tinkerer-friendly nature of projects like [AwesomeWM](https://awesomewm.org/) and [Hyprland](https://hypr.land/) Lua configuration, Lunar Plasma brings that same scriptable spirit to KDE Plasma.

Beyond desktop customization, Lunar Plasma also lets you interact with other system properties, such as adjusting the volume or changing screen brightness, all from the same simple Lua interface. Instead of clicking through menus every time you want to tweak your setup, or digging through Plasma's APIs to hack together a fragile, untested script, you write it once and let Lunar Plasma handle the rest.

> [!WARNING]
> **Early development software.** Lunar Plasma hasn't been battle-tested yet. Expect breaking changes between versions.

## Quick examples

### Set default output volume to 50%.

```lua
local plasma = dofile("lunar-plasma.lua")

plasma.sound.set(50)
```

### Send a desktop notification.

```lua
local plasma = dofile("lunar-plasma.lua")

plasma.notifications.send({
    title = "Lunar Plasma",
    text = "Notifications are working",
    icon = "dialog-information",
    sound = "message",
    timeout = 5000,
    type = "info",
})
```

### Set the normal power profile.

```lua
local plasma = dofile("lunar-plasma.lua")

plasma.power.set_profile("normal")
```

### Select a configured keyboard layout.

```lua
local plasma = dofile("lunar-plasma.lua")

plasma.keyboard.set_layout("latam")
```

### Set an image as wallpaper on every display.

```lua
local plasma = dofile("lunar-plasma.lua")

plasma.desktop.wallpaper.set("/path/to/wallpaper.png")
```

**You can run similar examples from the `examples` directory.**

## Features (PLACEHOLDER)

- Change themes and color schemes
- Set and rotate wallpapers
- React to desktop events in real time
- Run one-shot scripts from the terminal

## Current Goals

You can check our current goals in the [ROADMAP](ROADMAP.md).

## Installation

> PLACEHOLDER

```bash
# TODO
```

## Usage

### One-shot commands

```lua
-- TODO: example
```

### Event-driven scripts

```lua
-- TODO: example
```

## API Reference

See the complete [Lunar Plasma documentation](DOCUMENTATION.md).

## Contributing

PLACEHOLDER FOR GITLAB FLOW



## License

Lunar Plasma is licensed under the [GNU Lesser General Public License v3.0](LICENCE.md).
