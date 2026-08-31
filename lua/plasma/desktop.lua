-- Desktop API
-- Change settings related to the Plasma desktop.

local desktop = {}
local backend_client = require("plasma.backend")
local utils = require("plasma.utils")

-- Parse wallpaper data returned by the backend.
local function parse_wallpaper(line)
    local display, plugin, uri = line:match("^(%d+)\t([^\t]*)\t(.*)$")

    if not display or plugin == "" then
        return nil, "desktop backend returned an invalid wallpaper"
    end

    if uri == "" then
        uri = nil
    end

    return {
        display = tonumber(display),
        plugin = plugin,
        uri = uri,
        path = uri and uri:gsub("^file://", "") or nil,
    }
end

-- Validate a wallpaper display number or connector name.
local function validate_wallpaper_display(display)
    if display == nil then
        return nil
    end

    local number = tonumber(display)
    if number then
        if number % 1 ~= 0 or number < 1 then
            return nil, "display must be a positive integer or connector name"
        end

        return number
    end

    if type(display) ~= "string" or display == "" then
        return nil, "display must be a positive integer or connector name"
    end

    return display
end

-- Create a desktop API connected to a backend script.
function desktop.new(backend)
    local instance = {}
    local client = backend_client.new(backend, "desktop", {
        timeouts = {
            ["list-wallpapers"] = 10,
            ["set-wallpaper"] = 10,
        },
    })

    -- Return wallpapers for every display.
    function instance.list_wallpapers()
        local output, err = client.read("list-wallpapers")
        if not output then
            return nil, err
        end

        local wallpapers = {}
        for line in output:gmatch("[^\r\n]+") do
            local wallpaper
            wallpaper, err = parse_wallpaper(line)
            if not wallpaper then
                return nil, err
            end

            wallpapers[#wallpapers + 1] = wallpaper
        end

        if #wallpapers == 0 then
            return nil, "no Plasma displays are available"
        end

        return wallpapers
    end

    -- Return a wallpaper by display.
    function instance.get_wallpaper(display)
        local validated_display, err = validate_wallpaper_display(display or 1)
        if not validated_display then
            return nil, err
        end

        validated_display, err = utils.resolve_plasma_screen(client.read, validated_display)
        if not validated_display then
            return nil, err
        end

        local output
        output, err = client.read("get-wallpaper", { validated_display })
        if not output then
            return nil, err
        end

        return parse_wallpaper(output:gsub("[\r\n]+$", ""))
    end

    -- Set a wallpaper on one display or every display.
    function instance.set_wallpaper(path, options)
        if type(path) ~= "string" or path == "" then
            return nil, "wallpaper path must be a non-empty string"
        end

        if options ~= nil and type(options) ~= "table" and
            type(options) ~= "number" and type(options) ~= "string" then
            return nil, "wallpaper options must be a table, display number, or connector name"
        end

        if type(options) == "number" or type(options) == "string" then
            options = { display = options }
        else
            options = options or {}
        end

        local display, err = validate_wallpaper_display(options.display)
        if options.display ~= nil and not display then
            return nil, err
        end

        display, err = utils.resolve_plasma_screen(client.read, display)
        if options.display ~= nil and not display then
            return nil, err
        end

        local plugin = options.plugin or "org.kde.image"
        if type(plugin) ~= "string" or plugin == "" then
            return nil, "wallpaper plugin must be a non-empty string"
        end

        return client.execute("set-wallpaper", {
            path,
            display and tostring(display) or "all",
            plugin,
        })
    end

    return instance
end

return desktop
