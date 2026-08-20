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
    assert(os.execute(string.format("sleep %.2f", seconds)))
end

local original, err = plasma.power.get_brightness(display)
assert(original, err)

local animation_ok, animation_err = pcall(function()
    assert(plasma.power.set_brightness(display, 50))

    for brightness = 51, 100 do
        sleep(delay)
        assert(plasma.power.set_brightness(display, brightness))
    end

    sleep(0.5)
end)

local restored, restore_err = plasma.power.set_brightness(display, original)
assert(restored, restore_err)
assert(animation_ok, animation_err)
