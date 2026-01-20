local _, addon = ...

-- Lua
local _G = getfenv(0)
local error = _G.error
local next= _G.next
local pcall = _G.pcall
local s_format = _G.string.format
local t_insert = _G.table.insert
local type = _G.type
local t_wipe = _G.table.wipe
local tonumber = _G.tonumber

-- Mine
local C, D, L = {}, {}, {}
addon.C, addon.D, addon.L = C, D, L

------------
-- EVENTS --
------------

do
	local oneTimeEvents = {ADDON_LOADED = false, PLAYER_LOGIN = false}
	local registeredEvents = {}

	local dispatcher = CreateFrame("Frame", "LSWhistlesEventFrame")
	dispatcher:SetScript("OnEvent", function(_, event, ...)
		for _, func in next, registeredEvents[event] do
			func(...)
		end

		if oneTimeEvents[event] == false then
			oneTimeEvents[event] = true
		end
	end)

	function addon:RegisterEvent(event, func)
		if oneTimeEvents[event] then
			error(s_format("Failed to register for '%s' event, already fired!", event), 3)
		end

		if not func or type(func) ~= "function" then
			error(s_format("Failed to register for '%s' event, no handler!", event), 3)
		end

		if not registeredEvents[event] then
			registeredEvents[event] = {}

			dispatcher:RegisterEvent(event)
		end

		if not tContains(registeredEvents[event], func) then
			t_insert(registeredEvents[event], func)
		end
	end

	function addon:UnregisterEvent(event, func)
		local funcs = registeredEvents[event]
		if funcs then
			tDeleteItem(funcs, func)

			if #funcs == 0 then
				dispatcher:UnregisterEvent(event)
			end
		end
	end
end

----------
-- MISC --
----------

do
	local hiddenFrame = CreateFrame("Frame", nil, UIParent)
	hiddenFrame:Hide()

	function addon:ForceHide(object)
		if not object then return end

		-- EditMode bs
		if object.HideBase then
			object:HideBase(true)
		else
			object:Hide(true)
		end

		if object.EnableMouse then
			object:EnableMouse(false)
		end

		if object.UnregisterAllEvents then
			object:UnregisterAllEvents()
			object:SetAttribute("statehidden", true)
		end

		if object.SetUserPlaced then
			pcall(object.SetUserPlaced, object, true)
			pcall(object.SetDontSavePosition, object, true)
		end

		object:SetParent(hiddenFrame)
	end
end

-------------
-- COLOURS --
-------------

do
	local color_proto = {}

	function color_proto:GetHex()
		return self.hex
	end

	-- function color_proto:GenerateHexColor()
	-- 	return self.hex
	-- end

	-- override ColorMixin:GetRGBA
	function color_proto:GetRGBA(a)
		return self.r, self.g, self.b, a or self.a
	end

	function addon:CreateColor(r, g, b, a)
		if r > 1 or g > 1 or b > 1 then
			r, g, b = r / 255, g / 255, b / 255
		end

		local color = Mixin({}, ColorMixin, color_proto)
		color:SetRGBA(r, g, b, a)

		-- do not override SetRGBA, so calculate hex separately
		color.hex = color:GenerateHexColor()
		-- color.hex = C_ColorUtil.GenerateTextColorCode(color)

		return color
	end
end

do
	local rygColorCurve

	function addon:GetRYGColor(perc, needUnpack)
		if not rygColorCurve then
			rygColorCurve = C_CurveUtil.CreateColorCurve()
			for x, color in next, D.global.colors.ryg do
				rygColorCurve:AddPoint(x, color)
			end
		end

		if needUnpack then
			return rygColorCurve:EvaluateUnpacked(perc)
		else
			return rygColorCurve:Evaluate(perc)
		end
	end

	local gyrColorCurve

	function addon:GetGYRColor(perc, needUnpack)
		if not gyrColorCurve then
			gyrColorCurve = C_CurveUtil.CreateColorCurve()
			for x, color in next, D.global.colors.gyr do
				gyrColorCurve:AddPoint(x, color)
			end
		end

		if needUnpack then
			return gyrColorCurve:EvaluateUnpacked(perc)
		else
			return gyrColorCurve:Evaluate(perc)
		end
	end
end


-----------
-- ITEMS --
-----------

