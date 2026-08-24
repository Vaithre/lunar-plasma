-- Sound API
-- Control the default output and read its current state.

local sound = {}
local utils = require("plasma.utils")

-- Create a sound API connected to a backend script.
function sound.new(backend)
    local instance = {}

    -- Ensure values are integers between 0 and 100. KDE Plasma can go beyond
    -- those limits, but I do not know if I want to deal with that...
    local function validate_percentage(value, name)
        value = tonumber(value)

        if not value or value % 1 ~= 0 or value < 0 or value > 100 then
            return nil, name .. " must be an integer between 0 and 100"
        end

        return value
    end

    -- Run a backend action with an optional numeric argument without capturing
    -- its output.
    local function execute_backend(action, value)
        local command = utils.shell_quote(backend) .. " " .. utils.shell_quote(action)

        if value ~= nil then
            command = command .. string.format(" %d", value)
        end

        local ok, _, code = os.execute(command)
        if not ok then
            return nil, "sound backend failed with exit code " .. tostring(code)
        end

        return true
    end

    -- Run a backend action and return its standard output.
    local function read_backend(action)
        local process = io.popen(utils.shell_quote(backend) .. " " .. utils.shell_quote(action))
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
    function instance.set_volume(value)
        local validated, err = validate_percentage(value, "volume")
        if not validated then
            return nil, err
        end

        return execute_backend("set", validated)
    end

    -- Get the default output volume.
    function instance.get_volume()
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

    -- Increase the default output volume.
    function instance.increase_volume(amount)
        local validated, err = validate_percentage(amount, "amount")
        if not validated then
            return nil, err
        end

        local current
        current, err = instance.get_volume()
        if not current then
            return nil, err
        end

        return instance.set_volume(math.min(100, current + validated))
    end

    -- Decrease the default output volume.
    function instance.decrease_volume(amount)
        local validated, err = validate_percentage(amount, "amount")
        if not validated then
            return nil, err
        end

        local current
        current, err = instance.get_volume()
        if not current then
            return nil, err
        end

        return instance.set_volume(math.max(0, current - validated))
    end

    return instance
end

return sound
