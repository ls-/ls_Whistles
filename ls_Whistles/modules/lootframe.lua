local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.LootFrame = {}

-- Lua
local _G = getfenv(0)
local m_floor = _G.math.floor
local m_max = _G.math.max
local next = _G.next
local tonumber = _G.tonumber

-- Mine
local ELEMENT_SIZE = 37
local NUM_COLUMNS = 4
local SPACING = 5
local HORIZ_PADDING = 9
local VERT_PADDING = 6

local loot_button_proto = {}
do
	function loot_button_proto:OnClick()
		if IsModifiedClick() then
			HandleModifiedItemClick(self:GetSlotLink())
		else
			-- Values required by GroupLoot and MasterLoot frames. If these frames are returned
			-- to service, it would be ideal to expose these values through an API.
			LootFrame.selectedLootFrame = self
			LootFrame.selectedSlot = self:GetSlotIndex()
			LootFrame.selectedQuality = self:GetQuality()
			LootFrame.selectedItemName = self:GetName()
			LootFrame.selectedTexture = self:GetTexture()

			StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION")

			LootSlot(self:GetSlotIndex())

			EventRegistry:TriggerEvent("LootFrame.ItemLooted")
		end
	end

	function loot_button_proto:OnEnter()
		local lootSlotType = self:GetSlotType();
		if lootSlotType == Enum.LootSlotType.Currency then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetLootCurrency(self:GetSlotIndex())
		elseif lootSlotType == Enum.LootSlotType.Item then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetLootItem(self:GetSlotIndex())
		elseif lootSlotType == Enum.LootSlotType.Money then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self:GetName(), 1, 1, 1)
		end

		CursorUpdate(self);
	end

	function loot_button_proto:FadeOut()
		self.AnimOut:Play()
	end

	function loot_button_proto:FadeIn()
		self.AnimOut:Stop()
		self.AnimIn:Play()
	end

	function loot_button_proto:OnLeave()
		GameTooltip:Hide()
	end

	function loot_button_proto:GetSlotIndex()
		local elementData = self:GetElementData()
		return elementData.index
	end

	function loot_button_proto:GetSlotType()
		local elementData = self:GetElementData()
		return elementData.type
	end

	function loot_button_proto:GetSlotLink()
		local elementData = self:GetElementData()
		return elementData.link
	end

	function loot_button_proto:GetQuality()
		local elementData = self:GetElementData()
		return elementData.quality
	end

	function loot_button_proto:GetName()
		local elementData = self:GetElementData()
		return elementData.name
	end

	function loot_button_proto:GetTexture()
		local elementData = self:GetElementData()
		return elementData.texture
	end

	function loot_button_proto:Refresh()
		local elementData = self:GetElementData()

		self.icon:SetTexture(elementData.icon)

		SetItemButtonQuality(self, elementData.quality, elementData.link)

		self.Count:SetText(elementData.quantity > 1 and elementData.quantity or "")

		if elementData.questID and not elementData.isQuestActive then
			self.QuestTexture:SetTexture("Interface\\ContainerFrame\\UI-Icon-QuestBang")
		elseif elementData.questID or elementData.isQuestItem then
			self.QuestTexture:SetTexture("Interface\\ContainerFrame\\UI-Icon-QuestBorder")
		end

		self.QuestTexture:SetShown(elementData.questID or elementData.isQuestItem)

		if elementData.isLocked then
			SetItemButtonTextureVertexColor(self, 0.9, 0, 0)
			SetItemButtonNormalTextureVertexColor(self, 0.9, 0, 0)
		else
			SetItemButtonTextureVertexColor(self, 1.0, 1.0, 1.0)
			SetItemButtonNormalTextureVertexColor(self, 1.0, 1.0, 1.0)
		end
	end
end

local take_button_proto = {}
do
	function take_button_proto:OnClick()
		for i = 1, GetNumLootItems() do
			if GetLootSlotType(i) ~= Enum.LootSlotType.None then
				LootSlot(i)
			end
		end
	end

	function take_button_proto:OnKeyDown(key)
		if key == "SPACE" or key == GetBindingKey("INTERACTTARGET") then
			self:SetPropagateKeyboardInput(false)
			self:OnClick()
		elseif not InCombatLockdown() then
			self:SetPropagateKeyboardInput(true)
		end
	end

	function take_button_proto:OnEvent(event)
		if event == "PLAYER_REGEN_DISABLED" then
			self:SetScript("OnKeyDown", nil)
		elseif event == "PLAYER_REGEN_ENABLED" then
			self:SetScript("OnKeyDown", self.OnKeyDown)
		end
	end

	function take_button_proto:OnEnter()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["LOOT_ALL"], 1, 1, 1)
	end

	function take_button_proto:OnLeave()
		GameTooltip:Hide()
	end

	function take_button_proto:GetSlotIndex()
		return 0
	end
end

