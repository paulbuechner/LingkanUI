local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

function LingkanUI:InitGeneral()
    local parent = LingkanUI.MainFrame.Content
    local db = LingkanUI.db.profile.general

    W:CachedPanel(cache, "general", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 420)

        W:CreatePageHeader(content,
            { { "GENERAL", C.BLUE } },
            "Core LingkanUI behaviour and developer tooling.")

        W:CreateSectionHeader(content, "Interface", 10, -80)

        W:CreateCheckbox(content, {
            label = "Hide UI Errors",
            desc = "Hide UI error messages (\"Not enough rage\", \"Out of range\", ...) from appearing on screen.",
            db = db.interface, key = "hideUIErrors",
            x = 14, y = -104,
            onChange = function() LingkanUI.Interface:ApplyInterfaceSettings() end,
        })

        W:CreateCheckbox(content, {
            label = "Show Minimap Button",
            desc = "Show the LingkanUI button on the minimap.",
            get = function() return not LingkanUI.db.profile.minimap.hide end,
            set = function(value) LingkanUI.MinimapButton:SetShown(value) end,
            x = 14, y = -130,
        })

        W:CreateSeparator(content, 10, -162)

        W:CreateSectionHeader(content, "Developer", 10, -178)

        W:CreateCheckbox(content, {
            label = "Developer Mode",
            desc = "Enables per-module debug logging and test commands.",
            db = db, key = "developerMode",
            x = 14, y = -202,
            onChange = function(value)
                local profile = LingkanUI.db.profile
                if value then
                    LingkanUI:Print("Developer mode enabled.")
                    profile.general.interface.debug = true
                else
                    LingkanUI:Print("Developer mode disabled.")
                    -- Turn off all module debug modes when developer mode is disabled
                    profile.general.interface.debug = false
                    profile.sheath.debug = false
                    profile.lean.debug = false
                    profile.tabTargetArenaFix.debug = false
                    profile.betterCharacterPanel.debug = false
                    profile.zoneText.debug = false
                    if profile.roleIcons then
                        profile.roleIcons.debug = false
                    end
                end
            end,
        })

        local debugWrapper, debugContent = W:CreateCollapsibleSection(content, {
            text = "Module Debug Logging",
            x = 14, y = -232,
            height = 120,
            startOpen = false,
        })

        local debugToggles = {
            { label = "Interface",           db = db.interface,                              key = "debug" },
            { label = "Sheathing",           db = LingkanUI.db.profile.sheath,               key = "debug" },
            { label = "Leaning",             db = LingkanUI.db.profile.lean,                 key = "debug" },
            { label = "Tab Target Arena Fix", db = LingkanUI.db.profile.tabTargetArenaFix,   key = "debug" },
            { label = "Role Icons",          db = LingkanUI.db.profile.roleIcons,            key = "debug" },
            { label = "Zone Text",           db = LingkanUI.db.profile.zoneText,             key = "debug" },
            { label = "Character Panel",     db = LingkanUI.db.profile.betterCharacterPanel, key = "debug" },
        }

        for index, toggle in ipairs(debugToggles) do
            W:CreateCheckbox(debugContent, {
                label = toggle.label,
                db = toggle.db, key = toggle.key,
                x = 10, y = -4 - ((index - 1) * 20),
                disabled = function() return not LingkanUI.db.profile.general.developerMode end,
            })
        end

        debugContent:SetHeight(#debugToggles * 20 + 8)
        debugWrapper:RecalcHeight()
    end)
end
