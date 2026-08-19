#!/usr/bin/env lua

-- Test the notifications API. Run this file from the project root.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_notifications%.lua$") or "."

package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local notifications = require("plasma.notifications")
local backend = root .. "/tests/fixtures/notifications-backend.sh"

local function run()
    local plasma_notifications = notifications.new(backend)
    local tests = {
        {
            name = "send",
            run = function()
                assert(plasma_notifications.send({
                    title = "Lunar Plasma",
                    text = "Minimal notification",
                }))
            end,
        },
        {
            name = "send",
            run = function()
                assert(plasma_notifications.send({
                    title = "Lunar Plasma's notification",
                    text = "All optional fields",
                    icon = "dialog-information",
                    sound = "message",
                    timeout = 5000,
                    type = "success",
                }))
            end,
        },
        {
            name = "send",
            run = function()
                local ok, err = plasma_notifications.send({ text = "Missing title" })
                assert(not ok and err)
            end,
        },
        {
            name = "send",
            run = function()
                local ok, err = plasma_notifications.send({ title = "Missing text" })
                assert(not ok and err)
            end,
        },
        {
            name = "send",
            run = function()
                local ok, err = plasma_notifications.send({
                    title = "Invalid timeout",
                    text = "Test",
                    timeout = -2,
                })
                assert(not ok and err)
            end,
        },
        {
            name = "send",
            run = function()
                local ok, err = plasma_notifications.send({
                    title = "Invalid type",
                    text = "Test",
                    type = "unknown",
                })
                assert(not ok and err)
            end,
        },
    }

    local passed = 0

    for index, test in ipairs(tests) do
        local ok = pcall(test.run)
        if ok then
            passed = passed + 1
            print(string.format("[%d/%d] %s SUCCESS", index, #tests, test.name))
        else
            print(string.format("[%d/%d] %s FAILED", index, #tests, test.name))
        end
    end

    print(string.format("Summary: %d/%d successful", passed, #tests))
    return passed == #tests
end

if ... == nil then
    os.exit(run() and 0 or 1)
end

return {
    run = run,
}
