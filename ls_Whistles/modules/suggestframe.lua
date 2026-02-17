local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.SuggestFrame = {}

-- Lua
local _G = getfenv(0)
local ipairs = _G.ipairs
local s_trim = _G.string.trim
local t_insert = _G.table.insert
local t_wipe = _G.table.wipe

-- Mine
local button_proto = {}
do
	function button_proto:OnClick()
		C_AdventureJournal.SetPrimaryOffset(self.offset)
		C_AdventureJournal.ActivateEntry(self.index)

		self.Widget:SetPoint("CENTER", 1, -1)
	end

	function button_proto:OnEnter()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -8, -8)
		GameTooltip:SetText(self.title, 1, 1, 1, 1, true)
		GameTooltip:AddLine(self.description, nil, nil, nil, true)

		if self.buttonText then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(self.buttonText, 0.1, 1, 0.1, true)
		end

		GameTooltip:Show()
	end

	function button_proto:OnLeave()
		GameTooltip:Hide()

		self.Widget:SetPoint("CENTER", 0, 0)
	end
end

local list_proto = {}
do
	local activities = {}
	local other = {}

	local function addData(offset, index, data)
		t_insert(data.buttonText and activities or other, {
			offset = offset,
			index = index,
			title = s_trim(data.title),
			description = data.description,
			icon = data.iconPath,
			buttonText = data.buttonText,
		})
	end

	function list_proto:Refresh()
		self:RemoveDataProvider()

		local dataProvider = CreateDataProvider()
		self.dataProvider = dataProvider

		local numSuggestions = C_AdventureJournal.GetNumAvailableSuggestions()
		if numSuggestions > 0 then
			local suggestions = {}
			t_wipe(activities)
			t_wipe(other)

			for offset = 0, numSuggestions - 1 do
				C_AdventureJournal.SetPrimaryOffset(offset)
				C_AdventureJournal.GetSuggestions(suggestions)

				addData(offset, 3, suggestions[3])

				-- do it only once
				if offset == numSuggestions - 1 then
					addData(offset, 2, suggestions[2])
					addData(offset, 1, suggestions[1])
				end
			end

			if #activities >= 1 then
				dataProvider:Insert({category = _G.MAP_LEGEND_CATEGORY_ACTIVITIES})

				for _, suggestion in ipairs(activities) do
					dataProvider:Insert(suggestion)
				end
			end

			if #other >= 1 then
				if #activities >= 1 then
					dataProvider:Insert({divider = true})
				end

				dataProvider:Insert({category = _G.HUD_EDIT_MODE_SETTINGS_CATEGORY_TITLE_MISC})

				for _, suggestion in ipairs(other) do
					dataProvider:Insert(suggestion)
				end
			end
		end

		self:SetDataProvider(dataProvider)
	end
end

local isInit = false

function addon.SuggestFrame:IsInit()
	return isInit
end

