-- Keyboard API
-- Read and change the active keyboard layout.

local keyboard = {}

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function parse_layout(line)
    local index, id, variant, name = line:match("^(%d+)\t([^\t]*)\t([^\t]*)\t(.*)$")

    if not index or id == "" then
        return nil, "keyboard backend returned an invalid layout"
    end

    return {
        index = tonumber(index),
        id = id,
        variant = variant,
        name = name,
    }
end

local function validate_layout(layout, variant)
    if type(layout) == "table" then
        variant = layout.variant
        layout = layout.id or layout.index
    end

    if type(layout) == "number" then
        if layout % 1 ~= 0 or layout < 1 then
            return nil, nil, "layout index must be a positive integer"
        end
    elseif type(layout) ~= "string" or layout == "" then
        return nil, nil, "layout must be an ID, name, index, or layout table"
    end

    if variant ~= nil and type(variant) ~= "string" then
        return nil, nil, "layout variant must be a string"
    end

    return tostring(layout), variant or ""
end

-- Create a keyboard API connected to a backend script.
function keyboard.new(backend)
    local instance = {}

    local function execute_backend(action, arguments)
        local command = shell_quote(backend) .. " " .. action

        for _, argument in ipairs(arguments or {}) do
            command = command .. " " .. shell_quote(argument)
        end

        local ok, _, code = os.execute(command)
        if not ok then
            return nil, "keyboard backend failed with exit code " .. tostring(code)
        end

        return true
    end

    local function read_backend(action)
        local process = io.popen(shell_quote(backend) .. " " .. action)
        if not process then
            return nil, "could not start the keyboard backend"
        end

        local output = process:read("*a")
        local ok, _, code = process:close()

        if not ok then
            return nil, "keyboard backend failed with exit code " .. tostring(code)
        end

        return output
    end

    -- Return every keyboard layout configured in the current session.
    function instance.list_layouts()
        local output, err = read_backend("list-layouts")
        if not output then
            return nil, err
        end

        local layouts = {}
        for line in output:gmatch("[^\r\n]+") do
            local layout
            layout, err = parse_layout(line)
            if not layout then
                return nil, err
            end

            layouts[#layouts + 1] = layout
        end

        if #layouts == 0 then
            return nil, "no keyboard layouts are configured"
        end

        return layouts
    end

    -- Return the active keyboard layout.
    function instance.get_layout()
        local output, err = read_backend("get-layout")
        if not output then
            return nil, err
        end

        return parse_layout(output:match("^%s*(.-)%s*$"))
    end

    -- Select a layout by ID, name, one-based index, or layout table.
    function instance.set_layout(layout, variant)
        local selector, validated_variant, err = validate_layout(layout, variant)
        if not selector then
            return nil, err
        end

        return execute_backend("set-layout", { selector, validated_variant })
    end

    -- Switch to the next configured keyboard layout.
    function instance.next_layout()
        return execute_backend("next-layout")
    end

    -- Switch to the previous configured keyboard layout.
    function instance.previous_layout()
        return execute_backend("previous-layout")
    end

    return instance
end

return keyboard
