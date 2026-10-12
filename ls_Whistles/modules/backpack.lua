local _, addon = ...
local C, D, L, LEM = addon.C, addon.D, addon.L, addon.LibEditMode
addon.Backpack = {}

-- Lua
local _G = getfenv(0)

-- Mine
local backpack_proto = {}
do
	local CURRENCY_COLON = _G.CURRENCY .. _G.HEADER_COLON
	local CURRENCY_TEMPLATE = "%s%s |T%s:0:0:0:0:64:64:4:60:4:60|t"
	local GOLD = _G.BONUS_ROLL_REWARD_MONEY
	local _, TOKEN_NAME = C_Item.GetItemInfoInstant(WOW_TOKEN_ITEM_ID)
	local TOKEN_COLOR = ITEM_QUALITY_COLORS[8]
	local TIMEOUT_ICON = ("|A:UI-Frame-DastardlyDuos-icon-Speed:0:0:0:0:%d:%d:%d|a "):format(D.global.colors.yellow:GetRGBAsBytes())

	local lastTokenUpdate = 0

	function backpack_proto:OnEnterHook()
		if KeybindFrames_InQuickKeybindMode() then return end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(CURRENCY_COLON)

		for i = 1, 10 do
			local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
			if info then
				info = C_CurrencyInfo.GetCurrencyInfo(info.currencyTypesID)
				if info then
					local color = _G.WHITE_FONT_COLOR
					local texture = ""
					local hasTotalCap, hasWeeklyCap = info.maxQuantity > 0, info.maxWeeklyQuantity > 0
					if hasTotalCap or hasWeeklyCap then
						local isTotalCapped = hasTotalCap and (info.useTotalEarnedForMaxQty and info.totalEarned or info.quantity) == info.maxQuantity or false
						local isWeeklyCapped = hasWeeklyCap and info.quanityEarnedThisWeek == info.maxWeeklyQuantity or false
						if isTotalCapped or isWeeklyCapped then
							color = D.global.colors.red
							texture = TIMEOUT_ICON
						else
							color = D.global.colors.green
						end
					end

					GameTooltip:AddDoubleLine(
						ITEM_QUALITY_COLORS[info.quality].color:WrapTextInColorCode(info.name),
						CURRENCY_TEMPLATE:format(texture, BreakUpLargeNumbers(info.quantity), info.iconFileID),
						1, 1, 1,
						color:GetRGB()
					)
				end
			end
		end

		GameTooltip:AddDoubleLine(GOLD, GetMoneyString(GetMoney(), true), 1, 1, 1, 1, 1, 1)

		local tokenPrice = C_WowTokenPublic.GetCurrentMarketPrice()
		if tokenPrice and tokenPrice > 0 then
			GameTooltip:AddDoubleLine(TOKEN_NAME, GetMoneyString(tokenPrice, true), TOKEN_COLOR.r, TOKEN_COLOR.g, TOKEN_COLOR.b, 1, 1, 1)
		elseif GetTime() - lastTokenUpdate > 300 then -- 300 is pollTimeSeconds = select(2, C_WowTokenPublic.GetCommerceSystemStatus())
			C_WowTokenPublic.UpdateMarketPrice()
		end

		GameTooltip:Show()
	end

	function backpack_proto:OnEventHook(event, ...)
		if event == "TOKEN_MARKET_PRICE_UPDATED" then
			lastTokenUpdate = GetTime()

			if ... == LE_TOKEN_RESULT_ERROR_DISABLED then
				return
			end

			if GameTooltip:IsOwned(self) then
				GameTooltip:Hide()

				self:GetScript("OnEnter")(self)
			end
		end
	end
end

local isInit = false

function addon.Backpack:IsInit()
	return isInit
end

