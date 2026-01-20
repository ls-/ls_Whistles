local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.Button = {}

-- Lua
local _G = getfenv(0)
local hooksecurefunc = _G.hooksecurefunc

-- Mine
local function onSizeChanged(self, width, height)
	if self.OnSizeChanged then
		self:OnSizeChanged(width, height)
	else
		local icon = self.icon or self.Icon
		if icon then
			if width > height then
				local offset = 0.875 * (1 - height / width) / 2
				icon:SetTexCoord(0.0625, 0.9375, 0.0625 + offset, 0.9375 - offset)
			elseif width < height then
				local offset = 0.875 * (1 - width / height) / 2
				icon:SetTexCoord(0.0625 + offset, 0.9375 - offset, 0.0625, 0.9375)
			else
				icon:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375)
			end
		end
	end
end

local function setIcon(button, texture, l, r, t, b)
	local icon

	if button.CreateTexture then
		icon = button:CreateTexture(nil, "BACKGROUND", nil, 0)
	else
		icon = button
		icon:SetDrawLayer("BACKGROUND", 0)
	end

	icon:SetSnapToPixelGrid(false)
	icon:SetTexelSnappingBias(0)
	icon:ClearAllPoints()
	icon:SetPoint("TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", 0, 0)
	icon:SetTexelSnappingBias(0)
	icon:SetSnapToPixelGrid(false)
	icon:SetTexCoord(l or 0.0625, r or 0.9375, t or 0.0625, b or 0.9375)

	if texture then
		icon:SetTexture(texture)
	end

	return icon
end

local function setNormalAtlasTextureHook(self, texture)
	if texture and texture ~= 0 then
		self:SetNormalTexture(0)
	end
end
local function setPushedTexture(button)
	if not button.SetPushedTexture then return end

	button:SetPushedTexture("Interface\\Buttons\\CheckButtonHilight")
	button:GetPushedTexture():SetBlendMode("ADD")
	button:GetPushedTexture():SetAllPoints()
end

local function setHighlightTexture(button)
	if not button.SetHighlightTexture then return end

	button:SetHighlightTexture(button:IsObjectType("CheckButton") and "Interface\\Buttons\\CheckButtonHilight" or "Interface\\Buttons\\ButtonHilight-Square")
	button:GetHighlightTexture():SetBlendMode("ADD")
	button:GetHighlightTexture():SetAllPoints()
end

do
	local handled = {}

	local function azeriteSetDrawLayerHook(self, layer)
		if layer ~= "BACKGROUND" then
			self:SetDrawLayer("BACKGROUND", -1)
		end
	end

	local function updateBorderColor(self)
		if self:IsShown() then
			self:GetParent().Border_:SetVertexColor(self:GetVertexColor())
		else
			self:GetParent().Border_:SetVertexColor(1, 1, 1)
		end
	end

	local function setNoTextureHook(self, texture)
		if texture and texture ~= 0 then
			self:SetTexture(0)
		end
	end

	function addon.Button:SkinItemSlotButton(button)
		if not button or handled[button] then
			return
		end

		button:HookScript("OnSizeChanged", onSizeChanged)

		local cooldown = button.Cooldown
		if cooldown then
			cooldown:ClearAllPoints()
			cooldown:SetPoint("TOPLEFT", 1, -1)
			cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
		end

		local textureParent = CreateFrame("Frame", nil, button)
		textureParent:SetFrameLevel(cooldown and cooldown:GetFrameLevel() + 1 or button:GetFrameLevel() + 2)
		textureParent:SetAllPoints()
		button.TextureParent = textureParent

		local icon = button.icon
		if icon then
			setIcon(icon)
		end

		local normalTexture = button.GetNormalTexture and button:GetNormalTexture()
		if normalTexture then
			normalTexture:SetTexture(0)
			hooksecurefunc(button, "SetNormalTexture", setNormalAtlasTextureHook)
			hooksecurefunc(button, "SetNormalAtlas", setNormalAtlasTextureHook)
		end
		local pushedTexture = button.GetPushedTexture and button:GetPushedTexture()
		if pushedTexture then
			setPushedTexture(button)
		end

		local highlightTexture = button.GetHighlightTexture and button:GetHighlightTexture()
		if highlightTexture then
			setHighlightTexture(button)
		end

		local border = button:CreateTexture(nil, "BORDER")
		border:SetPoint("TOPLEFT", 0, 0)
		border:SetPoint("BOTTOMRIGHT", 3, -3)
		border:SetTexelSnappingBias(0)
		border:SetSnapToPixelGrid(false)
		border:SetAtlas("UI-HUD-ActionBar-IconFrame")
		button.Border_ = border

		local azeriteTexture = button.AzeriteTexture
		if azeriteTexture then
			azeriteTexture:SetDrawLayer("BACKGROUND", -1)
			hooksecurefunc(azeriteTexture, "SetDrawLayer", azeriteSetDrawLayerHook)
		end

		local bIconBorder = button.IconBorder
		if bIconBorder then
			bIconBorder:SetTexture(0)

			hooksecurefunc(bIconBorder, "Hide", updateBorderColor)
			hooksecurefunc(bIconBorder, "Show", updateBorderColor)
			hooksecurefunc(bIconBorder, "SetVertexColor", updateBorderColor)
			hooksecurefunc(bIconBorder, "SetTexture", setNoTextureHook)
			hooksecurefunc(bIconBorder, "SetAtlas", setNoTextureHook)
		end

		local popoutButton = button.popoutButton
		if popoutButton then
			popoutButton:SetFrameStrata("HIGH")
		end

		handled[button] = true
	end

	function addon.Button:SkinActionButton(button)
		if not button or handled[button] then return end

		local hotKey = button.HotKey
		if hotKey then
			hotKey:SetSize(0, 0)
			hotKey:SetJustifyH("RIGHT")
		end

		local count = button.Count
		if count then
			count:SetSize(0, 0)
			count:SetJustifyH("RIGHT")
			count:SetPoint("BOTTOMRIGHT", -3, 4)
		end

		handled[button] = true
	end
end

function addon.Button:Create(parent, name)
	local button = CreateFrame("Button", name, parent)
	button:SetSize(28, 28)
	button:HookScript("OnSizeChanged", onSizeChanged)

	button.Icon = setIcon(button)

	local border = button:CreateTexture(nil, "BORDER")
	border:SetPoint("TOPLEFT", 0, 0)
	border:SetPoint("BOTTOMRIGHT", 3, -3)
	border:SetTexelSnappingBias(0)
	border:SetSnapToPixelGrid(false)
	border:SetAtlas("UI-HUD-ActionBar-IconFrame")

	setHighlightTexture(button)
	setPushedTexture(button)

	return button
end
