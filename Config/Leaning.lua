local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

function LingkanUI:InitLeaning()
    local parent = LingkanUI.MainFrame.Content
    local db = LingkanUI.db.profile.lean

    W:CachedPanel(cache, "leaning", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 300)

        W:CreatePageHeader(content,
            { { "LEANING", C.BLUE } },
            "Runs the /lean emote automatically once you stand still.")

        W:CreateCheckbox(content, {
            label = "Enable Leaning",
            desc = "Automatically execute the leaning emote when you stop moving out of combat.",
            db = db, key = "enabled",
            x = 14, y = -84,
            isMaster = true,
            onChange = function(value)
                if value then
                    LingkanUI.Leaning:Load()
                else
                    LingkanUI.Leaning:Unload()
                end
            end,
        })

        W:CreateLabel(content,
            "Leaning is suppressed while mounted, casting or in combat.",
            { x = 14, y = -116, color = C.DIM })

        if not LingkanUI.Version.isRetail then
            W:CreateLabel(content,
                "|cff" .. C.ORANGE_HEX .. "This module only loads on retail clients.|r",
                { x = 14, y = -140 })
        end
    end)
end
