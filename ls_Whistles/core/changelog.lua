local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L

-- Lua
local _G = getfenv(0)

-- Mine
addon.CHANGELOG = [[
- Added 12.1.5 support.

### Backpack

- Reworked the tooltip. Removed the cap info because most currencies have multiple caps like weekly, seasonal, and total. Instead the addon will indicate if you maxed out a currency via colour and an icon.

### Widgets

- Added the module. For now it just adds a mover for the zone status indicator in Edit Mode. It's the widget that shows invasion, incursion, etc timers and info.
]]
