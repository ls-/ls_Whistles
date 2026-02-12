local _, addon = ...
local C, D, L, LEM = addon.C, addon.D, addon.L, addon.LibEditMode
addon.ActionBars = {}

-- Lua
local _G = getfenv(0)
local hooksecurefunc = _G.hooksecurefunc
local next = _G.next

-- Mine
local LKB = LibStub("LibKeyBound-1.0")

local BARS = {}
do
	BARS.MainActionBar = {} -- Action Bar 1
	for i = 1, 12 do
		BARS.MainActionBar[i] = _G["ActionButton" .. i]
	end

	BARS.MultiBarBottomLeft = {} -- Action Bar 2
	for i = 1, 12 do
		BARS.MultiBarBottomLeft[i] = _G["MultiBarBottomLeftButton" .. i]
	end

	BARS.MultiBarBottomRight = {} -- Action Bar 3
	for i = 1, 12 do
		BARS.MultiBarBottomRight[i] = _G["MultiBarBottomRightButton" .. i]
	end

	BARS.MultiBarRight = {} -- Action Bar 4
	for i = 1, 12 do
		BARS.MultiBarRight[i] = _G["MultiBarRightButton" .. i]
	end

	BARS.MultiBarLeft = {} -- Action Bar 5
	for i = 1, 12 do
		BARS.MultiBarLeft[i] = _G["MultiBarLeftButton" .. i]
	end

	BARS.MultiBar5 = {}
	for i = 1, 12 do
		BARS.MultiBar5[i] = _G["MultiBar5Button" .. i]
	end

	BARS.MultiBar6 = {}
	for i = 1, 12 do
		BARS.MultiBar6[i] = _G["MultiBar6Button" .. i]
	end

	BARS.MultiBar7 = {}
	for i = 1, 12 do
		BARS.MultiBar7[i] = _G["MultiBar7Button" .. i]
	end

	BARS.PetActionBar = {}
	for i = 1, 10 do
		BARS.PetActionBar[i] = _G["PetActionButton" .. i]
	end

	BARS.StanceBar = {}
	for i = 1, 10 do
		BARS.StanceBar[i] = _G["StanceButton" .. i]
	end

	BARS.PossessActionBar = {}
	for i = 1, 2 do
		BARS.PossessActionBar[i] = _G["PossessButton" .. i]
	end

	BARS.ExtraAbilityContainer = {
		ExtraActionButton1,
	}
end

local BUTTONS = {}
do
	for i = 1, 12 do
		BUTTONS[_G["ActionButton" .. i]] = "MainActionBar"
	end

	for i = 1, 12 do
		BUTTONS[_G["MultiBarBottomLeftButton" .. i]] = "MultiBarBottomLeft"
	end

	for i = 1, 12 do
		BUTTONS[_G["MultiBarBottomRightButton" .. i]] = "MultiBarBottomRight"
	end

	for i = 1, 12 do
		BUTTONS[_G["MultiBarRightButton" .. i]] = "MultiBarRight"
	end

	for i = 1, 12 do
		BUTTONS[_G["MultiBarLeftButton" .. i]] = "MultiBarLeft"
	end

	for i = 1, 12 do
		BUTTONS[_G["MultiBar5Button" .. i]] = "MultiBar5"
	end

	for i = 1, 12 do
		BUTTONS[_G["MultiBar6Button" .. i]] = "MultiBar6"
	end

	for i = 1, 12 do
		BUTTONS[_G["MultiBar7Button" .. i]] = "MultiBar7"
	end

	for i = 1, 10 do
		BUTTONS[_G["PetActionButton" .. i]] = "PetActionBar"
	end

	for i = 1, 10 do
		BUTTONS[_G["StanceButton" .. i]] = "StanceBar"
	end

	for i = 1, 2 do
		BUTTONS[_G["PossessButton" .. i]] = "PossessActionBar"
	end

	BUTTONS[ExtraActionButton1] = "ExtraAbilityContainer"
end

