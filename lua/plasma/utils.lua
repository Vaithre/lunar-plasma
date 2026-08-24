-- Shared helpers for Plasma-backed APIs.
-- There are still functions that could be moved here BUT they have a certain
-- complexity that would need extra parameters and might lose the value gained
-- by moving them to this sublibrary.

local utils = {}

-- Turn a value into a quoted string for Bash, avoiding injection or malformed
-- input.
function utils.shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

-- Convert text returned by some backend operations into a valid boolean.
function utils.parse_boolean(value)
    if value == "true" then
        return true
    end

    if value == "false" then
        return false
    end

    return nil
end

-- Split text into a table of tab-separated fields, useful for parsing backend
-- output.
function utils.split_fields(line)
    local fields = {}

    for field in (line .. "\t"):gmatch("(.-)\t") do
        fields[#fields + 1] = field
    end

    return fields
end

-- Convert a KDE Plasma screen identifier into a number. For example, if
-- DVI-D-1 is screen number "1", return that number. I'm still not sure how
-- useful this is when one already has the exact tag, but more options are not
-- bad either.
function utils.resolve_plasma_screen(read_backend, display)
    if type(display) ~= "string" then
        return display
    end

    local output, err = read_backend("screen-for-connector", { display })
    if not output then
        return nil, err
    end

    local plasma_screen = tonumber(output:match("^%s*(%-?%d+)%s*$"))
    if not plasma_screen or plasma_screen % 1 ~= 0 or plasma_screen < 0 then
        return nil, "desktop backend returned an invalid Plasma screen"
    end

    return plasma_screen + 1
end

return utils
