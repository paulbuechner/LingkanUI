local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

local SHEATH_MODES = {
    KEEP_SHEATED = "Keep Sheathed",
    KEEP_UNSHEATED = "Keep Unsheathed",
}
local SHEATH_MODE_ORDER = { "KEEP_SHEATED", "KEEP_UNSHEATED" }

function LingkanUI:InitSheathing()
    local parent = LingkanUI.MainFrame.Content
    local db = LingkanUI.db.profile.sheath

    local function IsOff() return not db.enabled end

    W:CachedPanel(cache, "sheathing", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 400)

        W:CreatePageHeader(content,
            { { "SHEATH ", C.BLUE }, { "CONTROL", C.ORANGE } },
            "Keep your weapons drawn or put away automatically.")

        W:CreateCheckbox(content, {
            label = "Enable Sheath Control",
            desc = "Enable automatic weapon sheath control.",
            db = db, key = "enabled",
            x = 14, y = -84,
            isMaster = true,
            onChange = function(value)
                if value then
                    LingkanUI.Sheathing:Load()
                else
                    LingkanUI.Sheathing:Unload()
                end
            end,
        })

        W:CreateDropdown(content, {
            label = "Sheath Mode",
            desc = "Choose whether to keep weapons sheathed or unsheathed.",
            db = db, key = "mode",
            values = SHEATH_MODES,
            order = SHEATH_MODE_ORDER,
            x = 14, y = -120,
            width = 220,
            disabled = IsOff,
        })

        W:CreateSectionHeader(content, "Weapon Type", 10, -184)

        W:CreateCheckbox(content, {
            label = "Melee Weapons Only",
            desc = "Only apply sheath control to melee weapons.",
            db = db, key = "meleeOnly",
            x = 14, y = -208,
            disabled = IsOff,
        })

        W:CreateCheckbox(content, {
            label = "Ranged Weapons Only",
            desc = "Only apply sheath control to ranged weapons.",
            db = db, key = "rangedOnly",
            x = 14, y = -234,
            disabled = IsOff,
        })
    end)
end
