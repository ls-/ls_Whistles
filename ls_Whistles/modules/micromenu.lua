local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.MicroMenu = {}

-- Lua
local _G = getfenv(0)
local hooksecurefunc = _G.hooksecurefunc
local ipairs = _G.ipairs
local m_abs = _G.math.abs
local next = _G.next
local t_insert = _G.table.insert
local t_sort = _G.table.sort
local t_wipe = _G.table.wipe
local unpack = _G.unpack

-- Mine
local BUTTONS = {
	CharacterMicroButton = {
		id = "character",
		events = {
			PLAYER_ENTERING_WORLD = true,
			UPDATE_INVENTORY_DURABILITY = true,
			CURRENCY_DISPLAY_UPDATE = true,
			-- PORTRAITS_UPDATED = true,
			-- UNIT_PORTRAIT_UPDATE = true,
		},
	},
	ProfessionMicroButton = {
		id = "spellbook",
		events = {},
	},
	PlayerSpellsMicroButton = {
		id = "talent",
		events = {
			HONOR_LEVEL_UPDATE = true,
			PLAYER_LEVEL_CHANGED = true,
			PLAYER_PVP_TALENT_UPDATE = true,
			PLAYER_SPECIALIZATION_CHANGED = true,
			PLAYER_TALENT_UPDATE = true,
			UPDATE_BATTLEFIELD_STATUS = true,
		},
	},
	AchievementMicroButton = {
		id = "achievement",
		events = {
			ACHIEVEMENT_EARNED = true,
			RECEIVED_ACHIEVEMENT_LIST = true,
		},
	},
	HousingMicroButton = {
		id = "housing",
		events = {
			HOUSING_SERVICES_AVAILABILITY_UPDATED = true,
		},
	},
	QuestLogMicroButton = {
		id = "quest",
		events = {},
	},
	GuildMicroButton = {
		id = "guild",
		events = {
			BN_CONNECTED = true,
			BN_DISCONNECTED = true,
			CHAT_DISABLED_CHANGE_FAILED = true,
			CHAT_DISABLED_CHANGED = true,
			CLUB_FINDER_COMMUNITY_OFFLINE_JOIN = true,
			CLUB_INVITATION_ADDED_FOR_SELF = true,
			CLUB_INVITATION_REMOVED_FOR_SELF = true,
			INITIAL_CLUBS_LOADED = true,
			PLAYER_ENTERING_WORLD = true,
			PLAYER_GUILD_UPDATE = true,
			STREAM_VIEW_MARKER_UPDATED = true,
		},
	},
	LFDMicroButton = {
		id = "lfd",
		events = {
			LFG_LOCK_INFO_RECEIVED = true,
		},
	},
	CollectionsMicroButton = {
		id = "collection",
		events = {
			COMPANION_LEARNED = true,
			HEIRLOOMS_UPDATED = true,
			PET_JOURNAL_LIST_UPDATE = true,
			PET_JOURNAL_NEW_BATTLE_SLOT = true,
			PLAYER_ENTERING_WORLD = true,
			TOYS_UPDATED = true,
		},
	},
	EJMicroButton = {
		id = "ej",
		events = {
			PLAYER_ENTERING_WORLD = true,
			UPDATE_INSTANCE_INFO = true,
			VARIABLES_LOADED = true,
			ZONE_CHANGED_NEW_AREA = true,
		},
	},
	StoreMicroButton = {
		id = "store",
		events = {
			STORE_STATUS_CHANGED = true,
		},
	},
	MainMenuMicroButton = {
		id = "main",
		events = {
			MODIFIER_STATE_CHANGED = true,
		},
	},
	HelpMicroButton = {
		help = "",
		events = {},
	},
}

