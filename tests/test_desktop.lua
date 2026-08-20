#!/usr/bin/env lua

-- Test the desktop API against the current Plasma session.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_desktop%.lua$") or "."

package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local desktop = require("plasma.desktop")
local backend = root .. "/scripts/desktop.sh"
local test_path = root .. "/resources/Nexus.png"

local function run()
    local plasma_desktop = desktop.new(backend)
    local original_wallpapers
    local tests = {
        {
            name = "list_wallpapers",
            run = function()
                original_wallpapers = assert(plasma_desktop.list_wallpapers())
                assert(#original_wallpapers > 0)
            end,
        },
        {
            name = "get_wallpaper",
            run = function()
                local wallpaper = assert(plasma_desktop.get_wallpaper(1))
                assert(wallpaper.display == 1 and wallpaper.uri ~= "")
            end,
        },
        {
            name = "set_wallpaper",
            run = function()
                assert(original_wallpapers)

                local operation_ok, operation_err = pcall(function()
                    assert(plasma_desktop.set_wallpaper(test_path))

                    local changed = assert(plasma_desktop.list_wallpapers())
                    for _, wallpaper in ipairs(changed) do
                        assert(wallpaper.path:match("/resources/Nexus%.png$"))
                    end
                end)

                local restoration_ok = true
                for _, wallpaper in ipairs(original_wallpapers) do
                    local restored = plasma_desktop.set_wallpaper(wallpaper.uri, {
                        display = wallpaper.display,
                        plugin = wallpaper.plugin,
                    })
                    restoration_ok = restoration_ok and restored == true
                end

                assert(restoration_ok, "could not restore the original wallpapers")
                assert(operation_ok, operation_err)
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