local frame_proto = {}
do
	local GOLD_PATTERN = _G.GOLD_AMOUNT:gsub("%%d", "(%%d+)")
	local SILVER_PATTERN = _G.SILVER_AMOUNT:gsub("%%d", "(%%d+)")
	local COPPER_PATTERN = _G.COPPER_AMOUNT:gsub("%%d", "(%%d+)")

	-- a modified version of LootFrameMixin.Open
	function frame_proto:Open()
		local dataProvider = CreateDataProvider()
		dataProvider:Insert({
			takeButton = true,
		})

		for index = 1, GetNumLootItems() do
			local slotType = GetLootSlotType(index)
			if slotType ~= Enum.LootSlotType.None then
				local texture, item, quantity, currencyID, itemQuality, locked, isQuestItem, questID, isActive, isCoin = GetLootSlotInfo(index)
				local slotLink = GetLootSlotLink(index)

				if currencyID then
					item, texture, quantity, itemQuality = CurrencyContainerUtil.GetCurrencyContainerInfo(currencyID, quantity, item, texture, itemQuality)
				end

				if isCoin then
					local copper = tonumber(item:match(COPPER_PATTERN) or 0)
					local silver = tonumber(item:match(SILVER_PATTERN) or 0)
					local gold = tonumber(item:match(GOLD_PATTERN) or 0)

					item = GetMoneyString(gold * 10000 + silver * 100 + copper)
				end

				dataProvider:Insert({
					index = index,
					type = slotType,
					link = slotLink,
					name = item:gsub("\n", " "),
					icon = texture,
					quantity = quantity,
					quality = itemQuality or Enum.ItemQuality.Common,
					isLocked = locked,
					isQuestItem = isQuestItem,
					questID = questID,
					isQuestActive = isActive,
				})
			end
		end

		self.ScrollBox:SetDataProvider(dataProvider)

		if GetCVarBool("lootUnderMouse") then
			if CanAutoSetGamePadCursorControl(true) then
				SetGamePadCursorControl(true)
			end

			self:Show()

			local x, y = GetCursorPosition()
			x = x / (self:GetEffectiveScale()) - 30
			y = m_max((y / self:GetEffectiveScale()) + 50, 350)

			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", x, y)
			self:Raise()
		else
			-- gets blocked while in combat even though the frame isn't secure
			-- ShowUIPanel(self)

			self:ApplySystemAnchor()
		end

		ScrollingFlatPanelMixin.Open(self)
	end

	-- a modified version of LootFrameMixin.OnEvent
	function frame_proto:OnEvent(event, ...)
		if event == "LOOT_OPENED" then
			local isAutoLoot, acquiredFromItem = ...

			self:Open()

			if self:IsShown() then
				if acquiredFromItem then
					PlaySound(SOUNDKIT.UI_CONTAINER_ITEM_OPEN)
				elseif IsFishingLoot() then
					PlaySound(SOUNDKIT.FISHING_REEL_IN)
				elseif self.ScrollBox:GetDataProvider():IsEmpty() then
					PlaySound(SOUNDKIT.LOOT_WINDOW_OPEN_EMPTY)
				end
			else
				CloseLoot(not isAutoLoot)
			end
		elseif event == "LOOT_SLOT_CLEARED" then
			local slotIndex = ...
			local button = self.ScrollBox:FindFrameByPredicate(function(button)
				return button:GetSlotIndex() == slotIndex
			end)

			if button then
				button:FadeOut()
			end
		elseif event == "LOOT_SLOT_CHANGED" then
			local slotIndex = ...
			if GetLootSlotType(slotIndex) == Enum.LootSlotType.None then return end

			local button = self.ScrollBox:FindFrameByPredicate(function(button)
				return button:GetSlotIndex() == slotIndex
			end)

			if button then
				button:Refresh()
			end
		elseif event == "LOOT_CLOSED" then
			self:Close()
		end
	end

	function frame_proto:CalculateElementsHeight()
		local offset = 8 -- ScrollingFlatPanelMixin.Resize adds extra 20px padding, compensate for it
		return ScrollUtil.CalculateScrollBoxElementExtent(m_floor(self.ScrollBox:GetDataProviderSize() / NUM_COLUMNS + 0.9), ELEMENT_SIZE, SPACING) - offset
	end
end

local isInit = false

function addon.LootFrame:IsInit()
	return isInit
end

