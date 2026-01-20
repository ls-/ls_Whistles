local _, addon = ...
local C, D, L = addon.C, addon.D, addon.L

-- Lua
local _G = getfenv(0)

-- Mine
local LEM = LibStub("LibEditMode-ls", true) or LibStub("LibEditMode")

function addon:GetActionBarLayout()
	return C.db.profile.actionbars.layouts[LEM:GetActiveLayoutName() or "Modern"]
end

function addon:GetActionBarConfigForBar(name)
	return C.db.profile.actionbars.layouts[LEM:GetActiveLayoutName() or "Modern"][name]
end

function addon:GetDefaultActionBarLayout()
	return C.db.profile.actionbars.layouts["*"]
end

local function rgb(...)
	return addon:CreateColor(...)
end

D.global = {
	colors = {
		addon = rgb(28, 169, 201), -- #1CA9C9 (Crayola Pacific Blue)
		red = rgb(220, 68, 54), -- #DC4436 (7.5R 5/14)
		green = rgb(46, 172, 52), -- #2EAC34 (10GY 6/12)
		blue = rgb(38, 125, 206), -- #267DCE (5PB 5/12)
		yellow = rgb(246, 196, 66), -- #F6C442 (2.5Y 8/10)
		ilvl = {
			[  0] = rgb(220, 68, 54), -- #DC4436 (7.5R 5/14)
			[0.5] = rgb(246, 196, 66), -- #F6C442 (2.5Y 8/10)
			[  1] = rgb(255, 255, 255), -- #FFFFFF
		},
		gyr = {
			[  0] = rgb(46, 172, 52), -- #2EAC34 (10GY 6/12)
			[0.5] = rgb(246, 196, 66), -- #F6C442 (2.5Y 8/10)
			[  1] = rgb(220, 68, 54), -- #DC4436 (7.5R 5/14)
		},
		ryg = {
			[  0] = rgb(220, 68, 54), -- #DC4436 (7.5R 5/14)
			[0.5] = rgb(246, 196, 66), -- #F6C442 (2.5Y 8/10)
			[  1] = rgb(46, 172, 52), -- #2EAC34 (10GY 6/12)
		},
	},
	settings = {
		["**"] = { -- bar
			text = false,
			fade = false,
		},
		["MainActionBar"] = {
			textures = false,
		},
	},
}

D.profile = {
	actionbars = {
		enabled = false,
		desaturation = {
			unusable = false,
			oom = false,
		},
		cast_vfx = true,
		short_hotkey = false,
		layouts = {
			["*"] = { -- layout
				["**"] = { -- bar
					hotkey = true,
					macro = true,
					fade = {
						enabled = false,
						combat = false,
						target = false,
						min_alpha = 0.25,
					},
				},
				["MainActionBar"] = {
					textures = {
						left_cap = "default", -- "", "ui-hud-actionbar-gryphon-left", "ui-hud-actionbar-wyvern-left"
						right_cap = "default", -- "", "ui-hud-actionbar-gryphon-right", "ui-hud-actionbar-wyvern-right"
					}
				},
				["ExtraAbilityContainer"] = { -- zone and extra
					textures = true,
				},
			},
		},
	},
	character_frame = {
		enabled = false,
		ilvl = true,
		upgrade = false,
		enhancements = true,
		missing_enhancements = {
			head = false,
			neck = false,
			shoulder = false,
			back = false,
			chest = false,
			wrist = false,
			main_hand = false,
			hands = false,
			waist = false,
			legs = false,
			feet = false,
			finger = false,
			trinket = false,
			secondary_hand = false,
		},
	},
	inspect_frame = {
		enabled = false,
		ilvl = true,
		upgrade = false,
		enhancements = true,
	},
	game_menu = {
		enabled = false,
		scale = 0.85,
	},
	mail = {
		enabled = false,
	},
	journey_frame = {
		enabled = false,
	},
	loot_frame = {
		enabled = false,
	},
	micro_menu = {
		enabled = false,
		helptips = true,
		buttons = {
			character = {
				tooltip = false,
			},
			-- spellbook = {
			-- },
			-- talent = {
			-- },
			-- achievement = {
			-- },
			quest = {
				tooltip = false,
			},
			-- housing = {
			-- },
			-- guild = {
			-- },
			lfd = {
				tooltip = false,
			},
			-- collection = {
			-- },
			ej = {
				tooltip = false,
			},
			-- store = {
			-- },
			main = {
				tooltip = false,
			},
			-- help = {
			-- },
		},
	},
	backpack = {
		enabled = false,
	},
	suggest_frame = {
		enabled = false,
	},
}
