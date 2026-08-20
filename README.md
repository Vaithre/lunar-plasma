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

## API Reference

See the complete [Lunar Plasma documentation](DOCUMENTATION.md).

## Quick examples

Once Lunar Plasma is installed, you can use it from any script or executable that loads `~/.local/opt/lunar-plasma/lunar-plasma.lua`. A more ergonomic way to load the library is planned for a future version.

#### Set default output volume to 50%

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.sound.set(50)
```

#### Send a desktop notification

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.notifications.send({
    title = "Lunar Plasma",
    text = "Notifications are working",
    icon = "dialog-information",
    sound = "message",
    timeout = 5000,
    type = "info",
})
```

#### Set the performance power profile

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.power.set_profile("performance")
```

#### Increase brightness while charging above 50%

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

if plasma.power.is_battery_charging() then
    local percentage = plasma.power.get_battery_percentage()

    if percentage > 50 then
        plasma.power.set_brightness("HDMI-A-1", 70)
        plasma.power.set_profile("performance")
    end
end
```

#### Set an image as wallpaper on every display

```lua
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

plasma.desktop.set_wallpaper("/path/to/wallpaper.png")
```

You can run similar examples from the project root or from inside the `examples` directory without installing Lunar Plasma first.

## Features

- Control the volume and mute state of the default audio output.
- Send desktop notifications with custom text, icons, sounds, urgency, and timeout.
- Read battery and power-source state, select power profiles, and request suspend, shutdown, or reboot actions.
- Read and adjust display brightness.
- Inspect connected displays, their current configuration, and available modes.
- List, inspect, and switch configured keyboard layouts.
- Read and change wallpapers across all displays or on a specific display.
- Inspect and control Wi-Fi state and read the active network.
- Inspect and control Bluetooth state and list known or connected devices.
- Use a single Lua entry point backed by D-Bus and system tools.

## Current Goals

You can check our current goals in the [ROADMAP](ROADMAP.md).

The main current goals are:

- Document integration with other languages such as C, C++, Python, and Rust.
- Add event detection for application launches, battery levels, network connectivity, and similar system changes.
- Expand the available API.

## Dependencies

A standard KDE Plasma desktop should already include most of the tools Lunar Plasma uses. Lua and Bash run the library, while tools such as `pactl`, `notify-send`, `qdbus`, `kscreen-doctor`, `setxkbmap`, `nmcli`, `bluetoothctl`, and `busctl` provide specific features or fallbacks. NetworkManager supplies Wi-Fi state, BlueZ supplies Bluetooth state, and UPower supplies battery information. Lunar Plasma detects the available `qdbus` command automatically.

> [!important]
> It's normal for the package manager to talk about "replacing packages." In this case you can test the program with the "tests" [`lua examples/test_all.lua`] and everything will probably work fine without the need to install anything! You can also install and use only what you need. **If you don't have bluetooth on your computer, you don't need to install bluez for this library to work for your use case**.

If a command is missing, these packages provide the usual dependencies for each distribution family:

### Arch Linux / Manjaro / EndeavourOS / etc

```bash
sudo pacman -S --needed lua bash libpulse libnotify qt6-tools libkscreen xorg-setxkbmap power-profiles-daemon networkmanager bluez-utils upower
```

### Fedora / Nobara / Ultramarine / etc

```bash
sudo dnf install lua bash pulseaudio-utils libnotify qt6-qttools libkscreen xorg-x11-xkb-utils power-profiles-daemon NetworkManager bluez upower
```

### Ubuntu / Linux Mint / Debian / etc

```bash
sudo apt install lua5.4 bash pulseaudio-utils libnotify-bin qdbus-qt6 libkscreen-bin x11-xkb-utils power-profiles-daemon network-manager bluez upower
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
  networkmanager
  bluez
  upower
];

services.power-profiles-daemon.enable = true;
```


## Installation

There are two ways to obtain Lunar Plasma: clone the repository for development, or download a release archive for a minimal installation.

### From Git

Clone the repository and run the installer from the project directory:

```bash
git clone https://github.com/Vaithre/lunar-plasma.git
cd lunar-plasma

chmod +x install.sh
./install.sh
```

This option includes the complete project, including the documentation, tests, examples, and development history.

Keep in mind that cloning **main** provides a preliminary version. For a more stable version, clone the **release** branch instead:

```bash
git clone --branch release https://github.com/Vaithre/lunar-plasma.git
```

The **release** branch contains the contents of the current tested release.

### From a release

Download a version from the [GitHub releases](https://github.com/Vaithre/lunar-plasma/releases) page, then extract it and run the installer.

```bash
tar -xzf "lunar-plasma-[VERSION].tar.gz"
cd "lunar-plasma-[VERSION]"

chmod +x install.sh
./install.sh
```

Release archives contain the runtime files, examples, and `DOCUMENTATION.md` required for distribution.

### Installation modes

When `install.sh` starts, choose one of the following modes:

- **Quick installation** installs the runtime only.
- **Custom installation** asks separately whether to install `DOCUMENTATION.md`, tests, and examples.

### Installation directory

Lunar Plasma will be installed in `~/.local/opt/lunar-plasma`.

To remove the installation:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## Known limitations

- The public API may change before the first stable release.
- Wallpaper and brightness support depend on the D-Bus interfaces and plugins available in the current Plasma session.
- Display inspection and keyboard fallbacks depend on optional system tools.
- Wi-Fi, Bluetooth, and battery information depend on NetworkManager, BlueZ, and UPower respectively.

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