function addon.LootFrame:Init()
	if isInit then return end
	if not C.db.profile.loot_frame.enabled then return end

	-- speed things up
	SetCVar("autoLootRate", 10)

	addon:ForceHide(LootFrame.ScrollBox)
	addon:ForceHide(LootFrame.ScrollBar)

	Mixin(LootFrame, frame_proto)

	LootFrame.panelTitle = _G.LOOT_NOUN
	LootFrame.panelWidth = 185

	LootFrame:SetTitle(LootFrame.panelTitle)
	LootFrame:SetScript("OnEvent", LootFrame.OnEvent)

	local scrollBox = CreateFrame("Frame", nil, LootFrame, "WowScrollBoxList")
	scrollBox:SetPoint("TOPLEFT", 4, -22)
	scrollBox:SetPoint("BOTTOM", 0, 4)
	scrollBox:SetFlattensRenderLayers(true)
	LootFrame.ScrollBox = scrollBox

	local scrollBar = CreateFrame("EventFrame", nil, LootFrame, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", LootFrame, "TOPRIGHT", -16, -28)
	scrollBar:SetPoint("BOTTOMLEFT", LootFrame, "BOTTOMRIGHT", -16, 6)
	scrollBar:SetFlattensRenderLayers(true)
	LootFrame.ScrollBar = scrollBar

	local view = CreateScrollBoxListGridView(NUM_COLUMNS, VERT_PADDING, VERT_PADDING, HORIZ_PADDING, HORIZ_PADDING, SPACING, SPACING)

	local function lootButtonInitializer(button)
		if not button.isInit then
			Mixin(button, loot_button_proto)

			button:SetScript("OnEnter", button.OnEnter)
			button:SetScript("OnLeave", button.OnLeave)
			button:SetScript("OnClick", button.OnClick)

			button.icon:SetTexelSnappingBias(0)
			button.icon:SetSnapToPixelGrid(false)

			button.IconBorder:SetTexelSnappingBias(0)
			button.IconBorder:SetSnapToPixelGrid(false)

			button.IconOverlay:SetTexelSnappingBias(0)
			button.IconOverlay:SetSnapToPixelGrid(false)

			button.IconOverlay2:SetTexelSnappingBias(0)
			button.IconOverlay2:SetSnapToPixelGrid(false)

			local overlay = CreateFrame("Frame", nil, button) -- used by CIMI/TLH
			overlay:SetAllPoints()
			button.Item = overlay

			local questTexture = button:CreateTexture(nil, "OVERLAY")
			questTexture:SetSize(37, 38)
			questTexture:SetPoint("TOPLEFT", 0, 0)
			button.QuestTexture = questTexture

			button.Count:Show()
			button.Count:SetPoint("BOTTOMRIGHT", -2, 2)

			local ag = button:CreateAnimationGroup()
			ag:SetToFinalAlpha(true)
			button.AnimIn = ag

			local anim = ag:CreateAnimation("Alpha")
			anim:SetDuration(0.0001) -- for whatever reason 0 doesn't work
			anim:SetFromAlpha(0)
			anim:SetToAlpha(1)
			anim:SetSmoothing("IN")

			ag = button:CreateAnimationGroup()
			ag:SetToFinalAlpha(true)
			button.AnimOut = ag

			anim = ag:CreateAnimation("Alpha")
			anim:SetDuration(0.15)
			anim:SetFromAlpha(1)
			anim:SetToAlpha(0)
			anim:SetSmoothing("OUT")

			button.isInit = true
		end

		button:FadeIn()
		button:Refresh()
	end

	local function takeButtonInitializer(button)
		if not button.isInit then
			Mixin(button, take_button_proto)

			button:EnableKeyboard(true)
			button:RegisterEvent("PLAYER_REGEN_DISABLED")
			button:RegisterEvent("PLAYER_REGEN_ENABLED")
			button:SetScript("OnClick", button.OnClick)
			button:SetScript("OnEnter", button.OnEnter)
			button:SetScript("OnEvent", button.OnEvent)
			button:SetScript("OnLeave", button.OnLeave)

			if not InCombatLockdown() then
				button:SetScript("OnKeyDown", button.OnKeyDown)
			end

			local icon = button:CreateTexture(nil, "BORDER")
			icon:SetAllPoints()
			icon:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-ItemIntoBag")
			button.Icon = icon

			local border = button:CreateTexture(nil, "OVERLAY")
			border:SetAllPoints()
			border:SetTexture("Interface\\Common\\WhiteIconFrame")
			border:SetVertexColor(0.66, 0.66, 0.66)
			button.Border = border

			button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
			button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

			button.isInit = true
		end
	end

	view:SetElementFactory(function(factory, elementData)
		if elementData.takeButton then
			factory("Button", takeButtonInitializer)
		else
			factory("ItemButton", lootButtonInitializer)
		end
	end)

	view:SetElementSizeCalculator(function()
		return ELEMENT_SIZE, ELEMENT_SIZE
	end)

	ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, view)

	EventUtil.ContinueOnAddOnLoaded("CanIMogIt", function()
		local function CIMIUpdateIcon(cimiFrame)
			if not cimiFrame then return end
			if not CIMI_CheckOverlayIconEnabled() then
				cimiFrame.CIMIIconTexture:SetShown(false)
				cimiFrame:SetScript("OnUpdate", nil)

				return
			end

			local link = GetLootSlotLink(cimiFrame:GetParent():GetParent():GetSlotIndex())
			if link then
				CIMI_SetIcon(cimiFrame, CIMIUpdateIcon, CanIMogIt:GetTooltipText(link))
			end
		end

		LootFrame:HookScript("OnShow", function()
			for _, frame in next, LootFrame.ScrollBox.view.frames do
				if frame.Item then
					local cimiFrame = frame.Item.CanIMogItOverlay
					if not cimiFrame then
						cimiFrame = CIMI_AddToFrame(frame.Item, CIMIUpdateIcon)
					end

					CIMIUpdateIcon(cimiFrame)
				end
			end
		end)
	end)

	isInit = true
end
