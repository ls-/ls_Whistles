local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.JourneyFrame = {}

-- Lua
local _G = getfenv(0)
local ipairs = _G.ipairs
local m_rad = _G.math.rad
local select = _G.select
local t_insert = _G.table.insert

-- Mine
local info = C_Texture.GetAtlasInfo("ui-journeys-renown-radial-fill")
local SWIPE_TEXTURE = info.file or info.filename
local SWIPE_LOW_TEX_COORDS = {
	x = info.leftTexCoord,
	y = info.topTexCoord,
}
local SWIPE_HIGH_TEX_COORDS = {
	x = info.rightTexCoord,
	y = info.bottomTexCoord,
}

local MAJOR_FACTION_ICON_FORMAT = "majorfactions_icons_%s512"

local progress_bar_proto = {}
do
	-- function progress_bar_proto:UpdateBar(cur, max)
	-- 	if not cur or not max or max == 0 then
	-- 		return
	-- 	end

	-- 	CooldownFrame_SetDisplayAsPercentage(self, cur / max)
	-- end

	function progress_bar_proto:RefreshBar(data)
		local paragonInfo = data.paragonInfo or data.essentialParagonInfo
		local cur, max
		if paragonInfo then
			cur, max = paragonInfo.curValue, paragonInfo.maxValue
		else
			cur, max = data.curValue, data.maxValue
		end

		if data.isUnlocked and data.factionFontColor then
			self:SetSwipeColor(data.factionFontColor.color:GetRGB())
		end

		CooldownFrame_SetDisplayAsPercentage(self, cur / max)
	end
end

local renown_button_proto = {}
do
	local function showRenownRewardsTooltip(frame, factionID)
		if GameTooltip:IsAnchoringSecret() then return end
		if GameTooltip.ItemTooltip:IsAnchoringSecret() then return end
		if GameTooltip.ItemTooltip.Tooltip:IsAnchoringSecret() then return end

		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
		RenownRewardUtil.AddMajorFactionLandingPageSummaryToTooltip(GameTooltip, factionID, GenerateClosure(showRenownRewardsTooltip, frame, factionID))
		GameTooltip_AddColoredLine(GameTooltip, _G.JOURNEYS_TOOLTIP_VIEW_JOURNEY, GREEN_FONT_COLOR)
		GameTooltip_AddColoredLine(GameTooltip, L["JOURNEYS_TOOLTIP_WATCH_JOURNEY"], GREEN_FONT_COLOR)
		GameTooltip:Show()
	end

	local function showParagonRewardsTooltip(frame, factionID)
		if EmbeddedItemTooltip:IsAnchoringSecret() then return end
		if EmbeddedItemTooltip.ItemTooltip:IsAnchoringSecret() then return end
		if EmbeddedItemTooltip.ItemTooltip.Tooltip:IsAnchoringSecret() then return end

		EmbeddedItemTooltip:SetOwner(frame, "ANCHOR_RIGHT")
		ReputationUtil.AddParagonRewardsToTooltip(EmbeddedItemTooltip, factionID)
		GameTooltip_SetBottomInstructions(EmbeddedItemTooltip, _G.JOURNEYS_TOOLTIP_VIEW_JOURNEY, L["JOURNEYS_TOOLTIP_WATCH_JOURNEY"])
		EmbeddedItemTooltip:Show()
	end

	function renown_button_proto:OnClick()
		if IsShiftKeyDown() then
			local data = C_Reputation.GetWatchedFactionData()
			if not data or data.factionID ~= self.majorFactionData.factionID then
				PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
				C_Reputation.SetWatchedFactionByID(self.majorFactionData.factionID)
			else
				PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
				C_Reputation.SetWatchedFactionByID(0)
			end
		else
			self.journeysFrame:ResetView(self.majorFactionData)
		end
	end

	function renown_button_proto:OnEnter()
		if self.majorFactionData and self.majorFactionData.factionID then
			if not self.majorFactionData.isUnlocked then
				if self.majorFactionData.unlockDescription then
					GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
					GameTooltip_AddErrorLine(GameTooltip, self.majorFactionData.unlockDescription)
					GameTooltip:Show()
				end
			elseif C_Reputation.IsFactionParagonForCurrentPlayer(self.majorFactionData.factionID) then
				showParagonRewardsTooltip(self, self.majorFactionData.factionID)
			else
				showRenownRewardsTooltip(self, self.majorFactionData.factionID)
			end
		end
	end
