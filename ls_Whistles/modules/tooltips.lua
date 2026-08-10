local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.Tooltips = {}

-- Lua
local _G = getfenv(0)
local unpack = _G.unpack

-- Mine
local EXPANSION = "|cffffd200" .. _G.EXPANSION_FILTER_TEXT .. _G.HEADER_COLON .. "|r %s"
local ID = "|cffffd200" .. _G.ID .. _G.HEADER_COLON .. "|r %d"
local TOTAL = "|cffffd200" .. _G.TOTAL .. _G.HEADER_COLON .. "|r %d"
local TOTAL_DETAILED = TOTAL .. " |cff888987(%d + %d)|r"

local GOOD_TOOLTIPS = {
	[GameTooltip] = true,
	[GameTooltipTooltip] = true,
	[ItemRefTooltip] = true,
}

local isInit = false

function addon.Tooltips:IsInit()
	return isInit
end

function addon.Tooltips:Init()
	if isInit then return end
	if not C.db.profile.tooltips.enabled then return end

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tooltip, data)
		if not GOOD_TOOLTIPS[tooltip] or tooltip:IsForbidden() then return end
		if not C.db.profile.tooltips.id then return end

		local id = data.id
		if id then
			tooltip:AddLine(ID:format(id), 1, 1, 1)
		end
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
		if not GOOD_TOOLTIPS[tooltip] or tooltip:IsForbidden() then return end
		if not C.db.profile.tooltips.id then return end

		local id = data.id
		if id then
			local textRight
			if C.db.profile.tooltips.count then
				local inBags = C_Item.GetItemCount(id)
				local total = C_Item.GetItemCount(id, true, false, true, true)
				local inBanks = total - inBags
				if inBanks > 0 then
					textRight = TOTAL_DETAILED:format(total, inBags, inBanks)
				else
					textRight = TOTAL:format(total)
				end
			end

			tooltip:AddLine(" ")
			tooltip:AddDoubleLine(ID:format(id), textRight or "", 1, 1, 1, 1, 1, 1)

			local _, _, _, _, _, _, _, _, _, _, _, _, _, _, expacID = C_Item.GetItemInfo(id)
			if expacID and expacID > 0 then
				local text = _G["EXPANSION_NAME" .. expacID]
				if text then
					tooltip:AddLine(EXPANSION:format(text), 1, 1, 1)
				end
			end
		end
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
		if not GOOD_TOOLTIPS[tooltip] or tooltip:IsForbidden() then return end
		if not C.db.profile.tooltips.id then return end

		local id = data.id
		if id then
			tooltip:AddLine(" ")
			tooltip:AddLine(ID:format(id), 1, 1, 1)
		end
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Macro, function(tooltip, data)
		if not GOOD_TOOLTIPS[tooltip] or tooltip:IsForbidden() then return end
		if not C.db.profile.tooltips.id then return end

		local id = data.lines[1].tooltipID
		if id then
			tooltip:AddLine(" ")
			tooltip:AddLine(ID:format(id), 1, 1, 1)
		end
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, function(tooltip, data)
		if not GOOD_TOOLTIPS[tooltip] or tooltip:IsForbidden() then return end
		if not C.db.profile.tooltips.id then return end

		local id = data.id
		if id then
			tooltip:AddLine(" ")
			tooltip:AddLine(ID:format(id), 1, 1, 1)
		end
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Toy, function(tooltip, data)
		if tooltip ~= GameTooltip or tooltip:IsForbidden() then return end
		if not C.db.profile.tooltips.id then return end

		local id = data.id
		if id then
			if data.lines[#data.lines].type ~= Enum.TooltipDataLineType.ToySource then
				tooltip:AddLine(" ")
			end

			tooltip:AddLine(ID:format(id), 1, 1, 1)
		end
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Achievement, function(tooltip, data)
		if not GOOD_TOOLTIPS[tooltip] or tooltip:IsForbidden() then return end
		if not C.db.profile.tooltips.id then return end

		local id = data.id
		if id then
			tooltip:AddLine(" ")
			tooltip:AddLine(ID:format(id), 1, 1, 1)
		end
	end)

	-- keep it in case I need it in the future
	-- local mountGetterToAPI = {
	-- 	["GetAction"] = function(...)
	-- 		return C_ActionBar.GetSpell(unpack(...))
	-- 	end,
	-- 	["GetMountBySpellID"] = function(...)
	-- 		return unpack(...)
	-- 	end,
	-- }

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Mount, function(tooltip, data)
		if not GOOD_TOOLTIPS[tooltip] or tooltip:IsForbidden() then return end
		if not C.db.profile.tooltips.id then return end

		-- local id
		-- local processor = mountGetterToAPI[tooltip.processingInfo.getterName]
		-- if processor then
		-- 	id = processor(tooltip.processingInfo.getterArgs)
		-- else
		-- 	print("Mount: |cffffd200", tooltip.processingInfo.getterName, "|r")
		-- 	print("getterArgs:")
		-- 	DevTools_Dump({tooltip.processingInfo.getterArgs})
		-- end

		local id = data.lines[1].tooltipID
		if id then
			tooltip:AddLine(" ")
			tooltip:AddLine(ID:format(id), 1, 1, 1)
		end
	end)

	local petGetterToAPI = {
		["GetAction"] = function(...)
			local _, petGUID = GetActionInfo(unpack(...))
			local _, _, _, _, _, _, _, _, _, _, id = C_PetJournal.GetPetInfoByPetID(petGUID)
			return id
		end,
		["GetCompanionPet"] = function(...)
			local _, _, _, _, _, _, _, _, _, _, id = C_PetJournal.GetPetInfoByPetID(unpack(...))
			return id
		end,
	}

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.CompanionPet, function(tooltip)
		if not GOOD_TOOLTIPS[tooltip] or tooltip:IsForbidden() then return end
		if not C.db.profile.tooltips.id then return end

		local id
		local processor = petGetterToAPI[tooltip.processingInfo.getterName]
		if processor then
			id = processor(tooltip.processingInfo.getterArgs)
		-- else
		-- 	print("CompanionPet: |cffffd200", tooltip.processingInfo.getterName, "|r")
		-- 	print("getterArgs:")
		-- 	DevTools_Dump({tooltip.processingInfo.getterArgs})
		end

		if id then
			tooltip:AddLine(" ")
			tooltip:AddLine(ID:format(id), 1, 1, 1)
		end
	end)

	isInit = true
end
