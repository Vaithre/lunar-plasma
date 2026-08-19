-- Sound API
-- Control the default output and read its current state.

local sound = {}

-- Create a sound API connected to a backend script.
function sound.new(backend)
    local instance = {}

    local function validate_percentage(value, name)
        value = tonumber(value)

        if not value or value % 1 ~= 0 or value < 0 or value > 100 then
            return nil, name .. " must be an integer between 0 and 100"
        end

        return value
    end

    local function execute_backend(action, value)
        local command = string.format("%q %q", backend, action)

        if value ~= nil then
            command = command .. string.format(" %d", value)
        end

        local ok, _, code = os.execute(command)
        if not ok then
            return nil, "sound backend failed with exit code " .. tostring(code)
        end

        return true
    end

    local function read_backend(action)
        local process = io.popen(string.format("%q %q", backend, action))
        if not process then
            return nil, "could not start the sound backend"
        end

        local output = process:read("*a"):match("^%s*(.-)%s*$")
        local ok, _, code = process:close()

        if not ok then
            return nil, "sound backend failed with exit code " .. tostring(code)
        end

        return output
    end

    -- Set the default output volume from 0 to 100.
    function instance.set(value)
        local validated, err = validate_percentage(value, "volume")
        if not validated then
            return nil, err
        end

        return execute_backend("set", validated)
    end

    -- Get the default output volume.
    function instance.get()
        local output, err = read_backend("get")
        if not output then
            return nil, err
        end

        local value = tonumber(output)
        if not value then
            return nil, "sound backend returned an invalid volume"
        end

        return value
    end

    -- Mute the default output.
    function instance.mute()
        return execute_backend("mute")
    end

    -- Unmute the default output.
    function instance.unmute()
        return execute_backend("unmute")
    end

    -- Check whether the default output is muted.
    function instance.is_muted()
        local output, err = read_backend("is-muted")
        if not output then
            return nil, err
        end

        if output == "true" then
            return true
        end

        if output == "false" then
            return false
        end

        return nil, "sound backend returned an invalid mute state"
    end

    -- Toggle the mute state of the default output.
    function instance.toggle_mute()
        return execute_backend("toggle-mute")
    end

    -- Increase the default output volume without exceeding 100.
    function instance.increase(amount)
        local validated, err = validate_percentage(amount, "amount")
        if not validated then
            return nil, err
        end

        local current
        current, err = instance.get()
        if not current then
            return nil, err
        end

        return instance.set(math.min(100, current + validated))
    end

    -- Decrease the default output volume without going below zero.
    function instance.decrease(amount)
        local validated, err = validate_percentage(amount, "amount")
        if not validated then
            return nil, err
        end

        local current
        current, err = instance.get()
        if not current then
            return nil, err
        end

        return instance.set(math.max(0, current - validated))
    end

    return instance
end

return sound
