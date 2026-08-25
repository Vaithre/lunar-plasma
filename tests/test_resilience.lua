#!/usr/bin/env lua

-- Test-suite resilience tests
-- Verify quoting properties, timeout and stream capture, generated validation cases, and mutation sensitivity.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_resilience%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. root .. "/tests/?.lua;" .. package.path
local utils = require("test_utils")
local sound = require("plasma.sound")

-- Create an isolated mutated copy of the Lua modules.
local function mutant(file, expression, assertion)
    local directory = utils.make_temp_dir()
    assert(os.execute("/usr/bin/mkdir " .. utils.shell_quote(directory .. "/lua")))
    assert(os.execute("/usr/bin/cp -a " .. utils.shell_quote(root .. "/lua/plasma") .. " " .. utils.shell_quote(directory .. "/lua/plasma")))
    local mutation = utils.run_command("/usr/bin/sed -i -e " .. utils.shell_quote(expression) .. " " .. utils.shell_quote(directory .. "/lua/plasma/" .. file))
    assert(mutation.ok, mutation.stderr)
    local code = "package.path=" .. string.format("%q", directory .. "/lua/?.lua;" .. directory .. "/lua/?/init.lua;") .. "..package.path;" .. assertion
    local result = utils.run_command("/usr/bin/lua -e " .. utils.shell_quote(code))
    utils.remove_temp_dir(directory)
    return result
end

-- Return generated and mutation-resilience cases.
local function cases()
    return {
        { name = "shell_quote round-trips hostile generated strings", run = function()
            math.randomseed(3202)
            local alphabet = { "a", "Z", " ", "'", '"', "$", "`", ";", "|", "\\", "\n", "\t", "☾" }
            for _ = 1, 25 do
                local parts = {}
                for _ = 1, math.random(0, 24) do parts[#parts + 1] = alphabet[math.random(#alphabet)] end
                local value = table.concat(parts)
                local result = utils.run_command("/usr/bin/printf %s " .. utils.shell_quote(value))
                assert(result.ok, result.stderr); utils.assert_equal(result.stdout, value, "quoted value")
            end
        end },
        { name = "generated volume values obey the public domain", run = function()
            local api = sound.new(root .. "/tests/fixtures/sound-backend.sh")
            math.randomseed(3203)
            for _ = 1, 40 do
                local value = math.random(-200, 300)
                local result, err = api.set_volume(value)
                if value >= 0 and value <= 100 then assert(result, err) else assert(result == nil and type(err) == "string") end
            end
        end },
        { name = "command runner captures both streams and exit status", run = function()
            local result = utils.run_command("/usr/bin/bash -c " .. utils.shell_quote("printf output; printf problem >&2; exit 7"))
            assert(not result.ok); utils.assert_equal(result.code, 7); utils.assert_equal(result.stdout, "output"); utils.assert_equal(result.stderr, "problem")
        end },
        { name = "command runner enforces the three-second timeout", run = function()
            local result = utils.run_command("/usr/bin/sleep 30"); assert(result.timed_out); utils.assert_equal(result.code, 124)
        end },
        { name = "boundary tests kill an exclusive upper-bound mutation", run = function()
            local result = mutant("sound.lua", "s/value > 100/value >= 100/", "local s=require('plasma.sound').new(" .. string.format("%q", root .. "/tests/fixtures/sound-backend.sh") .. ");assert(s.set_volume(100))")
            assert(not result.ok, "volume boundary mutant survived")
        end },
        { name = "profile tests kill an incorrect mapping mutation", run = function()
            local result = mutant("powermanagement.lua", "s/balanced = \"normal\"/balanced = \"saving\"/", "local p=require('plasma.powermanagement').new(" .. string.format("%q", root .. "/tests/fixtures/power-backend.sh") .. ");assert(p.get_profile()=='normal')")
            assert(not result.ok, "power profile mapping mutant survived")
        end },
        { name = "state tests kill an inverted Wi-Fi mutation", run = function()
            local result = mutant("wifi.lua", "0,/return status.connected/s//return not status.connected/", "local w=require('plasma.wifi').new(" .. string.format("%q", root .. "/tests/fixtures/wifi-backend.sh") .. ");assert(w.is_connected()==true)")
            assert(not result.ok, "Wi-Fi state mutant survived")
        end },
    }
end

-- Run the resilience suite.
local function run() return utils.run_suite("resilience", cases()) end
if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
