-- Wi-Fi API
-- Read and change the state of the Wi-Fi radio and active connection.

local wifi = {}

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
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

local function parse_status(line)
    local enabled_value, connected_value, network = line:match("^([^\t]+)\t([^\t]+)\t(.*)$")
    local enabled = parse_boolean(enabled_value)
    local connected = parse_boolean(connected_value)

    if enabled == nil or connected == nil then
        return nil, "wifi backend returned an invalid status"
    end

    if connected and (not enabled or network == "") then
        return nil, "wifi backend returned an invalid status"
    end

    return {
        enabled = enabled,
        connected = connected,
        network = network ~= "" and network or nil,
    }
end

-- Create a Wi-Fi API connected to a backend script.
function wifi.new(backend)
    local instance = {}

    local function execute_backend(action)
        local command = shell_quote(backend) .. " " .. shell_quote(action)
        local ok, _, code = os.execute(command)

        if not ok then
            return nil, "wifi backend failed with exit code " .. tostring(code)
        end

        return true
    end

    local function read_backend(action)
        local command = shell_quote(backend) .. " " .. shell_quote(action)
        local process = io.popen(command)

        if not process then
            return nil, "could not start the wifi backend"
        end

        local output = process:read("*a"):gsub("\r?\n$", "")
        local ok, _, code = process:close()

        if not ok then
            return nil, "wifi backend failed with exit code " .. tostring(code)
        end

        return output
    end

    -- Return the current Wi-Fi radio and connection state.
    function instance.get_status()
        local output, err = read_backend("get-status")
        if not output then
            return nil, err
        end

        return parse_status(output)
    end

    -- Check whether the Wi-Fi radio is enabled.
    function instance.is_enabled()
        local status, err = instance.get_status()
        if not status then
            return nil, err
        end

        return status.enabled
    end

    -- Check whether Wi-Fi has an active connection.
    function instance.is_connected()
        local status, err = instance.get_status()
        if not status then
            return nil, err
        end

        return status.connected
    end

    -- Return the name of the active Wi-Fi network.
    function instance.get_network()
        local status, err = instance.get_status()
        if not status then
            return nil, err
        end

        if not status.connected then
            return nil, "wifi is not connected"
        end

        return status.network
    end

    -- Enable the Wi-Fi radio.
    function instance.enable()
        return execute_backend("enable")
    end

    -- Disable the Wi-Fi radio.
    function instance.disable()
        return execute_backend("disable")
    end

    -- Toggle the Wi-Fi radio state.
    function instance.toggle()
        return execute_backend("toggle")
    end

    return instance
end

return wifi
