local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.InspectFrame = {}

-- Lua
local _G = getfenv(0)
local hooksecurefunc = _G.hooksecurefunc
local next = _G.next
local s_upper = _G.string.upper

-- Mine
local EQUIP_SLOTS

local avgItemLevel

local function scanSlot(slotID)
	local link = GetInventoryItemLink(InspectFrame.unit, slotID)
	if link then
		return true, addon:GetDetailedItemInfo(link)
	elseif GetInventoryItemTexture(InspectFrame.unit, slotID) then
		-- if there's no link, but there's a texture, it means that there's an item we have no info for
		return false
	end

	return true
end

local function updateSlot(button)
	if avgItemLevel == 0 then
		avgItemLevel = C_PaperDollInfo.GetInspectItemLevel(InspectFrame.unit)
	end

	local isOk, iLvl, upgrade, enchant, gem1, gem2, gem3 = scanSlot(button:GetID())
	if isOk then
		if C.db.profile.inspect_frame.ilvl then
			button.ItemLevelText:SetText(iLvl)
			button.ItemLevelText:SetTextColor(addon:GetItemLevelColor(iLvl, avgItemLevel))
		else
			button.ItemLevelText:SetText("")
		end

		if C.db.profile.inspect_frame.enhancements then
			button.EnchantText:SetText(enchant or "")
			button.EnchantIcon:SetShown(enchant)

			if PlayerIsTimerunning() then
				button.GemDisplay:SetGems()
			else
				button.GemDisplay:SetGems(gem1, gem2, gem3)
			end
		else
			button.EnchantText:SetText("")
			button.EnchantIcon:Hide()
			button.GemDisplay:SetGems()
		end

		if C.db.profile.inspect_frame.upgrade then
			button.UpgradeText:SetText(upgrade or "")
		else
			button.UpgradeText:SetText("")
		end
	end
end

local isInit = false

function addon.InspectFrame:IsInit()
	return isInit
end

