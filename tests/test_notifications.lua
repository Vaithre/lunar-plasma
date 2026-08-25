#!/usr/bin/env lua

-- Notification API tests
-- Verify defaults, supported types, escaping, validation, and backend failures.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_notifications%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. root .. "/tests/?.lua;" .. package.path

local notification = require("plasma.notification")
local utils = require("test_utils")
local backend = root .. "/tests/fixtures/notifications-backend.sh"

-- Return the complete set of notification API cases.
local function cases()
    local api = notification.new(backend)
    return {
        { name = "send applies optional defaults", run = function()
            utils.assert_success(api.send({ title = "Lunar Plasma", text = "Minimal" }))
        end },
        { name = "send accepts every notification type", run = function()
            for _, kind in ipairs({ "info", "warning", "error", "success" }) do
                utils.assert_success(api.send({ title = kind, text = "Test", type = kind }))
            end
        end },
        { name = "send preserves hostile text as one argument", run = function()
            utils.assert_success(api.send({ title = "Lunar's $(false)", text = "quotes; | $HOME `false`\nUnicode ☾", icon = "icon name", sound = "/tmp/sound's file.ogg", timeout = 0 }))
        end },
        { name = "send accepts timeout boundaries", run = function()
            utils.assert_success(api.send({ title = "A", text = "B", timeout = -1 }))
            utils.assert_success(api.send({ title = "A", text = "B", timeout = 0 }))
        end },
        { name = "send rejects a non-table options value", run = function()
            utils.assert_error("options must be a table", function() return api.send("bad") end)
        end },
        { name = "send rejects missing required text", run = function()
            utils.assert_error("title must be", function() return api.send({ text = "B" }) end)
            utils.assert_error("text must be", function() return api.send({ title = "A" }) end)
        end },
        { name = "send rejects invalid optional text", run = function()
            utils.assert_error("icon must be a string", function() return api.send({ title = "A", text = "B", icon = {} }) end)
            utils.assert_error("sound must be a string", function() return api.send({ title = "A", text = "B", sound = false }) end)
        end },
        { name = "send rejects invalid timeouts", run = function()
            for _, timeout in ipairs({ -2, 1.5, "bad", math.huge }) do
                utils.assert_error("timeout must be", function() return api.send({ title = "A", text = "B", timeout = timeout }) end)
            end
        end },
        { name = "send rejects an unknown type", run = function()
            utils.assert_error("type must be", function() return api.send({ title = "A", text = "B", type = "unknown" }) end)
        end },
        { name = "send propagates backend failure", run = function()
            local failed = notification.new("/usr/bin/false")
            utils.assert_error("backend failed", function() return failed.send({ title = "A", text = "B" }) end)
        end },
    }
end

-- Run the notification suite.
local function run()
    return utils.run_suite("notifications", cases())
end

if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
