#!/usr/bin/env lua

-- Wi-Fi API tests
-- Verify connected, disconnected, inconsistent, malformed, and failed backend states.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_wifi%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. root .. "/tests/?.lua;" .. package.path
local wifi = require("plasma.wifi")
local utils = require("test_utils")
local backend = root .. "/tests/fixtures/wifi-backend.sh"
local disconnected_backend = root .. "/tests/fixtures/wifi-disconnected-backend.sh"

-- Create a Wi-Fi backend with one controlled status response.
local function response_backend(output, code)
    local directory = utils.make_temp_dir()
    local path = directory .. "/backend.sh"
    utils.write_file(path, string.format(
        "#!/usr/bin/env bash\n[[ \"${1:-}\" == get-status ]] || exit 2\nprintf '%%s' %s\nexit %d\n",
        utils.shell_quote(output or ""),
        code or 0
    ))
    assert(os.execute("chmod +x " .. utils.shell_quote(path)))
    return wifi.new(path), directory
end

-- Return the complete set of Wi-Fi API cases.
local function cases()
    local connected = wifi.new(backend)
    local disconnected = wifi.new(disconnected_backend)
    return {
        {
            name = "get_status parses a connected network",
            run = function()
                local status = utils.assert_success(connected.get_status())
                utils.assert_equal(status.enabled, true)
                utils.assert_equal(status.connected, true)
                utils.assert_equal(status.network, "Lunar Network")
            end,
        },
        {
            name = "connected convenience methods agree with status",
            run = function()
                utils.assert_equal(connected.is_enabled(), true)
                utils.assert_equal(connected.is_connected(), true)
                utils.assert_equal(connected.get_active_network(), "Lunar Network")
            end,
        },
        {
            name = "get_status parses a disabled radio",
            run = function()
                local status = utils.assert_success(disconnected.get_status())
                utils.assert_equal(status.enabled, false)
                utils.assert_equal(status.connected, false)
                utils.assert_equal(status.network, nil)
            end,
        },
        {
            name = "get_active_network reports disconnection",
            run = function()
                utils.assert_error("wifi is not connected", disconnected.get_active_network)
            end,
        },
        {
            name = "radio controls reach the backend",
            run = function()
                utils.assert_success(connected.enable())
                utils.assert_success(connected.disable())
                utils.assert_success(connected.toggle())
            end,
        },
        {
            name = "status preserves spaces and Unicode in SSID",
            run = function()
                local custom, directory = response_backend("true\ttrue\tLunar ☾ Network\n")
                utils.assert_equal(custom.get_active_network(), "Lunar ☾ Network")
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "status parser rejects invalid booleans",
            run = function()
                local custom, directory = response_backend("yes\tfalse\t\n")
                utils.assert_error("invalid status", custom.get_status)
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "status parser rejects connection with disabled radio",
            run = function()
                local custom, directory = response_backend("false\ttrue\tNetwork\n")
                utils.assert_error("invalid status", custom.get_status)
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "status parser rejects connected state without network",
            run = function()
                local custom, directory = response_backend("true\ttrue\t\n")
                utils.assert_error("invalid status", custom.get_status)
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "status propagates backend failure",
            run = function()
                local custom, directory = response_backend("failed\n", 7)
                utils.assert_error("exit code 7", custom.get_status)
                utils.remove_temp_dir(directory)
            end,
        },
    }
end

-- Run the Wi-Fi suite.
local function run()
    return utils.run_suite("wifi", cases())
end
if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
