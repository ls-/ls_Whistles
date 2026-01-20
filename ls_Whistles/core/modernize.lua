local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L

-- Lua
local _G = getfenv(0)

-- Mine
function addon:Modernize(data, name, key)
	if not data.version then return end

	if key == "profile" then

	end
end
