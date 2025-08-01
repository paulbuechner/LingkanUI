local ADDON_NAME, LingkanUI = ...

-- Check WoW version
local WoW10 = select(4, GetBuildInfo()) >= 100000

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
        },
        roleIcons = {
            enabled = false,
            raid = true,
            tooltip = false,
            chat = true,
            system = true,
            classbuttons = true,
            rolebuttons = false,
            serverinfo = true,
            trimserver = true,
            autorole = true,
            target = true,
            focus = true,
            popup = true,
            map = true,
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
        modules = {
            name = "Modules",
            type = "group",
            order = 2,
            childGroups = "tab",
            args = {
                sheath = {
                    name = "Sheath Control",
                    type = "group",
                    order = 1,
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
                },
                roleIcons = {
                    name = "Role Icons",
                    type = "group",
                    order = 4,
                    hidden = function() return not WoW10 end,
                    args = {
                        debug = {
                            name = "Debug Mode",
                            desc = "Enable debug logging for role icons",
                            type = "toggle",
                            order = 1,
                            get = function() return LingkanUI.db.profile.roleIcons.debug end,
                            set = function(_, value) LingkanUI.db.profile.roleIcons.debug = value end,
                            disabled = function() return not LingkanUI.db.profile.roleIcons.enabled end,
                            hidden = function() return not LingkanUI.db.profile.general.developerMode end,
                        },
                        separator1 = {
                            name = "",
                            type = "description",
                            order = 2,
                            hidden = function() return not LingkanUI.db.profile.general.developerMode end,
                        },
                        header = {
                            name = "Role Icons Settings",
                            type = "header",
                            order = 3,
                        },
                        description = {
                            name = "Display role icons in various UI elements and chat. Only available in retail WoW.",
                            type = "description",
                            order = 4,
                        },
                        enabled = {
                            name = "Enable Role Icons",
                            desc = "Enable role icons display",
                            type = "toggle",
                            order = 5,
                            get = function() return LingkanUI.db.profile.roleIcons.enabled end,
                            set = function(_, value)
                                LingkanUI.db.profile.roleIcons.enabled = value
                                if value then
                                    LingkanUI.RoleIcons:Enable()
                                else
                                    LingkanUI.RoleIcons:Disable()
                                end
                            end,
                        },
                        displayOptions = {
                            name = "Display Options",
                            type = "group",
                            order = 6,
                            inline = true,
                            disabled = function() return not LingkanUI.db.profile.roleIcons.enabled end,
                            args = {
                                raid = {
                                    name = "Raid Frame",
                                    desc = "Show role icons on the Raid tab",
                                    type = "toggle",
                                    order = 1,
                                    get = function() return LingkanUI.db.profile.roleIcons.raid end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.raid = value end,
                                },
                                tooltip = {
                                    name = "Tooltips",
                                    desc = "Show role icons in player tooltips",
                                    type = "toggle",
                                    order = 2,
                                    get = function() return LingkanUI.db.profile.roleIcons.tooltip end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.tooltip = value end,
                                },
                                chat = {
                                    name = "Chat",
                                    desc = "Show role icons in chat windows",
                                    type = "toggle",
                                    order = 3,
                                    get = function() return LingkanUI.db.profile.roleIcons.chat end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.chat = value end,
                                },
                                system = {
                                    name = "System Messages",
                                    desc = "Show role icons in system messages",
                                    type = "toggle",
                                    order = 4,
                                    get = function() return LingkanUI.db.profile.roleIcons.system end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.system = value end,
                                },
                                target = {
                                    name = "Target Frame",
                                    desc = "Show role icons on the target frame",
                                    type = "toggle",
                                    order = 5,
                                    get = function() return LingkanUI.db.profile.roleIcons.target end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.target = value end,
                                },
                                focus = {
                                    name = "Focus Frame",
                                    desc = "Show role icons on the focus frame",
                                    type = "toggle",
                                    order = 6,
                                    get = function() return LingkanUI.db.profile.roleIcons.focus end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.focus = value end,
                                },
                                popup = {
                                    name = "Unit Popup Menus",
                                    desc = "Show role icons in unit popup menus",
                                    type = "toggle",
                                    order = 7,
                                    get = function() return LingkanUI.db.profile.roleIcons.popup end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.popup = value end,
                                },
                                map = {
                                    name = "Map Tooltips",
                                    desc = "Show role icons in map tooltips",
                                    type = "toggle",
                                    order = 8,
                                    get = function() return LingkanUI.db.profile.roleIcons.map end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.map = value end,
                                },
                            }
                        },
                        raidOptions = {
                            name = "Raid Frame Options",
                            type = "group",
                            order = 7,
                            inline = true,
                            disabled = function() return not LingkanUI.db.profile.roleIcons.enabled or not LingkanUI.db.profile.roleIcons.raid end,
                            args = {
                                classbuttons = {
                                    name = "Class Summary Buttons",
                                    desc = "Add class summary buttons to the Raid tab",
                                    type = "toggle",
                                    order = 1,
                                    get = function() return LingkanUI.db.profile.roleIcons.classbuttons end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.classbuttons = value end,
                                },
                                rolebuttons = {
                                    name = "Role Summary Buttons",
                                    desc = "Add role summary buttons to the Raid tab",
                                    type = "toggle",
                                    order = 2,
                                    get = function() return LingkanUI.db.profile.roleIcons.rolebuttons end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.rolebuttons = value end,
                                },
                                serverinfo = {
                                    name = "Server Info Frame",
                                    desc = "Add server info frame to the Raid tab",
                                    type = "toggle",
                                    order = 3,
                                    get = function() return LingkanUI.db.profile.roleIcons.serverinfo end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.serverinfo = value end,
                                },
                            }
                        },
                        miscOptions = {
                            name = "Miscellaneous Options",
                            type = "group",
                            order = 8,
                            inline = true,
                            disabled = function() return not LingkanUI.db.profile.roleIcons.enabled end,
                            args = {
                                trimserver = {
                                    name = "Trim Server Names",
                                    desc = "Trim server names in tooltips",
                                    type = "toggle",
                                    order = 1,
                                    get = function() return LingkanUI.db.profile.roleIcons.trimserver end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.trimserver = value end,
                                },
                                autorole = {
                                    name = "Auto Role Assignment",
                                    desc = "Automatically set role and respond to role checks based on your spec",
                                    type = "toggle",
                                    order = 2,
                                    get = function() return LingkanUI.db.profile.roleIcons.autorole end,
                                    set = function(_, value) LingkanUI.db.profile.roleIcons.autorole = value end,
                                },
                            }
                        },
                    }
                }
            }
        }
    }
}
