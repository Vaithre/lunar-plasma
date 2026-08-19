#!/usr/bin/env lua

-- Temporarily set an image as wallpaper on every display.

local home = os.getenv("HOME")
local install_dir = home .. "/.local/opt/lunar-plasma"
local plasma = dofile(install_dir .. "/lunar-plasma.lua")
local wallpaper = install_dir .. "/resources/Nexus.png"
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
