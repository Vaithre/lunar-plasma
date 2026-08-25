#!/usr/bin/env lua

-- Bluetooth API tests
-- Verify adapter and device parsing, address normalization, empty lists, validation, and failures.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_bluetooth%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. root .. "/tests/?.lua;" .. package.path
local bluetooth = require("plasma.bluetooth")
local utils = require("test_utils")
local backend = root .. "/tests/fixtures/bluetooth-backend.sh"

-- Create a Bluetooth backend with one controlled response.
local function response_backend(action, output, code)
    local directory = utils.make_temp_dir(); local path = directory .. "/backend.sh"
    utils.write_file(path, string.format("#!/usr/bin/env bash\n[[ \"${1:-}\" == %s ]] || exit 2\nprintf '%%s' %s\nexit %d\n", utils.shell_quote(action), utils.shell_quote(output or ""), code or 0))
    assert(os.execute("chmod +x " .. utils.shell_quote(path))); return bluetooth.new(path), directory
end

-- Return the complete set of Bluetooth API cases.
local function cases()
    local api = bluetooth.new(backend)
    return {
        { name = "get_status parses every adapter field", run = function() local status = utils.assert_success(api.get_status()); utils.assert_equal(status.enabled, true); utils.assert_equal(status.discoverable, false); utils.assert_equal(status.discovering, false); utils.assert_equal(status.address, "AA:BB:CC:DD:EE:FF"); utils.assert_equal(status.name, "Lunar Adapter") end },
        { name = "adapter controls reach the backend", run = function() utils.assert_equal(api.is_enabled(), true); utils.assert_success(api.enable()); utils.assert_success(api.disable()); utils.assert_success(api.toggle()) end },
        { name = "list_known_devices parses every flag", run = function() local devices = utils.assert_success(api.list_known_devices()); utils.assert_equal(#devices, 2); utils.assert_equal(devices[1].paired, true); utils.assert_equal(devices[1].trusted, true); utils.assert_equal(devices[1].connected, true); utils.assert_equal(devices[1].blocked, false); utils.assert_equal(devices[2].connected, false) end },
        { name = "list_connected_devices filters disconnected devices", run = function() local devices = utils.assert_success(api.list_connected_devices()); utils.assert_equal(#devices, 1); utils.assert_equal(devices[1].name, "Lunar Headphones") end },
        { name = "get_device accepts address and device table", run = function() utils.assert_equal(utils.assert_success(api.get_device("11:22:33:44:55:66")).connected, true); utils.assert_equal(utils.assert_success(api.get_device({ address = "77:88:99:aa:bb:cc" })).address, "77:88:99:AA:BB:CC") end },
        { name = "get_device rejects invalid selectors", run = function() for _, value in ipairs({ "invalid", "", {}, true, 1 }) do utils.assert_error("device must be", function() return api.get_device(value) end) end end },
        { name = "is_connected reflects device state", run = function() utils.assert_equal(api.is_connected("11:22:33:44:55:66"), true); utils.assert_equal(api.is_connected("77:88:99:AA:BB:CC"), false) end },
        { name = "device lists may be empty", run = function() local custom, directory = response_backend("list-devices", ""); utils.assert_equal(#utils.assert_success(custom.list_known_devices()), 0); utils.remove_temp_dir(directory) end },
        { name = "status parser rejects malformed rows", run = function() local custom, directory = response_backend("get-status", "yes\tfalse\tfalse\tAA:BB:CC:DD:EE:FF\tAdapter\n"); utils.assert_error("invalid status", custom.get_status); utils.remove_temp_dir(directory) end },
        { name = "device parser rejects malformed rows", run = function() local custom, directory = response_backend("list-devices", "11:22:33:44:55:66\ttrue\tbroken\tfalse\tfalse\tDevice\n"); utils.assert_error("invalid device", custom.list_known_devices); utils.remove_temp_dir(directory) end },
        { name = "backend stderr is preserved on reads", run = function()
            local directory = utils.make_temp_dir(); local path = directory .. "/backend.sh"; utils.write_file(path, "#!/usr/bin/env bash\nprintf 'specific failure\\n' >&2\nexit 8\n"); assert(os.execute("chmod +x " .. utils.shell_quote(path)))
            utils.assert_error("specific failure", bluetooth.new(path).get_status); utils.remove_temp_dir(directory)
        end },
    }
end

-- Run the Bluetooth suite.
local function run() return utils.run_suite("bluetooth", cases()) end
if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