local CLASS_ICONS = {
	["DEATHKNIGHT"] = {
		{1 / 1024, 65 / 1024, 1 / 512, 81 / 512},
		{1 / 1024, 65 / 1024, 82 / 512, 162 / 512},
		{1 / 1024, 65 / 1024, 163 / 512, 243 / 512},
		{1 / 1024, 65 / 1024, 244 / 512, 324 / 512},
	},
	["DEMONHUNTER"] = {
		{66 / 1024, 130 / 1024, 1 / 512, 81 / 512},
		{66 / 1024, 130 / 1024, 82 / 512, 162 / 512},
		{66 / 1024, 130 / 1024, 163 / 512, 243 / 512},
		{66 / 1024, 130 / 1024, 244 / 512, 324 / 512},
	},
	["DRUID"] = {
		{131 / 1024, 195 / 1024, 1 / 512, 81 / 512},
		{131 / 1024, 195 / 1024, 82 / 512, 162 / 512},
		{131 / 1024, 195 / 1024, 163 / 512, 243 / 512},
		{131 / 1024, 195 / 1024, 244 / 512, 324 / 512},
	},
	["EVOKER"] = {
		{196 / 1024, 260 / 1024, 1 / 512, 81 / 512},
		{196 / 1024, 260 / 1024, 82 / 512, 162 / 512},
		{196 / 1024, 260 / 1024, 163 / 512, 243 / 512},
		{196 / 1024, 260 / 1024, 244 / 512, 324 / 512},
	},
	["HUNTER"] = {
		{261 / 1024, 325 / 1024, 1 / 512, 81 / 512},
		{261 / 1024, 325 / 1024, 82 / 512, 162 / 512},
		{261 / 1024, 325 / 1024, 163 / 512, 243 / 512},
		{261 / 1024, 325 / 1024, 244 / 512, 324 / 512},
	},
	["MAGE"] = {
		{326 / 1024, 390 / 1024, 1 / 512, 81 / 512},
		{326 / 1024, 390 / 1024, 82 / 512, 162 / 512},
		{326 / 1024, 390 / 1024, 163 / 512, 243 / 512},
		{326 / 1024, 390 / 1024, 244 / 512, 324 / 512},
	},
	["MONK"] = {
		{391 / 1024, 455 / 1024, 1 / 512, 81 / 512},
		{391 / 1024, 455 / 1024, 82 / 512, 162 / 512},
		{391 / 1024, 455 / 1024, 163 / 512, 243 / 512},
		{391 / 1024, 455 / 1024, 244 / 512, 324 / 512},
	},
	["PALADIN"] = {
		{456 / 1024, 520 / 1024, 1 / 512, 81 / 512},
		{456 / 1024, 520 / 1024, 82 / 512, 162 / 512},
		{456 / 1024, 520 / 1024, 163 / 512, 243 / 512},
		{456 / 1024, 520 / 1024, 244 / 512, 324 / 512},
	},
	["PRIEST"] = {
		{521 / 1024, 585 / 1024, 1 / 512, 81 / 512},
		{521 / 1024, 585 / 1024, 82 / 512, 162 / 512},
		{521 / 1024, 585 / 1024, 163 / 512, 243 / 512},
		{521 / 1024, 585 / 1024, 244 / 512, 324 / 512},
	},
	["ROGUE"] = {
		{586 / 1024, 650 / 1024, 1 / 512, 81 / 512},
		{586 / 1024, 650 / 1024, 82 / 512, 162 / 512},
		{586 / 1024, 650 / 1024, 163 / 512, 243 / 512},
		{586 / 1024, 650 / 1024, 244 / 512, 324 / 512},
	},
	["SHAMAN"] = {
		{651 / 1024, 715 / 1024, 1 / 512, 81 / 512},
		{651 / 1024, 715 / 1024, 82 / 512, 162 / 512},
		{651 / 1024, 715 / 1024, 163 / 512, 243 / 512},
		{651 / 1024, 715 / 1024, 244 / 512, 324 / 512},
	},
	["WARLOCK"] = {
		{716 / 1024, 780 / 1024, 1 / 512, 81 / 512},
		{716 / 1024, 780 / 1024, 82 / 512, 162 / 512},
		{716 / 1024, 780 / 1024, 163 / 512, 243 / 512},
		{716 / 1024, 780 / 1024, 244 / 512, 324 / 512},
	},
	["WARRIOR"] = {
		{781 / 1024, 845 / 1024, 1 / 512, 81 / 512},
		{781 / 1024, 845 / 1024, 82 / 512, 162 / 512},
		{781 / 1024, 845 / 1024, 163 / 512, 243 / 512},
		{781 / 1024, 845 / 1024, 244 / 512, 324 / 512},
	},
}