function addon.SuggestFrame:Init()
	if isInit then return end
	if not C.db.profile.suggest_frame.enabled then return end

	EventUtil.ContinueOnAddOnLoaded("Blizzard_EncounterJournal", function()
		EncounterJournalSuggestFrame:UnregisterEvent("AJ_REFRESH_DISPLAY")
		EncounterJournalSuggestFrame:UnregisterEvent("AJ_REWARD_DATA_RECEIVED")
		EncounterJournalSuggestFrame:SetScript("OnShow", nil)
		EncounterJournalSuggestFrame:EnableMouseWheel(false)
		EncounterJournalSuggestFrame.Suggestion1:Hide()
		EncounterJournalSuggestFrame.Suggestion2:Hide()
		EncounterJournalSuggestFrame.Suggestion3:Hide()

		EventRegistry:RegisterCallback("EncounterJournal.TabSet", function(_, _, id)
			if id == EncounterJournal.suggestTab:GetID() then
				local data = GetEJTierData(GetServerExpansionLevel() + 1)
				if data then
					EncounterJournalInstanceSelect.bg:SetAtlas(data.backgroundAtlas, true)
					EncounterJournalInstanceSelect.bg:Show()
					EncounterJournalInstanceSelect.evergreenBg:Hide()
				else
					EncounterJournalInstanceSelect.bg:Hide()
					EncounterJournalInstanceSelect.evergreenBg:Show()
				end
			end
		end, addon.SuggestFrame)

		local scrollBox = Mixin(CreateFrame("Frame", nil, EncounterJournalSuggestFrame, "WowScrollBoxList"), list_proto)
		scrollBox:SetPoint("TOPLEFT", 9, -5)
		scrollBox:SetSize(748, 361)
		-- scrollBox:SetPoint("BOTTOMRIGHT", -27, 14)
		scrollBox:SetFlattensRenderLayers(true)
		EncounterJournalSuggestFrame.SuggestionList = scrollBox

		local scrollBar = CreateFrame("EventFrame", nil, EncounterJournalSuggestFrame, "MinimalScrollBar")
		scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 12, -2)
		scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 12, -6)
		scrollBar:SetFlattensRenderLayers(true)
		EncounterJournalSuggestFrame.ScrollBar = scrollBar

		local topPadding = 5
		local bottomPadding = 0
		local leftPadding = 0
		local rightPadding = 0
		local horizSpacing = 11
		local vertSpacing = 5
		local view = CreateScrollBoxListSequenceView(topPadding, bottomPadding, leftPadding, rightPadding, horizSpacing, vertSpacing)

		local function categoryNameInitializer(frame, elementData)
			frame.CategoryName:SetText(elementData.category)
		end

		local function suggestionInitalizer(button, elementData)
			if not button.isInit then
				Mixin(button, button_proto)
				button:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
				button:SetScript("OnClick", button.OnClick)
				button:SetScript("OnEnter", button.OnEnter)
				button:SetScript("OnLeave", button.OnLeave)
				button:SetScript("OnHide", button.OnLeave)

				local widget = CreateFrame("Button", nil, button, "LSWishlistMouseMotionPropagator")
				widget:SetSize(166, 64) -- 178, 80
				widget:SetPoint("CENTER", 0, 0)
				widget:EnableMouse(false)
				widget:EnableMouseMotion(true)
				button.Widget = widget

				local icon = widget:CreateTexture(nil, "ARTWORK", nil, 1)
				icon:SetPoint("TOPLEFT", 0, 0)
				icon:SetSize(64, 64)
				icon:SetTexCoord(4 / 64, 60 / 64, 4 / 64, 60 / 64)
				icon:SetTexelSnappingBias(0)
				icon:SetSnapToPixelGrid(false)
				button.Icon = icon

				local background = widget:CreateTexture(nil, "ARTWORK", nil, 2)
				background:SetAllPoints()
				background:SetTexture("Interface\\AddOns\\ls_Whistles\\assets\\suggestion")
				background:SetTexCoord(1 / 512, 333 / 512, 145 / 512, 273 / 512)
				background:SetTexelSnappingBias(0)
				background:SetSnapToPixelGrid(false)
				button.Background = background

				local title = widget:CreateFontString(nil, "ARTWORK", "Fancy14Font")
				title:SetJustifyH("CENTER")
				title:SetJustifyV("MIDDLE")
				title:SetPoint("TOPRIGHT", -7, -3)
				title:SetSize(92, 54)
				title:SetTextColor(1, 0.92, 0)
				title:SetShadowOffset(1, -1)
				title:SetShadowColor(0, 0, 0)
				button.Title = title

				local border = widget:CreateTexture(nil, "OVERLAY")
				border:SetPoint("CENTER")
				border:SetTexelSnappingBias(0)
				border:SetSnapToPixelGrid(false)
				border:SetTexture("Interface\\AddOns\\ls_Whistles\\assets\\suggestion")
				border:SetTexCoord(1 / 512, 349 / 512, 1 / 512, 145 / 512)
				border:SetSize(174, 72)
				button.Border = border

				widget:SetHighlightTexture("Interface\\AddOns\\ls_Whistles\\assets\\suggestion", "ADD")
				local highlight = widget:GetHighlightTexture()
				highlight:SetTexCoord(1 / 512, 349 / 512, 1 / 512, 145 / 512)
				highlight:SetAlpha(0.4)
				highlight:ClearAllPoints()
				highlight:SetPoint("TOPLEFT", -4, 4)
				highlight:SetPoint("BOTTOMRIGHT", 4, -4)

				button.isInit = true
			end

			button.offset = elementData.offset
			button.index = elementData.index
			button.title = elementData.title
			button.description = elementData.description
			button.buttonText = elementData.buttonText

			button.Icon:SetTexture(elementData.icon)

			button.Title:SetText(elementData.title)

			button:SetMouseClickEnabled(button.buttonText and #button.buttonText > 0)
		end

		view:SetElementFactory(function(factory, elementData)
			if elementData.category then
				factory("JourneysListCategoryNameTemplate", categoryNameInitializer)
			elseif elementData.divider then
				factory("JourneysListCategoryDividerTemplate", nop)
			else
				factory("Button", suggestionInitalizer)
			end
		end)

		view:SetElementSizeCalculator(function(_, elementData)
			if elementData.category then
				return 0, 20
			elseif elementData.divider then
				return 0, 16
			else
				return 178, 80
			end
		end)

		ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

		scrollBox:SetEdgeFadeLength(40)

		scrollBox.panExtentPercentage = 0.5
		scrollBox.wheelPanScalar = 4

		local timer = nil
		local function delayedUpdate()
			C_AdventureJournal.UpdateSuggestions()
			scrollBox:Refresh()

			timer = nil
		end

		addon:RegisterEvent("AJ_REFRESH_DISPLAY", function()
			if not timer then
				timer = C_Timer.NewTimer(0.25, delayedUpdate)
			end
		end)

		scrollBox:Refresh()
	end)

	isInit = true
end
