local addonName, addon = ...
local C, D, L = addon.C, addon.D, addon.L

-- Lua
local _G = getfenv(0)
local m_floor = _G.math.floor
local m_random = _G.math.random
local next = _G.next
local s_format = _G.string.format
local type = _G.type

-- Mine
local ACD = LibStub("AceConfigDialog-3.0")

-- move these elsehwere
local CL_LINK = "https://github.com/ls-/ls_Whistles/blob/master/CHANGELOG.md"
local CURSE_LINK = "https://www.curseforge.com/wow/addons/ls-whistles"
local DISCORD_LINK = "https://discord.gg/7QcJgQkDYD"
local GITHUB_LINK = "https://github.com/ls-/ls_Whistles"
local WAGO_LINK = "https://addons.wago.io/addons/ls-whistles"

local showLinkCopyPopup
do
	local function getStatusMessage()
		local num = m_random(1, 100)
		if num == 27 then
			return "The Cake is a Lie"
		else
			return L["LINK_COPY_SUCCESS"]
		end
	end

	local link = ""

	local popup = CreateFrame("Frame", nil, UIParent)
	popup:Hide()
	popup:SetPoint("CENTER", UIParent, "CENTER")
	popup:SetSize(384, 78)
	popup:EnableMouse(true)
	popup:SetFrameStrata("TOOLTIP")
	popup:SetFixedFrameStrata(true)
	popup:SetFrameLevel(100)
	popup:SetFixedFrameLevel(true)
	popup:EnableKeyboard(true)

	local border = CreateFrame("Frame", nil, popup, "DialogBorderTranslucentTemplate")
	border:SetAllPoints(popup)

	local editBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
	editBox:SetHeight(32)
	editBox:SetPoint("TOPLEFT", 22, -10)
	editBox:SetPoint("TOPRIGHT", -16, -10)
	editBox:EnableKeyboard(true)
	editBox:SetScript("OnChar", function(self)
		self:SetText(link)
		self:HighlightText()
	end)
	editBox:SetScript("OnMouseUp", function(self)
		self:HighlightText()
	end)
	editBox:SetScript("OnEscapePressed", function()
		popup:Hide()
	end)
	editBox:SetScript("OnEnterPressed", function()
		popup:Hide()
	end)
	editBox:SetScript("OnKeyUp", function(_, key)
		if IsControlKeyDown() and (key == "C" or key == "X") then
			ActionStatus:DisplayMessage(getStatusMessage())

			popup:Hide()
		end
	end)

	local button = CreateFrame("Button", nil, popup, "UIPanelButtonNoTooltipTemplate")
	button:SetText(_G.CLOSE)
	button:SetSize(90, 22)
	button:SetPoint("BOTTOM", 0, 16)
	button:SetScript("OnClick", function()
		popup:Hide()
	end)

	popup:SetScript("OnHide", function()
		link = ""
		editBox:SetText(link)
	end)
	popup:SetScript("OnShow", function()
		editBox:SetText(link)
		editBox:SetFocus()
		editBox:HighlightText()
	end)

	function showLinkCopyPopup(text)
		popup:Hide()
		link = text
		popup:Show()
	end
end