local function createButtonIndicator(button, indicator)
	indicator = indicator or button:CreateTexture()
	indicator:SetTexture("Interface\\AddOns\\ls_Whistles\\assets\\micromenu-indicator")
	indicator:SetTexCoord(0, 1, 0, 0.5)
	indicator:SetTexelSnappingBias(0)
	indicator:SetSnapToPixelGrid(false)
	indicator:SetDrawLayer("BACKGROUND", -1)
	indicator:ClearAllPoints()
	indicator:SetPoint("BOTTOMLEFT", 5, 4)
	indicator:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", -4, 6)

	return indicator
end

local function updateNormalTexture(button)
	button:SetNormalTexture("Interface\\AddOns\\ls_Whistles\\assets\\micromenu-icons")

	local texture = button:GetNormalTexture()
	texture:SetTexCoord(unpack(CLASS_ICONS[addon.PLAYER_CLASS][1]))
end

local function updateHighlightTexture(button)
	button:SetHighlightTexture("Interface\\AddOns\\ls_Whistles\\assets\\micromenu-icons", "BLEND")

	local texture = button:GetHighlightTexture()
	texture:SetTexCoord(unpack(CLASS_ICONS[addon.PLAYER_CLASS][2]))
end

local function updatePushedTexture(button)
	button:SetPushedTexture("Interface\\AddOns\\ls_Whistles\\assets\\micromenu-icons")

	local texture = button:GetPushedTexture()
	texture:SetTexCoord(unpack(CLASS_ICONS[addon.PLAYER_CLASS][3]))
end

local function updateDisabledTexture(button)
	button:SetDisabledTexture("Interface\\AddOns\\ls_Whistles\\assets\\micromenu-icons")

	local texture = button:GetDisabledTexture()
	texture:SetTexCoord(unpack(CLASS_ICONS[addon.PLAYER_CLASS][4]))
end

local function setNormalHook(button)
	if button.Indicator then
		button.Indicator:SetPoint("BOTTOMLEFT", 5, 4)
		button.Indicator:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", -4, 6)
	end

	if button.Portrait then
		button:SetHighlightTexture("Interface\\AddOns\\ls_Whistles\\assets\\micromenu-icons", "BLEND")

		local texture = button:GetHighlightTexture()
		texture:SetTexCoord(unpack(CLASS_ICONS[addon.PLAYER_CLASS][2]))
		texture:SetAlpha(1)
	end
end

local function setPushedHook(button)
	if button.Indicator then
		button.Indicator:SetPoint("BOTTOMLEFT", 6, 3)
		button.Indicator:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", -3, 5)
	end

	if button.Portrait then
		button:SetHighlightTexture("Interface\\AddOns\\ls_Whistles\\assets\\micromenu-icons", "ADD")

		local texture = button:GetHighlightTexture()
		texture:SetTexCoord(unpack(CLASS_ICONS[addon.PLAYER_CLASS][3]))
		texture:SetAlpha(0.5)
	end
end

local button_proto = {}

function button_proto:OnEnterOverride()
	if KeybindFrames_InQuickKeybindMode() then
		self:QuickKeybindButtonOnEnter()

		return
	end

	-- the main button uses OnUpdate which is disabled, so...
	MainMenuBarMicroButtonMixin.OnEnter(self)
end

function button_proto:UpdateEvents()
	self:UnregisterAllEvents()

	for event in next, BUTTONS[self:GetName()].events do
		self:RegisterEvent(event)
	end

	self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
	self:RegisterEvent("UPDATE_BINDINGS")
end

function button_proto:Update()
	self:UpdateEvents()
end

local function handleMicroButton(button)
	Mixin(button, button_proto)

	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:UnregisterAllEvents()
	button:SetScript("OnEnter", button.OnEnterOverride)
	button:SetScript("OnHide", nil)
	button:SetScript("OnShow", nil)
	button:SetScript("OnUpdate", nil)

	hooksecurefunc(button, "SetNormal", setNormalHook)
	hooksecurefunc(button, "SetPushed", setPushedHook)

	if button.Portrait then
		addon:ForceHide(button.Portrait)
		addon:ForceHide(button.PortraitMask)
	end

	if button.Shadow then
		addon:ForceHide(button.Shadow)
	end

	if button.PushedShadow then
		addon:ForceHide(button.PushedShadow)
	end
