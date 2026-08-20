#!/usr/bin/env lua

-- Run every test suite in sequence. Run this file from the project root.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_all%.lua$") or "."

package.path = root .. "/tests/?.lua;" .. package.path

local suites = {
    { name = "sound", module = require("test_sound") },
    { name = "notifications", module = require("test_notifications") },
    { name = "power", module = require("test_power") },
    { name = "keyboard", module = require("test_keyboard") },
    { name = "wifi", module = require("test_wifi") },
    { name = "bluetooth", module = require("test_bluetooth") },
    { name = "display", module = require("test_display") },
}

-- Run tests that modify the real desktop only when explicitly requested.
if os.getenv("LUNAR_PLASMA_INTEGRATION") == "1" then
    suites[#suites + 1] = { name = "desktop", module = require("test_desktop") }
end

local passed = 0

for index, suite in ipairs(suites) do
    if suite.module.run() then
        passed = passed + 1
        print(string.format("[%d/%d] %s SUCCESS", index, #suites, suite.name))
    else
        print(string.format("[%d/%d] %s FAILED", index, #suites, suite.name))
    end
end

print(string.format("Summary: %d/%d successful", passed, #suites))
os.exit(passed == #suites and 0 or 1)
