# Changelog

## [0.2.2] - Unreleased

### Changed

- Renamed the notification API from `plasma.notifications` to `plasma.notification` for consistency with the other module names.

### Fixed

- Wallpaper changes targeting a connector now use Plasma's own screen mapping instead of KScreen enumeration order, preventing the wallpaper from changing on the wrong display in multi-monitor setups.

## [0.2.1] - 2026-08-20

### Added

- Real-system test mode through `LUNAR_TEST_ON_SYSTEM=1` for checking available backends and desktop integration.

### Changed

- Test failures now end with a component and subtest summary including the reported errors.
- Real-system Bluetooth tests now skip systems without an adapter and time out stalled BlueZ queries.
- Real-system test timeouts are shorter for unavailable services and temporary notifications.
- Wallpaper changes now fall back between available D-Bus clients and preserve backend errors in test output.

### Fixed

- Wallpaper inspection now accepts Plasma's default state when no explicit image URI is configured.
- Examples now show concise warnings instead of stack traces when a feature is unavailable.
- Display inspection now works with the default `mawk` implementation used by Debian-based distributions.
- Bluetooth system tests now detect virtual machines without an adapter before querying BlueZ.

## [0.2.0] - 2026-08-20

### Added

- Wi-Fi state inspection, active network reporting, and radio controls through NetworkManager.
- Bluetooth adapter inspection and controls, plus known and connected device reporting through BlueZ.
- Battery, charging, power-source, warning-level, and remaining-time inspection through UPower.
- Reading of the active power profile.
- Display listing, lookup, primary display detection, and available mode inspection through KScreen.
- Unit test suites and deterministic fixtures for Wi-Fi, Bluetooth, battery, and display functionality.
- Executable examples for connection state, battery and power status, and connected displays.

### Changed

- Flattened wallpaper management into `plasma.desktop.list_wallpapers()`, `get_wallpaper()`, and `set_wallpaper()`.
- Examples now load Lunar Plasma from the project directory so they can run from the project root or from inside `examples` without installation.
- Project documentation, dependencies, feature summaries, and roadmap now cover the expanded APIs.
- The installer now offers quick and custom modes for selecting `DOCUMENTATION.md`, tests, and examples.
- Release archives now include `DOCUMENTATION.md` alongside the runtime files (and `LICENSE.md`, of course!).

## [0.1.0] - 2026-08-19

### Added

- A single Lua entry point exposing the current Lunar Plasma version.
- Sound controls for volume, mute state, and relative volume adjustments.
- Desktop notifications with configurable title, text, icon, sound, timeout, and type.
- Power profile selection, system suspend, shutdown, and reboot actions.
- Display brightness reading and adjustment for selected monitors.
- Keyboard layout listing, inspection, selection, and cycling.
- Wallpaper inspection and replacement across all displays or a selected display.
- Bash backends using D-Bus and compatible system tools where available.
- Executable examples for the available modules.
- Individual module tests and a complete test runner.
- User installation and uninstallation scripts with confirmation and verification.
- Project documentation, roadmap, version metadata, and release information.