local SYSTEMS = {
	MainBar = "MainActionBar",
	Bar2 = "MultiBarBottomLeft",
	Bar3 = "MultiBarBottomRight",
	RightBar2 = "MultiBarLeft",
	RightBar1 = "MultiBarRight",
	ExtraBar1 = "MultiBar5",
	ExtraBar2 = "MultiBar6",
	ExtraBar3 = "MultiBar7",
	StanceBar = "StanceBar",
	PetActionBar = "PetActionBar",
	PossessActionBar = "PossessActionBar",
	ExtraAbilities = "ExtraAbilityContainer",
}

local SPELLCAST_EVENTS = {
	"UNIT_SPELLCAST_SENT",
}

local SPELLCAST_UNIT_EVENTS = {
	"UNIT_SPELLCAST_CHANNEL_START",
	"UNIT_SPELLCAST_CHANNEL_STOP",
	"UNIT_SPELLCAST_EMPOWER_START",
	"UNIT_SPELLCAST_EMPOWER_STOP",
	"UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_INTERRUPTED",
	"UNIT_SPELLCAST_RETICLE_CLEAR",
	"UNIT_SPELLCAST_RETICLE_TARGET",
	"UNIT_SPELLCAST_START",
	"UNIT_SPELLCAST_STOP",
	"UNIT_SPELLCAST_SUCCEEDED",
}

local function actionButtonUpdateUnusable(self, _, isUsable, notEnoughMana)
	-- if this one is true just undo the unusable grey tint and bail
	if C_LevelLink.IsActionLocked(self.action) then
		self.icon:SetVertexColor(1, 1, 1)

		return
	end

	if isUsable == nil or notEnoughMana == nil then
		isUsable, notEnoughMana = C_ActionBar.IsUsableAction(self.action)
	end

	-- if self.action == 3 then
	-- 	isUsable, notEnoughMana = false, true
	-- end

	if isUsable then
		self.icon:SetDesaturated(false)
		-- self.icon:SetVertexColor(1, 1, 1)
	elseif notEnoughMana then
		if C.db.profile.actionbars.desaturation.oom then
			self.icon:SetDesaturated(true)
			self.icon:SetVertexColor(0.3, 0.5, 1)
		end
	else
		if C.db.profile.actionbars.desaturation.unusable then
			self.icon:SetDesaturated(true)
			self.icon:SetVertexColor(1, 1, 1)
		end
	end
end

local function petActionBarUpdateUnusable(self)
	if not C.db.profile.actionbars.desaturation.unusable then return end

	for i, button in next, self.actionButtons do
		if button.icon:IsShown() then
			if GetPetActionSlotUsable(i) then
				button.icon:SetDesaturated(false)
			else
				button.icon:SetDesaturated(true)
				button.icon:SetVertexColor(1, 1, 1)
			end
		end
	end
end

local function actionButtonUpdateHotkey(self)
	local hotKey = self.HotKey
	if not (hotKey and self.commandName) then return end

	local barName = BUTTONS[self]
	if barName then
		local config = addon:GetActionBarConfigForBar(barName)
		if not config.hotkey then
			hotKey:SetText(RANGE_INDICATOR)
			hotKey:Hide()

			return
		end
	end

	local key = GetBindingKey(self.commandName)
	if key then
		if IsBindingForGamePad(key) then
			hotKey:SetPoint("TOPLEFT", 0, 0)
			hotKey:SetPoint("TOPRIGHT", 0, 0)
		elseif self.hotkeyX then
			hotKey:SetPoint("TOPLEFT", 1, -4)
			hotKey:SetPoint("TOPRIGHT", -1, -4)
		else
			hotKey:SetPoint("TOPLEFT", 4, -6)
			hotKey:SetPoint("TOPRIGHT", -4, -6)
		end

		if C.db.profile.actionbars.short_hotkey then
			key = LKB:ToShortKey(key)
		else
			key = GetBindingText(key, true)
		end
	end

	if not key or key == "" then
		hotKey:SetText(RANGE_INDICATOR)
		hotKey:Hide()
	else
		hotKey:SetText(key)
		hotKey:Show()
	end

