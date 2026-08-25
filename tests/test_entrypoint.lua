#!/usr/bin/env lua

-- Entry point and example tests
-- Verify the public API, version metadata, working-directory independence, and safe example failures.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_entrypoint%.lua$") or "."
package.path = root .. "/tests/?.lua;" .. package.path
local utils = require("test_utils")

-- Return the sorted public method names exposed by one module.
local function method_names(module)
    local names = {}
    for name, value in pairs(module) do if type(value) == "function" then names[#names + 1] = name end end
    table.sort(names)
    return table.concat(names, ",")
end

-- Return entry point and example cases.
local function cases()
    return {
        { name = "entry point exposes version and stable module surface", run = function()
            local plasma = dofile(root .. "/lunar-plasma.lua")
            utils.assert_equal(plasma.version, "0.3.1", "version")
            local expected = {
                sound = "decrease_volume,get_volume,increase_volume,is_muted,mute,set_volume,toggle_mute,unmute",
                notification = "send",
                power = "get_battery_percentage,get_battery_state,get_battery_status,get_battery_time_remaining,get_battery_warning_level,get_brightness,get_power_source,get_profile,is_ac_connected,is_battery_charging,is_battery_present,is_on_battery,reboot,set_brightness,set_profile,shutdown,suspend",
                keyboard = "get_active_layout,list_layouts,select_next_layout,select_previous_layout,set_layout",
                desktop = "get_display,get_primary_display,get_wallpaper,list_display_modes,list_displays,list_wallpapers,set_wallpaper",
                wifi = "disable,enable,get_active_network,get_status,is_connected,is_enabled,toggle",
                bluetooth = "disable,enable,get_device,get_status,is_connected,is_enabled,list_connected_devices,list_known_devices,toggle",
            }
            for name, methods in pairs(expected) do utils.assert_type(plasma[name], "table", name); utils.assert_equal(method_names(plasma[name]), methods, name .. " methods") end
        end },
        { name = "module initializer exposes constructors only", run = function()
            package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
            local modules = require("plasma")
            for _, name in ipairs({ "sound", "notification", "power", "keyboard", "desktop", "wifi", "bluetooth" }) do utils.assert_type(modules[name], "table", name); utils.assert_type(modules[name].new, "function", name .. ".new") end
        end },
        { name = "entry point loads outside the project working directory", run = function()
            local command = "cd /tmp && /usr/bin/lua -e " .. utils.shell_quote("local p=dofile(" .. string.format("%q", root .. "/lunar-plasma.lua") .. "); assert(p.version=='0.3.1')")
            local result = utils.run_command(command); assert(result.ok, result.stderr)
        end },
        { name = "entry point rejects invalid version metadata", run = function()
            local directory = utils.make_temp_dir(); assert(os.execute("/usr/bin/cp -a " .. utils.shell_quote(root .. "/lua") .. " " .. utils.shell_quote(directory .. "/lua"))); assert(os.execute("/usr/bin/cp -a " .. utils.shell_quote(root .. "/scripts") .. " " .. utils.shell_quote(directory .. "/scripts"))); assert(os.execute("/usr/bin/cp " .. utils.shell_quote(root .. "/lunar-plasma.lua") .. " " .. utils.shell_quote(directory .. "/lunar-plasma.lua"))); utils.write_file(directory .. "/VERSION", "invalid\n")
            local result = utils.run_command("/usr/bin/lua " .. utils.shell_quote(directory .. "/lunar-plasma.lua")); assert(not result.ok); utils.assert_contains(result.stderr, "invalid Lunar Plasma version"); utils.remove_temp_dir(directory)
        end },
        { name = "examples load safely without desktop dependencies", run = function()
            local directory = utils.make_temp_dir(); assert(os.execute("/usr/bin/ln -s /usr/bin/bash " .. utils.shell_quote(directory .. "/bash")))
            local names = { "battery-status", "brightness-fade", "connection-status", "list-displays", "send-notification", "set-power-profile", "set-sound", "set-wallpaper" }
            for _, name in ipairs(names) do local result = utils.run_command("/usr/bin/lua " .. utils.shell_quote(root .. "/examples/" .. name .. ".lua"), { PATH = directory, HOME = directory }); assert(result.ok, name .. ": " .. result.stderr); assert(result.stderr:find("Warning:", 1, true), name .. " did not exercise its unavailable-backend path") end
            utils.remove_temp_dir(directory)
        end },
    }
end

-- Run the entry point and example suite.
local function run() return utils.run_suite("entrypoint", cases()) end
if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
