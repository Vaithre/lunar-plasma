#!/usr/bin/env lua

-- Test the sound API. Run this file from the project root.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_sound%.lua$") or "."

package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local sound = require("plasma.sound")
local backend = root .. "/tests/fixtures/sound-backend.sh"

local function expect_success(ok, err)
    assert(ok, err)
end

local function run()
    local plasma_sound = sound.new(backend)
    local tests = {
        {
            name = "set",
            run = function()
                expect_success(plasma_sound.set(50))
            end,
        },
        {
            name = "get",
            run = function()
                assert(plasma_sound.get() == 40)
            end,
        },
        {
            name = "mute",
            run = function()
                expect_success(plasma_sound.mute())
            end,
        },
        {
            name = "unmute",
            run = function()
                expect_success(plasma_sound.unmute())
            end,
        },
        {
            name = "is_muted",
            run = function()
                assert(plasma_sound.is_muted() == false)
            end,
        },
        {
            name = "toggle_mute",
            run = function()
                expect_success(plasma_sound.toggle_mute())
            end,
        },
        {
            name = "increase",
            run = function()
                expect_success(plasma_sound.increase(5))
            end,
        },
        {
            name = "decrease",
            run = function()
                expect_success(plasma_sound.decrease(5))
            end,
        },
        {
            name = "set",
            run = function()
                local ok, err = plasma_sound.set(101)
                assert(not ok and err)
            end,
        },
        {
            name = "increase",
            run = function()
                local ok, err = plasma_sound.increase(-1)
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