function addon.InspectFrame:Init()
	if isInit then return end
	if not C.db.profile.inspect_frame.enabled then return end

	EventUtil.ContinueOnAddOnLoaded("Blizzard_InspectUI", function()
		EQUIP_SLOTS = {
			[InspectBackSlot] = true,
			[InspectChestSlot] = true,
			[InspectFeetSlot] = true,
			[InspectFinger0Slot] = true,
			[InspectFinger1Slot] = true,
			[InspectHandsSlot] = true,
			[InspectHeadSlot] = true,
			[InspectLegsSlot] = true,
			[InspectMainHandSlot] = true,
			[InspectNeckSlot] = true,
			[InspectSecondaryHandSlot] = true,
			[InspectShirtSlot] = true,
			[InspectShoulderSlot] = true,
			[InspectTabardSlot] = true,
			[InspectTrinket0Slot] = true,
			[InspectTrinket1Slot] = true,
			[InspectWaistSlot] = true,
			[InspectWristSlot] = true,
		}

		local SLOT_TEXTURES_TO_REMOVE = {
			["410248"] = true,
			["INTERFACE\\CHARACTERFRAME\\CHAR-PAPERDOLL-PARTS"] = true,
			["130841"] = true,
			["INTERFACE\\BUTTONS\\UI-QUICKSLOT2"] = true,
		}

		for slot, textOnRight in next, {
			[InspectBackSlot] = true,
			[InspectChestSlot] = true,
			[InspectFeetSlot] = false,
			[InspectFinger0Slot] = false,
			[InspectFinger1Slot] = false,
			[InspectHandsSlot] = false,
			[InspectHeadSlot] = true,
			[InspectLegsSlot] = false,
			[InspectMainHandSlot] = false,
			[InspectNeckSlot] = true,
			[InspectSecondaryHandSlot] = true,
			[InspectShirtSlot] = true,
			[InspectShoulderSlot] = true,
			[InspectTabardSlot] = true,
			[InspectTrinket0Slot] = false,
			[InspectTrinket1Slot] = false,
			[InspectWaistSlot] = false,
			[InspectWristSlot] = true,
		} do
			for _, v in next, {slot:GetRegions()} do
				if v:IsObjectType("Texture") and SLOT_TEXTURES_TO_REMOVE[s_upper(v:GetTexture() or "")] then
					v:SetTexture(0)
					v:Hide()
				end
			end

			local isWeaponSlot = slot == InspectMainHandSlot or slot == InspectSecondaryHandSlot

			addon.Button:SkinItemSlotButton(slot)
			slot:SetSize(36, 36)

			local enchText = slot:CreateFontString(nil, "ARTWORK")
			enchText:SetFontObject("GameFontNormalSmall")
			enchText:SetSize(160, 22)
			enchText:SetJustifyH(textOnRight and "LEFT" or "RIGHT")
			enchText:SetJustifyV("TOP")
			enchText:SetTextColor(0, 1, 0)
			enchText:Hide()
			slot.EnchantText = enchText

			local enchIcon = slot:CreateTexture(nil, "OVERLAY", nil, 2)
			enchIcon:SetSize(12, 12)
			enchIcon:SetTexture("Interface\\ContainerFrame\\CosmeticIconBorder")
			enchIcon:SetDesaturated(true)
			enchIcon:SetVertexColor(0, 0.95, 0, 0.85)
			slot.EnchantIcon = enchIcon

			local upgradeText = slot:CreateFontString(nil, "ARTWORK")
			upgradeText:SetFontObject("GameFontHighlightSmall")
			upgradeText:SetSize(160, 0)
			upgradeText:SetJustifyH(textOnRight and "LEFT" or "RIGHT")
			upgradeText:Hide()
			slot.UpgradeText = upgradeText

			local iLvlText = slot:CreateFontString(nil, "ARTWORK")
			iLvlText:SetFontObject("GameFontHighlightOutline")
			iLvlText:SetJustifyV("BOTTOM")
			iLvlText:SetJustifyH(textOnRight and "LEFT" or "RIGHT")
			iLvlText:SetPoint("TOPLEFT", -1, -1)
			iLvlText:SetPoint("BOTTOMRIGHT", 2, 1)
			slot.ItemLevelText = iLvlText

			if textOnRight then
				enchText:SetPoint("TOPLEFT", slot, "TOPRIGHT", 6, 0)
				enchIcon:SetPoint("TOPLEFT", -2, 2)
				enchIcon:SetTexCoord(65 / 128, 41 / 128, 1 / 128, 25 / 128)
				upgradeText:SetPoint("BOTTOMLEFT", slot, "BOTTOMRIGHT", 6, 0)
			else
				enchText:SetPoint("TOPRIGHT", slot, "TOPLEFT", -6, 0)
				enchIcon:SetPoint("TOPRIGHT", 2, 2)
				enchIcon:SetTexCoord(41 / 128, 65 / 128, 1 / 128, 25 / 128)
				upgradeText:SetPoint("BOTTOMRIGHT", slot, "BOTTOMLEFT", -6, 0)
			end

			-- I could reuse .SocketDisplay, but my gut is telling me not to do it
			slot.GemDisplay = addon.GemDisplay:Create(slot, isWeaponSlot)

			if isWeaponSlot then
				slot.GemDisplay:SetPoint("TOP", 0, 7)
			elseif textOnRight then
				slot.GemDisplay:SetPoint("RIGHT", 7, 0)
			else
				slot.GemDisplay:SetPoint("LEFT", -7, 0)
			end
		end

		InspectHeadSlot:SetPoint("TOPLEFT", InspectFrame.Inset, "TOPLEFT", 6, -6)
		InspectHandsSlot:SetPoint("TOPRIGHT", InspectFrame.Inset, "TOPRIGHT", -6, -6)
		InspectMainHandSlot:SetPoint("BOTTOMLEFT", InspectFrame.Inset, "BOTTOMLEFT", 176, 5)
		InspectSecondaryHandSlot:ClearAllPoints()
		InspectSecondaryHandSlot:SetPoint("BOTTOMRIGHT", InspectFrame.Inset, "BOTTOMRIGHT", -176, 5)

		InspectModelFrame:SetSize(0, 0) -- needed for OrbitCameraMixin
		InspectModelFrame:ClearAllPoints()
		InspectModelFrame:SetPoint("TOPLEFT", 49, -66)
		InspectModelFrame:SetPoint("BOTTOMRIGHT", -51, 32)

		for _, texture in next, {
			InspectModelFrame.BackgroundBotLeft,
			InspectModelFrame.BackgroundBotRight,
			InspectModelFrame.BackgroundOverlay,
			InspectModelFrame.BackgroundTopLeft,
			InspectModelFrame.BackgroundTopRight,
			InspectModelFrameBorderBottom,
			InspectModelFrameBorderBottom2,
			InspectModelFrameBorderBottomLeft,
			InspectModelFrameBorderBottomRight,
			InspectModelFrameBorderLeft,
			InspectModelFrameBorderRight,
			InspectModelFrameBorderTop,
			InspectModelFrameBorderTopLeft,
			InspectModelFrameBorderTopRight,
		} do
			texture:SetTexture(0)
			texture:Hide()
		end

		InspectPaperDollItemsFrame.InspectTalents:SetPoint("BOTTOMRIGHT", InspectPaperDollItemsFrame, "BOTTOMRIGHT", -9, 7)

		local averageItemLevelText = InspectPaperDollItemsFrame:CreateFontString(nil, "ARTWORK")
		averageItemLevelText:SetFontObject("GameFontNormalSmall")
		averageItemLevelText:SetSize(0, 0)
		averageItemLevelText:SetJustifyH("LEFT")
		averageItemLevelText:SetPoint("BOTTOMLEFT", 9, 7)
		InspectPaperDollItemsFrame.AverageItemLevelText = averageItemLevelText

		hooksecurefunc("InspectSwitchTabs", function(tabID)
			if tabID == 1 then
				InspectFrame:SetSize(438, 431) -- 432 + 6, 424 + 7

				if not InspectFrame.unit then return end

				avgItemLevel = C_PaperDollInfo.GetInspectItemLevel(InspectFrame.unit)

				local class = UnitClassBase(InspectFrame.unit)

				InspectFrame.Inset.Bg:SetTexture("Interface\\DressUpFrame\\DressingRoom" .. class)
				InspectFrame.Inset.Bg:SetTexCoord(1 / 512, 479 / 512, 46 / 512, 455 / 512)
				InspectFrame.Inset.Bg:SetHorizTile(false)
				InspectFrame.Inset.Bg:SetVertTile(false)
			else
				InspectFrame:SetSize(338, 424) -- PortraitFrameBaseTemplate's default size
			end
		end)

		local isMouseOver
		InspectFrame:HookScript("OnUpdate", function()
			local state = InspectFrame:IsMouseOver()
			if state ~= isMouseOver then
				for button in next, EQUIP_SLOTS do
					button.EnchantText:SetShown(state)
					button.UpgradeText:SetShown(state)
				end

				isMouseOver = state
			end
		end)

		hooksecurefunc("InspectPaperDollItemSlotButton_Update", updateSlot)

		hooksecurefunc("InspectPaperDollFrame_SetLevel", function()
			averageItemLevelText:SetFormattedText(_G.DUNGEON_SCORE_LINK_ITEM_LEVEL, C_PaperDollInfo.GetInspectItemLevel(InspectFrame.unit))
		end)
	end)

	isInit = true
end

function addon.InspectFrame:Update()
	if not isInit then return end

	for button in next, EQUIP_SLOTS do
		updateSlot(button)
	end
end
