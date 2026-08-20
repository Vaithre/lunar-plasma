#!/usr/bin/env lua

-- Fade the display brightness from 50% to 100% then restore the original value.

-- This verbose lookup lets the example run locally from either project directory.
-- Once installed, loading Lunar Plasma only requires:
-- local home = os.getenv("HOME")
-- local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local plasma = dofile(example_dir .. "/../lunar-plasma.lua")

-- Example starts here !

local display = 1
local delay = 0.025

local function sleep(seconds)
    return os.execute(string.format("sleep %.2f", seconds))
end

local original = plasma.power.get_brightness(display)
if not original then
    io.stderr:write("Warning: could not read the display brightness\n")
    return
end

local animation_ok = plasma.power.set_brightness(display, 50)

if animation_ok then
    for brightness = 51, 100 do
        if not sleep(delay) or not plasma.power.set_brightness(display, brightness) then
            animation_ok = false
            break
        end
    end

    if animation_ok then
        animation_ok = sleep(0.5)
    end
end

local restored = plasma.power.set_brightness(display, original)
if not restored then
    io.stderr:write("Warning: could not restore the display brightness\n")
elseif not animation_ok then
    io.stderr:write("Warning: could not complete the brightness animation\n")
end