function addon.Backpack:Init()
	if isInit then return end
	if not C.db.profile.backpack.enabled then return end

	Mixin(MainMenuBarBackpackButton, backpack_proto)

	MainMenuBarBackpackButton:HookScript("OnEnter", MainMenuBarBackpackButton.OnEnterHook)
	MainMenuBarBackpackButton:HookScript("OnEvent", MainMenuBarBackpackButton.OnEventHook)
	MainMenuBarBackpackButton:RegisterEvent("TOKEN_MARKET_PRICE_UPDATED")

	local function layoutCallback(layoutName)
		-- AceDB takes care of layout table duplication
		local layout = C.db.profile.backpack.layouts[layoutName]

		addon.Backpack:UpdateFading()
	end

	function addon.Backpack:UpdateLayoutSettings()
		layoutCallback(LEM:GetActiveLayoutName())
	end

	LEM:RegisterCallback("layout", layoutCallback)

	LEM:AddSystemSettings(Enum.EditModeSystem.Bags, {
		{
			name = L["FADING"],
			kind = LEM.SettingType.Divider,
			hidden = function()
				return not C.db.global.settings.backpack.fade
			end,
		},
		{
			name = _G.ENABLE,
			kind = LEM.SettingType.Checkbox,
			hidden = function()
				return not C.db.global.settings.backpack.fade
			end,
			default = D.profile.backpack.layouts["*"].fade.enabled,
			get = function(layoutName)
				return C.db.profile.backpack.layouts[layoutName].fade.enabled
			end,
			set = function(layoutName, value)
				if C.db.profile.backpack.layouts[layoutName].fade.enabled ~= value then
					C.db.profile.backpack.layouts[layoutName].fade.enabled = value

					addon.Backpack:UpdateFading()
				end
			end,
		},
		{
			name = _G.COMBAT,
			desc = L["FADING_COMBAT_DESC"],
			kind = LEM.SettingType.Checkbox,
			hidden = function()
				return not C.db.global.settings.backpack.fade
			end,
			disabled = function(layoutName)
				return not C.db.profile.backpack.layouts[layoutName].fade.enabled
			end,
			default = D.profile.backpack.layouts["*"].fade.combat,
			get = function(layoutName)
				return C.db.profile.backpack.layouts[layoutName].fade.combat
			end,
			set = function(layoutName, value)
				if C.db.profile.backpack.layouts[layoutName].fade.combat ~= value then
					C.db.profile.backpack.layouts[layoutName].fade.combat = value

					addon.Backpack:UpdateFading()
				end
			end,
		},
		{
			name = _G.TARGET,
			desc = L["FADING_TARGET_DESC"],
			kind = LEM.SettingType.Checkbox,
			hidden = function()
				return not C.db.global.settings.backpack.fade
			end,
			disabled = function(layoutName)
				return not C.db.profile.backpack.layouts[layoutName].fade.enabled
			end,
			default = D.profile.backpack.layouts["*"].fade.target,
			get = function(layoutName)
				return C.db.profile.backpack.layouts[layoutName].fade.target
			end,
			set = function(layoutName, value)
				if C.db.profile.backpack.layouts[layoutName].fade.target ~= value then
					C.db.profile.backpack.layouts[layoutName].fade.target = value

					addon.Backpack:UpdateFading()
				end
			end,
		},
		{
			name = L["MIN_ALPHA"],
			kind = LEM.SettingType.Slider,
			hidden = function()
				return not C.db.global.settings.backpack.fade
			end,
			disabled = function(layoutName)
				return not C.db.profile.backpack.layouts[layoutName].fade.enabled
			end,
			default = D.profile.backpack.layouts["*"].fade.min_alpha,
			get = function(layoutName)
				return C.db.profile.backpack.layouts[layoutName].fade.min_alpha
			end,
			set = function(layoutName, value)
				if C.db.profile.backpack.layouts[layoutName].fade.min_alpha ~= value then
					C.db.profile.backpack.layouts[layoutName].fade.min_alpha = value

					addon.Backpack:UpdateFading()
				end
			end,
			formatter = function(value)
				return _G.PERCENTAGE_STRING:format(value * 100)
			end,
			minValue = 0,
			maxValue = 1,
			valueStep = 0.05,
		},
		{
			name = "DNT Fade Settings Expander",
			kind = LEM.SettingType.Expander,
			expandedLabel = L["COLLAPSE_OPTIONS"],
			collapsedLabel = L["FADING"],
			appendArrow = true,
			default = D.global.settings["**"].fade,
			get = function()
				return C.db.global.settings.backpack.fade
			end,
			set = function(_, value)
				C.db.global.settings.backpack.fade = value
			end,
		},
	})

	isInit = true
end

function addon.Backpack:UpdateFading()
	local config = addon:GetBackpackLayout()
	if config.fade.enabled then
		if config.fade.combat then
			addon.Fader:WatchCombat(BagsBar, config.fade.min_alpha)
		else
			addon.Fader:UnwatchCombat(BagsBar)
		end

		if config.fade.target then
			addon.Fader:WatchTarget(BagsBar, config.fade.min_alpha)
		else
			addon.Fader:UnwatchTarget(BagsBar)
		end

		if addon.Fader:CanHover(BagsBar) then
			addon.Fader:WatchHover(BagsBar, config.fade.min_alpha)
		end
	else
		addon.Fader:UnwatchCombat(BagsBar)
		addon.Fader:UnwatchTarget(BagsBar)
		addon.Fader:UnwatchHover(BagsBar)
	end
end

-- a stub
function addon.Backpack:UpdateLayoutSettings()
end
