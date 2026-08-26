-- Wi-Fi API
-- Read and change the state of the Wi-Fi radio and active connection.

local wifi = {}
local backend_client = require("plasma.backend")
local utils = require("plasma.utils")

-- Parse Wi-Fi state into an easy-to-work-with format.
local function parse_status(line)
    local enabled_value, connected_value, network = line:match("^([^\t]+)\t([^\t]+)\t(.*)$")
    local enabled = utils.parse_boolean(enabled_value)
    local connected = utils.parse_boolean(connected_value)

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
    local client = backend_client.new(backend, "wifi")

    -- Return the current Wi-Fi radio and connection state.
    function instance.get_status()
        local output, err = client.read("get-status")
        if not output then
            return nil, err
        end
        output = output:gsub("\r?\n$", "")

        return parse_status(output)
    end

    -- Check if Wi-Fi is enabled.
    function instance.is_enabled()
        local status, err = instance.get_status()
        if not status then
            return nil, err
        end

        return status.enabled
    end

    -- Check if Wi-Fi has an active connection.
    function instance.is_connected()
        local status, err = instance.get_status()
        if not status then
            return nil, err
        end

        return status.connected
    end

    -- Return the name of the active Wi-Fi network.
    function instance.get_active_network()
        local status, err = instance.get_status()
        if not status then
            return nil, err
        end

        if not status.connected then
            return nil, "wifi is not connected"
        end

        return status.network
    end

    -- Enable Wi-Fi.
    function instance.enable()
        return client.execute("enable")
    end

    -- Disable Wi-Fi.
    function instance.disable()
        return client.execute("disable")
    end

    -- Toggle Wi-Fi state.
    function instance.toggle()
        return client.execute("toggle")
    end

    return instance
end

return wifi
