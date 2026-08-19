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
> **Early development software.** Lunar Plasma is built with care to protect your Plasma preferences and other sensitive files, but it hasn't been battle-tested yet. Back up your configuration before using it, and expect breaking changes between versions.

## Examples

```lua
local plasma = dofile("lunar-plasma.lua")

plasma.volume.set(50)
```

Run a similar example from its directory:

```bash
cd examples
lua set-volume.lua
```

## Features (PLACEHOLDER)

- Change themes and color schemes
- Set and rotate wallpapers
- React to desktop events in real time
- Run one-shot scripts from the terminal

## Current Goals (PLACEHOLDER)

> This roadmap is temporary and will change as the project takes shape.

| Status | Area | Goal |
|:---:|---|---|
| <img src="./resources/status-completed.svg" width="22" height="22" alt="Completed"> | API | Define a Lua API entry point |
| <img src="./resources/status-completed.svg" width="22" height="22" alt="Completed"> | Volume | Set the default Plasma volume from Lua |
| <img src="./resources/status-completed.svg" width="22" height="22" alt="Completed"> | Backend | Use Bash as the first backend layer |
| <img src="./resources/status-completed.svg" width="22" height="22" alt="Completed"> | Examples | Provide a runnable volume example |
| <img src="./resources/status-development.svg" width="22" height="22" alt="In development"> | Volume | Expand the `volume` API |
| <img src="./resources/status-development.svg" width="22" height="22" alt="In development"> | Backends | Improve backend selection and D-Bus support |
| <img src="./resources/status-development.svg" width="22" height="22" alt="In development"> | Documentation | Document the public API and installation process |
| <img src="./resources/status-planned.svg" width="22" height="22" alt="Planned"> | Plasma | Add wallpaper and display controls |
| <img src="./resources/status-planned.svg" width="22" height="22" alt="Planned"> | Runner | Provide a standalone one-shot runner |
| <img src="./resources/status-planned.svg" width="22" height="22" alt="Planned"> | Scheduling | Add optional scheduling helpers |
| <img src="./resources/status-planned.svg" width="22" height="22" alt="Planned"> | Packaging | Package the library for use from other projects |

### Status legend

- <img src="./resources/status-completed.svg" width="16" height="16" alt="Completed"> Completed
- <img src="./resources/status-development.svg" width="16" height="16" alt="In development"> In development
- <img src="./resources/status-planned.svg" width="16" height="16" alt="Planned"> Planned

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

> CREATE DOCS

## Contributing

PLACEHOLDER FOR GITLAB FLOW



## License

Lunar Plasma is licensed under the [GNU Lesser General Public License v3.0](LICENCE.md).
