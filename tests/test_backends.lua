#!/usr/bin/env lua

-- Production backend integration tests
-- Execute shipped Bash backends with isolated command doubles and verify their observable contracts.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_backends%.lua$") or "."
package.path = root .. "/tests/?.lua;" .. package.path
local utils = require("test_utils")

-- Create an isolated PATH containing command doubles and required core utilities.
local function mock_environment(commands)
    local directory = utils.make_temp_dir()
    local binary = directory .. "/bin"
    local log = directory .. "/commands.log"
    assert(os.execute("/usr/bin/mkdir -p " .. utils.shell_quote(binary)))
    utils.write_file(log, "")

    local core = {
        bash = "/usr/bin/bash",
        awk = "/usr/bin/awk",
        sed = "/usr/bin/sed",
        grep = "/usr/bin/grep",
        basename = "/usr/bin/basename",
        sleep = "/usr/bin/sleep",
    }
    for name, target in pairs(core) do
        local command = "/usr/bin/ln -s " ..
            utils.shell_quote(target) .. " " ..
            utils.shell_quote(binary .. "/" .. name)
        assert(os.execute(command))
    end
    for _, name in ipairs(commands) do
        local mock = root .. "/tests/fixtures/mock-command.sh"
        if mock:sub(1, 1) ~= "/" then
            mock = assert(os.getenv("PWD")) .. "/" .. mock
        end
        local command = "/usr/bin/ln -s " ..
            utils.shell_quote(mock) .. " " ..
            utils.shell_quote(binary .. "/" .. name)
        assert(os.execute(command))
    end
    return directory, { PATH = binary, LUNAR_MOCK_LOG = log }, log
end

-- Execute one shipped backend action inside a mock environment.
local function backend(name, arguments, commands, extra_environment)
    local directory, environment, log = mock_environment(commands)
    for key, value in pairs(extra_environment or {}) do
        environment[key] = value
    end
    local command = utils.shell_quote(root .. "/scripts/" .. name .. ".sh")
    for _, argument in ipairs(arguments) do
        command = command .. " " .. utils.shell_quote(argument)
    end
    local result = utils.run_command(command, environment)
    result.log = utils.read_file(log)
    utils.remove_temp_dir(directory)
    return result
end

-- Assert a successful backend response.
local function assert_backend(result)
    assert(result.ok, string.format("backend failed (%s): %s", tostring(result.code), result.stderr))
    return result
end

