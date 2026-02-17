local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L

-- Lua
local _G = getfenv(0)

-- Mine
addon.CHANGELOG = [[
### Action Bars

- Added a set of options to adjust the usable equipment highlight. It's the green highlight you see for usable trinkets and stuff like that. Can be found in the advanced options.

### Adventure Guide

- Fixed an issue where opening the suggested content frame while in combat could result in an error.

### Character Frame

- Fixed an issue where ilvl colouring wouldn't apply on the initial login.
]]
