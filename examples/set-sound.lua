#!/usr/bin/env lua

-- Load the Lunar Plasma API.
local plasma = dofile("../lunar-plasma.lua")

-- Set the volume used by this example.
local value = 50

-- Execute the command and report backend errors.
local ok, err = plasma.sound.set(value)

assert(ok, err)
