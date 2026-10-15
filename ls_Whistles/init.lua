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

local function updateCallback()
	addon.ActionBars:UpdateLayoutSettings()
	addon.Backpack:UpdateLayoutSettings()
	addon.MicroMenu:UpdateLayoutSettings()
	addon.WidgetContainers:UpdateLayoutSettings()

	addon:AskToReloadUI("profile")
end

local function shutdownCallback()
	C.db.profile.version = addon.VER.number
end

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
	C.db:RegisterCallback("OnProfileChanged", updateCallback)
	C.db:RegisterCallback("OnProfileCopied", updateCallback)
	C.db:RegisterCallback("OnProfileReset", updateCallback)
	C.db:RegisterCallback("OnProfileShutdown", shutdownCallback)
	C.db:RegisterCallback("OnDatabaseShutdown", shutdownCallback)

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
	addon.Tooltips:Init()
	addon.WidgetContainers:Init()

	addon:CreateImportExport()
	addon:CreateBlizzConfig()
	addon:CreateAceConfig()

	AddonCompartmentFrame:RegisterAddon({
		text = L["ADDON_NAME"],
		icon = "Interface\\AddOns\\ls_Whistles\\assets\\logo-32",
		func = function()
			if IsShiftKeyDown() then
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
