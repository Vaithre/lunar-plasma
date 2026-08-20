#!/usr/bin/env lua

-- Test the display API. Run this file from the project root.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_display%.lua$") or "."

package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local desktop = require("plasma.desktop")
local backend = root .. "/tests/fixtures/display-backend.sh"

local function run()
    local plasma_desktop = desktop.new(backend)
    local tests = {
        {
            name = "list_displays",
            run = function()
                local displays = assert(plasma_desktop.list_displays())
                assert(#displays == 2)
                assert(displays[1].name == "eDP-1")
                assert(displays[1].connected == true)
                assert(displays[1].enabled == true)
                assert(displays[1].primary == true)
                assert(displays[1].mode.width == 1920)
                assert(displays[1].mode.refresh_rate == 60)
                assert(displays[2].name == "HDMI-A-1")
                assert(displays[2].connected == true)
                assert(displays[2].enabled == false)
                assert(displays[2].mode == nil)
            end,
        },
        {
            name = "get_display",
            run = function()
                local display = assert(plasma_desktop.get_display("HDMI-A-1"))
                assert(display.index == 2)
                assert(display.uuid == "hdmi-uuid")
                assert(display.scale == 1.25)
            end,
        },
        {
            name = "get_display",
            run = function()
                local display, err = plasma_desktop.get_display("missing")
                assert(not display and err)
            end,
        },
        {
            name = "get_primary_display",
            run = function()
                local display = assert(plasma_desktop.get_primary_display())
                assert(display.name == "eDP-1")
            end,
        },
        {
            name = "list_display_modes",
            run = function()
                local display = assert(plasma_desktop.get_display("eDP-1"))
                local modes = assert(plasma_desktop.list_display_modes(display))
                assert(#modes == 2)
                assert(modes[1].preferred == true)
                assert(modes[1].current == false)
                assert(modes[2].current == true)
            end,
        },
        {
            name = "list_display_modes",
            run = function()
                local modes, err = plasma_desktop.list_display_modes("eDP-1")
                assert(not modes and err)
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
