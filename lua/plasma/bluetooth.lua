-- Bluetooth API
-- Read and change the default Bluetooth adapter and inspect known devices.

local bluetooth = {}
local backend_client = require("plasma.backend")
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
    local client = backend_client.new(backend, "bluetooth", {
        timeouts = {
            ["get-status"] = 5,
            ["get-device"] = 5,
            ["list-devices"] = 15,
            ["list-connected-devices"] = 15,
            enable = 5,
            disable = 5,
            toggle = 5,
        },
    })

    -- Parse a list of Bluetooth devices returned by the backend.
    local function read_devices(action)
        local output, err = client.read(action)
        if not output then
            return nil, err
        end
        output = output:gsub("\r?\n$", "")

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
        local output, err = client.read("get-status")
        if not output then
            return nil, err
        end
        output = output:gsub("\r?\n$", "")

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
        return client.execute("enable")
    end

    -- Disable Bluetooth.
    function instance.disable()
        return client.execute("disable")
    end

    -- Toggle Bluetooth state.
    function instance.toggle()
        return client.execute("toggle")
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
        output, err = client.read("get-device", { address })
        if not output then
            return nil, err
        end
        output = output:gsub("\r?\n$", "")

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
