#!/usr/bin/env lua

-- Complete test runner
-- Run deterministic API, production backend, entry point, example, or opt-in real-system suites.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_all%.lua$") or "."

package.path = root .. "/tests/?.lua;" .. package.path

local system_mode = false
local disruptive_system_mode = false
local invalid_flag = false
for _, argument in ipairs(arg) do
    if argument == "--test-on-system" then
        system_mode = true
    elseif argument == "--test-disruptive-system" then
        system_mode = true
        disruptive_system_mode = true
    elseif argument:sub(1, 1) == "-" then
        io.stderr:write("Warning: unknown test runner flag: " .. argument .. "\n")
        invalid_flag = true
    end
end

if invalid_flag then
    os.exit(1)
end

local suites

if system_mode then
    suites = require("test_system").get_suites(root, disruptive_system_mode)
    print("Running tests against the current system.")
    if disruptive_system_mode then
        print("Disruptive radio, brightness, and wallpaper changes are enabled with restoration checks.")
    end
else
    suites = {
        { name = "backend", module = require("test_backend") },
        { name = "sound", module = require("test_sound") },
        { name = "notifications", module = require("test_notifications") },
        { name = "power", module = require("test_power") },
        { name = "keyboard", module = require("test_keyboard") },
        { name = "wifi", module = require("test_wifi") },
        { name = "bluetooth", module = require("test_bluetooth") },
        { name = "display", module = require("test_display") },
        { name = "backends", module = require("test_backends") },
        { name = "entrypoint", module = require("test_entrypoint") },
        { name = "resilience", module = require("test_resilience") },
    }

    print("Running deterministic API and production backend tests with a 3-second command timeout.")
end

local passed = 0
local failed_components = {}

local function format_error(err)
    return (tostring(err):gsub("[\r\n]+", " "))
end

for index, suite in ipairs(suites) do
    local run_ok, suite_ok, failures = pcall(suite.module.run)

    if not run_ok then
        failures = {
            {
                name = "suite runner",
                error = format_error(suite_ok),
            },
        }
        suite_ok = false
    end

    if suite_ok then
        passed = passed + 1
        print(string.format("[%d/%d] %s SUCCESS", index, #suites, suite.name))
    else
        failed_components[#failed_components + 1] = {
            name = suite.name,
            failures = failures or {},
        }
        print(string.format("[%d/%d] %s FAILED", index, #suites, suite.name))
    end
end

print(string.format("Summary: %d/%d successful", passed, #suites))

if #failed_components > 0 then
    print("Failed components and subtests:")

    for _, component in ipairs(failed_components) do
        print("  " .. component.name)

        if #component.failures == 0 then
            print("    - no subtest details were reported")
        else
            for _, failure in ipairs(component.failures) do
                local position = ""
                if failure.index and failure.total then
                    position = string.format("[%d/%d] ", failure.index, failure.total)
                end

                print(string.format(
                    "    - %s%s: %s",
                    position,
                    failure.name,
                    format_error(failure.error)
                ))
            end
        end
    end
end

os.exit(passed == #suites and 0 or 1)
