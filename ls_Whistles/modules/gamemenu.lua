local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.GameMenu = {}

-- Lua
local _G = getfenv(0)

-- Mine
local function adjustScale(self)
	if not C.db.profile.game_menu.enabled then return end

	self:SetScale(C.db.profile.game_menu.scale)
end

local isInit = false

function addon.GameMenu:IsInit()
	return isInit
end

function addon.GameMenu:Init()
	if isInit then return end
	if not C.db.profile.game_menu.enabled then return end

	GameMenuFrame:HookScript("OnShow", adjustScale)

	isInit = true
end
