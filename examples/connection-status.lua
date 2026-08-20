#!/usr/bin/env lua

-- Show the current Wi-Fi and Bluetooth connection state.

-- This verbose lookup lets the example run locally from either project directory.
-- Once installed, loading Lunar Plasma only requires:
-- local home = os.getenv("HOME")
-- local plasma = dofile(home .. "/.local/opt/lunar-plasma/lunar-plasma.lua")

local source = debug.getinfo(1, "S").source:sub(2)
local example_dir = source:match("^(.*)/[^/]+$") or "."
local plasma = dofile(example_dir .. "/../lunar-plasma.lua")

-- Example starts here !

local wifi = plasma.wifi.get_status()
if not wifi then
    io.stderr:write("Warning: could not read the Wi-Fi status\n")
else
    if not wifi.enabled then
        print("Wi-Fi: disabled")
    elseif wifi.connected then
        print("Wi-Fi: connected to " .. wifi.network)
    else
        print("Wi-Fi: enabled, not connected")
    end
end

local bluetooth = plasma.bluetooth.get_status()
if not bluetooth then
    io.stderr:write("Warning: could not read the Bluetooth status\n")
elseif not bluetooth.enabled then
    print("Bluetooth: disabled")
else
    local devices = plasma.bluetooth.list_connected_devices()
    if not devices then
        io.stderr:write("Warning: could not read connected Bluetooth devices\n")
    elseif #devices == 0 then
        print("Bluetooth: enabled, no connected devices")
    else
        print(string.format("Bluetooth: %d connected device%s", #devices, #devices == 1 and "" or "s"))

        for _, device in ipairs(devices) do
            print(string.format("  %s (%s)", device.name, device.address))
        end
    end
end