end

local function actionButtonUpdateMacro(self)
	local name = self.Name
	if not name then return end

	local barName = BUTTONS[self]
	if barName then
		local config = addon:GetActionBarConfigForBar(barName)

		name:SetShown(config.macro)
	end
end

local isInit = false

function addon.ActionBars:IsInit()
	return isInit
end

function addon.ActionBars:Init()
	if isInit then return end
	if not C.db.profile.actionbars.enabled then return end

	local controller = CreateFrame("Frame")
	controller:RegisterEvent("UPDATE_BINDINGS")
	controller:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
	controller:SetScript("OnEvent", function(_, event)
		if event == "UPDATE_BINDINGS" or event == "GAME_PAD_ACTIVE_CHANGED" then
			for button in next, BUTTONS do
				actionButtonUpdateHotkey(button)
			end
		end
	end)

	-- all buttons except for pet, stance, and possess buttons
	for button in next, BUTTONS do
		addon.Button:SkinActionButton(button)

		if button.UpdateUsable then
			hooksecurefunc(button, "UpdateUsable", actionButtonUpdateUnusable)
		end

		-- since Blizz stance buttons don't show hotkeys we'll be handing everything ourselves
		button:UnregisterEvent("GAME_PAD_ACTIVE_CHANGED")
		button:UnregisterEvent("UPDATE_BINDINGS")

		if button.HotKey and button.commandName then
			actionButtonUpdateHotkey(button)
		end

		if button.Name and button.Update then
			hooksecurefunc(button, "Update", actionButtonUpdateMacro)
		end
	end

	hooksecurefunc(PetActionBar, "Update", petActionBarUpdateUnusable)

	hooksecurefunc(MainActionBar, "UpdateEndCaps", function()
		local endCaps = MainActionBar.EndCaps
		if not endCaps or not endCaps:IsShown() then return end

		local config = addon:GetActionBarConfigForBar("MainActionBar")

		local leftTexture = config.textures.left_cap
		if leftTexture ~= "default" then
			if leftTexture == "" then
				endCaps.LeftEndCap:SetTexture(0)
			else
				endCaps.LeftEndCap:SetAtlas(leftTexture)
			end
		end

		local rightTexture = config.textures.right_cap
		if rightTexture ~= "default" then
			if rightTexture == "" then
				endCaps.RightEndCap:SetTexture(0)
			else
				endCaps.RightEndCap:SetAtlas(rightTexture)
			end
		end
	end)

	self:UpdateCastVFX()

	LEM:RegisterCallback("layout", function(layoutName)
		-- AceDB takes care of layout table duplication
		local layout = C.db.profile.actionbars.layouts[layoutName]

		for name in next, BARS do
			-- same as above
			local config = layout[name]

			addon.ActionBars:UpdateFading(name)
			addon.ActionBars:UpdateDesaturation(name)
			addon.ActionBars:UpdateHotkey(name)
			addon.ActionBars:UpdateMacro(name)
			addon.ActionBars:UpdateArt(name)
			addon.ActionBars:UpdateEndCaps()
		end
	end)

	for name, id in next, Enum.EditModeActionBarSystemIndices do
		local barName = SYSTEMS[name]

		if id == Enum.EditModeActionBarSystemIndices.MainBar then
			LEM:AddSystemSettings(Enum.EditModeSystem.ActionBar, {
				{
					name = _G.TEXTURES_SUBHEADER,
					kind = LEM.SettingType.Divider,
					hidden = function()
						return not C.db.global.settings.MainActionBar.textures
					end,
				},
				{
					name = L["LEFT_ENDCAP"],
					kind = LEM.SettingType.Dropdown,
					hidden = function()
						return not C.db.global.settings.MainActionBar.textures
					end,
					default = D.profile.actionbars.layouts["*"].MainActionBar.textures.left_cap,
					get = function(layoutName)
						return C.db.profile.actionbars.layouts[layoutName].MainActionBar.textures.left_cap
					end,
					set = function(layoutName, value)
						if C.db.profile.actionbars.layouts[layoutName].MainActionBar.textures.left_cap ~= value then
							C.db.profile.actionbars.layouts[layoutName].MainActionBar.textures.left_cap = value

							addon.ActionBars:UpdateEndCaps()
						end
					end,
					values = {
						{
							isRadio = true,
							text = _G.DEFAULT,
							value = "default",
						},
						{
							isRadio = true,
							text = L["GRYPHON"],
							value = "ui-hud-actionbar-gryphon-left",
						},
						{
							isRadio = true,
							text = L["WYVERN"],
							value = "ui-hud-actionbar-wyvern-left",
						},
						{
							isRadio = true,
							text = _G.NONE,
							value = "",
						},
					},
				},
				{
					name = L["RIGHT_ENDCAP"],
					kind = LEM.SettingType.Dropdown,
					hidden = function()
						return not C.db.global.settings.MainActionBar.textures
					end,
					default = D.profile.actionbars.layouts["*"].MainActionBar.textures.right_cap,
					get = function(layoutName)
						return C.db.profile.actionbars.layouts[layoutName].MainActionBar.textures.right_cap
					end,
					set = function(layoutName, value)
						if C.db.profile.actionbars.layouts[layoutName].MainActionBar.textures.right_cap ~= value then
							C.db.profile.actionbars.layouts[layoutName].MainActionBar.textures.right_cap = value

							addon.ActionBars:UpdateEndCaps()
						end
					end,
					values = {
						{
							isRadio = true,
							text = _G.DEFAULT,
							value = "default",
						},
						{
							isRadio = true,
							text = L["GRYPHON"],
							value = "ui-hud-actionbar-gryphon-right",
						},
						{
							isRadio = true,
							text = L["WYVERN"],
							value = "ui-hud-actionbar-wyvern-right",
						},
						{
							isRadio = true,
							text = _G.NONE,
							value = "",
						}
					},
				},
				{
					name = "DNT Caps Settings Expander",
					kind = LEM.SettingType.Expander,
					expandedLabel = L["COLLAPSE_OPTIONS"],
					collapsedLabel = _G.TEXTURES_SUBHEADER,
					appendArrow = true,
					default = D.global.settings.MainActionBar.textures,
					get = function()
						return C.db.global.settings.MainActionBar.textures
					end,
					set = function(_, value)
						C.db.global.settings.MainActionBar.textures = value
					end,
				},
			}, id)
		end

		if id ~= Enum.EditModeActionBarSystemIndices.PossessActionBar then
			LEM:AddSystemSettings(Enum.EditModeSystem.ActionBar, {
				{
					name = _G.LOCALE_TEXT_LABEL,
					kind = LEM.SettingType.Divider,
					hidden = function()
						return not C.db.global.settings[barName].text
					end,
				},
				{
					name = _G.KEY_BINDING,
					kind = LEM.SettingType.Checkbox,
					hidden = function()
						return not C.db.global.settings[barName].text
					end,
					default = D.profile.actionbars.layouts["*"]["**"].hotkey,
					get = function(layoutName)
						return C.db.profile.actionbars.layouts[layoutName][barName].hotkey
					end,
					set = function(layoutName, value)
						if C.db.profile.actionbars.layouts[layoutName][barName].hotkey ~= value then
							C.db.profile.actionbars.layouts[layoutName][barName].hotkey = value

							addon.ActionBars:UpdateHotkey(barName)
						end
					end,
				},
			}, id)

			if id ~= Enum.EditModeActionBarSystemIndices.PetActionBar and id ~= Enum.EditModeActionBarSystemIndices.StanceBar then
				LEM:AddSystemSettings(Enum.EditModeSystem.ActionBar, {
					{
						name = _G.MACRO,
						kind = LEM.SettingType.Checkbox,
						hidden = function()
							return not C.db.global.settings[barName].text
						end,
						default = D.profile.actionbars.layouts["*"]["**"].hotkey,
						get = function(layoutName)
							return C.db.profile.actionbars.layouts[layoutName][barName].macro
						end,
						set = function(layoutName, value)
							if C.db.profile.actionbars.layouts[layoutName][barName].macro ~= value then
								C.db.profile.actionbars.layouts[layoutName][barName].macro = value

								addon.ActionBars:UpdateMacro(barName)
							end
						end,
					},
				}, id)
			end

			LEM:AddSystemSettings(Enum.EditModeSystem.ActionBar, {
				{
					name = "DNT Text Settings Expander",
					kind = LEM.SettingType.Expander,
					expandedLabel = L["COLLAPSE_OPTIONS"],
					collapsedLabel = _G.LOCALE_TEXT_LABEL,
					appendArrow = true,
					default = D.global.settings["**"].text,
					get = function()
						return C.db.global.settings[barName].text
					end,
					set = function(_, value)
						C.db.global.settings[barName].text = value
					end,
				},
			}, id)
		end

		LEM:AddSystemSettings(Enum.EditModeSystem.ActionBar, {
			{
				name = L["FADING"],
				kind = LEM.SettingType.Divider,
				hidden = function()
					return not C.db.global.settings[barName].fade
				end,
			},
			{
				name = _G.ENABLE,
				kind = LEM.SettingType.Checkbox,
				hidden = function()
					return not C.db.global.settings[barName].fade
				end,
				default = D.profile.actionbars.layouts["*"]["**"].fade.enabled,
				get = function(layoutName)
					return C.db.profile.actionbars.layouts[layoutName][barName].fade.enabled
				end,
				set = function(layoutName, value)
					if C.db.profile.actionbars.layouts[layoutName][barName].fade.enabled ~= value then
						C.db.profile.actionbars.layouts[layoutName][barName].fade.enabled = value

						addon.ActionBars:UpdateFading(barName)
					end
				end,
			},
			{
				name = _G.COMBAT,
				desc = L["FADING_COMBAT_DESC"],
				kind = LEM.SettingType.Checkbox,
				hidden = function()
					return not C.db.global.settings[barName].fade
				end,
				disabled = function(layoutName)
					return not C.db.profile.actionbars.layouts[layoutName][barName].fade.enabled
				end,
				default = D.profile.actionbars.layouts["*"]["**"].fade.combat,
				get = function(layoutName)
					return C.db.profile.actionbars.layouts[layoutName][barName].fade.combat
				end,
				set = function(layoutName, value)
					if C.db.profile.actionbars.layouts[layoutName][barName].fade.combat ~= value then
						C.db.profile.actionbars.layouts[layoutName][barName].fade.combat = value

						addon.ActionBars:UpdateFading(barName)
					end
				end,
			},
			{
				name = _G.TARGET,
				desc = L["FADING_TARGET_DESC"],
				kind = LEM.SettingType.Checkbox,
				hidden = function()
					return not C.db.global.settings[barName].fade
				end,
				disabled = function(layoutName)
					return not C.db.profile.actionbars.layouts[layoutName][barName].fade.enabled
				end,
				default = D.profile.actionbars.layouts["*"]["**"].fade.target,
				get = function(layoutName)
					return C.db.profile.actionbars.layouts[layoutName][barName].fade.target
				end,
				set = function(layoutName, value)
					if C.db.profile.actionbars.layouts[layoutName][barName].fade.target ~= value then
						C.db.profile.actionbars.layouts[layoutName][barName].fade.target = value

						addon.ActionBars:UpdateFading(barName)
					end
				end,
			},
			{
				name = L["MIN_ALPHA"],
				kind = LEM.SettingType.Slider,
				hidden = function()
					return not C.db.global.settings[barName].fade
				end,
				disabled = function(layoutName)
					return not C.db.profile.actionbars.layouts[layoutName][barName].fade.enabled
				end,
				default = D.profile.actionbars.layouts["*"]["**"].fade.min_alpha,
				get = function(layoutName)
					return C.db.profile.actionbars.layouts[layoutName][barName].fade.min_alpha
				end,
				set = function(layoutName, value)
					if C.db.profile.actionbars.layouts[layoutName][barName].fade.min_alpha ~= value then
						C.db.profile.actionbars.layouts[layoutName][barName].fade.min_alpha = value

						addon.ActionBars:UpdateFading(barName)
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
					return C.db.global.settings[barName].fade
				end,
				set = function(_, value)
					C.db.global.settings[barName].fade = value
				end,
			},
		}, id)
	end

	LEM:AddSystemSettings(Enum.EditModeSystem.ExtraAbilities, {
		{
			name = _G.TEXTURES_SUBHEADER,
			kind = LEM.SettingType.Checkbox,
			default = D.profile.actionbars.layouts["*"].ExtraAbilityContainer.textures,
			get = function(layoutName)
				return C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.textures
			end,
			set = function(layoutName, value)
				if C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.textures ~= value then
					C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.textures = value

					addon.ActionBars:UpdateArt("ExtraAbilityContainer")
				end
			end,
		},
		{
			name = _G.LOCALE_TEXT_LABEL,
			kind = LEM.SettingType.Divider,
			hidden = function()
				return not C.db.global.settings.ExtraAbilityContainer.text
			end,
		},
		{
			name = _G.KEY_BINDINGS,
			kind = LEM.SettingType.Checkbox,
			hidden = function()
				return not C.db.global.settings.ExtraAbilityContainer.text
			end,
			default = D.profile.actionbars.layouts["*"]["**"].hotkey,
			get = function(layoutName)
				return C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.hotkey
			end,
			set = function(layoutName, value)
				if C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.hotkey ~= value then
					C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.hotkey = value

					addon.ActionBars:UpdateHotkey("ExtraAbilityContainer")
				end
			end,
		},
		{
		name = "DNT Text Settings Expander",
			kind = LEM.SettingType.Expander,
			expandedLabel = L["COLLAPSE_OPTIONS"],
			collapsedLabel = _G.LOCALE_TEXT_LABEL,
			appendArrow = true,
			default = D.global.settings["**"].text,
			get = function()
				return C.db.global.settings.ExtraAbilityContainer.text
			end,
			set = function(_, value)
				C.db.global.settings.ExtraAbilityContainer.text = value
			end,
		},
		{
			name = L["FADING"],
			kind = LEM.SettingType.Divider,
			hidden = function()
				return not C.db.global.settings.ExtraAbilityContainer.fade
			end,
		},
		{
			name = _G.ENABLE,
			kind = LEM.SettingType.Checkbox,
			hidden = function()
				return not C.db.global.settings.ExtraAbilityContainer.fade
			end,
			default = D.profile.actionbars.layouts["*"]["**"].fade.enabled,
			get = function(layoutName)
				return C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.enabled
			end,
			set = function(layoutName, value)
				if C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.enabled ~= value then
					C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.enabled = value

					addon.ActionBars:UpdateFading("ExtraAbilityContainer")
				end
			end,
		},
		{
			name = _G.COMBAT,
			desc = L["FADING_COMBAT_DESC"],
			kind = LEM.SettingType.Checkbox,
			disabled = function(layoutName)
				return not C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.enabled
			end,
			hidden = function()
				return not C.db.global.settings.ExtraAbilityContainer.fade
			end,
			default = D.profile.actionbars.layouts["*"]["**"].fade.combat,
			get = function(layoutName)
				return C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.combat
			end,
			set = function(layoutName, value)
				if C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.combat ~= value then
					C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.combat = value

					addon.ActionBars:UpdateFading("ExtraAbilityContainer")
				end
			end,
		},
		{
			name = _G.TARGET,
			desc = L["FADING_TARGET_DESC"],
			kind = LEM.SettingType.Checkbox,
			disabled = function(layoutName)
				return not C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.enabled
			end,
			hidden = function()
				return not C.db.global.settings.ExtraAbilityContainer.fade
			end,
			default = D.profile.actionbars.layouts["*"]["**"].fade.target,
			get = function(layoutName)
				return C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.target
			end,
			set = function(layoutName, value)
				if C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.target ~= value then
					C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.target = value

					addon.ActionBars:UpdateFading("ExtraAbilityContainer")
				end
			end,
		},
		{
			name = L["MIN_ALPHA"],
			kind = LEM.SettingType.Slider,
			disabled = function(layoutName)
				return not C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.enabled
			end,
			hidden = function()
				return not C.db.global.settings.ExtraAbilityContainer.fade
			end,
			default = D.profile.actionbars.layouts["*"]["**"].fade.min_alpha,
			get = function(layoutName)
				return C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.min_alpha
			end,
			set = function(layoutName, value)
				if C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.min_alpha ~= value then
					C.db.profile.actionbars.layouts[layoutName].ExtraAbilityContainer.fade.min_alpha = value

					addon.ActionBars:UpdateFading("ExtraAbilityContainer")
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
				return C.db.global.settings.ExtraAbilityContainer.fade
			end,
			set = function(_, value)
				C.db.global.settings.ExtraAbilityContainer.fade = value
			end,
		},
	})

	isInit = true
