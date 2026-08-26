#!/usr/bin/env lua

-- Shared backend runner tests
-- Verify argument preservation, stream isolation, failures, and operation timeouts.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_backend%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" ..
    root .. "/tests/?.lua;" .. package.path

local backend = require("plasma.backend")
local utils = require("test_utils")

-- Create one isolated executable script.
local function executable_script(content)
    local directory = utils.make_temp_dir()
    local path = directory .. "/script.sh"
    utils.write_file(path, content)
    assert(os.execute("chmod +x " .. utils.shell_quote(path)))
    return path, directory
end

-- Return the shared backend runner cases.
local function cases()
    return {
        {
            name = "runner preserves actions and hostile arguments",
            run = function()
                local path, directory = executable_script(
                    "#!/usr/bin/env bash\nprintf '%s\\t%s\\n' \"${1:-}\" \"${2:-}\"\n"
                )
                local client = backend.new(path, "test")
                local value = "Lunar's $(false); | $HOME `false` ☾"
                local output = utils.assert_success(client.read("inspect", { value }))
                utils.assert_equal(output, "inspect\t" .. value .. "\n")
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "runner isolates stderr from successful output",
            run = function()
                local path, directory = executable_script(
                    "#!/usr/bin/env bash\nprintf 'value\\n'\nprintf 'warning\\n' >&2\n"
                )
                local client = backend.new(path, "test")
                utils.assert_equal(client.read("read"), "value\n")
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "runner preserves backend error details",
            run = function()
                local path, directory = executable_script(
                    "#!/usr/bin/env bash\nprintf 'specific failure\\n' >&2\nexit 7\n"
                )
                local client = backend.new(path, "test")
                local err = utils.assert_error("exit code 7", function()
                    return client.read("read")
                end)
                utils.assert_contains(err, "specific failure")
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "runner uses stdout when a failed backend has no stderr",
            run = function()
                local path, directory = executable_script(
                    "#!/usr/bin/env bash\nprintf 'stdout failure\\n'\nexit 9\n"
                )
                local client = backend.new(path, "test")
                local err = utils.assert_error("exit code 9", function()
                    return client.execute("write")
                end)
                utils.assert_contains(err, "stdout failure")
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "runner applies default and operation timeouts",
            run = function()
                local runner, directory = executable_script(
                    "#!/usr/bin/env bash\nprintf '0\\0%s\\t%s\\n' \"${1:-}\" \"${3:-}\"\n"
                )
                local client = backend.new("/unused/backend", "test", {
                    runner = runner,
                    timeouts = { slow = 1 },
                })
                utils.assert_equal(client.read("normal"), "3\tnormal\n")
                utils.assert_equal(client.read("slow"), "1\tslow\n")
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "runner terminates an expired operation",
            run = function()
                local path, directory = executable_script(
                    "#!/usr/bin/env bash\n/usr/bin/sleep 30\n"
                )
                local client = backend.new(path, "test", { timeout = 1 })
                utils.assert_error("timed out after 1 second", function()
                    return client.read("slow")
                end)
                utils.remove_temp_dir(directory)
            end,
        },
        {
            name = "runner validates configuration and calls",
            run = function()
                local ok, err = pcall(function()
                    backend.new("/backend", "test", { timeout = 0 })
                end)
                assert(not ok)
                utils.assert_contains(err, "positive integer")

                local client = backend.new("/backend", "test")
                utils.assert_error("action must be", function()
                    return client.read("")
                end)
                utils.assert_error("arguments must be", function()
                    return client.execute("write", true)
                end)
            end,
        },
    }
end

-- Run the shared backend runner suite.
local function run()
    return utils.run_suite("backend", cases())
end

if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
