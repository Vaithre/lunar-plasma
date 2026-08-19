#!/usr/bin/env lua

-- Load the Lunar Plasma API.
local home = os.getenv("HOME")
local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

-- Send a notification and report backend errors.
local ok, err = plasma.notifications.send({
    title = "Lunar Plasma",
    text = "Notifications are working",
    icon = "dialog-information",
    sound = "message",
    timeout = 5000,
    type = "info",
})

assert(ok, err)
