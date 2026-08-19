<img src="resources/icon.svg" width="64" align="left" alt="Lunar Plasma">

# Lunar Plasma
Lua scripting interface for the KDE Plasma desktop

<br clear="left"/>

![License: LGPL v3](https://img.shields.io/badge/license-LGPL--3.0-blue)
![Status](https://img.shields.io/badge/status-early--development-red)

## Overview

Lunar Plasma lets you control your [KDE Plasma](https://kde.org/plasma-desktop/) desktop through a [Lua](https://www.lua.org/about.html) interface. Its goal is to make it easy to write scripts that inspect and modify your desktop on demand. Inspired by the scriptable, tinkerer-friendly spirit of projects such as [AwesomeWM](https://awesomewm.org/) and [Hyprland](https://hypr.land/), Lunar Plasma brings that same approach to KDE Plasma.

Beyond desktop customization, Lunar Plasma also lets you interact with other system properties, such as adjusting the volume or changing screen brightness, all from the same simple Lua interface. Instead of clicking through menus every time you want to tweak your setup, or digging through Plasma's APIs to hack together a fragile, untested script, you write it once and let Lunar Plasma handle the rest.

> [!WARNING]
> **Early development software.** Lunar Plasma hasn't been battle-tested yet. Expect breaking changes between versions.

## Quick examples

### Set default output volume to 50%.

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/share/opt/lunar-plasma/lunar-plasma.lua")

plasma.sound.set(50)
```

### Send a desktop notification.

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/share/opt/lunar-plasma/lunar-plasma.lua")

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
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/share/opt/lunar-plasma/lunar-plasma.lua")

plasma.power.set_profile("normal")
```

### Select a configured keyboard layout.

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/share/opt/lunar-plasma/lunar-plasma.lua")

plasma.keyboard.set_layout("latam")
```

### Set an image as wallpaper on every display.

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/share/opt/lunar-plasma/lunar-plasma.lua")

plasma.desktop.wallpaper.set("/path/to/wallpaper.png")
```

**You can run similar examples from the `examples` directory.**

## Features

- Control the volume and mute state of the default audio output.
- Send desktop notifications with custom text, icons, sounds, urgency, and timeout.
- Select power profiles and request suspend, shutdown, or reboot actions.
- Read and adjust display brightness.
- List, inspect, and switch configured keyboard layouts.
- Read and change wallpapers across all displays or on a specific display.
- Use a single Lua entry point backed by D-Bus and system tools.
- Run module-specific tests and practical example scripts.

## Current Goals

You can check our current goals in the [ROADMAP](ROADMAP.md).

The main current goals are:

- Document integration with other languages such as C, C++, Python, and Rust.
- Add event detection for application launches, battery levels, network connectivity, and similar system changes.
- Expand the available API.

## Dependencies

A standard KDE Plasma desktop should already include most of the tools Lunar Plasma uses. Lua and Bash run the library, while tools such as `pactl`, `notify-send`, `qdbus`, `kscreen-doctor`, and `setxkbmap` provide specific features or fallbacks. Lunar Plasma detects the available `qdbus` command automatically.

If a command is missing, these packages provide the usual dependencies for each distribution family:

### Arch Linux / Manjaro / EndeavourOS

```bash
sudo pacman -S --needed lua bash libpulse libnotify qt6-tools libkscreen xorg-setxkbmap power-profiles-daemon
```

### Fedora / Nobara / Ultramarine

```bash
sudo dnf install lua bash pulseaudio-utils libnotify qt6-qttools libkscreen xorg-x11-xkb-utils power-profiles-daemon
```

### Ubuntu / Kubuntu / KDE neon

```bash
sudo apt install lua5.4 bash pulseaudio-utils libnotify-bin qdbus-qt6 libkscreen-bin x11-xkb-utils power-profiles-daemon
```

### NixOS

Add the tools to your NixOS configuration. Bash and the D-Bus services normally come with the system and Plasma environment.

```nix
environment.systemPackages = with pkgs; [
  lua54
  pulseaudio
  libnotify
  kdePackages.qttools
  kdePackages.libkscreen
  xorg.setxkbmap
];

services.power-profiles-daemon.enable = true;
```


## Installation

Run the installer from the project directory:

```bash
chmod +x install.sh uninstall.sh
./install.sh
```

Lunar Plasma will be installed in `~/.local/share/opt/lunar-plasma`. The installer copies the Lua library, version file, backend scripts, examples, and the example wallpaper. Existing files in that directory are replaced only after confirmation.

To remove the installation:

```bash
./uninstall.sh
```

## API Reference

See the complete [Lunar Plasma documentation](DOCUMENTATION.md).

## Known limitations

- The public API may change before the first stable release.
- Wallpaper and brightness support depend on the D-Bus interfaces and plugins available in the current Plasma session.
- Display selection and keyboard fallbacks depend on optional system tools.
- Event automation, user modules, and the one-shot interpreter are not available yet.

## Contributing

This project uses a variant of [gitlab flow](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/), where development is done directly on **main** and accepted changes are merged into the **release** branch. You can create pull requests for **main** at any time with any changes, improvements, or bug fixes you would like to suggest. If the contribution makes sense, it will be merged into **main** and will eventually make its way into **release**.

There are no rules regarding commit naming. Contributions that add new features related to the roadmap are especially appreciated. 

Please run the regular test suite before submitting a change:

```bash
lua tests/test_all.lua
```

To include tests that modify the current desktop and restore it afterward:

```bash
LUNAR_PLASMA_INTEGRATION=1 lua tests/test_all.lua
```

## License

Lunar Plasma is licensed under the [GNU Lesser General Public License v3.0](LICENSE.md).
