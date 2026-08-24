-- Desktop API
-- Change settings related to the Plasma desktop.
-- All display-related functions should be in their own "display" module. I do
-- not want to touch the API any more for now, so they will stay merged with
-- the Wallpaper option temporarily.

local desktop = {}
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

-- Map KScreen rotation flags to public rotation names.
local rotations = {
    [1] = "normal",
    [2] = "left",
    [4] = "inverted",
    [8] = "right",
    [16] = "flipped",
    [32] = "flipped90",
    [64] = "flipped180",
    [128] = "flipped270",
}

-- Parse display data returned by the backend.
local function parse_display(line)
    local fields = utils.split_fields(line)
    local enabled = utils.parse_boolean(fields[5])
    local connected = utils.parse_boolean(fields[6])
    local primary = utils.parse_boolean(fields[7])
    local index = tonumber(fields[1])
    local id = tonumber(fields[2])
    local priority = tonumber(fields[8])
    local x = tonumber(fields[9])
    local y = tonumber(fields[10])
    local width = tonumber(fields[11])
    local height = tonumber(fields[12])
    local scale = tonumber(fields[13])
    local rotation = rotations[tonumber(fields[14])]

    if #fields ~= 18 or not index or not id or fields[3] == "" or fields[4] == "" or
        enabled == nil or connected == nil or primary == nil or not priority or
        not x or not y or not width or not height or not scale or not rotation then
        return nil, "desktop backend returned an invalid display"
    end

    local mode
    if fields[15] ~= "" then
        local mode_width = tonumber(fields[16])
        local mode_height = tonumber(fields[17])
        local refresh_rate = tonumber(fields[18])

        if not mode_width or not mode_height or not refresh_rate then
            return nil, "desktop backend returned an invalid display mode"
        end

        mode = {
            id = fields[15],
            width = mode_width,
            height = mode_height,
            refresh_rate = refresh_rate,
        }
    end

    return {
        index = index,
        id = id,
        name = fields[3],
        uuid = fields[4],
        enabled = enabled,
        connected = connected,
        primary = primary,
        priority = priority,
        position = {
            x = x,
            y = y,
        },
        size = {
            width = width,
            height = height,
        },
        scale = scale,
        rotation = rotation,
        mode = mode,
    }
end

-- Parse a display mode returned by the backend.
local function parse_display_mode(line)
    local fields = utils.split_fields(line)
    local preferred = utils.parse_boolean(fields[5])
    local current = utils.parse_boolean(fields[6])
    local width = tonumber(fields[2])
    local height = tonumber(fields[3])
    local refresh_rate = tonumber(fields[4])

    if #fields ~= 6 or fields[1] == "" or not width or not height or
        not refresh_rate or preferred == nil or current == nil then
        return nil, "desktop backend returned an invalid display mode"
    end

    return {
        id = fields[1],
        width = width,
        height = height,
        refresh_rate = refresh_rate,
        preferred = preferred,
        current = current,
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

    -- Execute a backend action and preserve its error output.
    local function execute_backend(action, arguments)
        local command = utils.shell_quote(backend) .. " " .. action

        for _, argument in ipairs(arguments or {}) do
            command = command .. " " .. utils.shell_quote(argument)
        end

        local process = io.popen(command .. " 2>&1")
        if not process then
            return nil, "could not start the desktop backend"
        end

        local output = process:read("*a"):gsub("\r?\n$", "")
        local ok, _, code = process:close()
        if not ok then
            local detail = output ~= "" and ": " .. output or ""
            return nil, "desktop backend failed with exit code " .. tostring(code) .. detail
        end

        return true
    end

    -- Read a backend response and preserve its error output.
    local function read_backend(action, arguments)
        local command = utils.shell_quote(backend) .. " " .. action

        for _, argument in ipairs(arguments or {}) do
            command = command .. " " .. utils.shell_quote(argument)
        end

        local process = io.popen(command .. " 2>&1")
        if not process then
            return nil, "could not start the desktop backend"
        end

        local output = process:read("*a")
        local ok, _, code = process:close()

        if not ok then
            local detail = output:match("^%s*(.-)%s*$")
            detail = detail ~= "" and ": " .. detail or ""
            return nil, "desktop backend failed with exit code " .. tostring(code) .. detail
        end

        return output
    end

    -- Return wallpapers for every display.
    function instance.list_wallpapers()
        local output, err = read_backend("list-wallpapers")
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

        validated_display, err = utils.resolve_plasma_screen(read_backend, validated_display)
        if not validated_display then
            return nil, err
        end

        local output
        output, err = read_backend("get-wallpaper", { validated_display })
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

        display, err = utils.resolve_plasma_screen(read_backend, display)
        if options.display ~= nil and not display then
            return nil, err
        end

        local plugin = options.plugin or "org.kde.image"
        if type(plugin) ~= "string" or plugin == "" then
            return nil, "wallpaper plugin must be a non-empty string"
        end

        return execute_backend("set-wallpaper", {
            path,
            display and tostring(display) or "all",
            plugin,
        })
    end

    -- Return displays reported by Plasma.
    function instance.list_displays()
        local output, err = read_backend("list-displays")
        if not output then
            return nil, err
        end

        local displays = {}
        for line in output:gmatch("[^\r\n]+") do
            local display
            display, err = parse_display(line)
            if not display then
                return nil, err
            end

            displays[#displays + 1] = display
        end

        if #displays == 0 then
            return nil, "no Plasma displays are available"
        end

        return displays
    end

    -- Return a display by connector name.
    function instance.get_display(name)
        if type(name) ~= "string" or name == "" then
            return nil, "display name must be a non-empty string"
        end

        local displays, err = instance.list_displays()
        if not displays then
            return nil, err
        end

        for _, display in ipairs(displays) do
            if display.name == name then
                return display
            end
        end

        return nil, "display not found: " .. name
    end

    -- Return the primary display.
    function instance.get_primary_display()
        local displays, err = instance.list_displays()
        if not displays then
            return nil, err
        end

        for _, display in ipairs(displays) do
            if display.primary then
                return display
            end
        end

        return nil, "no primary display is available"
    end

    -- Return display modes supported by a display table.
    function instance.list_display_modes(display)
        if type(display) ~= "table" or type(display.name) ~= "string" or display.name == "" then
            return nil, "display must be a display table"
        end

        local output, err = read_backend("list-display-modes", { display.name })
        if not output then
            return nil, err
        end

        local modes = {}
        for line in output:gmatch("[^\r\n]+") do
            local mode
            mode, err = parse_display_mode(line)
            if not mode then
                return nil, err
            end

            modes[#modes + 1] = mode
        end

        if #modes == 0 then
            return nil, "no display modes are available for " .. display.name
        end

        return modes
    end

    return instance
end

return desktop
