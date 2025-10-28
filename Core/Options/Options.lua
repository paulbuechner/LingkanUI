local ADDON_NAME, LingkanUI = ...

-- Check WoW version
local WoW10 = select(4, GetBuildInfo()) >= 100000

-- Database defaults
LingkanUI.defaults = {
    profile = {
        general = {
            developerMode = false,
            interface = {
                debug = false,
                hideUIErrors = false,
            },
        },
        sheath = {
            enabled = false,
            mode = "KEEP_UNSHEATED", -- "KEEP_SHEATED" or "KEEP_UNSHEATED"
            meleeOnly = false,
            rangedOnly = false,
            debug = false,
        },
        lean = {
            enabled = false,
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
        },
        betterCharacterPanel = {
            enabled = false,
            debug = false,
            showItemLevel = true,
            showEnchants = true,
            showDurability = true,
            showSockets = true,
        },
    }
}

-- Stub WoW globals for external linters (ignored in-game if already defined)
_G.StaticPopupDialogs = _G.StaticPopupDialogs or {}
_G.StaticPopup_Show = _G.StaticPopup_Show or function(...) end
_G.ReloadUI = _G.ReloadUI or function() end
_G.RELOADUI = _G.RELOADUI or "Reload UI"
_G.CANCEL = _G.CANCEL or "Cancel"

-- Generic multi-module option staging & reload popup system
-- Allows any module (profile key) to stage multiple changes, present a single reload popup, and revert all on cancel.
LingkanUI._reloadStage = LingkanUI._reloadStage or { modules = {} }

-- Internal: count total dirty changes across all modules
local function ReloadStage_TotalDirty()
    local total = 0
    for _, data in pairs(LingkanUI._reloadStage.modules) do
        for _ in pairs(data.dirty) do total = total + 1 end
    end
    return total
end

-- Internal: build multiline summary of pending changes
local function ReloadStage_Summary()
    local lines = {}
    for moduleName, data in pairs(LingkanUI._reloadStage.modules) do
        local count = 0
        for _ in pairs(data.dirty) do count = count + 1 end
        if count > 0 then
            table.insert(lines, string.format("- %s: %d", moduleName, count))
        end
    end
    table.sort(lines)
    return table.concat(lines, "\n")
end

local function ReloadStage_UpdatePopup()
    if not StaticPopup_FindVisible then return end
    local frame = StaticPopup_FindVisible("LINGKANUI_RELOAD_PENDING")
    if frame and frame.text then
        local total = ReloadStage_TotalDirty()
        local modules = 0
        for name, data in pairs(LingkanUI._reloadStage.modules) do
            for _ in pairs(data.dirty) do
                modules = modules + 1; break
            end
        end
        local summary = ReloadStage_Summary()
        frame.text:SetText(string.format(
            "LingkanUI settings changed (%d pending across %d module%s).\nReload UI to apply or Cancel to revert.\n\n%s",
            total,
            modules,
            modules == 1 and "" or "s",
            summary ~= "" and summary or "(No staged changes)"
        ))
    end
end

