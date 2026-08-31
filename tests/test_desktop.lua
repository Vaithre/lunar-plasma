#!/usr/bin/env lua

-- Desktop API tests
-- Verify wallpapers, connector mapping, validation, escaping, and malformed data.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_desktop%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. root .. "/tests/?.lua;" .. package.path
local desktop = require("plasma.desktop")
local utils = require("test_utils")
local backend = root .. "/tests/fixtures/desktop-backend.sh"

-- Create a desktop backend with one controlled response.
local function response_backend(action, output, code)
    local directory = utils.make_temp_dir()
    local path = directory .. "/backend.sh"
    utils.write_file(path, string.format(
        "#!/usr/bin/env bash\n[[ \"${1:-}\" == %s ]] || exit 2\nprintf '%%s' %s\nexit %d\n",
        utils.shell_quote(action),
        utils.shell_quote(output or ""),
        code or 0
    ))
    assert(os.execute("chmod +x " .. utils.shell_quote(path)))
    return desktop.new(path), directory
end

-- Return the complete set of desktop API cases.
local function cases()
    local api = desktop.new(backend)
    return {
        {
            name = "list_wallpapers parses URI path and plugin",
            run = function()
                local values = utils.assert_success(api.list_wallpapers())
                utils.assert_equal(#values, 2)
                utils.assert_equal(values[1].display, 1)
                utils.assert_equal(values[1].plugin, "org.kde.image")
                utils.assert_equal(values[1].uri, "file:///home/user/Pictures/one.png")
                utils.assert_equal(values[1].path, "/home/user/Pictures/one.png")
            end,
        },
        {
            name = "get_wallpaper accepts number and connector",
            run = function()
                local numbered = utils.assert_success(api.get_wallpaper(2))
                local connected = utils.assert_success(api.get_wallpaper("HDMI-A-1"))
                utils.assert_equal(numbered.display, 2)
                utils.assert_equal(connected.display, 1)
            end,
        },
        {
            name = "get_wallpaper handles a missing URI",
            run = function()
                local wallpaper = utils.assert_success(api.get_wallpaper(3))
                utils.assert_equal(wallpaper.uri, nil)
                utils.assert_equal(wallpaper.path, nil)
            end,
        },
        {
            name = "wallpaper selectors reject invalid values",
            run = function()
                for _, value in ipairs({ 0, -1, 1.5, "", {}, true }) do
                    utils.assert_error("display must", function()
                        return api.get_wallpaper(value)
                    end)
                end
            end,
        },
        {
            name = "set_wallpaper accepts all selector forms and plugin",
            run = function()
                utils.assert_success(api.set_wallpaper("/home/user/Pictures/one.png"))
                utils.assert_success(api.set_wallpaper("/home/user/Pictures/two.png", 2))
                utils.assert_success(api.set_wallpaper("/home/user/Pictures/connector.png", "HDMI-A-1"))
                utils.assert_success(api.set_wallpaper("/tmp/Lunar's $(false).png", {
                    display = 1,
                    plugin = "custom plugin",
                }))
            end,
        },
        {
            name = "set_wallpaper rejects invalid paths and options",
            run = function()
                utils.assert_error("path must", function()
                    return api.set_wallpaper("")
                end)
                utils.assert_error("options must", function()
                    return api.set_wallpaper("x", true)
                end)
                utils.assert_error("plugin must", function()
                    return api.set_wallpaper("x", { plugin = "" })
                end)
            end,
        },
        {
            name = "empty wallpaper lists are rejected",
            run = function()
                local custom, directory = response_backend("list-wallpapers", "")
                utils.assert_error("no Plasma displays", custom.list_wallpapers)
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "wallpaper parser rejects malformed rows",
            run = function()
                local custom, directory = response_backend(
                    "list-wallpapers",
                    "x\torg.kde.image\tfile:///x\n"
                )
                utils.assert_error("invalid wallpaper", custom.list_wallpapers)
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "desktop backend error details are preserved",
            run = function()
                local custom, directory = response_backend("list-wallpapers", "specific failure\n", 6)
                utils.assert_error("specific failure", custom.list_wallpapers)
                utils.remove_temp_dir(directory)
            end,
        },
    }
end

-- Run the desktop suite.
local function run()
    return utils.run_suite("desktop", cases())
end
if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