end

local char_button_proto = {}
do
	local DURABILITY_COLON = _G.DURABILITY .. _G.HEADER_COLON

	local slots = {
		[ 1] = _G["HEADSLOT"],
		[ 3] = _G["SHOULDERSLOT"],
		[ 5] = _G["CHESTSLOT"],
		[ 6] = _G["WAISTSLOT"],
		[ 7] = _G["LEGSSLOT"],
		[ 8] = _G["FEETSLOT"],
		[ 9] = _G["WRISTSLOT"],
		[10] = _G["HANDSSLOT"],
		[16] = _G["MAINHANDSLOT"],
		[17] = _G["SECONDARYHANDSLOT"],
	}
	local durabilities = {}
	local minDurability = 100

	function char_button_proto:OnEnterOverride()
		button_proto.OnEnterOverride(self)

		if self:IsEnabled() then
			if #durabilities > 0 then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(DURABILITY_COLON)

				for i = 1, 17 do
					local cur = durabilities[i]
					if cur then
						GameTooltip:AddDoubleLine(slots[i], ("%d%%"):format(cur), 1, 1, 1, addon:GetRYGColor(cur / 100, true))
					end
				end

				GameTooltip:Show()
			end
		end
	end

	local deferredUpdate, timer

	function char_button_proto:OnEventHook(event)
		if event == "UPDATE_INVENTORY_DURABILITY" then
			if not deferredUpdate then
				deferredUpdate = function()
					self:UpdateIndicator()

					timer = nil
				end
			end

			if not timer then
				timer = C_Timer.NewTimer(1, deferredUpdate)
			end
		end
	end

	function char_button_proto:Update()
		button_proto.Update(self)

		if C.db.profile.micro_menu.buttons.character.tooltip then
			self:SetScript("OnEnter", self.OnEnterOverride)
		else
			self:SetScript("OnEnter", button_proto.OnEnterOverride)
		end

		self:UpdateIndicator()
	end

	function char_button_proto:UpdateIndicator()
		t_wipe(durabilities)
		minDurability = 100

		for i = 1, 17 do
			if slots[i] then
				local cur, max = GetInventoryItemDurability(i)

				if cur then
					cur = cur / max * 100

					durabilities[i] = cur

					if cur < minDurability then
						minDurability = cur
					end
				end
			end
		end

		self.Indicator:SetVertexColor(addon:GetRYGColor(minDurability / 100, true))

		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()

			self:GetScript("OnEnter")(self)
		end
	end
end

local quest_button_proto = {}
do
	function quest_button_proto:OnEnterOverride()
		button_proto.OnEnterOverride(self)

		if self:IsEnabled() then
			GameTooltip:AddLine(L["DAILY_QUEST_RESET_TIME_TOOLTIP"]:format(SecondsToTime(GetQuestResetTime())))
			GameTooltip:Show()
		end
	end

	function quest_button_proto:Update()
		button_proto.Update(self)

		if C.db.profile.micro_menu.buttons.quest.tooltip then
			self:SetScript("OnEnter", self.OnEnterOverride)
		else
			self:SetScript("OnEnter", button_proto.OnEnterOverride)
		end
	end
end