end

local function processData(data)
	local isParagon = C_Reputation.IsFactionParagonForCurrentPlayer(data.factionID)
	if isParagon then
		local cur, max, rewardQuestID, hasRewardPending, _, paragonStorageLevel = C_Reputation.GetFactionParagonInfo(data.factionID)
		cur = cur % max

		-- ContinueOnItemLoad can be late to the party, keep a barebones copy
		-- do not create .paragonInfo too early because blizz reward track code will shit itself
		data.essentialParagonInfo = {
			curValue = cur,
			maxValue = max,
			level = paragonStorageLevel, -- this makes blizz code happy
			totalLevel = paragonStorageLevel + data.renownLevel,
			hasRewardPending = hasRewardPending,
		}

		if rewardQuestID then
			local itemID = select(6, GetQuestLogRewardInfo(1, rewardQuestID))
			if itemID then
				local item = Item:CreateFromItemID(itemID)
				item:ContinueOnItemLoad(function()
					local itemName, itemLink, _, _, _, _, _, _, _, itemIcon, _, _, _, _, _, _, _, itemDescription = C_Item.GetItemInfo(itemID)

					data.paragonInfo = {
						curValue = cur,
						maxValue = max,
						level = paragonStorageLevel, -- this makes blizz code happy
						totalLevel = paragonStorageLevel + data.renownLevel,
						hasRewardPending = hasRewardPending,
						rewardInfo = {
							name = itemName,
							icon = itemIcon,
							description = itemDescription,
							isWarbandItem = C_Item.IsItemBindToAccount(itemLink),
						},
					}
				end)
			end
		end
	else
		data.maxValue = data.renownLevelThreshold

		if C_MajorFactions.HasMaximumRenown(data.factionID) then
			data.curValue = data.renownLevelThreshold
		else
			data.curValue = data.renownReputationEarned
		end
	end

	return data
end

local isInit = false

function addon.JourneyFrame:IsInit()
	return isInit
end

