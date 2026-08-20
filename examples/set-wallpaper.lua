#!/usr/bin/env lua

-- Temporarily set an image as wallpaper on every display.

-- This verbose lookup lets the example run locally from either project directory.
-- Once installed, loading Lunar Plasma only requires:
-- local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local plasma = dofile(example_dir .. "/../lunar-plasma.lua")

-- Example starts here !

local wallpaper = example_dir .. "/../resources/Nexus.png"
local originals = plasma.desktop.list_wallpapers()

if not originals then
    io.stderr:write("Warning: could not read the current wallpapers\n")
    return
end

for _, original in ipairs(originals) do
    if not original.uri then
        io.stderr:write("Warning: could not guarantee wallpaper restoration\n")
        return
    end
end

if not plasma.desktop.set_wallpaper(wallpaper) then
    io.stderr:write("Warning: could not set the wallpaper\n")
    return
end

os.execute("sleep 3")

local restoration_ok = true

for _, original in ipairs(originals) do
    local restored = plasma.desktop.set_wallpaper(original.uri, {
        display = original.display,
        plugin = original.plugin,
    })
    restoration_ok = restoration_ok and restored == true
end

if not restoration_ok then
    io.stderr:write("Warning: could not restore the original wallpapers\n")
end
