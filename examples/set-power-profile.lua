#!/usr/bin/env lua

-- Load the Lunar Plasma API.
local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local root = example_dir .. "/.."
local plasma = dofile(root .. "/lunar-plasma.lua")

-- Set the normal power profile and report backend errors.
local ok, err = plasma.power.set_profile("power-saver")

assert(ok, err)