do
	local ILVL_LINE = Enum.TooltipDataLineType.ItemLevel
	local ILVL_PATTERN = "(%d+)"
	local UPGRADE_LINE = Enum.TooltipDataLineType.ItemUpgradeLevel
	local UPGRADE_PATTERN = _G.ITEM_UPGRADE_TOOLTIP_FORMAT_STRING:gsub("([:：]).+", "%1(.+)")
	local ENCHANT_LINE = Enum.TooltipDataLineType.ItemEnchantmentPermanent
	local ENCHANT_PATTERN = _G.ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)")
	local ENCHANT_QUALITY_PATTERN = "|A.+|a"
	local GEM_LINE = Enum.TooltipDataLineType.GemSocket
	local SOCKET_TEMPLATE = "Interface\\ItemSocketingFrame\\UI-EmptySocket-%s"

	local dataCache = {}
	local itemCache = {}

	function addon:GetDetailedItemInfo(itemLink)
		if itemCache[itemLink] then
			return itemCache[itemLink].ilvl, itemCache[itemLink].upgrade, itemCache[itemLink].enchant, itemCache[itemLink].gem1, itemCache[itemLink].gem2, itemCache[itemLink].gem3
		end

		local data = C_TooltipInfo.GetHyperlink(itemLink, nil, nil, true)
		if not data then return nil, nil, nil, nil, nil, nil end

		local ilvl, upgrade, enchant, gems, gemIndex = nil, nil, nil, {}, 1
		for _, line in next, data.lines do
			if line.type == ILVL_LINE then
				ilvl = line.leftText:match(ILVL_PATTERN)
				if ilvl then
					ilvl = ilvl:trim()
				end
			elseif line.type == UPGRADE_LINE then
				upgrade = line.leftText:match(UPGRADE_PATTERN)
				if upgrade then
					upgrade = upgrade:trim()
				end
			elseif line.type == ENCHANT_LINE then
				enchant = line.leftText:match(ENCHANT_PATTERN)
				if enchant then
					enchant = enchant:gsub(ENCHANT_QUALITY_PATTERN, "")
					if enchant then
						enchant = enchant:trim()
					end
				end
			elseif line.type == GEM_LINE then
				-- sidestep caching
				local gemID = C_Item.GetItemGemID(itemLink, gemIndex)
				if gemID then
					local _, _, _, _, icon = C_Item.GetItemInfoInstant(gemID)
					gems[gemIndex] = icon
				else
					gems[gemIndex] = SOCKET_TEMPLATE:format(line.socketType)
				end

				gemIndex = gemIndex + 1
			end
		end

		dataCache[data.dataInstanceID] = itemLink

		itemCache[itemLink] = {
			ilvl = ilvl,
			upgrade = upgrade,
			enchant = enchant,
			gem1 = gems[1],
			gem2 = gems[2],
			gem3 = gems[3],
		}

		return ilvl, upgrade, enchant, gems[1], gems[2], gems[3]
	end

	local wipeTimer

	local function wiper()
		t_wipe(dataCache)
	end

	addon:RegisterEvent("TOOLTIP_DATA_UPDATE", function(dataInstanceID)
		local itemLink = dataCache[dataInstanceID]
		if itemLink then
			itemCache[itemLink] = nil
			dataCache[dataInstanceID] = nil

			if not wipeTimer then
				wipeTimer = C_Timer.NewTimer(5, wiper)
			else
				wipeTimer:Cancel()

				wipeTimer = C_Timer.NewTimer(5, wiper)
			end
		end
	end)
end

do
	local ILVL_STEP = 13 -- the ilvl step between content difficulties
	local iLvlColorCurve

	function addon:GetItemLevelColor(itemLevel, avgItemLevel)
		if not iLvlColorCurve then
			iLvlColorCurve = C_CurveUtil.CreateColorCurve()
			for x, color in next, D.global.colors.ilvl do
				iLvlColorCurve:AddPoint(x, color)
			end
		end

		itemLevel = tonumber(itemLevel or "") or 0

		-- if an item is worse than the average ilvl by one full step, it's really bad
		return iLvlColorCurve:EvaluateUnpacked((itemLevel - avgItemLevel + ILVL_STEP) / ILVL_STEP)
	end
end
