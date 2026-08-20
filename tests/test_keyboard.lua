#!/usr/bin/env lua

-- Test the keyboard API. Run this file from the project root.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_keyboard%.lua$") or "."

package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local keyboard = require("plasma.keyboard")
local backend = root .. "/tests/fixtures/keyboard-backend.sh"

local function run()
    local plasma_keyboard = keyboard.new(backend)
    local tests = {
        {
            name = "list_layouts",
            run = function()
                local layouts = assert(plasma_keyboard.list_layouts())
                assert(#layouts == 2)
                assert(layouts[1].index == 1 and layouts[1].id == "latam")
                assert(layouts[2].variant == "intl")
            end,
        },
        {
            name = "get_layout",
            run = function()
                local layout = assert(plasma_keyboard.get_layout())
                assert(layout.index == 1 and layout.id == "latam")
            end,
        },
        {
            name = "set_layout",
            run = function()
                assert(plasma_keyboard.set_layout("us", "intl"))
            end,
        },
        {
            name = "set_layout",
            run = function()
                assert(plasma_keyboard.set_layout(2))
            end,
        },
        {
            name = "set_layout",
            run = function()
                assert(plasma_keyboard.set_layout({ id = "latam", variant = "" }))
            end,
        },
        {
            name = "set_layout",
            run = function()
                local ok, err = plasma_keyboard.set_layout(0)
                assert(not ok and err)
            end,
        },
        {
            name = "next_layout",
            run = function()
                assert(plasma_keyboard.next_layout())
            end,
        },
        {
            name = "previous_layout",
            run = function()
                assert(plasma_keyboard.previous_layout())
            end,
        },
    }

    local passed = 0
    local failures = {}

    for index, test in ipairs(tests) do
        local ok, err = pcall(test.run)
        if ok then
            passed = passed + 1
            print(string.format("[%d/%d] %s SUCCESS", index, #tests, test.name))
        else
            failures[#failures + 1] = {
                index = index,
                total = #tests,
                name = test.name,
                error = tostring(err),
            }
            print(string.format("[%d/%d] %s FAILED", index, #tests, test.name))
        end
    end

    print(string.format("Summary: %d/%d successful", passed, #tests))
    return #failures == 0, failures
end

if ... == nil then
    os.exit(run() and 0 or 1)
end

return {
    run = run,
}