end

function addon.ActionBars:UpdateDesaturation(name)
	if not BARS[name] then return end

	if name == "PetActionBar" then
		petActionBarUpdateUnusable(_G[name])
	else
		for _, button in next, BARS[name] do
			if button.UpdateUsable then -- don't use UpdateUsable itself
				actionButtonUpdateUnusable(button)
			end
		end
	end
end

function addon.ActionBars:UpdateCastVFX()
	if C.db.profile.actionbars.cast_vfx then
		FrameUtil.RegisterFrameForEvents(ActionBarActionEventsFrame, SPELLCAST_EVENTS)
		FrameUtil.RegisterFrameForUnitEvents(ActionBarActionEventsFrame, SPELLCAST_UNIT_EVENTS, "player")
	else
		FrameUtil.UnregisterFrameForEvents(ActionBarActionEventsFrame, SPELLCAST_EVENTS)
		FrameUtil.UnregisterFrameForEvents(ActionBarActionEventsFrame, SPELLCAST_UNIT_EVENTS)
	end
end

function addon.ActionBars:UpdateEndCaps()
	MainActionBar:UpdateEndCaps(MainActionBar.hideBarArt)
end

function addon.ActionBars:UpdateFading(name)
	local bar = _G[name]
	if not bar then return end

	local config = addon:GetActionBarConfigForBar(name)
	if config.fade.enabled then
		if config.fade.combat then
			addon.Fader:WatchCombat(bar)
		else
			addon.Fader:UnwatchCombat(bar)
		end

		if config.fade.target then
			addon.Fader:WatchTarget(bar)
		else
			addon.Fader:UnwatchTarget(bar)
		end

		if addon.Fader:CanHover(bar) then
			addon.Fader:WatchHover(bar, config.fade.min_alpha)
		end
	else
		addon.Fader:UnwatchCombat(bar)
		addon.Fader:UnwatchTarget(bar)
		addon.Fader:UnwatchHover(bar)
	end
end

function addon.ActionBars:UpdateHotkey(name)
	if not BARS[name] then return end

	for _, button in next, BARS[name] do
		actionButtonUpdateHotkey(button)
	end
end

function addon.ActionBars:UpdateMacro(name)
	if not BARS[name] then return end

	for _, button in next, BARS[name] do
		actionButtonUpdateMacro(button)
	end
end

function addon.ActionBars:UpdateArt(name)
	if not BARS[name] then return end

	local config = addon:GetActionBarConfigForBar(name)

	if name == "ExtraAbilityContainer" then
		ExtraActionButton1.style:SetShown(config.textures)
		ZoneAbilityFrame.Style:SetShown(config.textures)
	end
end

function addon.ActionBars:ForAll(method)
	if not self[method] then return end

	for name in next, BARS do
		self[method](self, name)
	end
end

--[[
/dump MultiBarRightButton10.commandName
/dump GetBindingKey(MultiBarRightButton10.commandName)
]]
