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

local profile = plasma.power.get_profile()
local present = plasma.power.is_battery_present()

if not profile then
    io.stderr:write("Warning: could not read the power profile\n")
    return
end

if present == nil then
    io.stderr:write("Warning: could not read the battery status\n")
    return
end

if present then
    local percentage = plasma.power.get_battery_percentage()
    if not percentage then
        io.stderr:write("Warning: could not read the battery level\n")
        return
    end

    print(string.format("Battery level: %.1f%%", percentage))
else
    local plugged_in = plasma.power.is_ac_connected()
    if plugged_in == nil then
        io.stderr:write("Warning: could not read the power source\n")
        return
    end

    if plugged_in then
        print("Power: plugged in")
    else
        print("Power: no battery or AC source detected")
    end
end

print("Power profile: " .. profile)
