-- Public entry point for Lunar Plasma

-- Find the library root from this file's location
local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*)/lunar%-plasma%.lua$") or "."

-- Add the internal Lua modules to the search path
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

-- Load the sound API and give it its backend
local sound = require("plasma.sound")

-- Expose the public API
return {
    sound = sound.new(root .. "/scripts/sound.sh"),
}
