-- Shared backend process runner.
-- Execute Bash backends with consistent quoting, errors, and operation timeouts.

local backend = {}
local utils = require("plasma.utils")

local default_timeout = 3
local source = debug.getinfo(1, "S").source:sub(2)
local project_root = source:match("^(.*)/lua/plasma/backend%.lua$") or "."
local default_runner = project_root .. "/scripts/backend-runner.sh"

-- Validate one timeout in seconds.
local function validate_timeout(value, name)
    value = tonumber(value)

    if not value or value % 1 ~= 0 or value < 1 then
        error(name .. " must be a positive integer", 3)
    end

    return value
end

-- Build the wrapper command for one backend operation.
local function build_command(runner, timeout, path, action, arguments)
    local command = table.concat({
        utils.shell_quote(runner),
        tostring(timeout),
        utils.shell_quote(path),
        utils.shell_quote(action),
    }, " ")

    for _, argument in ipairs(arguments or {}) do
        command = command .. " " .. utils.shell_quote(argument)
    end

    return command
end

-- Create a process client for one backend script.
function backend.new(path, name, options)
    if type(path) ~= "string" or path == "" then
        error("backend path must be a non-empty string", 2)
    end

    if type(name) ~= "string" or name == "" then
        error("backend name must be a non-empty string", 2)
    end

    options = options or {}
    if type(options) ~= "table" then
        error("backend options must be a table", 2)
    end

    local runner = options.runner or default_runner
    if type(runner) ~= "string" or runner == "" then
        error("backend runner path must be a non-empty string", 2)
    end

    local standard_timeout = validate_timeout(
        options.timeout or default_timeout,
        "backend timeout"
    )
    local configured_timeouts = options.timeouts or {}
    if type(configured_timeouts) ~= "table" then
        error("backend operation timeouts must be a table", 2)
    end

    local operation_timeouts = {}
    for action, timeout in pairs(configured_timeouts) do
        if type(action) ~= "string" or action == "" then
            error("backend timeout action must be a non-empty string", 2)
        end
        operation_timeouts[action] = validate_timeout(
            timeout,
            "backend timeout for " .. action
        )
    end

    local instance = {}

    -- Resolve the configured timeout for one operation.
    local function timeout_for(action)
        return operation_timeouts[action] or standard_timeout
    end

    -- Execute one operation and capture its relevant output.
    local function run(action, arguments)
        if type(action) ~= "string" or action == "" then
            return nil, "backend action must be a non-empty string"
        end

        if arguments ~= nil and type(arguments) ~= "table" then
            return nil, "backend arguments must be a table"
        end

        local timeout = timeout_for(action)
        local command = build_command(runner, timeout, path, action, arguments)
        local process = io.popen(command .. " 2>&1")
        if not process then
            return nil, "could not start the " .. name .. " backend"
        end

        local response = process:read("*a")
        process:close()

        local code, output = response:match("^(%d+)%z(.*)$")
        code = tonumber(code)

        if not code then
            local detail = response:match("^%s*(.-)%s*$")
            detail = detail ~= "" and ": " .. detail or ""
            return nil, name .. " backend runner returned an invalid response" .. detail
        end

        if code ~= 0 then
            if code == 124 then
                return nil, string.format(
                    "%s backend timed out after %d second%s",
                    name,
                    timeout,
                    timeout == 1 and "" or "s"
                )
            end

            local detail = output:match("^%s*(.-)%s*$")
            detail = detail ~= "" and ": " .. detail or ""
            return nil, string.format(
                "%s backend failed with exit code %s%s",
                name,
                tostring(code),
                detail
            )
        end

        return output
    end

    -- Execute an operation without returning its output.
    function instance.execute(action, arguments)
        local output, err = run(action, arguments)
        if not output then
            return nil, err
        end

        return true
    end

    -- Execute an operation and return its standard output.
    function instance.read(action, arguments)
        return run(action, arguments)
    end

    return instance
end

return backend
