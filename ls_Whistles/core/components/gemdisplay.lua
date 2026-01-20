local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L
addon.GemDisplay = {}

-- Lua
local _G = getfenv(0)
local ipairs = _G.ipairs
local next = _G.next

-- Mine
local gem_display_proto = {}

function gem_display_proto:SetGems(...)
	local sockets = {...}
	local numSockets = 0

	for _, socket in next, sockets do
		numSockets = numSockets + (socket and 1 or 0)
	end

	for index, slot in ipairs(self.Slots) do
		slot:SetShown(index <= numSockets)
		-- slot:SetShown(true)

		slot.Gem:SetTexture(sockets[index])
		-- slot.Gem:SetTexture("Interface\\ICONS\\INV_Misc_Gem_Opal_01")
	end

	self:Layout()
end

function addon.GemDisplay:Create(parent, isHorizontal)
	local gemDisplay = Mixin(CreateFrame("Frame", nil, parent, isHorizontal and "PaperDollItemSocketDisplayHorizontalTemplate" or "PaperDollItemSocketDisplayVerticalTemplate"), gem_display_proto)
	gemDisplay:Show()

	for i = 1, 3 do
		gemDisplay["Slot" .. i]:SetSize(12, 12)

		gemDisplay["Slot" .. i].Gem:Show()
		gemDisplay["Slot" .. i].Gem:SetTexCoord(6 / 64, 58 / 64, 6 / 64, 58 / 64)
		gemDisplay["Slot" .. i].Gem:SetSnapToPixelGrid(false)
		gemDisplay["Slot" .. i].Gem:SetTexelSnappingBias(0)

		gemDisplay["Slot" .. i].Slot:SetDrawLayer("OVERLAY")
		gemDisplay["Slot" .. i].Slot:SetTexture("Interface\\AddOns\\ls_Whistles\\assets\\empty-socket")
		gemDisplay["Slot" .. i].Slot:SetTexCoord(4 / 32, 28 / 32, 4 / 32, 28 / 32)
		gemDisplay["Slot" .. i].Slot:SetSnapToPixelGrid(false)
		gemDisplay["Slot" .. i].Slot:SetTexelSnappingBias(0)
	end

	return gemDisplay
end
