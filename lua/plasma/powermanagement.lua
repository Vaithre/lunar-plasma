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

local public_profiles = {
    ["power-saver"] = "saving",
    balanced = "normal",
    performance = "performance",
}

local battery_states = {
    unknown = true,
    charging = true,
    discharging = true,
    empty = true,
    ["fully-charged"] = true,
    ["pending-charge"] = true,
    ["pending-discharge"] = true,
}

local power_sources = {
    battery = true,
    ac = true,
    unknown = true,
}

local warning_levels = {
    unknown = true,
    none = true,
    discharging = true,
    low = true,
    critical = true,
    action = true,
}

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function split_fields(line)
    local fields = {}

    for field in (line .. "\t"):gmatch("(.-)\t") do
        fields[#fields + 1] = field
    end

    return fields
end

local function parse_boolean(value)
    if value == "true" then
        return true
    end

    if value == "false" then
        return false
    end

    return nil
end

local function parse_battery_status(line)
    local fields = split_fields(line)
    local present = parse_boolean(fields[1])
    local percentage = fields[2] ~= "" and tonumber(fields[2]) or nil
    local time_remaining = fields[5] ~= "" and tonumber(fields[5]) or nil

    if #fields ~= 6 or present == nil or not battery_states[fields[3]] or
        not power_sources[fields[4]] or not warning_levels[fields[6]] or
        (percentage and (percentage < 0 or percentage > 100)) or
        (time_remaining and (time_remaining % 1 ~= 0 or time_remaining < 0)) then
        return nil, "power backend returned an invalid battery status"
    end

    if present and percentage == nil then
        return nil, "power backend returned an invalid battery percentage"
    end

    return {
        present = present,
        percentage = percentage,
        state = fields[3],
        source = fields[4],
        time_remaining = time_remaining,
        warning_level = fields[6],
    }
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

    -- Return the active power profile.
    function instance.get_profile()
        local output, err = read_backend("get-profile")
        if not output then
            return nil, err
        end

        local profile = public_profiles[output]
        if not profile then
            return nil, "power backend returned an invalid profile"
        end

        return profile
    end

    -- Return the complete system battery and power-source state.
    function instance.get_battery_status()
        local output, err = read_backend("get-battery-status")
        if not output then
            return nil, err
        end

        return parse_battery_status(output)
    end

    -- Check whether the system has a battery.
    function instance.is_battery_present()
        local status, err = instance.get_battery_status()
        if not status then
            return nil, err
        end

        return status.present
    end

    -- Return the current system battery percentage.
    function instance.get_battery_percentage()
        local status, err = instance.get_battery_status()
        if not status then
            return nil, err
        end

        if not status.present then
            return nil, "no system battery is available"
        end

        return status.percentage
    end

    -- Return the current system battery state.
    function instance.get_battery_state()
        local status, err = instance.get_battery_status()
        if not status then
            return nil, err
        end

        if not status.present then
            return nil, "no system battery is available"
        end

        return status.state
    end

    -- Check whether the system battery is charging.
    function instance.is_battery_charging()
        local status, err = instance.get_battery_status()
        if not status then
            return nil, err
        end

        return status.present and status.state == "charging"
    end

    -- Return the relevant charge or discharge time estimate in seconds.
    function instance.get_battery_time_remaining()
        local status, err = instance.get_battery_status()
        if not status then
            return nil, err
        end

        if not status.present then
            return nil, "no system battery is available"
        end

        if status.time_remaining == nil then
            return nil, "battery time estimate is not available"
        end

        return status.time_remaining
    end

    -- Return the current system battery warning level.
    function instance.get_battery_warning_level()
        local status, err = instance.get_battery_status()
        if not status then
            return nil, err
        end

        if not status.present then
            return nil, "no system battery is available"
        end

        return status.warning_level
    end

    -- Return the active system power source.
    function instance.get_power_source()
        local status, err = instance.get_battery_status()
        if not status then
            return nil, err
        end

        return status.source
    end

    -- Check whether the system is drawing power from its battery.
    function instance.is_on_battery()
        local source, err = instance.get_power_source()
        if not source then
            return nil, err
        end

        return source == "battery"
    end

    -- Check whether the system is connected to AC power.
    function instance.is_ac_connected()
        local source, err = instance.get_power_source()
        if not source then
            return nil, err
        end

        return source == "ac"
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
