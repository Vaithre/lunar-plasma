#!/usr/bin/env lua

-- Show the current battery level, power source, and power profile.

-- This verbose lookup lets the example run locally from either project directory.
-- Once installed, loading Lunar Plasma only requires:
-- local home = os.getenv("HOME")
-- local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local plasma = dofile(example_dir .. "/../lunar-plasma.lua")

-- Example starts here !

local profile, profile_err = plasma.power.get_profile()
local present, present_err = plasma.power.is_battery_present()

assert(profile, profile_err)
assert(present ~= nil, present_err)

if present then
    local percentage, percentage_err = plasma.power.get_battery_percentage()
    assert(percentage, percentage_err)

    print(string.format("Battery level: %.1f%%", percentage))
else
    local plugged_in, power_err = plasma.power.is_ac_connected()
    assert(plugged_in ~= nil, power_err)

    if plugged_in then
        print("Power: plugged in")
    else
        print("Power: no battery or AC source detected")
    end
end

print("Power profile: " .. profile)
