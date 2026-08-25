#!/usr/bin/env lua

-- Power API tests
-- Verify profiles, battery states, power sources, brightness, validation, and malformed responses.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_power%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. root .. "/tests/?.lua;" .. package.path

local power = require("plasma.powermanagement")
local utils = require("test_utils")
local backend = root .. "/tests/fixtures/power-backend.sh"
local no_battery_backend = root .. "/tests/fixtures/power-no-battery-backend.sh"

-- Create a backend that returns controlled profile, battery, or brightness data.
local function response_backend(action, output, code)
    local directory = utils.make_temp_dir()
    local path = directory .. "/backend.sh"
    utils.write_file(path, string.format("#!/usr/bin/env bash\n[[ \"${1:-}\" == %s ]] || exit 2\nprintf '%%s' %s\nexit %d\n", utils.shell_quote(action), utils.shell_quote(output or ""), code or 0))
    assert(os.execute("chmod +x " .. utils.shell_quote(path)))
    return power.new(path), directory
end

-- Return the complete set of power API cases.
local function cases()
    local api = power.new(backend)
    local desktop = power.new(no_battery_backend)
    return {
        { name = "set_profile maps every public profile", run = function()
            for _, profile in ipairs({ "saving", "normal", "performance", "power-saver", "balanced" }) do utils.assert_success(api.set_profile(profile)) end
        end },
        { name = "set_profile rejects unsupported values", run = function()
            for _, profile in ipairs({ "unknown", "", 1, {} }) do utils.assert_error("profile must be", function() return api.set_profile(profile) end) end
        end },
        { name = "get_profile maps the backend profile", run = function() utils.assert_equal(api.get_profile(), "normal", "profile") end },
        { name = "get_profile rejects malformed output", run = function()
            local custom, directory = response_backend("get-profile", "turbo\n")
            utils.assert_error("invalid profile", custom.get_profile); utils.remove_temp_dir(directory)
        end },
        { name = "get_battery_status parses every field", run = function()
            local status = utils.assert_success(api.get_battery_status())
            utils.assert_equal(status.present, true, "present"); utils.assert_equal(status.percentage, 73.4, "percentage")
            utils.assert_equal(status.state, "discharging", "state"); utils.assert_equal(status.source, "battery", "source")
            utils.assert_equal(status.time_remaining, 7200, "time remaining"); utils.assert_equal(status.warning_level, "low", "warning")
        end },
        { name = "battery convenience methods agree with status", run = function()
            utils.assert_equal(api.is_battery_present(), true); utils.assert_equal(api.get_battery_percentage(), 73.4)
            utils.assert_equal(api.get_battery_state(), "discharging"); utils.assert_equal(api.is_battery_charging(), false)
            utils.assert_equal(api.get_battery_time_remaining(), 7200); utils.assert_equal(api.get_battery_warning_level(), "low")
            utils.assert_equal(api.get_power_source(), "battery"); utils.assert_equal(api.is_on_battery(), true); utils.assert_equal(api.is_ac_connected(), false)
        end },
        { name = "battery methods handle a system without a battery", run = function()
            local status = utils.assert_success(desktop.get_battery_status())
            utils.assert_equal(status.present, false); utils.assert_equal(status.percentage, nil); utils.assert_equal(status.source, "ac")
            utils.assert_equal(desktop.is_battery_charging(), false); utils.assert_equal(desktop.is_ac_connected(), true)
            for _, method in ipairs({ desktop.get_battery_percentage, desktop.get_battery_state, desktop.get_battery_time_remaining, desktop.get_battery_warning_level }) do
                utils.assert_error("no system battery", method)
            end
        end },
        { name = "battery parser rejects malformed combinations", run = function()
            local invalid = { "maybe\t50\tdischarging\tbattery\t1\tlow\n", "true\t\tdischarging\tbattery\t1\tlow\n", "true\t101\tdischarging\tbattery\t1\tlow\n", "true\t50\tbroken\tbattery\t1\tlow\n", "true\t50\tdischarging\tbroken\t1\tlow\n", "true\t50\tdischarging\tbattery\t-1\tlow\n" }
            for _, output in ipairs(invalid) do local custom, directory = response_backend("get-battery-status", output); utils.assert_error("invalid", custom.get_battery_status); utils.remove_temp_dir(directory) end
        end },
        { name = "system power actions reach the backend", run = function()
            utils.assert_success(api.suspend()); utils.assert_success(api.shutdown()); utils.assert_success(api.reboot())
        end },
        { name = "brightness accepts selectors and boundaries", run = function()
            utils.assert_success(api.set_brightness(1, 0)); utils.assert_success(api.set_brightness("display0", 100)); utils.assert_equal(api.get_brightness("monitor 1"), 40)
        end },
        { name = "brightness rejects invalid selectors", run = function()
            for _, display in ipairs({ "", {}, true }) do utils.assert_error("display must", function() return api.set_brightness(display, 50) end) end
        end },
        { name = "brightness rejects invalid percentages", run = function()
            for _, value in ipairs({ -1, 101, 1.5, "bad", {}, math.huge }) do utils.assert_error("brightness must be", function() return api.set_brightness(1, value) end) end
        end },
        { name = "get_brightness rejects malformed output", run = function()
            for _, output in ipairs({ "bad\n", "101\n", "1.5\n" }) do local custom, directory = response_backend("get-brightness", output); utils.assert_error("invalid brightness", function() return custom.get_brightness(1) end); utils.remove_temp_dir(directory) end
        end },
    }
end

-- Run the power suite.
local function run() return utils.run_suite("power", cases()) end
if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