do
	local header_proto = {}

	do
		function header_proto:OnHyperlinkClick(hyperlink)
			showLinkCopyPopup(hyperlink)
		end
	end

	local function createHeader(parent, text)
		local header = Mixin(CreateFrame("Frame", nil, parent, "InlineHyperlinkFrameTemplate"), header_proto)
		header:SetHeight(50)
		header:SetScript("OnHyperlinkClick", header.OnHyperlinkClick)

		local title = header:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
		title:SetPoint("TOPLEFT", 7, -22)
		title:SetText(text)

		local divider = header:CreateTexture(nil, "ARTWORK")
		divider:SetAtlas("Options_HorizontalDivider", true)
		divider:SetPoint("TOP", 0, -50)

		return header
	end

	local button_proto = {}

	do
		function button_proto:OnEnter()
			self.Icon:SetScale(1.1)

			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(self.tooltip)
			GameTooltip:Show()
		end

		function button_proto:OnLeave()
			self.Icon:SetScale(1)

			GameTooltip:Hide()
		end

		function button_proto:OnClick()
			showLinkCopyPopup(self.link)
		end
	end

	local container_proto = {
		numChildren = 0,
	}

	do
		function container_proto:AddButton(texture, tooltip, link)
			self.numChildren = self.numChildren + 1
			self.spacing = m_floor(580 / (self.numChildren + 1))

			local button = Mixin(CreateFrame("Button", nil, self), button_proto)
			button:SetSize(64, 64)
			button:SetScript("OnEnter", button.OnEnter)
			button:SetScript("OnLeave", button.OnLeave)
			button:SetScript("OnClick", button.OnClick)
			button.layoutIndex = self.numChildren

			local icon = button:CreateTexture(nil, "ARTWORK")
			icon:SetPoint("CENTER")
			icon:SetSize(48, 48)
			icon:SetTexture(texture)
			button.Icon = icon

			button.tooltip = tooltip
			button.link = link
		end
	end

	function addon:CreateBlizzConfig()
		local panel = CreateFrame("Frame", "LSWhistlesConfigPanel")
		panel:Hide()

		local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		versionText:SetPoint("TOPRIGHT", -2, 4)
		versionText:SetTextColor(0.4, 0.4, 0.4)
		versionText:SetText(addon.VER.string)

		-- UIPanelButtonTemplate
		local configButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		configButton:SetText(_G.ADVANCED_OPTIONS)
		configButton:SetWidth(configButton:GetTextWidth() + 18)
		configButton:SetPoint("TOPRIGHT", -36, -16)
		configButton:SetScript("OnClick", function()
			if not addon.OpenAceConfig then
				addon:CreateAceConfig()
			end

			addon:OpenAceConfig()
		end)

		local supportHeader = createHeader(panel, L["SUPPORT_FEEDBACK"])
		supportHeader:SetPoint("TOPLEFT")
		supportHeader:SetPoint("TOPRIGHT")

		local supportContainer = Mixin(CreateFrame("Frame", nil, panel, "HorizontalLayoutFrame"), container_proto)
		supportContainer:SetPoint("TOP", supportHeader, "BOTTOM", 0, -4)

		supportContainer:AddButton("Interface\\AddOns\\ls_Whistles\\assets\\discord-64", L["DISCORD"], DISCORD_LINK)
		supportContainer:AddButton("Interface\\AddOns\\ls_Whistles\\assets\\github-64", L["GITHUB"], GITHUB_LINK)

		local downloadHeader = createHeader(panel, L["DOWNLOADS"])
		downloadHeader:SetPoint("TOP", supportContainer, "BOTTOM", 0, 8)
		downloadHeader:SetPoint("LEFT")
		downloadHeader:SetPoint("RIGHT")

		local downloadContainer = Mixin(CreateFrame("Frame", nil, panel, "HorizontalLayoutFrame"), container_proto)
		downloadContainer:SetPoint("TOP", downloadHeader, "BOTTOM", 0, -4)

		-- downloadContainer:AddButton("Interface\\AddOns\\ls_Whistles\\assets\\mmoui-64", L["WOWINTERFACE"])
		downloadContainer:AddButton("Interface\\AddOns\\ls_Whistles\\assets\\curseforge-64", L["CURSEFORGE"], CURSE_LINK)
		downloadContainer:AddButton("Interface\\AddOns\\ls_Whistles\\assets\\wago-64", L["WAGO"], WAGO_LINK)

		local changelogHeader = createHeader(panel, s_format("%s |H%s|h[|c%s%s|r]|h",  L["CHANGELOG"], CL_LINK, D.global.colors.addon:GetHex(), L["CHANGELOG_FULL"]))
		changelogHeader:SetPoint("TOP", downloadContainer, "BOTTOM", 0, 8)
		changelogHeader:SetPoint("LEFT")
		changelogHeader:SetPoint("RIGHT")

		-- recreation of "ScrollingFontTemplate"
		local changelog = Mixin(CreateFrame("Frame", nil, panel), ScrollingFontMixin)
		changelog:SetPoint("TOPLEFT", changelogHeader, "BOTTOMLEFT", 6, -8)
		changelog:SetPoint("BOTTOMRIGHT", changelogHeader, "BOTTOMRIGHT", -38, -192)
		changelog:SetScript("OnSizeChanged", changelog.OnSizeChanged)
		changelog.fontName = "GameFontHighlight"

		local border = CreateFrame("Frame", nil, changelog, "FloatingBorderedFrame")
		border:SetPoint("TOPLEFT")
		border:SetPoint("BOTTOMRIGHT", 20, 0)
		border:SetUsingParentLevel(true)

		for _, region in next, {border:GetRegions()} do
			region:SetVertexColor(0, 0, 0, 0.3)
		end

		local scrollBox = CreateFrame("Frame", nil, changelog, "WowScrollBox")
		scrollBox:SetAllPoints()
		changelog.ScrollBox = scrollBox

		local fontStringContainer = CreateFrame("Frame", nil, scrollBox)
		fontStringContainer:SetHeight(1)
		fontStringContainer.scrollable = true
		scrollBox.FontStringContainer = fontStringContainer

		local fontString = fontStringContainer:CreateFontString(nil, "ARTWORK")
		fontString:SetPoint("TOPLEFT")
		fontString:SetNonSpaceWrap(true)
		fontString:SetJustifyH("LEFT")
		fontString:SetJustifyV("TOP")
		fontStringContainer.FontString = fontString

		local scrollBar = CreateFrame("EventFrame", nil, panel, "MinimalScrollBar")
		scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
		scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, -3)
		scrollBar:SetHideIfUnscrollable(true)
		changelog.ScrollBar = scrollBar

		ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, scrollBar)

		changelog:OnLoad()
		changelog:SetText(addon.CHANGELOG)

		supportContainer:MarkDirty()

		local category = Settings.RegisterCanvasLayoutCategory(panel, L["LS_WHISTLES"])

		Settings.RegisterAddOnCategory(category)

		function addon:OpenBlizzConfig()
			Settings.OpenToCategory(category:GetID())
		end
	end
