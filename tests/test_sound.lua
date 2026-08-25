#!/usr/bin/env lua

-- Sound API tests
-- Verify sound validation, state parsing, boundary behavior, and backend failures.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_sound%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. root .. "/tests/?.lua;" .. package.path

local sound = require("plasma.sound")
local utils = require("test_utils")
local backend = root .. "/tests/fixtures/sound-backend.sh"

-- Create a backend that returns one controlled response.
local function response_backend(action, output, exit_code)
    local directory = utils.make_temp_dir()
    local path = directory .. "/backend.sh"
    utils.write_file(path, string.format(
        "#!/usr/bin/env bash\n[[ \"${1:-}\" == %s ]] || exit 2\nprintf '%%s' %s\nexit %d\n",
        utils.shell_quote(action), utils.shell_quote(output or ""), exit_code or 0
    ))
    assert(os.execute("chmod +x " .. utils.shell_quote(path)))
    return sound.new(path), directory
end

-- Return the complete set of sound API cases.
local function cases()
    local api = sound.new(backend)
    return {
        { name = "set_volume accepts both boundaries", run = function()
            utils.assert_success(api.set_volume(0)); utils.assert_success(api.set_volume(100))
        end },
        { name = "set_volume accepts an integer string", run = function()
            utils.assert_success(api.set_volume("50"))
        end },
        { name = "set_volume rejects invalid values", run = function()
            for _, value in ipairs({ -1, 101, 1.5, "", "no", {}, true, math.huge }) do
                utils.assert_error("volume must be an integer between 0 and 100", function()
                    return api.set_volume(value)
                end)
            end
        end },
        { name = "get_volume parses numeric output", run = function()
            utils.assert_equal(api.get_volume(), 40, "volume")
        end },
        { name = "get_volume rejects malformed output", run = function()
            local custom, directory = response_backend("get", "not-a-number\n")
            utils.assert_error("invalid volume", custom.get_volume)
            utils.remove_temp_dir(directory)
        end },
        { name = "get_volume propagates backend failure", run = function()
            local custom, directory = response_backend("get", "failure\n", 9)
            utils.assert_error("exit code 9", custom.get_volume)
            utils.remove_temp_dir(directory)
        end },
        { name = "mute controls succeed", run = function()
            utils.assert_success(api.mute()); utils.assert_success(api.unmute()); utils.assert_success(api.toggle_mute())
        end },
        { name = "is_muted parses false", run = function()
            utils.assert_equal(api.is_muted(), false, "mute state")
        end },
        { name = "is_muted rejects malformed output", run = function()
            local custom, directory = response_backend("is-muted", "maybe\n")
            utils.assert_error("invalid mute state", custom.is_muted)
            utils.remove_temp_dir(directory)
        end },
        { name = "relative volume clamps at both boundaries", run = function()
            utils.assert_success(api.increase_volume(100)); utils.assert_success(api.decrease_volume(100))
        end },
        { name = "relative volume rejects invalid amounts", run = function()
            for _, value in ipairs({ -1, 101, 0.5, "bad", {} }) do
                utils.assert_error("amount must be an integer between 0 and 100", function()
                    return api.increase_volume(value)
                end)
            end
        end },
    }
end

-- Run the sound suite.
local function run()
    return utils.run_suite("sound", cases())
end

if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
