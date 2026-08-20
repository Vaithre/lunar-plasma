#!/usr/bin/env lua

-- Show the number and names of connected displays.

-- This verbose lookup lets the example run locally from either project directory.
-- Once installed, loading Lunar Plasma only requires:
-- local home = os.getenv("HOME")
-- local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local plasma = dofile(example_dir .. "/../lunar-plasma.lua")

-- Example starts here !

local displays = plasma.desktop.list_displays()

if not displays then
    io.stderr:write("Warning: could not list connected displays\n")
    return
end

local connected = {}

for _, display in ipairs(displays) do
    if display.connected then
        connected[#connected + 1] = display
    end
end

print(string.format("Connected displays: %d", #connected))

for _, display in ipairs(connected) do
    print(display.name)
end
