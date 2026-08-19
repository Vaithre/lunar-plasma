-- Desktop API
-- Change settings related to the Plasma desktop.

local desktop = {}

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function parse_wallpaper(line)
    local display, plugin, uri = line:match("^(%d+)\t([^\t]*)\t(.*)$")

    if not display or plugin == "" or uri == "" then
        return nil, "desktop backend returned an invalid wallpaper"
    end

    return {
        display = tonumber(display),
        plugin = plugin,
        uri = uri,
        path = uri:gsub("^file://", ""),
    }
end

local function validate_display(display)
    if display == nil then
        return nil
    end

    display = tonumber(display)
    if not display or display % 1 ~= 0 or display < 1 then
        return nil, "display must be a positive integer"
    end

    return display
end

-- Create a desktop API connected to a backend script.
function desktop.new(backend)
    local instance = {
        wallpaper = {},
    }

    local function execute_backend(action, arguments)
        local command = shell_quote(backend) .. " " .. action

        for _, argument in ipairs(arguments or {}) do
            command = command .. " " .. shell_quote(argument)
        end

        local ok, _, code = os.execute(command)
        if not ok then
            return nil, "desktop backend failed with exit code " .. tostring(code)
        end

        return true
    end

    local function read_backend(action, arguments)
        local command = shell_quote(backend) .. " " .. action

        for _, argument in ipairs(arguments or {}) do
            command = command .. " " .. shell_quote(argument)
        end

        local process = io.popen(command)
        if not process then
            return nil, "could not start the desktop backend"
        end

        local output = process:read("*a")
        local ok, _, code = process:close()

        if not ok then
            return nil, "desktop backend failed with exit code " .. tostring(code)
        end

        return output
    end

    -- Return the wallpaper assigned to every display.
    function instance.wallpaper.list()
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

    -- Return the wallpaper assigned to one display.
    function instance.wallpaper.get(display)
        local validated_display, err = validate_display(display or 1)
        if not validated_display then
            return nil, err
        end

        local output
        output, err = read_backend("get-wallpaper", { validated_display })
        if not output then
            return nil, err
        end

        return parse_wallpaper(output:match("^%s*(.-)%s*$"))
    end

    -- Set an image as wallpaper on one display or every display.
    function instance.wallpaper.set(path, options)
        if type(path) ~= "string" or path == "" then
            return nil, "wallpaper path must be a non-empty string"
        end

        if options ~= nil and type(options) ~= "table" and type(options) ~= "number" then
            return nil, "wallpaper options must be a table or display number"
        end

        if type(options) == "number" then
            options = { display = options }
        else
            options = options or {}
        end

        local display, err = validate_display(options.display)
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

    return instance
end

return desktop
