local ADDON_NAME, LingkanUI = ...

-- Database defaults
LingkanUI.defaults = {
    profile = {
        general = {
            developerMode = false,
        },
        sheath = {
            enabled = false,
            mode = "KEEP_UNSHEATED", -- "KEEP_SHEATED" or "KEEP_UNSHEATED"
            meleeOnly = false,
            rangedOnly = false,
            debug = false,
        },
        tabTargetArenaFix = {
            enabled = false,
            showMessages = true,
            debug = false,
        }
    }
}

-- Options table for AceConfig
LingkanUI.options = {
    name = "LingkanUI",
    type = "group",
    args = {
        general = {
            name = "General",
            type = "group",
            order = 1,
            args = {
                header = {
                    name = "LingkanUI Settings",
                    type = "header",
                    order = 1,
                },
                description = {
                    name = "Configure various LingkanUI features.",
                    type = "description",
                    order = 2,
                },
                debug = {
                    name = "Developer Mode",
                    desc = "Enable developer mode for additional logging and test commands",
                    type = "toggle",
                    order = 3,
                    get = function() return LingkanUI.db.profile.general.developerMode end,
                    set = function(_, value)
                        LingkanUI.db.profile.general.developerMode = value
                        LingkanUI.debug = value
                        if value then
                            LingkanUI:Print("Developer mode enabled. Additional slash commands are now available.")
                            LingkanUI:RegisterDebugCommands()
                        else
                            LingkanUI:Print("Developer mode disabled.")
                            LingkanUI:UnregisterDebugCommands()
                        end
                    end,
                },
            }
        },
        sheath = {
            name = "Sheath Control",
            type = "group",
            order = 2,
            args = {
                debug = {
                    name = "Debug Mode",
                    desc = "Enable debug logging for sheath control",
                    type = "toggle",
                    order = 1,
                    get = function() return LingkanUI.db.profile.sheath.debug end,
                    set = function(_, value) LingkanUI.db.profile.sheath.debug = value end,
                    disabled = function() return not LingkanUI.db.profile.sheath.enabled end,
                    hidden = function() return not LingkanUI.db.profile.general.developerMode end,
                },
                header = {
                    name = "Weapon Sheath Settings",
                    type = "header",
                    order = 2,
                },
                description = {
                    name = "Control whether your weapons stay sheathed or unsheathed.",
                    type = "description",
                    order = 3,
                },
                enabled = {
                    name = "Enable Sheath Control",
                    desc = "Enable automatic weapon sheath control",
                    type = "toggle",
                    order = 4,
                    get = function() return LingkanUI.db.profile.sheath.enabled end,
                    set = function(_, value)
                        LingkanUI.db.profile.sheath.enabled = value
                        if value then
                            LingkanUI.Sheathing:EnableSheathHandler()
                        else
                            LingkanUI.Sheathing:DisableSheathHandler()
                        end
                    end,
                },
                mode = {
                    name = "Sheath Mode",
                    desc = "Choose whether to keep weapons sheathed or unsheathed",
                    type = "select",
                    order = 5,
                    values = {
                        KEEP_SHEATED = "Keep Sheathed",
                        KEEP_UNSHEATED = "Keep Unsheathed",
                    },
                    get = function() return LingkanUI.db.profile.sheath.mode end,
                    set = function(_, value) LingkanUI.db.profile.sheath.mode = value end,
                    disabled = function() return not LingkanUI.db.profile.sheath.enabled end,
                },
                weaponType = {
                    name = "Weapon Type",
                    type = "group",
                    order = 6,
                    inline = true,
                    disabled = function() return not LingkanUI.db.profile.sheath.enabled end,
                    args = {
                        meleeOnly = {
                            name = "Melee Weapons Only",
                            desc = "Only apply sheath control to melee weapons",
                            type = "toggle",
                            order = 1,
                            get = function() return LingkanUI.db.profile.sheath.meleeOnly end,
                            set = function(_, value)
                                LingkanUI.db.profile.sheath.meleeOnly = value
                            end,
                        },
                        rangedOnly = {
                            name = "Ranged Weapons Only",
                            desc = "Only apply sheath control to ranged weapons",
                            type = "toggle",
                            order = 2,
                            get = function() return LingkanUI.db.profile.sheath.rangedOnly end,
                            set = function(_, value)
                                LingkanUI.db.profile.sheath.rangedOnly = value
                            end,
                        },
                    }
                },
            }
        },
        tabTargetArenaFix = {
            name = "Tab Target Arena Fix",
            type = "group",
            order = 3,
            args = {
                debug = {
                    name = "Debug Mode",
                    desc = "Enable debug logging for tab target arena fix",
                    type = "toggle",
                    order = 1,
                    get = function() return LingkanUI.db.profile.tabTargetArenaFix.debug end,
                    set = function(_, value) LingkanUI.db.profile.tabTargetArenaFix.debug = value end,
                    disabled = function() return not LingkanUI.db.profile.tabTargetArenaFix.enabled end,
                    hidden = function() return not LingkanUI.db.profile.general.developerMode end,
                },
                header = {
                    name = "Arena Tab Targeting Settings",
                    type = "header",
                    order = 2,
                },
                description = {
                    name = "Automatically adjust tab targeting behavior in arenas to target enemy players only, avoiding pets and totems.",
                    type = "description",
                    order = 3,
                },
                enabled = {
                    name = "Enable Tab Target Arena Fix",
                    desc = "Enable automatic tab targeting adjustment in arenas",
                    type = "toggle",
                    order = 4,
                    get = function() return LingkanUI.db.profile.tabTargetArenaFix.enabled end,
                    set = function(_, value)
                        LingkanUI.db.profile.tabTargetArenaFix.enabled = value
                        if value then
                            LingkanUI.TabTargetArenaFix:EnableTabTargetArenaFix()
                        else
                            LingkanUI.TabTargetArenaFix:DisableTabTargetArenaFix()
                        end
                    end,
                },
                showMessages = {
                    name = "Show Messages",
                    desc = "Show chat messages when tab targeting mode changes",
                    type = "toggle",
                    order = 5,
                    get = function() return LingkanUI.db.profile.tabTargetArenaFix.showMessages end,
                    set = function(_, value) LingkanUI.db.profile.tabTargetArenaFix.showMessages = value end,
                    disabled = function() return not LingkanUI.db.profile.tabTargetArenaFix.enabled end,
                },
            }
        }
    }
}
