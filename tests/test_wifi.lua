#!/usr/bin/env lua

-- Test the Wi-Fi API. Run this file from the project root.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_wifi%.lua$") or "."

package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local wifi = require("plasma.wifi")
local backend = root .. "/tests/fixtures/wifi-backend.sh"
local disconnected_backend = root .. "/tests/fixtures/wifi-disconnected-backend.sh"

local function run()
    local plasma_wifi = wifi.new(backend)
    local disconnected_wifi = wifi.new(disconnected_backend)
    local tests = {
        {
            name = "get_status",
            run = function()
                local status = assert(plasma_wifi.get_status())
                assert(status.enabled == true)
                assert(status.connected == true)
                assert(status.network == "Lunar Network")
            end,
        },
        {
            name = "is_enabled",
            run = function()
                assert(plasma_wifi.is_enabled() == true)
            end,
        },
        {
            name = "is_connected",
            run = function()
                assert(plasma_wifi.is_connected() == true)
            end,
        },
        {
            name = "get_active_network",
            run = function()
                assert(plasma_wifi.get_active_network() == "Lunar Network")
            end,
        },
        {
            name = "get_disconnected_status",
            run = function()
                local status = assert(disconnected_wifi.get_status())
                assert(status.enabled == false)
                assert(status.connected == false)
                assert(status.network == nil)
            end,
        },
        {
            name = "get_disconnected_network",
            run = function()
                local network, err = disconnected_wifi.get_active_network()
                assert(not network and err == "wifi is not connected")
            end,
        },
        {
            name = "enable",
            run = function()
                assert(plasma_wifi.enable())
            end,
        },
        {
            name = "disable",
            run = function()
                assert(plasma_wifi.disable())
            end,
        },
        {
            name = "toggle",
            run = function()
                assert(plasma_wifi.toggle())
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
