local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L

-- Lua
local _G = getfenv(0)

-- Mine
addon.CHANGELOG = [[
- Added 12.1.0 support.

### Tooltips

- Removed caster names from aura tooltips. This info is no longer available to addons when it
  actually matters.
]]
