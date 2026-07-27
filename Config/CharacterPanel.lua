local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

function LingkanUI:InitCharacterPanel()
    local parent = LingkanUI.MainFrame.Content
    local db = LingkanUI.db.profile.betterCharacterPanel
    local BCP = LingkanUI.BetterCharacterPanel

    local function IsOff() return not db.enabled end

    W:CachedPanel(cache, "characterPanel", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 520)

        W:CreatePageHeader(content,
            { { "CHARACTER ", C.BLUE }, { "PANEL", C.ORANGE } },
            "Item level, enchants, sockets and durability on the character and inspect panels.")

        W:CreateCheckbox(content, {
            label = "Enable Better Character Panel",
            desc = "Adds item level, enchant, socket and durability information to the character and inspect panels.",
            db = db, key = "enabled",
            x = 14, y = -84,
            isMaster = true,
            onChange = function() LingkanUI:RequestReload() end,
        })

        W:CreateLabel(content,
            "Changing the display options below needs a UI reload to fully apply.",
            { x = 14, y = -112, color = C.DIM })

        -- Display options -------------------------------------------------------------
        W:CreateSectionHeader(content, "Display Options", 10, -140)

        local displayToggles = {
            { key = "showItemLevel", label = "Item Level",     desc = "Display item level text on equipment slots." },
            { key = "showEnchants",  label = "Enchants",       desc = "Display enchant text, or a missing enchant warning." },
            { key = "showDurability", label = "Durability Bar", desc = "Display a durability bar when an item is below 100%." },
            { key = "showSockets",   label = "Sockets & Gems", desc = "Display socket and gem icons; missing sockets show in red." },
        }

        for index, toggle in ipairs(displayToggles) do
            W:CreateCheckbox(content, {
                label = toggle.label,
                desc = toggle.desc,
                db = db, key = toggle.key,
                x = 14, y = -164 - ((index - 1) * 26),
                disabled = IsOff,
                onChange = function() LingkanUI:RequestReload() end,
            })
        end

        W:CreateSeparator(content, 10, -280)

        -- Panel scale -----------------------------------------------------------------
        W:CreateSectionHeader(content, "Panel", 10, -296)

        W:CreateLabel(content,
            "Applies immediately. Works independently of the display options above.",
            { x = 14, y = -318, color = C.DIM })

        W:CreateSlider(content, {
            label = "Panel Scale",
            desc = "Size of the Blizzard character panel.",
            db = db, key = "scale",
            min = BCP.MIN_SCALE, max = BCP.MAX_SCALE, step = 0.01,
            isPercent = true,
            x = 14, y = -344,
            width = 260,
            onChange = function() BCP:ApplyScale() end,
        })

        W:CreateButton(content, {
            label = "Reset Scale",
            desc = "Reset the panel scale to 100%.",
            x = 14, y = -400,
            width = 110,
            disabled = function() return db.scale == BCP.DEFAULT_SCALE end,
            func = function()
                db.scale = BCP.DEFAULT_SCALE
                BCP:ApplyScale()
            end,
        })
    end)
end
