#!/usr/bin/env lua

-- Send a desktop notification.

-- This verbose lookup lets the example run locally from either project directory.
-- Once installed, loading Lunar Plasma only requires:
-- local plasma = dofile(os.getenv("HOME").."/.local/opt/lunar-plasma/lunar-plasma.lua")

local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local plasma = dofile(example_dir .. "/../lunar-plasma.lua")

-- Example starts here !

local ok = plasma.notifications.send({
    title = "Lunar Plasma",
    text = "Notifications are working",
    icon = "dialog-information",
    sound = "message",
    timeout = 5000,
    type = "info",
})

if not ok then
    io.stderr:write("Warning: could not send the notification\n")
end
