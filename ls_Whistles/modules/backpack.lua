local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.Backpack = {}

-- Lua
local _G = getfenv(0)

-- Mine
local backpack_proto = {}
do
	local CURRENCY_COLON = _G.CURRENCY .. _G.HEADER_COLON
	local CURRENCY_DETAILED_TEMPLATE = "%s / %s|T%s:0:0:0:0:64:64:4:60:4:60|t"
	local CURRENCY_TEMPLATE = "%s |T%s:0:0:0:0:64:64:4:60:4:60|t"
	local GOLD = _G.BONUS_ROLL_REWARD_MONEY
	local _, TOKEN_NAME = C_Item.GetItemInfoInstant(WOW_TOKEN_ITEM_ID)
	local TOKEN_COLOR = ITEM_QUALITY_COLORS[8]

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
					if info.maxQuantity and info.maxQuantity > 0 then
						if info.quantity == info.maxQuantity then
							GameTooltip:AddDoubleLine(
								ITEM_QUALITY_COLORS[info.quality].color:WrapTextInColorCode(info.name),
								CURRENCY_DETAILED_TEMPLATE:format(BreakUpLargeNumbers(info.quantity), BreakUpLargeNumbers(info.maxQuantity), info.iconFileID),
								1, 1, 1,
								D.global.colors.red:GetRGB()
							)
						else
							GameTooltip:AddDoubleLine(
								ITEM_QUALITY_COLORS[info.quality].color:WrapTextInColorCode(info.name),
								CURRENCY_DETAILED_TEMPLATE:format(BreakUpLargeNumbers(info.quantity), BreakUpLargeNumbers(info.maxQuantity), info.iconFileID),
								1, 1, 1,
								D.global.colors.green:GetRGB()
							)
						end
					else
						GameTooltip:AddDoubleLine(
							ITEM_QUALITY_COLORS[info.quality].color:WrapTextInColorCode(info.name),
							CURRENCY_TEMPLATE:format(BreakUpLargeNumbers(info.quantity), info.iconFileID),
							1, 1, 1,
							1, 1, 1
						)
					end
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

	isInit = true
end
