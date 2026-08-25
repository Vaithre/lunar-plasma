-- Test utilities
-- Provide assertions, isolated temporary files, command execution, skips, and a shared suite runner.

local test_utils = {}

test_utils.timeout = 3

local skipped = {}
local temporary_directories = {}
local seed_reported = false

-- Quote one value for safe use in a shell command.
function test_utils.shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

-- Assert that a value is truthy and preserve a returned API error.
function test_utils.assert_success(value, err)
    assert(value, err or "expected a successful result")
    return value
end

-- Assert that two scalar values are equal and report both values.
function test_utils.assert_equal(actual, expected, label)
    if actual ~= expected then
        error(string.format(
            "%s: expected %s, got %s",
            label or "value",
            tostring(expected),
            tostring(actual)
        ), 2)
    end
    return actual
end

-- Assert that a value has the expected Lua type.
function test_utils.assert_type(value, expected, label)
    test_utils.assert_equal(type(value), expected, (label or "value") .. " type")
    return value
end

-- Assert that text contains a literal fragment.
function test_utils.assert_contains(value, expected, label)
    if type(value) ~= "string" or not value:find(expected, 1, true) then
        error(string.format(
            "%s: expected %s to contain %s",
            label or "text",
            tostring(value),
            tostring(expected)
        ), 2)
    end
    return value
end

-- Assert that a function returns nil and a useful error.
function test_utils.assert_error(expected, callback)
    local value, err = callback()
    assert(value == nil, "expected an error, got " .. tostring(value))
    test_utils.assert_type(err, "string", "error")
    assert(err ~= "", "expected a non-empty error")
    if expected then
        test_utils.assert_contains(err, expected, "error")
    end
    return err
end

-- Mark a test as intentionally skipped.
function test_utils.skip(reason)
    return skipped, reason
end

-- Create an isolated temporary directory.
function test_utils.make_temp_dir()
    local process = assert(io.popen("/usr/bin/mktemp -d 2>&1"))
    local path = process:read("*a"):gsub("[\r\n]+$", "")
    local ok = process:close()
    assert(ok and path ~= "", "could not create a temporary directory: " .. path)
    temporary_directories[path] = true
    return path
end

-- Remove a temporary directory created by the test suite.
function test_utils.remove_temp_dir(path)
    assert(type(path) == "string" and path:match("^/tmp/[^/]+$"), "unsafe temporary path")
    local ok = os.execute("/usr/bin/rm -rf -- " .. test_utils.shell_quote(path))
    assert(ok, "could not remove temporary directory: " .. path)
    temporary_directories[path] = nil
end

-- Write fixture data to a file.
function test_utils.write_file(path, content)
    local file = assert(io.open(path, "wb"))
    assert(file:write(content))
    assert(file:close())
end

-- Read all data from a file.
function test_utils.read_file(path)
    local file = assert(io.open(path, "rb"))
    local content = assert(file:read("*a"))
    assert(file:close())
    return content
end

-- Execute a command with captured streams and the suite timeout.
function test_utils.run_command(command, environment)
    local directory = test_utils.make_temp_dir()
    local stdout_path = directory .. "/stdout"
    local stderr_path = directory .. "/stderr"
    local prefix = ""

    for name, value in pairs(environment or {}) do
        assert(name:match("^[A-Z_][A-Z0-9_]*$"), "invalid environment variable name")
        prefix = prefix .. name .. "=" .. test_utils.shell_quote(value) .. " "
    end

    local full_command = string.format(
        "%s/usr/bin/timeout --signal=TERM --kill-after=1s %ds %s >%s 2>%s",
        prefix,
        test_utils.timeout,
        command,
        test_utils.shell_quote(stdout_path),
        test_utils.shell_quote(stderr_path)
    )
    local ok, reason, code = os.execute(full_command)
    local stdout = test_utils.read_file(stdout_path)
    local stderr = test_utils.read_file(stderr_path)
    test_utils.remove_temp_dir(directory)

    return {
        ok = not not ok,
        reason = reason,
        code = code,
        stdout = stdout,
        stderr = stderr,
        timed_out = reason == "exit" and code == 124,
    }
end

-- Poll an asynchronous state for at most three seconds.
function test_utils.eventually(callback, message)
    local last_error
    for _ = 1, test_utils.timeout * 10 do
        local ok, result = pcall(callback)
        if ok and result then return result end
        last_error = ok and "condition returned false" or result
        os.execute("/usr/bin/sleep 0.1")
    end
    error((message or "condition was not reached") .. ": " .. tostring(last_error), 2)
end

-- Return tests filtered and optionally shuffled by environment settings.
local function selected_tests(tests)
    local selected = {}
    local names = {}
    local filter = os.getenv("LUNAR_TEST_FILTER")

    for _, test in ipairs(tests) do
        assert(type(test.name) == "string" and test.name ~= "", "test name must not be empty")
        assert(not names[test.name], "duplicate test name: " .. test.name)
        names[test.name] = true
        if not filter or test.name:find(filter, 1, true) then
            selected[#selected + 1] = test
        end
    end

    local seed = tonumber(os.getenv("LUNAR_TEST_SEED"))
    if seed then
        math.randomseed(seed)
        for index = #selected, 2, -1 do
            local target = math.random(index)
            selected[index], selected[target] = selected[target], selected[index]
        end
        if not seed_reported then
            print("Test seed: " .. seed)
            seed_reported = true
        end
    end

    return selected
end

-- Run one suite and return structured failures to the complete runner.
function test_utils.run_suite(name, tests)
    tests = selected_tests(tests)
    local passed = 0
    local skipped_count = 0
    local failures = {}

    for index, test in ipairs(tests) do
        local ok, result, detail = pcall(test.run)

        for path in pairs(temporary_directories) do
            local cleanup_ok, cleanup_error = pcall(test_utils.remove_temp_dir, path)
            if not cleanup_ok and ok then
                ok = false
                result = cleanup_error
            end
        end

        if ok and result == skipped then
            skipped_count = skipped_count + 1
            print(string.format("[%d/%d] %s SKIPPED: %s", index, #tests, test.name, detail))
        elseif ok and result ~= false then
            passed = passed + 1
            print(string.format("[%d/%d] %s SUCCESS", index, #tests, test.name))
        else
            local err = ok and (detail or "test returned false") or result
            failures[#failures + 1] = {
                index = index,
                total = #tests,
                name = test.name,
                error = tostring(err):gsub("[\r\n]+", " "),
            }
            print(string.format("[%d/%d] %s FAILED: %s", index, #tests, test.name, failures[#failures].error))
        end
    end

    print(string.format(
        "%s summary: %d successful, %d skipped, %d failed",
        name,
        passed,
        skipped_count,
        #failures
    ))
    return #failures == 0, failures
end

return test_utils