end

do
	local UPGRADE_LEVEL = _G.ITEM_UPGRADE_TOOLTIP_FORMAT_STRING:gsub("[:：].+", "")

	local orders = {}

	local function reset(order)
		orders[order] = 1
		return orders[order]
	end

	local function inc(order)
		orders[order] = orders[order] + 1
		return orders[order]
	end

	local function createSpacer(order, noHeight)
		return {
			order = order,
			type = "description",
			name = noHeight and "" or " ",
		}
	end

	local globalIgnoredKeys = {
		["point"] = true,
	}

	local function copySettings(src, dest, ignoredKeys)
		for k, v in next, dest do
			if not globalIgnoredKeys[k] and not (ignoredKeys and ignoredKeys[k]) then
				if src[k] ~= nil then
					if type(v) == "table" then
						if next(v) and type(src[k]) == "table" then
							copySettings(src[k], v, ignoredKeys)
						end
					else
						if type(v) == type(src[k]) then
							dest[k] = src[k]
						end
					end
				end
			end
		end
	end

	local function colorSettingThatReloads(text)
		return CONTEXT_FEEDBACK_COLOR:WrapTextInColorCode(text)
	end

	local function confirmReset()
		return _G.CONFIRM_CONTINUE
	end

	local pendingChanges = {}

	local function askToReloadUI(sender, shouldRemove)
		if shouldRemove then
			pendingChanges[sender] = nil
		else
			pendingChanges[sender] = true
		end

		local frame = ACD.OpenFrames[addonName]
		if frame then
			frame:SetStatusText(next(pendingChanges) and L["RELOAD_UI_POPUP"] or "")
		end
	end

	local function shouldReloadUI()
		if not next(pendingChanges) then return end

		local frame = ACD.popup
		frame:Show()
		frame.text:SetText(L["RELOAD_UI_POPUP"])
		frame:SetHeight(61 + frame.text:GetHeight())

		frame.accept:ClearAllPoints()
		frame.accept:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -6, 16)
		frame.accept:SetText(_G.RELOADUI)
		frame.accept:SetScript("OnClick", ReloadUI)

		frame.cancel:Show()
		frame.cancel:SetText(_G.LATER)
		frame.cancel:SetScript("OnClick", function()
			frame:Hide()
			frame.accept:SetScript("OnClick", nil)
			frame.cancel:SetScript("OnClick", nil)
		end)
	end

	function addon:CreateAceConfig()
		C.options = {
			type = "group",
			name = s_format("%s |cffcacaca(%s)|r", L["LS_WHISTLES"], addon.VER.string),
			childGroups = "tab",
			args = {
				mail = {
					order = reset(1),
					type = "toggle",
					name = colorSettingThatReloads(_G.MAIL_LABEL),
					desc = L["MAIL_DESC"],
					get = function()
						return C.db.profile.mail.enabled
					end,
					set = function(_, value)
						C.db.profile.mail.enabled = value

						if addon.Mail:IsInit() then
							askToReloadUI("mail.enabled", value)
						else
							if value then
								addon.Mail:Init()
							end
						end
					end,
				},
				loot_frame = {
					order = inc(1),
					type = "toggle",
					name = colorSettingThatReloads(_G.HUD_EDIT_MODE_LOOT_FRAME_LABEL),
					desc = L["LOOT_DESC"],
					get = function()
						return C.db.profile.loot_frame.enabled
					end,
					set = function(_, value)
						C.db.profile.loot_frame.enabled = value

						if addon.LootFrame:IsInit() then
							askToReloadUI("loot_frame.enabled", value)
						else
							if value then
								addon.LootFrame:Init()
							end
						end
					end,
				},
				backpack = {
					order = inc(1),
					type = "toggle",
					name = colorSettingThatReloads(_G.BAG_NAME_BACKPACK),
					desc = L["BACKPACK_DESC"],
					get = function()
						return C.db.profile.backpack.enabled
					end,
					set = function(_, value)
						C.db.profile.backpack.enabled = value

						if addon.Backpack:IsInit() then
							askToReloadUI("backpack.enabled", value)
						else
							if value then
								addon.Backpack:Init()
							end
						end
					end,
				},
				actionbars = {
					order = inc(1),
					type = "group",
					name = _G.ACTIONBARS_LABEL,
					get = function(info)
						return C.db.profile.actionbars[info[#info]]
					end,
					args = {
						enabled = {
							order = reset(2),
							type = "toggle",
							name = colorSettingThatReloads(_G.ENABLE),
							set = function(_, value)
								C.db.profile.actionbars.enabled = value

								if addon.ActionBars:IsInit() then
									askToReloadUI("actionbars.enabled", value)
								else
									if value then
										addon.ActionBars:Init()
									end
								end
							end,
						},
						spacer_1 = createSpacer(inc(2)),
						cast_vfx = {
							order = inc(2),
							type = "toggle",
							name = L["CAST_VFX"],
							width = 1.25,
							disabled =  function()
								return not addon.ActionBars:IsInit()
							end,
							set = function(_, value)
								C.db.profile.actionbars.cast_vfx = value

								addon.ActionBars:UpdateCastVFX()
							end,
						},
						short_hotkey = {
							order = inc(2),
							type = "toggle",
							name = L["SHORT_HOTKEY"],
							width = 1.25,
							disabled =  function()
								return not addon.ActionBars:IsInit()
							end,
							set = function(_, value)
								C.db.profile.actionbars.short_hotkey = value

								addon.ActionBars:ForAll("UpdateHotkey")
							end,
						},
						spacer_2 = createSpacer(inc(2)),
						desaturation = {
							order = inc(2),
							type = "group",
							name = L["DESATURATION"],
							inline = true,
							disabled =  function()
								return not addon.ActionBars:IsInit()
							end,
							get = function(info)
								return C.db.profile.actionbars.desaturation[info[#info]]
							end,
							set = function(info, value)
								C.db.profile.actionbars.desaturation[info[#info]] = value

								addon.ActionBars:ForAll("UpdateDesaturation")
							end,
							args = {
								unusable = {
									order = reset(3),
									type = "toggle",
									name = _G.MOUNT_JOURNAL_FILTER_UNUSABLE,
									width = 1.25,
								},
								oom = {
									order = inc(3),
									type = "toggle",
									name = L["OUT_OF_MANA"],
									width = 1.25,
								},
							},
						},
						spacer_3 = createSpacer(inc(2)),
						equipped = {
							order = inc(2),
							type = "group",
							name = L["EQUIPPED_HIGHLIGHT"],
							inline = true,
							disabled =  function()
								return not addon.ActionBars:IsInit()
							end,
							get = function(info)
								return C.db.profile.actionbars.equipped[info[#info]]
							end,
							set = function(info, value)
								C.db.profile.actionbars.equipped[info[#info]] = value

								addon.ActionBars:ForAll("UpdateEquippedHighlight")
							end,
							args = {
								icon = {
									order = reset(3),
									type = "toggle",
									name = _G.SELF_HIGHLIGHT_ICON,
									width = 1.25,
								},
								border = {
									order = inc(3),
									type = "toggle",
									name = L["BORDER"],
									width = 1.25,
								},
							},
						},
						spacer_4 = createSpacer(inc(2)),
						footer = {
							order = inc(2),
							type = "description",
							name = L["ACTIONBARS_DESC"],
							image = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew",
							imageWidth = 24,
							imageHeight = 24,
						},
					},
				},
				adventure_guide = {
					order = inc(1),
					type = "group",
					name = _G.ADVENTURE_JOURNAL,
					args = {
						journey_frame = {
							order = reset(2),
							type = "toggle",
							name = colorSettingThatReloads(_G.JOURNEYS_LABEL),
							desc = L["AJ_TAB_DESC"],
							get = function()
								return C.db.profile.journey_frame.enabled
							end,
							set = function(_, value)
								C.db.profile.journey_frame.enabled = value

								if addon.JourneyFrame:IsInit() then
									askToReloadUI("journey_frame.enabled", value)
								else
									if value then
										addon.JourneyFrame:Init()
									end
								end
							end,
						},
						suggest_frame = {
							order = inc(2),
							type = "toggle",
							name = colorSettingThatReloads(_G.AJ_SUGGESTED_CONTENT_TAB),
							desc = L["AJ_TAB_DESC"],
							get = function()
								return C.db.profile.suggest_frame.enabled
							end,
							set = function(_, value)
								C.db.profile.suggest_frame.enabled = value

								if addon.SuggestFrame:IsInit() then
									askToReloadUI("suggest_frame.enabled", value)
								else
									if value then
										addon.SuggestFrame:Init()
									end
								end
							end,
						},
					},
				},
				character_frame = {
					order = inc(1),
					type = "group",
					name = L["CHARACTER_FRAME"],
					get = function(info)
						return C.db.profile.character_frame[info[#info]]
					end,
					set = function(info, value)
						if C.db.profile.character_frame[info[#info]] ~= value then
							C.db.profile.character_frame[info[#info]] = value

							addon.CharacterFrame:Update()
						end
					end,
					args = {
						enabled = {
							order = reset(2),
							type = "toggle",
							name = colorSettingThatReloads(_G.ENABLE),
							get = function()
								return C.db.profile.character_frame.enabled
							end,
							set = function(_, value)
								C.db.profile.character_frame.enabled = value

								if addon.CharacterFrame:IsInit() then
									askToReloadUI("character_frame.enabled", value)
								else
									if value then
										addon.CharacterFrame:Init()
									end
								end
							end,
						},
						spacer_1 = createSpacer(inc(2)),
						ilvl = {
							order = inc(2),
							type = "toggle",
							name = _G.ITEM_LEVEL_ABBR,
							disabled =  function()
								return not addon.CharacterFrame:IsInit()
							end,
						},
						upgrade = {
							order = inc(2),
							type = "toggle",
							name = UPGRADE_LEVEL,
							disabled =  function()
								return not addon.CharacterFrame:IsInit()
							end,
						},
						enhancements = {
							order = inc(2),
							type = "toggle",
							name = _G.AUCTION_CATEGORY_ITEM_ENHANCEMENT,
							disabled =  function()
								return not addon.CharacterFrame:IsInit()
							end,
						},
						spacer_2 = createSpacer(inc(2)),
						missing_enhancements = {
							order = inc(2),
							type = "group",
							inline = true,
							name = L["MISSING_ENCHANTS"],
							disabled = function()
								return not (addon.CharacterFrame:IsInit() and C.db.profile.character_frame.enhancements)
							end,
							get = function(info)
								return C.db.profile.character_frame.missing_enhancements[info[#info]]
							end,
							set = function(info, value)
								if C.db.profile.character_frame.missing_enhancements[info[#info]] ~= value then
									C.db.profile.character_frame.missing_enhancements[info[#info]] = value

									addon.CharacterFrame:Update()
								end
							end,
							args = {
								reset = {
									type = "execute",
									order = reset(3),
									name = _G.RESET_TO_DEFAULT,
									confirm = confirmReset,
									func = function()
										copySettings(D.profile.character_frame.missing_enhancements, C.db.profile.character_frame.missing_enhancements)

										addon.CharacterFrame:Update()
									end,
								},
								spacer_1 = createSpacer(inc(3)),
								head = {
									order = inc(3),
									type = "toggle",
									name = _G.HEADSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								hands = {
									order = inc(3),
									type = "toggle",
									name = _G.HANDSSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								neck = {
									order = inc(3),
									type = "toggle",
									name = _G.NECKSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								waist = {
									order = inc(3),
									type = "toggle",
									name = _G.WAISTSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								shoulder = {
									order = inc(3),
									type = "toggle",
									name = _G.SHOULDERSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								legs = {
									order = inc(3),
									type = "toggle",
									name = _G.LEGSSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								back = {
									order = inc(3),
									type = "toggle",
									name = _G.BACKSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								feet = {
									order = inc(3),
									type = "toggle",
									name = _G.FEETSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								chest = {
									order = inc(3),
									type = "toggle",
									name = _G.CHESTSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								finger = {
									order = inc(3),
									type = "toggle",
									name = _G.FINGER0SLOT,
									width = "relative",
									relWidth = 0.5,
								},
								wrist = {
									order = inc(3),
									type = "toggle",
									name = _G.WRISTSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								trinket = {
									order = inc(3),
									type = "toggle",
									name = _G.TRINKET0SLOT,
									width = "relative",
									relWidth = 0.5,
								},
								main_hand = {
									order = inc(3),
									type = "toggle",
									name = _G.MAINHANDSLOT,
									width = "relative",
									relWidth = 0.5,
								},
								secondary_hand = {
									order = inc(3),
									type = "toggle",
									name = _G.SECONDARYHANDSLOT,
									width = "relative",
									relWidth = 0.5,
								},
							},
						},
					},
				},
				inspect_frame = {
					order = inc(1),
					type = "group",
					name = L["INSPECT_FRAME"],
					get = function(info)
						return C.db.profile.inspect_frame[info[#info]]
					end,
					set = function(info, value)
						if C.db.profile.inspect_frame[info[#info]] ~= value then
							C.db.profile.inspect_frame[info[#info]] = value

							addon.InspectFrame:Init()
						end
					end,
					args = {
						enabled = {
							order = reset(2),
							type = "toggle",
							name = colorSettingThatReloads(_G.ENABLE),
							get = function()
								return C.db.profile.inspect_frame.enabled
							end,
							set = function(_, value)
								C.db.profile.inspect_frame.enabled = value

								if addon.InspectFrame:IsInit() then
									askToReloadUI("inspect_frame.enabled", value)
								else
									if value then
										addon.InspectFrame:Init()
									end
								end
							end,
						},
						spacer_1 = createSpacer(inc(2)),
						ilvl = {
							order = inc(2),
							type = "toggle",
							name = _G.ITEM_LEVEL_ABBR,
							disabled =  function()
								return not addon.InspectFrame:IsInit()
							end,
						},
						upgrade = {
							order = inc(2),
							type = "toggle",
							name = UPGRADE_LEVEL,
							disabled =  function()
								return not addon.InspectFrame:IsInit()
							end,
						},
						enhancements = {
							order = inc(2),
							type = "toggle",
							name = _G.AUCTION_CATEGORY_ITEM_ENHANCEMENT,
							disabled =  function()
								return not addon.InspectFrame:IsInit()
							end,
						},
					},
				},
				micro_menu = {
					order = inc(1),
					type = "group",
					name = _G.HUD_EDIT_MODE_MICRO_MENU_LABEL,
					get = function(info)
						return C.db.profile.micro_menu[info[#info]]
					end,
					args = {
						enabled =  {
							order = reset(2),
							type = "toggle",
							name = colorSettingThatReloads(_G.ENABLE),
							set = function(_, value)
								C.db.profile.micro_menu.enabled = value

								if addon.MicroMenu:IsInit() then
									askToReloadUI("micro_menu.enabled", value)
								else
									if value then
										addon.MicroMenu:Init()
									end
								end
							end,
						},
						spacer_1 = createSpacer(inc(2)),
						helptips =  {
							order = inc(2),
							type = "toggle",
							name = _G.COMMUNITIES_NOTIFICATION_SETTINGS_DIALOG_SETTINGS_LABEL,
							disabled = function()
								return not addon.MicroMenu:IsInit()
							end,
							set = function(_, value)
								C.db.profile.micro_menu.helptips = value
							end,
						},
						spacer_2 = createSpacer(inc(2)),
						tooltips = {
							order = inc(2),
							type = "group",
							inline = true,
							name = _G.USE_UBERTOOLTIPS,
							disabled = function()
								return not addon.MicroMenu:IsInit()
							end,
							get = function(info)
								return C.db.profile.micro_menu.buttons[info[#info]].tooltip
							end,
							set = function(info, value)
								if C.db.profile.micro_menu.buttons[info[#info]].tooltip ~= value then
									C.db.profile.micro_menu.buttons[info[#info]].tooltip = value

									addon.MicroMenu:UpdateButton(info[#info])
								end
							end,
							args = {
								reset = {
									type = "execute",
									order = reset(3),
									name = _G.RESET_TO_DEFAULT,
									confirm = confirmReset,
									func = function()
										copySettings(D.profile.micro_menu.buttons, C.db.profile.micro_menu.buttons)
									end,
								},
								spacer_1 = createSpacer(inc(3)),
								character = {
									order = inc(3),
									type = "toggle",
									name = _G.CHARACTER_BUTTON,
									desc = L["CHARACTER_BUTTON_DESC"],
								},
								quest = {
									order = inc(3),
									type = "toggle",
									name = _G.QUESTLOG_BUTTON,
									desc = L["QUESTLOG_BUTTON_DESC"],
								},
								lfd = {
									order = inc(3),
									type = "toggle",
									name = _G.DUNGEONS_BUTTON,
									desc = L["LFD_BUTTON_DESC"],
								},
								ej = {
									order = inc(3),
									type = "toggle",
									name = _G.ADVENTURE_JOURNAL,
									desc = L["EJ_BUTTON_DESC"],
								},
								main = {
									order = inc(3),
									type = "toggle",
									name = _G.MAINMENU_BUTTON,
									desc = L["MAINMENU_BUTTON_DESC"],
								},
							},
						},
					},
				},
				game_menu = {
					order = inc(1),
					type = "group",
					name = _G.MAINMENU_BUTTON,
					get = function(info)
						return C.db.profile.game_menu[info[#info]]
					end,
					set = function(info, value)
						C.db.profile.game_menu[info[#info]] = value
					end,
					args = {
						enabled =  {
							order = reset(2),
							type = "toggle",
							name = colorSettingThatReloads(_G.ENABLE),
							get = function()
								return C.db.profile.game_menu.enabled
							end,
							set = function(_, value)
								C.db.profile.game_menu.enabled = value

								if addon.GameMenu:IsInit() then
									askToReloadUI("game_menu.enabled", value)
								else
									if value then
										addon.GameMenu:Init()
									end
								end
							end,
						},
						spacer_1 = createSpacer(inc(2)),
						scale = {
							order = inc(2),
							type = "range",
							name = _G.HOUSING_EXPERT_DECOR_SUBMODE_SCALE,
							min = 0.5, max = 1, step = 0.01, bigStep = 0.05,
							isPercent = true,
							disabled = function()
								return not addon.GameMenu:IsInit()
							end,
						},
					},
				},
			},
		}

		LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, C.options)

		function addon:OpenAceConfig()
			if not InCombatLockdown() then
				HideUIPanel(SettingsPanel)
			end

			ACD:Open(addonName)

			local frame = ACD.OpenFrames[addonName]
			if frame then
				frame:SetCallback("OnRelease", shouldReloadUI)
			end
		end
	end
end
