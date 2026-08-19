#!/usr/bin/env lua

-- Load the Lunar Plasma API.
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

-- Set the normal power profile and report backend errors.
local ok, err = plasma.power.set_profile("power-saver")

assert(ok, err)
