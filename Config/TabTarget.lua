local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

function LingkanUI:InitTabTarget()
    local parent = LingkanUI.MainFrame.Content
    local db = LingkanUI.db.profile.tabTargetArenaFix

    W:CachedPanel(cache, "tabTarget", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 320)

        W:CreatePageHeader(content,
            { { "TAB TARGET ", C.BLUE }, { "ARENA FIX", C.ORANGE } },
            "Restricts tab targeting to enemy players while in arenas.")

        W:CreateCheckbox(content, {
            label = "Enable Tab Target Arena Fix",
            desc = "Rebinds TAB to target enemy players only inside arenas, avoiding pets and totems.",
            db = db, key = "enabled",
            x = 14, y = -84,
            isMaster = true,
            onChange = function(value)
                if value then
                    LingkanUI.TabTargetArenaFix:Load()
                else
                    LingkanUI.TabTargetArenaFix:Unload()
                end
            end,
        })

        W:CreateCheckbox(content, {
            label = "Show Messages",
            desc = "Print a chat message whenever the tab targeting mode changes.",
            db = db, key = "showMessages",
            x = 14, y = -116,
            disabled = function() return not db.enabled end,
        })

        W:CreateLabel(content,
            "This changes the TAB keybind at runtime; it is restored to the default when disabled.",
            { x = 14, y = -148, color = C.DIM })
    end)
end
