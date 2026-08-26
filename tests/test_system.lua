#!/usr/bin/env lua

-- Real-system integration tests
-- Verify available desktop services while restoring every reversible state change.

local system = {}
local utils = require("test_utils")
local skip = utils.skip

-- Create a real-system component suite with the shared runner.
local function make_suite(name, tests)
    return { run = function() return utils.run_suite(name, tests) end }
end

function system.get_suites(root, disruptive_mode)
    local plasma = dofile(root .. "/lunar-plasma.lua")

    local sound_tests = {
        {
            name = "read state",
            run = function()
                local volume = assert(plasma.sound.get_volume())
                local muted, muted_err = plasma.sound.is_muted()
                assert(muted ~= nil, muted_err)
                assert(type(volume) == "number" and volume >= 0 and volume <= 100)
                assert(type(muted) == "boolean")
            end,
        },
        {
            name = "controls and restore",
            run = function()
                local original_volume = assert(plasma.sound.get_volume())
                local original_muted, muted_err = plasma.sound.is_muted()
                assert(original_muted ~= nil, muted_err)

                local operation_ok, operation_err = pcall(function()
                    assert(plasma.sound.set_volume(original_volume))
                    assert(plasma.sound.increase_volume(0))
                    assert(plasma.sound.decrease_volume(0))
                    assert(plasma.sound.toggle_mute())
                    assert(plasma.sound.toggle_mute())
                    assert(plasma.sound.mute())
                    assert(plasma.sound.unmute())
                end)

                local volume_ok, volume_err = plasma.sound.set_volume(original_volume)
                assert(volume_ok, volume_err)

                local mute_ok, mute_err
                if original_muted then
                    mute_ok, mute_err = plasma.sound.mute()
                else
                    mute_ok, mute_err = plasma.sound.unmute()
                end
                assert(mute_ok, mute_err)
                assert(operation_ok, operation_err)
                utils.eventually(function()
                    return plasma.sound.get_volume() == original_volume and
                        plasma.sound.is_muted() == original_muted
                end, "sound state was not restored")
            end,
        },
    }

    local notification_tests = {
        {
            name = "send notification",
            run = function()
                assert(plasma.notification.send({
                    title = "Lunar Plasma system test",
                    text = "The notification backend is working",
                    icon = "dialog-information",
                    timeout = 1000,
                    type = "info",
                }))
            end,
        },
    }

    local power_tests = {
        {
            name = "power profile",
            run = function()
                local profile = assert(plasma.power.get_profile())
                assert(plasma.power.set_profile(profile))
                utils.eventually(function()
                    return plasma.power.get_profile() == profile
                end, "power profile did not settle")
            end,
        },
        {
            name = "battery and power source",
            run = function()
                local status = assert(plasma.power.get_battery_status())
                assert(plasma.power.is_battery_present() == status.present)
                assert(plasma.power.get_power_source() == status.source)
                assert(plasma.power.is_on_battery() == (status.source == "battery"))
                assert(plasma.power.is_ac_connected() == (status.source == "ac"))
                assert(type(plasma.power.is_battery_charging()) == "boolean")

                if status.present then
                    assert(plasma.power.get_battery_percentage() == status.percentage)
                    assert(plasma.power.get_battery_state() == status.state)
                    assert(plasma.power.get_battery_warning_level() == status.warning_level)

                    local remaining, remaining_err = plasma.power.get_battery_time_remaining()
                    if status.time_remaining == nil then
                        assert(not remaining and remaining_err)
                    else
                        assert(remaining == status.time_remaining)
                    end
                else
                    local percentage, percentage_err = plasma.power.get_battery_percentage()
                    local state, state_err = plasma.power.get_battery_state()
                    local warning, warning_err = plasma.power.get_battery_warning_level()
                    local remaining, remaining_err = plasma.power.get_battery_time_remaining()
                    assert(not percentage and percentage_err)
                    assert(not state and state_err)
                    assert(not warning and warning_err)
                    assert(not remaining and remaining_err)
                end
            end,
        },
        {
            name = "display brightness",
            run = function()
                local brightness = assert(plasma.power.get_brightness(1))
                local target = disruptive_mode and (brightness == 100 and 99 or brightness + 1) or brightness
                local operation_ok, operation_err = pcall(function()
                    assert(plasma.power.set_brightness(1, target))
                    utils.eventually(function()
                        return plasma.power.get_brightness(1) == target
                    end, "brightness did not change")
                end)
                local restored, restore_err = plasma.power.set_brightness(1, brightness)
                assert(restored, restore_err)
                utils.eventually(function()
                    return plasma.power.get_brightness(1) == brightness
                end, "brightness was not restored")
                assert(operation_ok, operation_err)
            end,
        },
        {
            name = "suspend",
            run = function()
                return skip("not executed automatically because it suspends the system")
            end,
        },
        {
            name = "shutdown",
            run = function()
                return skip("not executed automatically because it shuts down the system")
            end,
        },
        {
            name = "reboot",
            run = function()
                return skip("not executed automatically because it reboots the system")
            end,
        },
    }

    local keyboard_tests = {
        {
            name = "read layouts",
            run = function()
                local layouts = assert(plasma.keyboard.list_layouts())
                local active = assert(plasma.keyboard.get_active_layout())
                assert(#layouts > 0)
                assert(type(active.id) == "string" and active.id ~= "")
            end,
        },
        {
            name = "controls and restore",
            run = function()
                local original = assert(plasma.keyboard.get_active_layout())

                local operation_ok, operation_err = pcall(function()
                    assert(plasma.keyboard.set_layout(original))
                    assert(plasma.keyboard.select_next_layout())
                    assert(plasma.keyboard.select_previous_layout())
                end)

                local restored, restore_err = plasma.keyboard.set_layout(original)
                assert(restored, restore_err)
                utils.eventually(function()
                    local current = plasma.keyboard.get_active_layout()
                    return current and current.id == original.id and current.variant == original.variant
                end, "keyboard layout was not restored")
                assert(operation_ok, operation_err)
            end,
        },
    }

    local wifi_tests = {
        {
            name = "read state",
            run = function()
                local status = assert(plasma.wifi.get_status())
                assert(plasma.wifi.is_enabled() == status.enabled)
                assert(plasma.wifi.is_connected() == status.connected)

                local network, network_err = plasma.wifi.get_active_network()
                if status.connected then
                    assert(network == status.network)
                else
                    assert(not network and network_err)
                end
            end,
        },
        {
            name = "current radio state",
            run = function()
                local original = assert(plasma.wifi.get_status())

                if original.enabled then
                    assert(plasma.wifi.enable())
                else
                    assert(plasma.wifi.disable())
                end

                assert(plasma.wifi.is_enabled() == original.enabled)
            end,
        },
        {
            name = "disruptive radio controls",
            run = function()
                if not disruptive_mode then
                    return skip("enable with --test-disruptive-system to test radio changes")
                end
                local original = assert(plasma.wifi.get_status())
                local operation_ok, operation_err = pcall(function()
                    assert(plasma.wifi.toggle())
                    utils.eventually(function()
                        return plasma.wifi.is_enabled() ~= original.enabled
                    end, "Wi-Fi did not toggle")
                end)
                local restored, restore_err = original.enabled and plasma.wifi.enable() or plasma.wifi.disable()
                assert(restored, restore_err)
                utils.eventually(function()
                    return plasma.wifi.is_enabled() == original.enabled
                end, "Wi-Fi was not restored")
                assert(operation_ok, operation_err)
            end,
        },
    }

    local bluetooth_checked = false
    local bluetooth_status
    local bluetooth_status_error

    local function get_bluetooth_adapter()
        if not bluetooth_checked then
            bluetooth_status, bluetooth_status_error = plasma.bluetooth.get_status()
            bluetooth_checked = true
        end

        if bluetooth_status then
            return bluetooth_status
        end

        if bluetooth_status_error and
            bluetooth_status_error:find("no Bluetooth adapter is available", 1, true) then
            return nil, "no Bluetooth adapter is available"
        end

        error(bluetooth_status_error or "could not inspect the Bluetooth adapter", 0)
    end

    local bluetooth_tests = {
        {
            name = "read adapter state",
            run = function()
                local status, reason = get_bluetooth_adapter()
                if not status then
                    return skip(reason)
                end

                assert(plasma.bluetooth.is_enabled() == status.enabled)
            end,
        },
        {
            name = "current radio state",
            run = function()
                local original, reason = get_bluetooth_adapter()
                if not original then
                    return skip(reason)
                end

                if original.enabled then
                    assert(plasma.bluetooth.enable())
                else
                    assert(plasma.bluetooth.disable())
                end

                assert(plasma.bluetooth.is_enabled() == original.enabled)
            end,
        },
        {
            name = "disruptive radio controls",
            run = function()
                local status, reason = get_bluetooth_adapter()
                if not status then
                    return skip(reason)
                end

                if not disruptive_mode then
                    return skip("enable with --test-disruptive-system to test radio changes")
                end
                local operation_ok, operation_err = pcall(function()
                    assert(plasma.bluetooth.toggle())
                    utils.eventually(function()
                        return plasma.bluetooth.is_enabled() ~= status.enabled
                    end, "Bluetooth did not toggle")
                end)
                local restored, restore_err = status.enabled and plasma.bluetooth.enable() or plasma.bluetooth.disable()
                assert(restored, restore_err)
                utils.eventually(function()
                    return plasma.bluetooth.is_enabled() == status.enabled
                end, "Bluetooth was not restored")
                assert(operation_ok, operation_err)
            end,
        },
        {
            name = "devices",
            run = function()
                local status, reason = get_bluetooth_adapter()
                if not status then
                    return skip(reason)
                end

                local devices = assert(plasma.bluetooth.list_known_devices())
                local connected = assert(plasma.bluetooth.list_connected_devices())
                assert(type(connected) == "table")

                if #devices == 0 then
                    return skip("no known Bluetooth devices are available")
                end

                local device = assert(plasma.bluetooth.get_device(devices[1]))
                assert(plasma.bluetooth.is_connected(device) == device.connected)
            end,
        },
    }

    local system_wallpapers

    local desktop_tests = {
        {
            name = "displays",
            run = function()
                local displays = assert(plasma.desktop.list_displays())
                assert(#displays > 0)
                local display = assert(plasma.desktop.get_display(displays[1].name))
                assert(display.name == displays[1].name)
                assert(plasma.desktop.get_primary_display())

                local mode_display
                for _, current in ipairs(displays) do
                    if current.enabled and current.connected then
                        mode_display = current
                        break
                    end
                end

                if not mode_display then
                    return skip("no enabled display is available for mode inspection")
                end

                assert(plasma.desktop.list_display_modes(mode_display))
            end,
        },
        {
            name = "read wallpapers",
            run = function()
                system_wallpapers = assert(plasma.desktop.list_wallpapers())
                assert(#system_wallpapers > 0)
                assert(plasma.desktop.get_wallpaper(system_wallpapers[1].display))
            end,
        },
        {
            name = "write and restore wallpapers",
            run = function()
                system_wallpapers = system_wallpapers or
                    assert(plasma.desktop.list_wallpapers())

                for _, wallpaper in ipairs(system_wallpapers) do
                    if not wallpaper.uri then
                        return skip(
                            "the original wallpaper could not be restored reliably; " ..
                            "wallpaper changes may still work"
                        )
                    end
                end

                local operation_ok, operation_err = pcall(function()
                    if disruptive_mode then
                        assert(plasma.desktop.set_wallpaper(root .. "/resources/Nexus.png"))
                    else
                        for _, wallpaper in ipairs(system_wallpapers) do
                            assert(plasma.desktop.set_wallpaper(wallpaper.uri, {
                                display = wallpaper.display,
                                plugin = wallpaper.plugin,
                            }))
                        end
                    end
                end)
                for _, wallpaper in ipairs(system_wallpapers) do
                    assert(plasma.desktop.set_wallpaper(wallpaper.uri, {
                        display = wallpaper.display,
                        plugin = wallpaper.plugin,
                    }))
                end
                for _, wallpaper in ipairs(system_wallpapers) do
                    utils.eventually(function()
                        local current = plasma.desktop.get_wallpaper(wallpaper.display)
                        return current and current.uri == wallpaper.uri and current.plugin == wallpaper.plugin
                    end, "wallpaper was not restored")
                end
                assert(operation_ok, operation_err)
            end,
        },
    }

    return {
        { name = "sound (system)", module = make_suite("sound (system)", sound_tests) },
        { name = "notifications (system)", module = make_suite("notifications (system)", notification_tests) },
        { name = "power (system)", module = make_suite("power (system)", power_tests) },
        { name = "keyboard (system)", module = make_suite("keyboard (system)", keyboard_tests) },
        { name = "wifi (system)", module = make_suite("wifi (system)", wifi_tests) },
        { name = "bluetooth (system)", module = make_suite("bluetooth (system)", bluetooth_tests) },
        { name = "desktop (system)", module = make_suite("desktop (system)", desktop_tests) },
    }
end

return system