-- Return production backend integration cases.
local function cases()
    return {
        {
            name = "sound backend parses state and sends exact controls",
            run = function()
                local volume = assert_backend(backend("sound", { "get" }, { "pactl" }))
                utils.assert_equal(volume.stdout, "40\n")

                local set = assert_backend(backend("sound", { "set", "75" }, { "pactl" }))
                utils.assert_contains(set.log, "pactl\tset-sink-volume\t@DEFAULT_SINK@\t75%")

                local mute = assert_backend(backend("sound", { "toggle-mute" }, { "pactl" }))
                utils.assert_contains(mute.log, "pactl\tset-sink-mute\t@DEFAULT_SINK@\ttoggle")
            end,
        },
        {
            name = "sound backend rejects invalid values and mute output",
            run = function()
                local invalid = backend("sound", { "set", "101" }, { "pactl" })
                assert(not invalid.ok)
                utils.assert_equal(invalid.code, 2)

                local mute = backend(
                    "sound",
                    { "is-muted" },
                    { "pactl" },
                    { LUNAR_MOCK_SCENARIO = "invalid-mute" }
                )
                assert(not mute.ok)
                utils.assert_contains(mute.stderr, "could not read mute state")
            end,
        },
        {
            name = "notification backend maps defaults types sound and timeout",
            run = function()
                local result = assert_backend(backend(
                    "notifications",
                    { "send", "Title", "Text", "", "message", "500", "warning" },
                    { "notify-send" }
                ))
                utils.assert_contains(result.log, "--urgency=critical")
                utils.assert_contains(result.log, "--icon=dialog-warning")
                utils.assert_contains(result.log, "--expire-time=500")
                utils.assert_contains(result.log, "string:sound-name:message")
            end,
        },
        {
            name = "notification backend preserves hostile arguments",
            run = function()
                local title = "Lunar's $(false); | ☾"
                local result = assert_backend(backend(
                    "notifications",
                    { "send", title, "Text\nline", "icon", "/tmp/a b.ogg", "-1", "success" },
                    { "notify-send" }
                ))
                utils.assert_contains(result.log, title)
                utils.assert_contains(result.log, "string:sound-file:/tmp/a b.ogg")
                assert(not result.log:find("expire-time", 1, true))
            end,
        },
        {
            name = "wifi backend reports connected disabled and disconnected states",
            run = function()
                local connected = assert_backend(backend(
                    "wifi",
                    { "get-status" },
                    { "nmcli" }
                ))
                utils.assert_equal(connected.stdout, "true\ttrue\tLunar Network\n")

                local disabled = assert_backend(backend(
                    "wifi",
                    { "get-status" },
                    { "nmcli" },
                    { LUNAR_MOCK_SCENARIO = "wifi-disabled" }
                ))
                utils.assert_equal(disabled.stdout, "false\tfalse\t\n")

                local disconnected = assert_backend(backend(
                    "wifi",
                    { "get-status" },
                    { "nmcli" },
                    { LUNAR_MOCK_SCENARIO = "wifi-disconnected" }
                ))
                utils.assert_equal(disconnected.stdout, "true\tfalse\t\n")
            end,
        },
        {
            name = "wifi backend sends exact radio controls",
            run = function()
                for action, state in pairs({ enable = "on", disable = "off" }) do
                    local result = assert_backend(backend("wifi", { action }, { "nmcli" }))
                    utils.assert_contains(result.log, "nmcli\tradio\twifi\t" .. state)
                end
                local toggle = assert_backend(backend("wifi", { "toggle" }, { "nmcli" }))
                utils.assert_contains(toggle.log, "nmcli\tradio\twifi\toff")
            end,
        },
        {
            name = "keyboard backend parses Plasma layouts and controls selection",
            run = function()
                local layouts = assert_backend(backend(
                    "keyboard",
                    { "list-layouts" },
                    { "qdbus-qt6", "setxkbmap" }
                ))
                utils.assert_contains(layouts.stdout, "1\tlatam\t\tSpanish")

                local set = assert_backend(backend(
                    "keyboard",
                    { "set-layout", "us", "intl" },
                    { "qdbus-qt6", "setxkbmap" }
                ))
                utils.assert_contains(set.log, "org.kde.KeyboardLayouts.setLayout\t1")
            end,
        },
        {
            name = "keyboard backend falls back to XKB configuration",
            run = function()
                local result = assert_backend(backend(
                    "keyboard",
                    { "list-layouts" },
                    { "setxkbmap" },
                    { HOME = "/nonexistent", XDG_CONFIG_HOME = "/nonexistent" }
                ))
                utils.assert_contains(result.stdout, "1\tlatam")
                utils.assert_contains(result.stdout, "2\tus\tintl")
            end,
        },
        {
            name = "qdbus discovery supports every conventional executable name",
            run = function()
                for _, executable in ipairs({ "qdbus-qt6", "qdbus6", "qdbus-qt5", "qdbus" }) do
                    local result = assert_backend(backend(
                        "desktop",
                        { "screen-for-connector", "HDMI-A-1" },
                        { executable }
                    ))
                    utils.assert_equal(result.stdout, "0\n")
                    utils.assert_contains(result.log, executable)
                end
            end,
        },
        {
            name = "power backend reads profile and complete battery state",
            run = function()
                local profile = assert_backend(backend(
                    "power",
                    { "get-profile" },
                    { "busctl", "powerprofilesctl", "qdbus-qt6" }
                ))
                utils.assert_equal(profile.stdout, "balanced\n")

                local battery = assert_backend(backend(
                    "power",
                    { "get-battery-status" },
                    { "busctl" }
                ))
                utils.assert_equal(
                    battery.stdout,
                    "true\t73.4\tdischarging\tbattery\t7200\tlow\n"
                )
            end,
        },
        {
            name = "power backend propagates each failed battery property",
            run = function()
                for _, property in ipairs({
                    "IsPresent", "OnBattery", "State", "WarningLevel",
                    "Percentage", "TimeToEmpty", "TimeToFull",
                }) do
                    local result = backend(
                        "power", { "get-battery-status" }, { "busctl" },
                        {
                            LUNAR_MOCK_FAILED_PROPERTY = property,
                            LUNAR_MOCK_SCENARIO = property == "TimeToFull" and
                                "battery-charging" or "default",
                        }
                    )
                    assert(not result.ok, property .. " failure was ignored")
                    utils.assert_equal(result.stdout, "")
                    utils.assert_contains(result.stderr, "UPower query failed: " .. property)
                end
            end,
        },
        {
            name = "power backend rejects invalid battery booleans",
            run = function()
                for _, property in ipairs({ "IsPresent", "OnBattery" }) do
                    local result = backend(
                        "power", { "get-battery-status" }, { "busctl" },
                        { LUNAR_MOCK_INVALID_PROPERTY = property }
                    )
                    assert(not result.ok)
                    utils.assert_equal(result.stdout, "")
                    utils.assert_contains(result.stderr, "invalid battery boolean")
                end
            end,
        },
        {
            name = "power backend accepts explicit AC and charging states",
            run = function()
                local ac = assert_backend(backend(
                    "power", { "get-battery-status" }, { "busctl" },
                    { LUNAR_MOCK_SCENARIO = "battery-ac" }
                ))
                utils.assert_contains(ac.stdout, "\tac\t")
                local charging = assert_backend(backend(
                    "power", { "get-battery-status" }, { "busctl" },
                    { LUNAR_MOCK_SCENARIO = "battery-charging" }
                ))
                utils.assert_contains(charging.stdout, "\tcharging\tbattery\t3600\t")
            end,
        },
        {
            name = "power backend falls back from busctl to powerprofilesctl",
            run = function()
                local result = assert_backend(backend(
                    "power",
                    { "get-profile" },
                    { "busctl", "powerprofilesctl" },
                    { LUNAR_MOCK_SCENARIO = "busctl-fails" }
                ))
                utils.assert_equal(result.stdout, "balanced\n")
                utils.assert_contains(result.log, "powerprofilesctl\tget")
            end,
        },
        {
            name = "power backend falls back to Plasma and systemctl",
            run = function()
                local profile = assert_backend(backend(
                    "power",
                    { "get-profile" },
                    { "qdbus" }
                ))
                utils.assert_equal(profile.stdout, "balanced\n")

                local reboot = assert_backend(backend(
                    "power",
                    { "reboot" },
                    { "systemctl" }
                ))
                utils.assert_contains(reboot.log, "systemctl\treboot")
            end,
        },
        {
            name = "power backend resolves display and rounds brightness",
            run = function()
                local get = assert_backend(backend(
                    "power",
                    { "get-brightness", "Internal Display" },
                    { "qdbus-qt6", "kscreen-doctor" }
                ))
                utils.assert_equal(get.stdout, "40\n")

                local set = assert_backend(backend(
                    "power",
                    { "set-brightness", "display1", "75" },
                    { "qdbus-qt6", "kscreen-doctor" }
                ))
                utils.assert_contains(
                    set.log,
                    "org.kde.ScreenBrightness.Display.SetBrightness\t750\t0"
                )
            end,
        },
        {
            name = "brightness selectors preserve identity across display order and subsets",
            run = function()
                for _, scenario in ipairs({ "brightness-reordered", "brightness-subset" }) do
                    for _, selector in ipairs({
                        "display1", "/org/kde/ScreenBrightness/display1", "External Display",
                        "1", "monitor 1", "screen 1",
                    }) do
                        local result = assert_backend(backend(
                            "power", { "set-brightness", selector, "75" },
                            { "qdbus-qt6", "kscreen-doctor" },
                            { LUNAR_MOCK_SCENARIO = scenario }
                        ))
                        utils.assert_contains(result.log,
                            "/org/kde/ScreenBrightness/display1\t" ..
                            "org.kde.ScreenBrightness.Display.SetBrightness\t750\t0")
                        assert(not result.log:find("kscreen-doctor", 1, true))
                    end
                end
            end,
        },
        {
            name = "brightness never maps connectors or UUIDs by display position",
            run = function()
                for _, scenario in ipairs({ "default", "brightness-reordered", "brightness-subset" }) do
                    for _, selector in ipairs({ "eDP-1", "HDMI-A-1", "panel-uuid", "hdmi-uuid" }) do
                        for _, action in ipairs({ "get-brightness", "set-brightness" }) do
                            local result = backend(
                                "power", { action, selector, "75" },
                                { "qdbus-qt6", "kscreen-doctor" },
                                { LUNAR_MOCK_SCENARIO = scenario }
                            )
                            assert(not result.ok, "unmapped selector was accepted: " .. selector)
                            utils.assert_contains(result.stderr, "display not found")
                            assert(not result.log:find("Display.SetBrightness", 1, true))
                            assert(not result.log:find("Display.Brightness", 1, true))
                        end
                    end
                end
            end,
        },
        {
            name = "brightness rejects ambiguous labels without changing a display",
            run = function()
                local result = backend(
                    "power", { "set-brightness", "Internal Display", "75" },
                    { "qdbus-qt6" },
                    { LUNAR_MOCK_SCENARIO = "brightness-duplicate-label" }
                )
                assert(not result.ok)
                utils.assert_contains(result.stderr, "ambiguous display label")
                assert(not result.log:find("Display.SetBrightness", 1, true))
            end,
        },
        {
            name = "brightness propagates discovery failures and empty lists",
            run = function()
                for scenario, message in pairs({
                    ["brightness-list-fails"] = "brightness display query failed",
                    ["brightness-label-fails"] = "brightness label query failed",
                    ["brightness-empty"] = "no brightness displays",
                }) do
                    local result = backend(
                        "power", { "set-brightness", "External Display", "75" },
                        { "qdbus-qt6" },
                        { LUNAR_MOCK_SCENARIO = scenario }
                    )
                    assert(not result.ok)
                    utils.assert_contains(result.stderr, message)
                    assert(not result.log:find("Display.SetBrightness", 1, true))
                end
            end,
        },
        {
            name = "display backend parses displays with mawk-compatible output",
            run = function()
                local result = assert_backend(backend(
                    "display",
                    { "list-displays" },
                    { "kscreen-doctor" }
                ))
                utils.assert_contains(result.stdout, "eDP-1\tpanel-uuid\ttrue\ttrue\ttrue")
                utils.assert_contains(result.stdout, "-10\t20\t1920\t1080\t1.25")
            end,
        },
        {
            name = "display backend lists modes",
            run = function()
                local modes = assert_backend(backend(
                    "display",
                    { "list-display-modes", "eDP-1" },
                    { "kscreen-doctor" }
                ))
                utils.assert_contains(modes.stdout, "59.94\tfalse\ttrue")
            end,
        },
        {
            name = "desktop backend maps wallpaper connectors",
            run = function()
                local screen = assert_backend(backend(
                    "desktop",
                    { "screen-for-connector", "HDMI-A-1" },
                    { "qdbus-qt6" }
                ))
                utils.assert_equal(screen.stdout, "0\n")
            end,
        },
        {
            name = "desktop backend reads and writes wallpaper with D-Bus fallback",
            run = function()
                local read = assert_backend(backend(
                    "desktop",
                    { "get-wallpaper", "1" },
                    { "qdbus-qt6" }
                ))
                utils.assert_contains(
                    read.stdout,
                    "1\torg.kde.image\tfile:///tmp/wallpaper.png"
                )

                local write = assert_backend(backend(
                    "desktop",
                    { "set-wallpaper", "file:///tmp/Lunar's image.png", "1", "org.kde.image" },
                    { "busctl", "gdbus" },
                    { LUNAR_MOCK_SCENARIO = "busctl-fails" }
                ))
                utils.assert_contains(write.log, "gdbus\tcall")
            end,
        },
        {
            name = "desktop backend prefers busctl for wallpaper changes",
            run = function()
                local result = assert_backend(backend(
                    "desktop",
                    { "set-wallpaper", "file:///tmp/image.png", "1", "org.kde.image" },
                    { "busctl", "gdbus" }
                ))
                utils.assert_contains(result.log, "busctl\t--user\tcall")
                assert(not result.log:find("gdbus", 1, true))
            end,
        },
        {
            name = "desktop backend reports every failed wallpaper fallback",
            run = function()
                local result = backend(
                    "desktop",
                    { "set-wallpaper", "file:///tmp/image.png", "1", "org.kde.image" },
                    { "busctl", "gdbus" },
                    { LUNAR_MOCK_SCENARIO = "dbus-fails" }
                )
                assert(not result.ok)
                utils.assert_contains(result.stderr, "busctl: busctl failure")
                utils.assert_contains(result.stderr, "gdbus: gdbus failure")
            end,
        },
        {
            name = "Bluetooth backend parses adapter devices and controls",
            run = function()
                local sysfs = utils.make_temp_dir()
                assert(os.execute("/usr/bin/mkdir " .. utils.shell_quote(sysfs .. "/hci0")))
                local environment = { LUNAR_PLASMA_BLUETOOTH_SYSFS = sysfs }

                local status = assert_backend(backend(
                    "bluetooth",
                    { "get-status" },
                    { "bluetoothctl" },
                    environment
                ))
                utils.assert_contains(
                    status.stdout,
                    "true\tfalse\tfalse\tAA:BB:CC:DD:EE:FF\tLunar Adapter"
                )

                local devices = assert_backend(backend(
                    "bluetooth",
                    { "list-connected-devices" },
                    { "bluetoothctl" },
                    environment
                ))
                utils.assert_contains(devices.stdout, "Lunar Headphones")
                assert(not devices.stdout:find("Lunar Controller", 1, true))

                local toggle = assert_backend(backend(
                    "bluetooth",
                    { "toggle" },
                    { "bluetoothctl" },
                    environment
                ))
                utils.assert_contains(toggle.log, "bluetoothctl\t--timeout\t2\tpower\toff")
                utils.remove_temp_dir(sysfs)
            end,
        },
        {
            name = "Bluetooth device lists distinguish query failure from no devices",
            run = function()
                local sysfs = utils.make_temp_dir()
                assert(os.execute("/usr/bin/mkdir " .. utils.shell_quote(sysfs .. "/hci0")))
                for _, action in ipairs({ "list-devices", "list-connected-devices" }) do
                    local failed = backend(
                        "bluetooth", { action }, { "bluetoothctl" },
                        {
                            LUNAR_PLASMA_BLUETOOTH_SYSFS = sysfs,
                            LUNAR_MOCK_SCENARIO = "bluetooth-devices-fails",
                        }
                    )
                    assert(not failed.ok)
                    utils.assert_equal(failed.stdout, "")
                    utils.assert_contains(failed.stderr, "Bluetooth device query failed")

                    local empty = assert_backend(backend(
                        "bluetooth", { action }, { "bluetoothctl" },
                        {
                            LUNAR_PLASMA_BLUETOOTH_SYSFS = sysfs,
                            LUNAR_MOCK_SCENARIO = "bluetooth-devices-empty",
                        }
                    ))
                    utils.assert_equal(empty.stdout, "")
                end
                utils.remove_temp_dir(sysfs)
            end,
        },
        {
            name = "backends reject unknown actions and missing dependencies",
            run = function()
                local names = {
                    "sound",
                    "notifications",
                    "wifi",
                    "keyboard",
                    "power",
                    "desktop",
                    "display",
                }
                for _, name in ipairs(names) do
                    local result = backend(name, { "unknown" }, {})
                    assert(not result.ok, name .. " accepted an unknown action")
                end
            end,
        },
    }
end

-- Run the production backend integration suite.
local function run()
    return utils.run_suite("backends", cases())
end
if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
