#!/usr/bin/env lua

-- Load the Lunar Plasma API.
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

-- Set the volume used by this example.
local value = 50

-- Execute the command and report backend errors.
local ok, err = plasma.sound.set(value)

assert(ok, err)