local lfd_button_proto = {}
do
	local DAMAGER = D.global.colors.red:WrapTextInColorCode(_G.DAMAGER)
	local HEALER = D.global.colors.green:WrapTextInColorCode(_G.HEALER)
	local TANK = D.global.colors.blue:WrapTextInColorCode(_G.TANK)

	local cta = {
		tank = {},
		healer = {},
		damager = {},
		total = 0
	}
	local ROLES = {"tank", "healer", "damager"}
	local ROLE_NAMES = {
		damager = DAMAGER,
		healer = HEALER,
		tank = TANK,
	}

	local function fetchCTAData(dungeonID, dungeonName, shortageRole, shortageIndex, numRewards)
		cta[shortageRole][dungeonID] = cta[shortageRole][dungeonID] or {}
		cta[shortageRole][dungeonID].name = dungeonName

		for rewardIndex = 1, numRewards do
			local name, texture, quantity = GetLFGDungeonShortageRewardInfo(dungeonID, shortageIndex, rewardIndex)

			if not name or name == "" then
				name = _G.UNKNOWN
				texture = texture or QUESTION_MARK_ICON
			end

			cta[shortageRole][dungeonID][rewardIndex] = {
				name = name,
				texture = "|T" .. texture .. ":0|t",
				quantity = quantity or 1
			}

			cta.total = cta.total + 1
		end
	end

	local function updateCTARewards(dungeonID, dungeonName)
		if IsLFGDungeonJoinable(dungeonID) then
			for shortageIndex = 1, LFG_ROLE_NUM_SHORTAGE_TYPES do
				local eligible, forTank, forHealer, forDamager, numRewards = GetLFGRoleShortageRewards(dungeonID, shortageIndex)
				local tank, healer, damager = UnitGetAvailableRoles("player")

				if eligible and numRewards > 0 then
					if tank and forTank then
						fetchCTAData(dungeonID, dungeonName, "tank", shortageIndex, numRewards)
					end

					if healer and forHealer then
						fetchCTAData(dungeonID, dungeonName, "healer", shortageIndex, numRewards)
					end

					if damager and forDamager then
						fetchCTAData(dungeonID, dungeonName, "damager", shortageIndex, numRewards)
					end
				end
			end
		end
	end

	function lfd_button_proto:OnEnterOverride()
		button_proto.OnEnterOverride(self)

		if self:IsEnabled() then
			for _, role in next, ROLES do
				local hasTitle = false

				for _, v in next, cta[role] do
					if v then
						if not hasTitle then
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine(_G.LFG_CALL_TO_ARMS:format(ROLE_NAMES[role]))

							hasTitle = true
						end

						GameTooltip:AddLine(v.name, 1, 1, 1)

						for i = 1, #v do
							GameTooltip:AddDoubleLine(v[i].name, v[i].quantity .. v[i].texture, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5)
						end
					end
				end
			end

			GameTooltip:Show()
		end
	end

	function lfd_button_proto:OnEventHook(event)
		if event == "LFG_LOCK_INFO_RECEIVED" then
			if GetTime() - (self.lastUpdate or 0) > 9 then
				self:UpdateIndicator()
				self.lastUpdate = GetTime()
			end
		end
	end

	function lfd_button_proto:Update()
		button_proto.Update(self)

		if C.db.profile.micro_menu.buttons.lfd.tooltip then
			self:SetScript("OnEnter", self.OnEnterOverride)
		else
			self:SetScript("OnEnter", button_proto.OnEnterOverride)
		end

		if not self.Ticker then
			self.Ticker = C_Timer.NewTicker(15, function()
				if C.db.profile.micro_menu.buttons.lfd.tooltip then
					RequestLFDPlayerLockInfo()
					RequestLFDPartyLockInfo()
				end

				self:UpdateIndicator()
			end)
		end

		self:UpdateIndicator()
	end

	function lfd_button_proto:UpdateIndicator()
		t_wipe(cta.tank)
		t_wipe(cta.healer)
		t_wipe(cta.damager)
		cta.total = 0

		if C.db.profile.micro_menu.buttons.lfd.tooltip then
			-- dungeons
			for i = 1, GetNumRandomDungeons() do
				updateCTARewards(GetLFGRandomDungeonInfo(i))
			end

			-- raids
			for i = 1, GetNumRFDungeons() do
				updateCTARewards(GetRFDungeonInfo(i))
			end
		end

		if cta.total > 0 then
			UIFrameFlash(self.FlashBorder, 1, 1, -1, false, 0, 0, "microbutton")
		else
			UIFrameFlashStop(self.FlashBorder)
		end

		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()

			self:GetScript("OnEnter")(self)
		end
	end
end

