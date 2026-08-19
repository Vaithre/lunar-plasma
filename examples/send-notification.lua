#!/usr/bin/env lua

-- Load the Lunar Plasma API.
local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local root = example_dir .. "/.."
local plasma = dofile(root .. "/lunar-plasma.lua")

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
