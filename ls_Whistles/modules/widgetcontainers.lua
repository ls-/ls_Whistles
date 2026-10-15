local _, addon = ...
local C, D, L, LEM = addon.C, addon.D, addon.L, addon.LibEditMode
addon.WidgetContainers = {}

-- Lua
local _G = getfenv(0)

-- Mine
local isInit = false

function addon.WidgetContainers:IsInit()
	return isInit
end

function addon.WidgetContainers:Init()
	if isInit then return end
	if not C.db.profile.widget_containers.enabled then return end

	-- initially it's only 10 x 10
	UIWidgetTopCenterContainerFrame.minimumWidth = 128
	UIWidgetTopCenterContainerFrame.minimumHeight = 16

	UIWidgetTopCenterContainerFrame:SetSize(128, 16)

	local function onPositionChanged(_, layoutName, point, x, y)
		C.db.profile.widget_containers.layouts[layoutName].UIWidgetTopCenterContainerFrame.point.point = point
		C.db.profile.widget_containers.layouts[layoutName].UIWidgetTopCenterContainerFrame.point.x = x
		C.db.profile.widget_containers.layouts[layoutName].UIWidgetTopCenterContainerFrame.point.y = y
	end

	LEM:AddFrame(UIWidgetTopCenterContainerFrame, onPositionChanged, D.profile.widget_containers.layouts["*"].UIWidgetTopCenterContainerFrame.point, "UIWidgetTopCenterContainerFrame")

	local function layoutCallback(layoutName)
		-- AceDB takes care of layout table duplication
		local layout = C.db.profile.widget_containers.layouts[layoutName]

		UIWidgetTopCenterContainerFrame:ClearAllPoints()
		UIWidgetTopCenterContainerFrame:SetPoint(layout.UIWidgetTopCenterContainerFrame.point.point, layout.UIWidgetTopCenterContainerFrame.point.x, layout.UIWidgetTopCenterContainerFrame.point.y)
	end

	function addon.WidgetContainers:UpdateLayoutSettings()
		layoutCallback(LEM:GetActiveLayoutName())
	end

	LEM:RegisterCallback("layout", layoutCallback)

	LEM:RegisterCallback("create", function(newLayoutName, _, sourceLayoutName)
		if sourceLayoutName then
			addon:CopyTable(C.db.profile.widget_containers.layouts[sourceLayoutName], C.db.profile.widget_containers.layouts[newLayoutName])
		end
	end)

	LEM:RegisterCallback("delete", function(oldLayoutName)
		C.db.profile.widget_containers.layouts[oldLayoutName] = nil
	end)

	LEM:RegisterCallback("rename", function(oldLayoutName, newLayoutName)
		addon:CopyTable(C.db.profile.widget_containers.layouts[oldLayoutName], C.db.profile.widget_containers.layouts[newLayoutName])

		C.db.profile.widget_containers.layouts[oldLayoutName] = nil
	end)
end
