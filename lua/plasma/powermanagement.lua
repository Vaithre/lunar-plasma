-- Power management API
-- Control power profiles, system power actions, and display brightness.

local power = {}

local profiles = {
    saving = "power-saver",
    normal = "balanced",
    performance = "performance",
    ["power-saver"] = "power-saver",
    balanced = "balanced",
}

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function validate_brightness(value)
    value = tonumber(value)

    if not value or value % 1 ~= 0 or value < 0 or value > 100 then
        return nil, "brightness must be an integer between 0 and 100"
    end

    return value
end

local function validate_display(display)
    if type(display) ~= "string" and type(display) ~= "number" then
        return nil, "display must be a name, ID, or monitor number"
    end

    display = tostring(display)
    if display == "" then
        return nil, "display must not be empty"
    end

    return display
end

-- Create a power API connected to a backend script.
function power.new(backend)
    local instance = {}

    local function execute_backend(action, arguments)
        local command = shell_quote(backend) .. " " .. action

        for _, argument in ipairs(arguments or {}) do
            command = command .. " " .. shell_quote(argument)
        end

        local ok, _, code = os.execute(command)
        if not ok then
            return nil, "power backend failed with exit code " .. tostring(code)
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
            return nil, "could not start the power backend"
        end

        local output = process:read("*a"):match("^%s*(.-)%s*$")
        local ok, _, code = process:close()

        if not ok then
            return nil, "power backend failed with exit code " .. tostring(code)
        end

        return output
    end

    -- Set the active power profile when profile management is available.
    function instance.set_profile(profile)
        local mapped_profile = profiles[profile]
        if not mapped_profile then
            return nil, "profile must be saving, normal, or performance"
        end

        return execute_backend("set-profile", { mapped_profile })
    end

    -- Suspend the system.
    function instance.suspend()
        return execute_backend("suspend")
    end

    -- Shut down the system.
    function instance.shutdown()
        return execute_backend("shutdown")
    end

    -- Reboot the system.
    function instance.reboot()
        return execute_backend("reboot")
    end

    -- Set the brightness of a selected display from 0 to 100.
    function instance.set_brightness(display, value)
        local validated_display, err = validate_display(display)
        if not validated_display then
            return nil, err
        end

        local brightness
        brightness, err = validate_brightness(value)
        if not brightness then
            return nil, err
        end

        return execute_backend("set-brightness", { validated_display, brightness })
    end

    -- Get the brightness of a selected display from 0 to 100.
    function instance.get_brightness(display)
        local validated_display, err = validate_display(display)
        if not validated_display then
            return nil, err
        end

        local output
        output, err = read_backend("get-brightness", { validated_display })
        if not output then
            return nil, err
        end

        local brightness = tonumber(output)
        if not brightness or brightness % 1 ~= 0 or brightness < 0 or brightness > 100 then
            return nil, "power backend returned an invalid brightness"
        end

        return brightness
    end

    return instance
end

return power
