# Changelog

## [0.3.2] - Unreleased

### Added

- Added a shared Lua backend client and Bash process runner with a three-second default timeout and operation-specific overrides.
- Added deterministic runner tests for argument preservation, output isolation, failure details, configuration validation, and default, overridden, and enforced timeouts.
- Added `test_utils.lua` with shared assertions, isolated temporary resources, filtering, seeded ordering, skip handling, etc.
- Added deterministic integration tests that execute the production Bash backends against controlled command doubles.
- Added malformed-response, backend-failure, boundary, escaping, fallback, generated-input, mutation-sensitivity, entry-point, and example smoke tests.

### Changed

- Unified every Lua API module on the shared backend execution and error contract.
- Isolated backend standard output from diagnostic output and normalized process results across Lua 5.4 and LuaJIT through an explicit runner protocol.
- Updated mutation-sensitivity tests to reproduce the production backend-runner layout in their isolated projects.
- Updated the installer to require and verify the executable backend runner.
- Declared GNU coreutils as a runtime dependency in the wiki installation documentation.
- Reworked every Lua API suite to use unique descriptive cases and actionable expected-versus-actual failures.
- Strengthened real-system suite result handling so an explicit false result cannot be reported as successful.
- Added an explicit `--test-disruptive-system` mode with asynchronous state polling and verified restoration for reversible radio, brightness, keyboard, sound, and wallpaper changes.
- Made the Bluetooth sysfs root configurable for isolated backend testing while preserving `/sys/class/bluetooth` as the default.

### Fixed

- Fixed Plasma keyboard layout parsing so multiple returned layouts are preserved.
- Fixed power-profile discovery so a failing `busctl` query continues to the supported fallback backends.

## [0.3.1] - 2026-08-24

### Changed

- Moved shared shell quoting, boolean parsing, and tab-separated field splitting helpers to `utils.lua`.
- Restructured code comments to make the implementation easier to understand.
- Moved the complete project documentation to the GitHub wiki and removed `DOCUMENTATION.md`.
- Updated the custom installer to select tests and examples now that documentation is maintained online.

## [0.3.0] - 2026-08-21

### Added

- Added the internal `utils.lua` sublibrary for shared Plasma API helpers.

### Changed

- Renamed the notification API from `plasma.notifications` to `plasma.notification` for consistency with the other module names.
- Improved API function names to make operations more descriptive and standardized naming conventions across modules.
- Replaced the `LUNAR_TEST_ON_SYSTEM=1` environment variable with the `--test-on-system` test runner flag.

### Fixed

- Wallpaper inspection and changes targeting a connector now use Plasma's own screen mapping instead of KScreen enumeration order, preventing operations from addressing the wrong display in multi-monitor setups.
- Display brightness lookup now preserves the output UUID used to resolve monitors when connector-name matching is unavailable.

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
