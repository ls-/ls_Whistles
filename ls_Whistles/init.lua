local addonName, addon = ...
local C, D, L = addon.C, addon.D, addon.L

-- Lua
local _G = getfenv(0)
local next = _G.next
local tonumber = _G.tonumber

-- Mine
addon.VER = {}
addon.VER.string = C_AddOns.GetAddOnMetadata(addonName, "Version")
addon.VER.number = tonumber(addon.VER.string:gsub("%D", ""), nil)

addon.PLAYER_CLASS = UnitClassBase("player")

addon:RegisterEvent("ADDON_LOADED", function(arg1)
	if arg1 ~= addonName then return end

	if LS_WHISTLES_GLOBAL_CONFIG then
		if LS_WHISTLES_GLOBAL_CONFIG.profiles then
			for profile, data in next, LS_WHISTLES_GLOBAL_CONFIG.profiles do
				addon:Modernize(data, profile, "profile")
			end
		end
	end

	C.db = LibStub("AceDB-3.0"):New("LS_WHISTLES_GLOBAL_CONFIG", D, true)

	addon.ActionBars:Init()
	addon.Backpack:Init()
	addon.CharacterFrame:Init()
	addon.GameMenu:Init()
	addon.InspectFrame:Init()
	addon.JourneyFrame:Init()
	addon.LootFrame:Init()
	addon.Mail:Init()
	addon.MicroMenu:Init()
	addon.SuggestFrame:Init()

	addon:CreateAceConfig()
	addon:CreateBlizzConfig()

	AddonCompartmentFrame:RegisterAddon({
		text = L["LS_WHISTLES"],
		icon = "Interface\\AddOns\\ls_Whistles\\assets\\logo-32",
		func = function()
			if IsShiftKeyDown() then
				if not addon.OpenAceConfig then
					addon:CreateAceConfig()
				end

				addon:OpenAceConfig()
			else
				addon:OpenBlizzConfig()
			end
		end,
		funcOnEnter = function(button)
			GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:AddLine(L["AC_TOOLTIP"], 1, 1, 1)
			GameTooltip:Show()
		end,
		funcOnLeave = function()
			GameTooltip:Hide()
		end,
	})

	addon:RegisterEvent("PLAYER_LOGIN", function()
	end)
end)
