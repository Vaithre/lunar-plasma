-- Notification API
-- Send desktop notifications through the system notification server.

local notification = {}
local utils = require("plasma.utils")

local notification_types = {
    info = true,
    warning = true,
    error = true,
    success = true,
}

-- Validate required notification text.
local function validate_required_text(value, name)
    if type(value) ~= "string" or value == "" then
        return nil, name .. " must be a non-empty string"
    end

    return value
end

-- Validate optional notification text.
local function validate_optional_text(value, name)
    if value == nil then
        return ""
    end

    if type(value) ~= "string" then
        return nil, name .. " must be a string"
    end

    return value
end

-- Create a notification API connected to a backend script.
function notification.new(backend)
    local instance = {}

    -- Send a notification.
    function instance.send(options)
        if type(options) ~= "table" then
            return nil, "options must be a table"
        end

        local title, err = validate_required_text(options.title, "title")
        if not title then
            return nil, err
        end

        local text
        text, err = validate_required_text(options.text, "text")
        if not text then
            return nil, err
        end

        local icon
        icon, err = validate_optional_text(options.icon, "icon")
        if not icon then
            return nil, err
        end

        local sound
        sound, err = validate_optional_text(options.sound, "sound")
        if not sound then
            return nil, err
        end

        local timeout = options.timeout == nil and -1 or tonumber(options.timeout)
        if not timeout or timeout % 1 ~= 0 or timeout < -1 then
            return nil, "timeout must be an integer greater than or equal to -1"
        end

        local notification_type = options.type or "info"
        if not notification_types[notification_type] then
            return nil, "type must be info, warning, error, or success"
        end

        local command = table.concat({
            utils.shell_quote(backend),
            "send",
            utils.shell_quote(title),
            utils.shell_quote(text),
            utils.shell_quote(icon),
            utils.shell_quote(sound),
            tostring(timeout),
            utils.shell_quote(notification_type),
        }, " ")

        local ok, _, code = os.execute(command)
        if not ok then
            return nil, "notifications backend failed with exit code " .. tostring(code)
        end

        return true
    end

    return instance
end

return notification
