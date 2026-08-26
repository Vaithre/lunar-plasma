#!/usr/bin/env lua

-- Desktop and display API tests
-- Verify wallpapers, connector mapping, displays, modes, validation, escaping, and malformed data.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_display%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. root .. "/tests/?.lua;" .. package.path
local desktop = require("plasma.desktop")
local utils = require("test_utils")
local backend = root .. "/tests/fixtures/display-backend.sh"

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

-- Return the complete set of desktop and display API cases.
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
            name = "list_displays parses connected and disabled displays",
            run = function()
                local displays = utils.assert_success(api.list_displays())
                utils.assert_equal(#displays, 2)
                utils.assert_equal(displays[1].primary, true)
                utils.assert_equal(displays[1].position.x, 0)
                utils.assert_equal(displays[1].mode.width, 1920)
                utils.assert_equal(displays[2].enabled, false)
                utils.assert_equal(displays[2].scale, 1.25)
                utils.assert_equal(displays[2].mode, nil)
            end,
        },
        {
            name = "display lookup finds named and primary displays",
            run = function()
                local display = utils.assert_success(api.get_display("HDMI-A-1"))
                local primary = utils.assert_success(api.get_primary_display())
                utils.assert_equal(display.uuid, "hdmi-uuid")
                utils.assert_equal(primary.name, "eDP-1")
                utils.assert_error("display not found", function()
                    return api.get_display("missing")
                end)
            end,
        },
        {
            name = "display mode parser preserves flags and decimals",
            run = function()
                local display = utils.assert_success(api.get_display("eDP-1"))
                local modes = utils.assert_success(api.list_display_modes(display))
                utils.assert_equal(#modes, 2)
                utils.assert_equal(modes[1].preferred, true)
                utils.assert_equal(modes[2].current, true)
                utils.assert_equal(modes[2].refresh_rate, 60)
            end,
        },
        {
            name = "list_display_modes requires a display table",
            run = function()
                utils.assert_error("display must be a display table", function()
                    return api.list_display_modes("eDP-1")
                end)
            end,
        },
        {
            name = "empty wallpaper and display lists are rejected",
            run = function()
                for _, action in ipairs({ "list-wallpapers", "list-displays" }) do
                    local custom, directory = response_backend(action, "")
                    local operation = action == "list-wallpapers" and
                        custom.list_wallpapers or custom.list_displays
                    utils.assert_error("no Plasma displays", operation)
                    utils.remove_temp_dir(directory)
                end
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
            name = "display parser rejects malformed rows and rotations",
            run = function()
                local custom, directory = response_backend(
                    "list-displays",
                    "1\t1\teDP-1\tuuid\ttrue\ttrue\ttrue\t1\t0\t0\t1\t1\t1\t999\t\t\t\t\n"
                )
                utils.assert_error("invalid display", custom.list_displays)
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "display mode parser rejects malformed rows",
            run = function()
                local custom, directory = response_backend(
                    "list-display-modes",
                    "1\t1920\t1080\tbad\ttrue\tfalse\n"
                )
                utils.assert_error("invalid display mode", function()
                    return custom.list_display_modes({ name = "eDP-1" })
                end)
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "desktop backend error details are preserved",
            run = function()
                local custom, directory = response_backend("list-displays", "specific failure\n", 6)
                utils.assert_error("specific failure", custom.list_displays)
                utils.remove_temp_dir(directory)
            end,
        },
    }
end

-- Run the desktop and display suite.
local function run()
    return utils.run_suite("display", cases())
end
if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