local ej_button_proto = {}
do
	local isInfoRequested = false

	local lockouts = {}
	local instanceNames = {}
	local instanceResets = {}

	local EXPIRATION_FORMAT = _G.RAID_INSTANCE_EXPIRES .. _G.HEADER_COLON
	local WORLD_BOSS = _G.RAID_INFO_WORLD_BOSS
	local WORLD_BOSS_ID = 172
	local WORLD_BOSS_PROGRESS = "1 / 1"

	local function difficultySortFunc(a, b)
		return a[1] < b[1]
	end

	function ej_button_proto:OnEnterOverride()
		button_proto.OnEnterOverride(self)

		if self:IsEnabled() then
			if not isInfoRequested then
				RequestRaidInfo()

				isInfoRequested = true
			end

			for _, instanceReset in next, instanceResets do
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(EXPIRATION_FORMAT:format(SecondsToTime(instanceReset, true, nil, 3)))

				for _, instanceName in ipairs(instanceNames) do
					local resetData = lockouts[instanceReset][instanceName]
					if resetData then
						GameTooltip:AddLine(instanceName, 1, 1, 1)

						-- it's easier to sort on demand here
						t_sort(resetData, difficultySortFunc)

						for _, difficultyData in ipairs(resetData) do
							GameTooltip:AddDoubleLine(difficultyData[2], difficultyData[3], 0.5, 0.5, 0.5, difficultyData[4].r, difficultyData[4].g, difficultyData[4].b)
						end
					end
				end
			end

			GameTooltip:Show()
		end
	end

	function ej_button_proto:OnEventHook(event)
		if event == "UPDATE_INSTANCE_INFO" then
			local savedInstances = GetNumSavedInstances()
			local savedWorldBosses = GetNumSavedWorldBosses()

			if savedInstances + savedWorldBosses > 0 then
				t_wipe(lockouts)
				t_wipe(instanceNames)
				t_wipe(instanceResets)

				for i = 1, savedInstances + savedWorldBosses do
					if i <= savedInstances then
						local instanceName, _, instanceReset, difficultyID, _, _, _, _, _, difficultyName, numEncounters, encounterProgress  = GetSavedInstanceInfo(i)
						if instanceReset > 0 then
							if not lockouts[instanceReset] then
								lockouts[instanceReset] = {}

								t_insert(instanceResets, instanceReset)
							end

							if not lockouts[instanceReset][instanceName] then
								lockouts[instanceReset][instanceName] = {}

								-- the same instance can have multiple resets because heroics reset daily, but mythics reset weekly
								if not instanceNames[instanceName] then

									instanceNames[instanceName] = true
									t_insert(instanceNames, instanceName)
								end
							end

							t_insert(lockouts[instanceReset][instanceName], {
								difficultyID,
								difficultyName,
								encounterProgress .. " / " .. numEncounters,
								encounterProgress == numEncounters and C.db.global.colors.red or C.db.global.colors.green,
							})
						end
					else
						local instanceName, _, instanceReset = GetSavedWorldBossInfo(i - savedInstances)
						if instanceReset > 0 then
							-- there's some desync between instance and WB reset timers, sometimes it can be as bad as 600s
							for _, reset in next, instanceResets do
								if m_abs(reset - instanceReset) <= 600 then
									instanceReset = reset

									break
								end
							end

							if not lockouts[instanceReset] then
								lockouts[instanceReset] = {}

								t_insert(instanceResets, instanceReset)
							end

							if not lockouts[instanceReset][instanceName] then
								lockouts[instanceReset][instanceName] = {}

								if not instanceNames[instanceName] then

									instanceNames[instanceName] = true
									t_insert(instanceNames, instanceName)
								end
							end

							t_insert(lockouts[instanceReset][instanceName], {
								WORLD_BOSS_ID,
								WORLD_BOSS,
								WORLD_BOSS_PROGRESS,
								C.db.global.colors.red,
							})
						end
					end
				end

				t_sort(instanceNames)
				t_sort(instanceResets)
			end

			if GameTooltip:IsOwned(self) then
				self:GetScript("OnEnter")(self)
			end
		end
	end

	function ej_button_proto:OnLeaveHook()
		isInfoRequested = false
	end

	function ej_button_proto:Update()
		button_proto.Update(self)

		if C.db.profile.micro_menu.buttons.ej.tooltip then
			self:SetScript("OnEnter", self.OnEnterOverride)
		else
			self:SetScript("OnEnter", button_proto.OnEnterOverride)
		end
	end
