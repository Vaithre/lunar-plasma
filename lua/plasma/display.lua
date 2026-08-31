-- Display API
-- Inspect Plasma displays and their available modes.

local display = {}
local backend_client = require("plasma.backend")
local utils = require("plasma.utils")

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
        return nil, "display backend returned an invalid display"
    end

    local mode
    if fields[15] ~= "" then
        local mode_width = tonumber(fields[16])
        local mode_height = tonumber(fields[17])
        local refresh_rate = tonumber(fields[18])

        if not mode_width or not mode_height or not refresh_rate then
            return nil, "display backend returned an invalid display mode"
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
        return nil, "display backend returned an invalid display mode"
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

-- Create a display API connected to a backend script.
function display.new(backend)
    local instance = {}
    local client = backend_client.new(backend, "display")

    -- Return displays reported by Plasma.
    function instance.list_displays()
        local output, err = client.read("list-displays")
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

        local output, err = client.read("list-display-modes", { display.name })
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

return display
