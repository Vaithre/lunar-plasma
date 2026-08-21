-- Shared helpers for Plasma-backed APIs.

local utils = {}

-- Resolve a connector name to Plasma's one-based screen index.
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