function addon.JourneyFrame:Init()
	if isInit then return end
	if not C.db.profile.journey_frame.enabled then return end

	EventUtil.ContinueOnAddOnLoaded("Blizzard_EncounterJournal", function()
		local function categoryNameInitializer(frame, elementData)
			frame.CategoryName:SetText(elementData.category)
		end

		local function renownButtonInitializer(button, elementData)
			if not button.isInit then
				Mixin(button, RenownCardButtonMixin, renown_button_proto)
				button:SetScript("OnEnter", button.OnEnter)
				button:SetScript("OnLeave", button.OnLeave)
				button:SetScript("OnClick", button.OnClick)

				local background = button:CreateTexture(nil, "BACKGROUND")
				background:SetSize(102, 102)
				background:SetPoint("CENTER")
				background:SetAtlas("ui-journeys-delve-renown-circle-pit")
				button.Background = background

				local icon = button:CreateTexture(nil, "ARTWORK", nil, 1)
				icon:SetSize(50, 50)
				icon:SetPoint("CENTER")
				icon:SetTexelSnappingBias(0)
				icon:SetSnapToPixelGrid(false)
				button.Icon = icon

				local glass = button:CreateTexture(nil, "ARTWORK", nil, 4)
				glass:SetPoint("TOPLEFT", 2, -2)
				glass:SetPoint("BOTTOMRIGHT", -2, 2)
				glass:SetAtlas("covenantsanctum-reservoir-idle-venthyr-glass")
				glass:SetAlpha(0.6)
				button.Glass = glass

				local progressBar = Mixin(CreateFrame("Cooldown", nil, button), progress_bar_proto)
				progressBar:SetSize(90, 90)
				progressBar:SetPoint("CENTER")
				progressBar:SetHideCountdownNumbers(true)
				progressBar:SetReverse(true)
				progressBar:SetRotation(m_rad(180))
				progressBar:SetSwipeTexture(SWIPE_TEXTURE)
				progressBar:SetTexCoordRange(SWIPE_LOW_TEX_COORDS, SWIPE_HIGH_TEX_COORDS)
				progressBar:SetSwipeColor(1, 1, 1, 1)
				button.ProgressBar = progressBar

				local progressBarBorder = progressBar:CreateTexture(nil, "BORDER")
				progressBarBorder:SetSize(90, 90)
				progressBarBorder:SetPoint("CENTER")
				progressBarBorder:SetAtlas("ui-journeys-renown-radial-bar")
				progressBar.Border = progressBarBorder

				local levelBorder = progressBar:CreateTexture(nil, "OVERLAY")
				levelBorder:SetSize(34, 27) -- 33, 29
				levelBorder:SetAtlas("UI-Journeys-Delve-rewardicon-rectangle-frame")
				levelBorder:SetTexelSnappingBias(0)
				levelBorder:SetSnapToPixelGrid(false)
				levelBorder:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
				button.LevelBorder = levelBorder

				local level = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				level:SetJustifyH("CENTER")
				level:SetPoint("TOPLEFT", levelBorder, "TOPLEFT", 0, 0)
				level:SetPoint("BOTTOMRIGHT", levelBorder, "BOTTOMRIGHT", 0, 0)
				button.Level = level

				local lockIcon = CreateFrame("Frame", nil, button)
				lockIcon:SetFrameLevel(progressBar:GetFrameLevel() + 1)
				lockIcon:SetSize(28, 28)
				lockIcon:SetPoint("BOTTOM", 0, 5)
				lockIcon:Hide()
				button.LockIcon = lockIcon

				local lockTexture = lockIcon:CreateTexture(nil, "ARTWORK")
				lockTexture:SetSize(24, 28)
				lockTexture:SetPoint("CENTER")
				lockTexture:SetAtlas("ui-journeys-greatvault-lock")
				lockTexture:SetTexelSnappingBias(0)
				lockTexture:SetSnapToPixelGrid(false)

				local rewardIcon = CreateFrame("Frame", nil, button)
				rewardIcon:SetFrameLevel(progressBar:GetFrameLevel() + 1)
				rewardIcon:SetSize(18, 18)
				rewardIcon:SetPoint("BOTTOM", 0, 10)
				rewardIcon:Hide()
				button.RewardIcon = rewardIcon

				local rewardTexture = rewardIcon:CreateTexture(nil, "ARTWORK", nil, 1)
				rewardTexture:SetPoint("CENTER", -1, 0)
				rewardTexture:SetAtlas("ParagonReputation_Bag", true)
				rewardTexture:SetDesaturated(true)
				rewardTexture:SetTexelSnappingBias(0)
				rewardTexture:SetSnapToPixelGrid(false)

				local rewardCheckmark = rewardIcon:CreateTexture(nil, "ARTWORK", nil, 2)
				rewardCheckmark:SetPoint("CENTER", 4, -3)
				rewardCheckmark:SetAtlas("ParagonReputation_Checkmark", true)
				rewardCheckmark:SetDesaturated(true)
				rewardCheckmark:SetTexelSnappingBias(0)
				rewardCheckmark:SetSnapToPixelGrid(false)

				button.journeysFrame = EncounterJournalJourneysFrame
				button.isInit = true
			end

			button.majorFactionData = elementData

			local isLocked = not button.majorFactionData.isUnlocked
			button:DesaturateHierarchy(isLocked and 1 or 0)

			local paragonInfo = elementData.paragonInfo or elementData.essentialParagonInfo
			if isLocked then
				button.Level:SetText("")
				button.LockIcon:Show()
				button.RewardIcon:Hide()
			elseif paragonInfo and paragonInfo.hasRewardPending then
				button.Level:SetText("")
				button.LockIcon:Hide()
				button.RewardIcon:Show()
			else
				button.Level:SetText(paragonInfo and paragonInfo.totalLevel or elementData.renownLevel)
				button.LockIcon:Hide()
				button.RewardIcon:Hide()
			end

			button.Icon:SetAtlas(MAJOR_FACTION_ICON_FORMAT:format(elementData.textureKit))
			button.ProgressBar:RefreshBar(elementData)
		end

		local function journeyCardInitializer(button, elementData)
			if not button.isInit then
				button.JourneyCardProgressBar:ClearAllPoints()
				button.JourneyCardProgressBar:SetPoint("BOTTOMLEFT", 20, 14)
				button.JourneyCardProgressBar:SetPoint("BOTTOMRIGHT", -21, 14)
				button.JourneyCardProgressBar.JourneyCardProgressBarBG:SetAllPoints()
				button.JourneyCardProgressBar.JourneyCardProgressBarBG:SetTexelSnappingBias(0)
				button.JourneyCardProgressBar.JourneyCardProgressBarBG:SetSnapToPixelGrid(false)
				button.JourneyCardProgressBar.JourneyCardProgressBarFrame:SetAllPoints()
				button.JourneyCardProgressBar.JourneyCardProgressBarFrame:SetTexelSnappingBias(0)
				button.JourneyCardProgressBar.JourneyCardProgressBarFrame:SetSnapToPixelGrid(false)

				button.LockFrame:SetPoint("TOPRIGHT", -10, -10)

				button.LockFrame.LockIcon:SetSize(24, 28)
				button.LockFrame.LockIcon:SetAtlas("ui-journeys-greatvault-lock")
				button.LockFrame.LockIcon:SetTexelSnappingBias(0)
				button.LockFrame.LockIcon:SetSnapToPixelGrid(false)

				button.journeysFrame = EncounterJournalJourneysFrame
				button.isInit = true
			end

			button.majorFactionData = elementData

			button.JourneyCardName:SetText(elementData.name)

			local isLocked = not button.majorFactionData.isUnlocked
			button.LockFrame.LockIcon:SetShown(isLocked)

			local normalButtonAtlas = isLocked and "ui-journeys-%s-button-disable" or "ui-journeys-%s-button"
			local pressedButtonAtlas = isLocked and "ui-journeys-%s-button-disable-pressed" or "ui-journeys-%s-button-pressed"

			button.NormalTexture:SetAtlas(normalButtonAtlas:format(elementData.textureKit))
			button.PushedTexture:SetAtlas(pressedButtonAtlas:format(elementData.textureKit))
			button:UpdateHighlightForState()

			local paragonInfo = elementData.paragonInfo or elementData.essentialParagonInfo
			if paragonInfo then
				button.JourneyCardLevel:SetText(_G.JOURNEYS_MAX_LEVEL_LABEL:format(paragonInfo.totalLevel))

				button.JourneyCardProgressBar:SetMinMaxValues(0, paragonInfo.maxValue)
				button.JourneyCardProgressBar:SetValue(paragonInfo.curValue)
			else
				button.JourneyCardLevel:SetText(_G.JOURNEYS_LEVEL_LABEL:format(elementData.renownLevel))

				button.JourneyCardProgressBar:SetMinMaxValues(0, elementData.maxValue)
				button.JourneyCardProgressBar:SetValue(elementData.curValue)
			end
		end

		EncounterJournalJourneysFrame.JourneysList.view:SetElementFactory(function(factory, elementData)
			if elementData.category then
				factory("JourneysListCategoryNameTemplate", categoryNameInitializer)
			elseif elementData.divider then
				factory("JourneysListCategoryDividerTemplate", nop)
			elseif elementData.isRenownJourney then
				factory("Button", renownButtonInitializer)
			else
				factory("JourneyCardButtonTemplate", journeyCardInitializer)
			end
		end)

		EncounterJournalJourneysFrame.JourneysList.view:SetElementSizeCalculator(function(_, elementData)
			if elementData.category then
				return 0, 20
			elseif elementData.divider then
				return 0, 16
			elseif elementData.isRenownJourney then
				return 122, 104
			else
				return 250, 110
			end
		end)

		EncounterJournalJourneysFrame.JourneysList:SetEdgeFadeLength(65)

		function EncounterJournalJourneysFrame:Refresh()
			-- old elements get stuck, flush them
			if self.dataProvider then
				self.dataProvider:Flush()
			end

			local renownIDs = C_MajorFactions.GetMajorFactionIDs(self.expansionFilter)
			local dataProvider = CreateDataProvider()
			self.dataProvider = dataProvider
			self.renownJourneyData = {}
			self.encountersJourneyData = {}

			for _, id in ipairs(renownIDs) do
				if not C_MajorFactions.IsMajorFactionHiddenFromExpansionPage(id) then
					if C_MajorFactions.ShouldDisplayMajorFactionAsJourney(id) then
						t_insert(self.encountersJourneyData, processData(C_MajorFactions.GetMajorFactionData(id)))
					else
						if not self.currentSeason then
							t_insert(self.renownJourneyData, processData(C_MajorFactions.GetMajorFactionData(id)))
						end
					end
				end
			end

			if #self.renownJourneyData >= 1 then
				self:AddCategoryHeader(JOURNEYS_RENOWN_LABEL)

				for _, renown in ipairs(self.renownJourneyData) do
					renown.isRenownJourney = true

					dataProvider:Insert(renown)
				end
			end

			if #self.encountersJourneyData >= 1 then
				if #self.renownJourneyData >= 1 then
					self:AddDivider()
				end

				self:AddCategoryHeader(_G.JOURNEYS_ENCOUNTERS_LABEL)

				for _, encounter in ipairs(self.encountersJourneyData) do
					dataProvider:Insert(encounter)
				end
			end

			self.JourneysList:SetDataProvider(dataProvider)
		end

		function EncounterJournalJourneysFrame.JourneyProgress:SetupProgressDetails()
			local data = self.majorFactionData

			local paragonInfo = data.paragonInfo or data.essentialParagonInfo
			local cur, max, level
			if paragonInfo then
				cur = paragonInfo.curValue
				max = paragonInfo.maxValue
				level = paragonInfo.totalLevel
			else
				cur = data.curValue
				max = data.maxValue
				level = data.renownLevel
			end

			self.ProgressDetailsFrame.JourneyLevel:SetText(level)
			self.ProgressDetailsFrame.JourneyLevelProgress:SetText(_G.JOURNEYS_CURRENT_PROGRESS:format(cur, max))

			if not C_MajorFactions.ShouldUseJourneyRewardTrack(data.factionID)  then
				self.DelveRewardProgressBar:Hide()
			else
				self.DelveRewardProgressBar:SetMinMaxValues(0, max)
				self.DelveRewardProgressBar:SetValue(cur)
				self.DelveRewardProgressBar:Show()
			end
		end

		Mixin(EncounterJournalJourneysFrame.JourneyOverview.OverviewProgressBar, progress_bar_proto)
		EncounterJournalJourneysFrame.JourneyOverview.OverviewProgressBar:SetSwipeTexture(SWIPE_TEXTURE)
		EncounterJournalJourneysFrame.JourneyOverview.OverviewProgressBar:SetTexCoordRange(SWIPE_LOW_TEX_COORDS, SWIPE_HIGH_TEX_COORDS)
	end)

	isInit = true
end
