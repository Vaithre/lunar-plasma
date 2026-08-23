-- Public entry point for Lunar Plasma

-- Find the library root from this file's location
local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/lunar%-plasma%.lua$") or "."

-- Add the internal Lua modules to the search path
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

-- Read the installed Lunar Plasma version
local version_file = assert(io.open(root .. "/VERSION", "r"), "cannot read Lunar Plasma version")
local version = version_file:read("*l")
version_file:close()

assert(version and version:match("^%d+%.%d+%.%d+$"), "invalid Lunar Plasma version")

-- Load native APIs
local sound = require("plasma.sound")
local notification = require("plasma.notification")
local power = require("plasma.powermanagement")
local keyboard = require("plasma.keyboard")
local desktop = require("plasma.desktop")
local wifi = require("plasma.wifi")
local bluetooth = require("plasma.bluetooth")

-- Public API
return {
    version = version,
    sound = sound.new(root .. "/scripts/sound.sh"),
    notification = notification.new(root .. "/scripts/notifications.sh"),
    power = power.new(root .. "/scripts/power.sh"),
    keyboard = keyboard.new(root .. "/scripts/keyboard.sh"),
    desktop = desktop.new(root .. "/scripts/desktop.sh"),
    wifi = wifi.new(root .. "/scripts/wifi.sh"),
    bluetooth = bluetooth.new(root .. "/scripts/bluetooth.sh"),
}
