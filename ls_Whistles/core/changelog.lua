local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L

-- Lua
local _G = getfenv(0)

-- Mine
addon.CHANGELOG = [[
- Added 12.0.7 support.

### Adventure Guide

- Fixed an issue where the expansion dropdown would sometimes disappear. It's a Blizz bug.

### Tooltips

- Fixed an issue where the module would fail to enable without a reload.
]]
