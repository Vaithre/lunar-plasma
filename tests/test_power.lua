#!/usr/bin/env lua

-- Test the power API. Run this file from the project root.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_power%.lua$") or "."

package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local power = require("plasma.powermanagement")
local backend = root .. "/tests/fixtures/power-backend.sh"
local no_battery_backend = root .. "/tests/fixtures/power-no-battery-backend.sh"

local function run()
    local plasma_power = power.new(backend)
    local desktop_power = power.new(no_battery_backend)
    local tests = {
        {
            name = "set_profile",
            run = function()
                assert(plasma_power.set_profile("saving"))
            end,
        },
        {
            name = "set_profile",
            run = function()
                assert(plasma_power.set_profile("normal"))
            end,
        },
        {
            name = "set_profile",
            run = function()
                assert(plasma_power.set_profile("performance"))
            end,
        },
        {
            name = "set_profile",
            run = function()
                local ok, err = plasma_power.set_profile("unknown")
                assert(not ok and err)
            end,
        },
        {
            name = "get_profile",
            run = function()
                assert(plasma_power.get_profile() == "normal")
            end,
        },
        {
            name = "get_battery_status",
            run = function()
                local status = assert(plasma_power.get_battery_status())
                assert(status.present == true)
                assert(status.percentage == 73.4)
                assert(status.state == "discharging")
                assert(status.source == "battery")
                assert(status.time_remaining == 7200)
                assert(status.warning_level == "low")
            end,
        },
        {
            name = "battery_values",
            run = function()
                assert(plasma_power.is_battery_present() == true)
                assert(plasma_power.get_battery_percentage() == 73.4)
                assert(plasma_power.get_battery_state() == "discharging")
                assert(plasma_power.is_battery_charging() == false)
                assert(plasma_power.get_battery_time_remaining() == 7200)
                assert(plasma_power.get_battery_warning_level() == "low")
            end,
        },
        {
            name = "power_source",
            run = function()
                assert(plasma_power.get_power_source() == "battery")
                assert(plasma_power.is_on_battery() == true)
                assert(plasma_power.is_ac_connected() == false)
            end,
        },
        {
            name = "no_battery",
            run = function()
                local status = assert(desktop_power.get_battery_status())
                assert(status.present == false)
                assert(status.percentage == nil)
                assert(status.source == "ac")
                assert(desktop_power.is_battery_present() == false)
                assert(desktop_power.is_battery_charging() == false)
                assert(desktop_power.is_ac_connected() == true)

                local percentage, err = desktop_power.get_battery_percentage()
                assert(not percentage and err == "no system battery is available")
            end,
        },
        {
            name = "suspend",
            run = function()
                assert(plasma_power.suspend())
            end,
        },
        {
            name = "shutdown",
            run = function()
                assert(plasma_power.shutdown())
            end,
        },
        {
            name = "reboot",
            run = function()
                assert(plasma_power.reboot())
            end,
        },
        {
            name = "set_brightness",
            run = function()
                assert(plasma_power.set_brightness(1, 50))
            end,
        },
        {
            name = "set_brightness",
            run = function()
                assert(plasma_power.set_brightness("display0", 75))
            end,
        },
        {
            name = "get_brightness",
            run = function()
                assert(plasma_power.get_brightness("monitor 1") == 40)
            end,
        },
        {
            name = "set_brightness",
            run = function()
                local ok, err = plasma_power.set_brightness({}, 50)
                assert(not ok and err)
            end,
        },
        {
            name = "set_brightness",
            run = function()
                local ok, err = plasma_power.set_brightness(1, 101)
                assert(not ok and err)
            end,
        },
    }

    local passed = 0

    for index, test in ipairs(tests) do
        local ok = pcall(test.run)
        if ok then
            passed = passed + 1
            print(string.format("[%d/%d] %s SUCCESS", index, #tests, test.name))
        else
            print(string.format("[%d/%d] %s FAILED", index, #tests, test.name))
        end
    end

    print(string.format("Summary: %d/%d successful", passed, #tests))
    return passed == #tests
end

if ... == nil then
    os.exit(run() and 0 or 1)
end

return {
    run = run,
}
