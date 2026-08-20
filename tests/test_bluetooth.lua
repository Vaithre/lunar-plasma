#!/usr/bin/env lua

-- Test the Bluetooth API. Run this file from the project root.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_bluetooth%.lua$") or "."

package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local bluetooth = require("plasma.bluetooth")
local backend = root .. "/tests/fixtures/bluetooth-backend.sh"

local function run()
    local plasma_bluetooth = bluetooth.new(backend)
    local tests = {
        {
            name = "get_status",
            run = function()
                local status = assert(plasma_bluetooth.get_status())
                assert(status.enabled == true)
                assert(status.discoverable == false)
                assert(status.discovering == false)
                assert(status.address == "AA:BB:CC:DD:EE:FF")
                assert(status.name == "Lunar Adapter")
            end,
        },
        {
            name = "is_enabled",
            run = function()
                assert(plasma_bluetooth.is_enabled() == true)
            end,
        },
        {
            name = "enable",
            run = function()
                assert(plasma_bluetooth.enable())
            end,
        },
        {
            name = "disable",
            run = function()
                assert(plasma_bluetooth.disable())
            end,
        },
        {
            name = "toggle",
            run = function()
                assert(plasma_bluetooth.toggle())
            end,
        },
        {
            name = "list_devices",
            run = function()
                local devices = assert(plasma_bluetooth.list_devices())
                assert(#devices == 2)
                assert(devices[1].address == "11:22:33:44:55:66")
                assert(devices[1].name == "Lunar Headphones")
                assert(devices[1].paired == true)
                assert(devices[1].trusted == true)
                assert(devices[1].connected == true)
                assert(devices[1].blocked == false)
                assert(devices[2].connected == false)
            end,
        },
        {
            name = "list_connected_devices",
            run = function()
                local devices = assert(plasma_bluetooth.list_connected_devices())
                assert(#devices == 1)
                assert(devices[1].name == "Lunar Headphones")
                assert(devices[1].connected == true)
            end,
        },
        {
            name = "get_device",
            run = function()
                local device = assert(plasma_bluetooth.get_device("11:22:33:44:55:66"))
                assert(device.name == "Lunar Headphones")
                assert(device.connected == true)
            end,
        },
        {
            name = "get_device",
            run = function()
                local device = assert(plasma_bluetooth.get_device({
                    address = "77:88:99:aa:bb:cc",
                }))
                assert(device.name == "Lunar Controller")
                assert(device.connected == false)
            end,
        },
        {
            name = "get_device",
            run = function()
                local device, err = plasma_bluetooth.get_device("invalid")
                assert(not device and err)
            end,
        },
        {
            name = "is_connected",
            run = function()
                assert(plasma_bluetooth.is_connected("11:22:33:44:55:66") == true)
                assert(plasma_bluetooth.is_connected("77:88:99:AA:BB:CC") == false)
            end,
        },
    }

    local passed = 0
    local failures = {}

    for index, test in ipairs(tests) do
        local ok, err = pcall(test.run)
        if ok then
            passed = passed + 1
            print(string.format("[%d/%d] %s SUCCESS", index, #tests, test.name))
        else
            failures[#failures + 1] = {
                index = index,
                total = #tests,
                name = test.name,
                error = tostring(err),
            }
            print(string.format("[%d/%d] %s FAILED", index, #tests, test.name))
        end
    end

    print(string.format("Summary: %d/%d successful", passed, #tests))
    return #failures == 0, failures
end

if ... == nil then
    os.exit(run() and 0 or 1)
end

return {
    run = run,
}