end

local main_button_proto = {}
do
	local cache = {}
	local addOns = {}
	local cpuUsage, memUsage = 0, 0
	local latencyHome, latencyWorld = 0, 0
	local LATENCY_COLON = L["LATENCY"] .. _G.HEADER_COLON
	local PERFORMANCE_COLON = _G.ADDON_LIST_PERFORMANCE_HEADER .. _G.HEADER_COLON
	local LATENCY_TEMPLATE = "%d |cff808080" .. _G.MILLISECONDS_ABBR .. "|r"
	local MEMORY_TEMPLATE = "%.2f |cff808080MB|r"
	local MEMORY_CPU_TEMPLATE = "%.2f |cff808080MB|r |cff313131\124 |r|cff808080%.2f%%|r"
	local _

	local function sortFunc(a, b)
		return a[2] > b[2]
	end

	local function getCPUUsage(t, id, metric)
		local clientCPU = C_AddOnProfiler.GetApplicationMetric(metric)
		local addonsCPU = C_AddOnProfiler.GetOverallMetric(metric)

		for i, data in next, cache do
			local addonCPU = C_AddOnProfiler.GetAddOnMetric(data[1], metric)
			local relativeCPU = clientCPU - addonsCPU + addonCPU
			if relativeCPU <= 0 then
				cache[i][id] = 0
			else
				cache[i][id] = addonCPU / relativeCPU * 100
			end
		end

		return addonsCPU / clientCPU * 100
	end

	local latencyCurve = C_CurveUtil.CreateColorCurve()
	latencyCurve:AddPoint(0, D.global.colors.green)
	latencyCurve:AddPoint(300, D.global.colors.yellow)
	latencyCurve:AddPoint(600, D.global.colors.red)

	function main_button_proto:OnEnterOverride()
		button_proto.OnEnterOverride(self)

		if self:IsEnabled() then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(LATENCY_COLON)
			GameTooltip:AddDoubleLine(L["LATENCY_HOME"], LATENCY_TEMPLATE:format(latencyHome), 1, 1, 1, latencyCurve:EvaluateUnpacked(latencyHome))
			GameTooltip:AddDoubleLine(L["LATENCY_WORLD"], LATENCY_TEMPLATE:format(latencyWorld), 1, 1, 1, latencyCurve:EvaluateUnpacked(latencyWorld))

			if IsShiftKeyDown() then
				UpdateAddOnMemoryUsage()

				for i = 1, C_AddOns.GetNumAddOns() do
					if C_AddOns.IsAddOnLoaded(i) then
						if not cache[i] then
							cache[i] = {}
							cache[i][1], cache[i][2] = C_AddOns.GetAddOnInfo(i) -- name, title
						end

						cache[i][3] = GetAddOnMemoryUsage(i)
					end
				end

				local isProfilerEnabled = C_AddOnProfiler.IsEnabled()
				if isProfilerEnabled then
					cpuUsage = getCPUUsage(cache, 4, Enum.AddOnProfilerMetric.RecentAverageTime)
				end

				t_wipe(addOns)
				memUsage = 0

				for _, data in next, cache do
					t_insert(addOns, {data[2], data[3], data[4]})

					memUsage = memUsage + data[3]
				end

				if memUsage > 0 then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(PERFORMANCE_COLON)

					t_sort(addOns, sortFunc)

					for _, data in ipairs(addOns) do
						local m = data[2]

						if isProfilerEnabled then
							GameTooltip:AddDoubleLine(data[1], MEMORY_CPU_TEMPLATE:format(m / 1024, data[3]), 1, 1, 1, addon:GetGYRColor(m / (memUsage == m and 1 or (memUsage - m)), true))
						else
							GameTooltip:AddDoubleLine(data[1], MEMORY_TEMPLATE:format(m / 1024), 1, 1, 1, addon:GetGYRColor(m / (memUsage == m and 1 or (memUsage - m)), true))
						end
					end

					if isProfilerEnabled then
						GameTooltip:AddDoubleLine(_G.TOTAL, MEMORY_CPU_TEMPLATE:format(memUsage / 1024, cpuUsage))
					else
						GameTooltip:AddDoubleLine(_G.TOTAL, MEMORY_TEMPLATE:format(memUsage / 1024))
					end
				end
			else
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(L["MAINMENU_BUTTON_HOLD_TOOLTIP"])
			end

			GameTooltip:Show()
		end
	end

	function main_button_proto:OnEventOverride(event)
		if event == "MODIFIER_STATE_CHANGED" then
			if GameTooltip:IsOwned(self) then
				GameTooltip:Hide()

				self:GetScript("OnEnter")(self)
			end
		elseif event == "UPDATE_BINDINGS" then
			self.tooltipText = MicroButtonTooltipText(_G.MAINMENU_BUTTON, "TOGGLEGAMEMENU")
		end
	end

	function main_button_proto:Update()
		button_proto.Update(self)

		if C.db.profile.micro_menu.buttons.main.tooltip then
			self:SetScript("OnEnter", self.OnEnterOverride)
		else
			self:SetScript("OnEnter", button_proto.OnEnterOverride)
		end

		if not self.Ticker then
			self.Ticker = C_Timer.NewTicker(30, function()
				self:UpdateIndicator()
			end)
		end

		self:UpdateIndicator()
	end

	function main_button_proto:UpdateIndicator()
		_, _, latencyHome, latencyWorld = GetNetStats()
		self.Indicator:SetVertexColor(latencyCurve:EvaluateUnpacked(latencyWorld))
	end