-- Public API: Stage a change for a given module (profile root key) & option key
function LingkanUI:StageOptionChange(moduleName, optionKey, newValue)
    if not self.db or not self.db.profile then return end
    local moduleProfile = self.db.profile[moduleName]
    if not moduleProfile then return end
    local oldValue = moduleProfile[optionKey]
    if oldValue == newValue then return end

    local stage = self._reloadStage.modules[moduleName]
    if not stage then
        stage = { originals = {}, dirty = {} }
        self._reloadStage.modules[moduleName] = stage
    end
    -- Record original only once
    if stage.originals[optionKey] == nil then
        stage.originals[optionKey] = oldValue
    end

    -- Apply staged value immediately so UI reflects it
    moduleProfile[optionKey] = newValue
    stage.dirty[optionKey] = true

    -- If user toggles back to original value, clear dirty state for that key
    if newValue == stage.originals[optionKey] then
        stage.dirty[optionKey] = nil
        -- If no dirty left for module remove module entry
        local any
        for _ in pairs(stage.dirty) do
            any = true
            break
        end
        if not any then
            self._reloadStage.modules[moduleName] = nil
        end
    end

    -- Manage popup lifecycle
    if not (StaticPopup_FindVisible and StaticPopup_FindVisible("LINGKANUI_RELOAD_PENDING")) then
        if not StaticPopupDialogs["LINGKANUI_RELOAD_PENDING"] then
            StaticPopupDialogs["LINGKANUI_RELOAD_PENDING"] = {
                text = "LingkanUI settings changed. Reload UI to apply or Cancel to revert.",
                button1 = _G.RELOADUI or "Reload UI",
                button2 = _G.CANCEL or "Cancel",
                OnAccept = function() if ReloadUI then ReloadUI() end end,
                OnCancel = function()
                    local db = LingkanUI.db and LingkanUI.db.profile
                    if db then
                        for modName, data in pairs(LingkanUI._reloadStage.modules) do
                            local modProfile = db[modName]
                            if modProfile then
                                for k, _ in pairs(data.dirty) do
                                    local orig = data.originals[k]
                                    if orig ~= nil then
                                        modProfile[k] = orig
                                    end
                                end
                            end
                        end
                    end
                    -- Reset staging tables
                    LingkanUI._reloadStage.modules = {}
                    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
                    end
                end,
                OnShow = function() ReloadStage_UpdatePopup() end,
                timeout = 0,
                whileDead = 1,
                hideOnEscape = 1,
                preferredIndex = 3,
            }
        end
        StaticPopup_Show("LINGKANUI_RELOAD_PENDING")
    else
        ReloadStage_UpdatePopup()
        -- If no staged changes left, hide popup automatically
        if ReloadStage_TotalDirty() == 0 then
            local frame = StaticPopup_FindVisible("LINGKANUI_RELOAD_PENDING")
            if frame then frame:Hide() end
        end
    end

    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end

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
                        if value then
                            LingkanUI:Print("Developer mode enabled.")
                            LingkanUI.db.profile.general.interface.debug = true
                        else
                            LingkanUI:Print("Developer mode disabled.")
                            -- Turn off all module debug modes when developer mode is disabled
                            LingkanUI.db.profile.general.interface.debug = false
                            LingkanUI.db.profile.sheath.debug = false
                            LingkanUI.db.profile.lean.debug = false
                            LingkanUI.db.profile.tabTargetArenaFix.debug = false
                            if LingkanUI.db.profile.roleIcons then
                                LingkanUI.db.profile.roleIcons.debug = false
                            end
                        end
                    end,
                },
                interfaceHeader = {
                    name = "Interface Settings",
                    type = "header",
                    order = 4,
                },
                hideUIErrors = {
                    name = "Hide UI Errors",
                    desc = "Hide UI error messages from appearing on screen",
                    type = "toggle",
                    order = 5,
                    get = function() return LingkanUI.db.profile.general.interface.hideUIErrors end,
                    set = function(_, value)
                        LingkanUI.db.profile.general.interface.hideUIErrors = value
                        LingkanUI.Interface:ApplyInterfaceSettings()
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
                lean = {
                    name = "Leaning",
                    type = "group",
                    order = 2,
                    args = {
                        debug = {
                            name = "Debug Mode",
                            desc = "Enable debug logging for leaning",
                            type = "toggle",
                            order = 1,
                            get = function() return LingkanUI.db.profile.lean.debug end,
                            set = function(_, value) LingkanUI.db.profile.lean.debug = value end,
                            disabled = function() return not LingkanUI.db.profile.lean.enabled end,
                            hidden = function() return not LingkanUI.db.profile.general.developerMode end,
                        },
                        header = {
                            name = "Leaning Settings",
                            type = "header",
                            order = 2,
                        },
                        description = {
                            name = "Automatically execute the /lean console command when triggered.",
                            type = "description",
                            order = 3,
                        },
                        enabled = {
                            name = "Enable Leaning",
                            desc = "Enable automatic leaning command execution",
                            type = "toggle",
                            order = 4,
                            get = function() return LingkanUI.db.profile.lean.enabled end,
                            set = function(_, value)
                                LingkanUI.db.profile.lean.enabled = value
                                if value then
                                    LingkanUI.Leaning:Load()
                                else
                                    LingkanUI.Leaning:Unload()
                                end
                            end,
                        },
                    }
                },
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
                                    LingkanUI.Sheathing:Load()
                                else
                                    LingkanUI.Sheathing:Unload()
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
                                    LingkanUI.TabTargetArenaFix:Load()
                                else
                                    LingkanUI.TabTargetArenaFix:Unload()
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
                                    LingkanUI.RoleIcons:Load()
                                else
                                    LingkanUI.RoleIcons:Unload()
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
                },
                betterCharacterPanel = {
                    name = "Better Character Panel",
                    type = "group",
                    order = 5,
                    args = {
                        reloadInfo = {
                            name = "Changing display options requires a UI reload to fully apply changes.",
                            type = "description",
                            order = 0,
                        },
                        debug = {
                            name = "Debug Mode",
                            desc = "Enable debug logging for Better Character Panel",
                            type = "toggle",
                            order = 1,
                            get = function() return LingkanUI.db.profile.betterCharacterPanel.debug end,
                            set = function(_, value) LingkanUI.db.profile.betterCharacterPanel.debug = value end,
                            disabled = function() return not LingkanUI.db.profile.betterCharacterPanel.enabled end,
                            hidden = function() return not LingkanUI.db.profile.general.developerMode end,
                        },
                        header = {
                            name = "Display Settings",
                            type = "header",
                            order = 2,
                        },
                        description = {
                            name = "Enhances the character and inspect panels with item level, enchants, sockets, and durability bars.",
                            type = "description",
                            order = 3,
                        },
                        enabled = {
                            name = "Enable Better Character Panel",
                            desc = "Enable enhanced character and inspect panel display (reload required)",
                            type = "toggle",
                            order = 4,
                            get = function() return LingkanUI.db.profile.betterCharacterPanel.enabled end,
                            set = function(_, value) LingkanUI:StageOptionChange("betterCharacterPanel", "enabled", value) end,
                        },
                        displayOptions = {
                            name = "Display Options",
                            type = "group",
                            order = 5,
                            inline = true,
                            disabled = function() return not LingkanUI.db.profile.betterCharacterPanel.enabled end,
                            args = {
                                showItemLevel = {
                                    name = "Item Level",
                                    desc = "Display item level text on equipment slots.",
                                    type = "toggle",
                                    order = 1,
                                    get = function() return LingkanUI.db.profile.betterCharacterPanel.showItemLevel end,
                                    set = function(_, value) LingkanUI:StageOptionChange("betterCharacterPanel", "showItemLevel", value) end,
                                },
                                showEnchants = {
                                    name = "Enchants",
                                    desc = "Display enchant text (or missing enchant warning).",
                                    type = "toggle",
                                    order = 2,
                                    get = function() return LingkanUI.db.profile.betterCharacterPanel.showEnchants end,
                                    set = function(_, value) LingkanUI:StageOptionChange("betterCharacterPanel", "showEnchants", value) end,
                                },
                                showDurability = {
                                    name = "Durability Bar",
                                    desc = "Display durability bar when below 100%.",
                                    type = "toggle",
                                    order = 3,
                                    get = function() return LingkanUI.db.profile.betterCharacterPanel.showDurability end,
                                    set = function(_, value) LingkanUI:StageOptionChange("betterCharacterPanel", "showDurability", value) end,
                                },
                                showSockets = {
                                    name = "Sockets & Gems",
                                    desc = "Display socket and gem icons (empty sockets in red).",
                                    type = "toggle",
                                    order = 4,
                                    get = function() return LingkanUI.db.profile.betterCharacterPanel.showSockets end,
                                    set = function(_, value) LingkanUI:StageOptionChange("betterCharacterPanel", "showSockets", value) end,
                                },
                            }
                        },
                    }
                }
            }
        }
    }
}
