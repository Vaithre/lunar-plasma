#!/usr/bin/env lua

-- Keyboard API tests
-- Verify layout parsing, selectors, variants, cycling, validation, and malformed responses.

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_keyboard%.lua$") or "."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. root .. "/tests/?.lua;" .. package.path
local keyboard = require("plasma.keyboard")
local utils = require("test_utils")
local backend = root .. "/tests/fixtures/keyboard-backend.sh"

-- Create a keyboard backend with one controlled read response.
local function response_backend(action, output)
    local directory = utils.make_temp_dir(); local path = directory .. "/backend.sh"
    utils.write_file(path, string.format("#!/usr/bin/env bash\n[[ \"${1:-}\" == %s ]] || exit 2\nprintf '%%s' %s\n", utils.shell_quote(action), utils.shell_quote(output)))
    assert(os.execute("chmod +x " .. utils.shell_quote(path))); return keyboard.new(path), directory
end

-- Return the complete set of keyboard API cases.
local function cases()
    local api = keyboard.new(backend)
    return {
        { name = "list_layouts parses all layout fields", run = function()
            local layouts = utils.assert_success(api.list_layouts()); utils.assert_equal(#layouts, 2)
            utils.assert_equal(layouts[1].index, 1); utils.assert_equal(layouts[1].id, "latam"); utils.assert_equal(layouts[1].variant, "")
            utils.assert_equal(layouts[2].variant, "intl"); utils.assert_equal(layouts[2].name, "English (US, intl.)")
        end },
        { name = "get_active_layout parses the active layout", run = function() local layout = utils.assert_success(api.get_active_layout()); utils.assert_equal(layout.index, 1); utils.assert_equal(layout.id, "latam") end },
        { name = "set_layout accepts id index and table selectors", run = function()
            utils.assert_success(api.set_layout("us", "intl")); utils.assert_success(api.set_layout(2)); utils.assert_success(api.set_layout({ id = "latam", variant = "" })); utils.assert_success(api.set_layout({ index = 1 }))
        end },
        { name = "set_layout rejects invalid selectors and variants", run = function()
            for _, value in ipairs({ 0, -1, 1.5, "", {}, true }) do utils.assert_error("layout", function() return api.set_layout(value) end) end
            utils.assert_error("variant must be a string", function() return api.set_layout("us", {}) end)
        end },
        { name = "layout cycling reaches the backend", run = function() utils.assert_success(api.select_next_layout()); utils.assert_success(api.select_previous_layout()) end },
        { name = "list_layouts rejects an empty response", run = function() local custom, directory = response_backend("list-layouts", ""); utils.assert_error("no keyboard layouts", custom.list_layouts); utils.remove_temp_dir(directory) end },
        { name = "layout parser rejects malformed rows", run = function()
            for _, output in ipairs({ "x\tus\t\tUS\n", "1\t\t\tUS\n" }) do local custom, directory = response_backend("list-layouts", output); utils.assert_error("invalid layout", custom.list_layouts); utils.remove_temp_dir(directory) end
        end },
    }
end

-- Run the keyboard suite.
local function run() return utils.run_suite("keyboard", cases()) end
if ... == nil then os.exit(run() and 0 or 1) end
return { run = run }
