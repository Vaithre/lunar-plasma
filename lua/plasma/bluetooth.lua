-- Bluetooth API
-- Read and change the default Bluetooth adapter and inspect known devices.

local bluetooth = {}
local utils = require("plasma.utils")

-- Parse the default Bluetooth adapter status returned by the backend.
local function parse_status(line)
    local enabled_value, discoverable_value, discovering_value, address, name =
        line:match("^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t(.*)$")
    local enabled = utils.parse_boolean(enabled_value)
    local discoverable = utils.parse_boolean(discoverable_value)
    local discovering = utils.parse_boolean(discovering_value)

    if enabled == nil or discoverable == nil or discovering == nil or
        not address or address == "" or name == "" then
        return nil, "bluetooth backend returned an invalid status"
    end

    return {
        enabled = enabled,
        discoverable = discoverable,
        discovering = discovering,
        address = address,
        name = name,
    }
end

-- Parse a Bluetooth device returned by the backend.
local function parse_device(line)
    local address, paired_value, trusted_value, connected_value, blocked_value, name =
        line:match("^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t(.*)$")
    local paired = utils.parse_boolean(paired_value)
    local trusted = utils.parse_boolean(trusted_value)
    local connected = utils.parse_boolean(connected_value)
    local blocked = utils.parse_boolean(blocked_value)

    if not address or address == "" or paired == nil or trusted == nil or
        connected == nil or blocked == nil or name == "" then
        return nil, "bluetooth backend returned an invalid device"
    end

    return {
        address = address,
        name = name,
        paired = paired,
        trusted = trusted,
        connected = connected,
        blocked = blocked,
    }
end

-- Validate a Bluetooth address or device table.
local function validate_device(device)
    if type(device) == "table" then
        device = device.address
    end

    if type(device) ~= "string" or
        not device:match("^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$") then
        return nil, "device must be a Bluetooth address or device table"
    end

    return device:upper()
end

-- Create a Bluetooth API connected to a backend script.
function bluetooth.new(backend)
    local instance = {}

    -- Build a shell command for a backend action.
    local function build_command(action, arguments)
        local command = utils.shell_quote(backend) .. " " .. utils.shell_quote(action)

        for _, argument in ipairs(arguments or {}) do
            command = command .. " " .. utils.shell_quote(argument)
        end

        return command
    end

    -- Execute a backend action.
    local function execute_backend(action, arguments)
        local ok, _, code = os.execute(build_command(action, arguments))

        if not ok then
            return nil, "bluetooth backend failed with exit code " .. tostring(code)
        end

        return true
    end

    -- Read a backend response.
    local function read_backend(action, arguments)
        local process = io.popen(build_command(action, arguments) .. " 2>&1")

        if not process then
            return nil, "could not start the bluetooth backend"
        end

        local output = process:read("*a"):gsub("\r?\n$", "")
        local ok, _, code = process:close()

        if not ok then
            local detail = output ~= "" and ": " .. output or ""
            return nil, "bluetooth backend failed with exit code " .. tostring(code) .. detail
        end

        return output
    end

    -- Parse a list of Bluetooth devices returned by the backend.
    local function read_devices(action)
        local output, err = read_backend(action)
        if not output then
            return nil, err
        end

        local devices = {}
        for line in output:gmatch("[^\r\n]+") do
            local device
            device, err = parse_device(line)
            if not device then
                return nil, err
            end

            devices[#devices + 1] = device
        end

        return devices
    end

    -- Return the default Bluetooth status.
    function instance.get_status()
        local output, err = read_backend("get-status")
        if not output then
            return nil, err
        end

        return parse_status(output)
    end

    -- Check if Bluetooth is enabled.
    function instance.is_enabled()
        local status, err = instance.get_status()
        if not status then
            return nil, err
        end

        return status.enabled
    end

    -- Enable Bluetooth.
    function instance.enable()
        return execute_backend("enable")
    end

    -- Disable Bluetooth.
    function instance.disable()
        return execute_backend("disable")
    end

    -- Toggle Bluetooth state.
    function instance.toggle()
        return execute_backend("toggle")
    end

    -- Return known Bluetooth devices.
    function instance.list_known_devices()
        return read_devices("list-devices")
    end

    -- Return connected Bluetooth devices.
    function instance.list_connected_devices()
        return read_devices("list-connected-devices")
    end

    -- Return a Bluetooth device by address or device table.
    function instance.get_device(device)
        local address, err = validate_device(device)
        if not address then
            return nil, err
        end

        local output
        output, err = read_backend("get-device", { address })
        if not output then
            return nil, err
        end

        return parse_device(output)
    end

    -- Check if a Bluetooth device is connected.
    function instance.is_connected(device)
        local current, err = instance.get_device(device)
        if not current then
            return nil, err
        end

        return current.connected
    end

    return instance
end

return bluetooth
