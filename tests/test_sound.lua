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
            name = "set_volume",
            run = function()
                expect_success(plasma_sound.set_volume(50))
            end,
        },
        {
            name = "get_volume",
            run = function()
                assert(plasma_sound.get_volume() == 40)
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
            name = "increase_volume",
            run = function()
                expect_success(plasma_sound.increase_volume(5))
            end,
        },
        {
            name = "decrease_volume",
            run = function()
                expect_success(plasma_sound.decrease_volume(5))
            end,
        },
        {
            name = "set_volume",
            run = function()
                local ok, err = plasma_sound.set_volume(101)
                assert(not ok and err)
            end,
        },
        {
            name = "increase_volume",
            run = function()
                local ok, err = plasma_sound.increase_volume(-1)
                assert(not ok and err)
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