end

local BAD_SYSTEMS = {
	MicroButtons = true,
	TeleportToHouseHelpTips = true,
}

local function hideHelpTips(self)
	if C.db.profile.micro_menu.helptips then return end

	for frame in self.framePool:EnumerateActive() do
		if frame.info and BAD_SYSTEMS[frame.info.system] then
			frame:Hide()
		end
	end
end

local isInit = false

function addon.MicroMenu:IsInit()
	return isInit
end

function addon.MicroMenu:Init()
	if isInit then return end
	if not C.db.profile.micro_menu.enabled then return end

	for name, data in next, BUTTONS do
		local button = _G[name]

		handleMicroButton(button)

		if data.id == "character" then
			Mixin(button, char_button_proto)
			button:HookScript("OnEvent", button.OnEventHook)

			updateNormalTexture(button)
			updatePushedTexture(button)
			updateHighlightTexture(button)
			updateDisabledTexture(button)

			button.Indicator = createButtonIndicator(button)
		-- elseif data.id == "spellbook" then
		-- elseif data.id == "talent" then
		-- elseif data.id == "achievement" then
		elseif data.id == "quest" then
			Mixin(button, quest_button_proto)
		-- elseif data.id == "housing" then
		-- elseif data.id == "guild" then
		elseif data.id == "lfd" then
			Mixin(button, lfd_button_proto)
			button:HookScript("OnEvent", button.OnEventHook)
		-- elseif data.id == "collection" then
		elseif data.id == "ej" then
			Mixin(button, ej_button_proto)
			button:HookScript("OnEvent", button.OnEventHook)
			button:HookScript("OnLeave", button.OnLeaveHook)
		-- elseif data.id == "store" then
		elseif data.id == "main" then
			Mixin(button, main_button_proto)
			button:SetScript("OnEvent", button.OnEventOverride)
			button:SetScript("OnLeave", MainMenuBarMicroButtonMixin.OnLeave)

			button.Indicator = createButtonIndicator(button, button.MainMenuBarPerformanceBar)
		-- elseif data.id == "help" then
		end

		button:Update()
	end

	hooksecurefunc(HelpTip, "Show", hideHelpTips)

	addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		hideHelpTips(HelpTip)
	end)

	if IsLoggedIn() then
		hideHelpTips(HelpTip)
	end

	isInit = true
end

function addon.MicroMenu:UpdateButton(id)
	for name, data in next, BUTTONS do
		if data.id == id then
			local button = _G[name]
			if button then
				button:Update()
			end
		end
	end
end
