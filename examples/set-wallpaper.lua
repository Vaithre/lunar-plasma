#!/usr/bin/env lua

-- Temporarily set an image as wallpaper on every display.

local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local root = example_dir .. "/.."
local plasma = dofile(root .. "/lunar-plasma.lua")
local wallpaper = root .. "/resources/Nexus.png"
local originals = assert(plasma.desktop.wallpaper.list())

local operation_ok, operation_err = pcall(function()
    assert(plasma.desktop.wallpaper.set(wallpaper))
    assert(os.execute("sleep 3"))
end)

local restoration_ok = true

for _, original in ipairs(originals) do
    local restored = plasma.desktop.wallpaper.set(original.uri, {
        display = original.display,
        plugin = original.plugin,
    })
    restoration_ok = restoration_ok and restored == true
end

assert(restoration_ok, "could not restore the original wallpapers")
assert(operation_ok, operation_err)
