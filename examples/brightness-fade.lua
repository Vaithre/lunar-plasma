#!/usr/bin/env lua

-- Load the Lunar Plasma API.
local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local root = example_dir .. "/.."
local plasma = dofile(root .. "/lunar-plasma.lua")

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
