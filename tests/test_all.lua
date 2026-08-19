#!/usr/bin/env lua

local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/tests/test_all%.lua$") or "."

package.path = root .. "/tests/?.lua;" .. package.path

local suites = {
    { name = "sound", module = require("test_sound") },
}

local passed = 0

for index, suite in ipairs(suites) do
    if suite.module.run() then
        passed = passed + 1
        print(string.format("[%d/%d] SUCCESS", index, #suites))
    else
        print(string.format("[%d/%d] FAILED", index, #suites))
    end
end

print(string.format("Summary: %d/%d successful", passed, #suites))
os.exit(passed == #suites and 0 or 1)
