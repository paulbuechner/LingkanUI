local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

function LingkanUI:InitZoneText()
    local parent = LingkanUI.MainFrame.Content
    local db = LingkanUI.db.profile.zoneText
    local ZoneText = LingkanUI.ZoneText

    local function IsOff() return not db.enabled end
    local function Apply() ZoneText:ApplyFontSizes() end

    W:CachedPanel(cache, "zoneText", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 480)

        W:CreatePageHeader(content,
            { { "ZONE ", C.BLUE }, { "TEXT", C.ORANGE } },
            "Size of the large zone announcement in the centre of the screen.")

        W:CreateCheckbox(content, {
            label = "Override Zone Text Size",
            desc = "Take control of the zone and subzone announcement font sizes. " ..
                "Turning this off hands them back to Blizzard or ElvUI.",
            db = db, key = "enabled",
            x = 14, y = -84,
            isMaster = true,
            onChange = Apply,
        })

        W:CreateSlider(content, {
            label = "Zone Name Size",
            desc = "Font size of the zone name (the top, larger line).",
            db = db, key = "zoneSize",
            min = ZoneText.MIN_SIZE, max = ZoneText.MAX_SIZE, step = 1,
            x = 14, y = -120,
            width = 260,
            disabled = IsOff,
            onChange = Apply,
        })

        W:CreateSlider(content, {
            label = "Subzone Name Size",
            desc = "Font size of the subzone name (the second, smaller line).",
            db = db, key = "subZoneSize",
            min = ZoneText.MIN_SIZE, max = ZoneText.MAX_SIZE, step = 1,
            x = 14, y = -176,
            width = 260,
            disabled = IsOff,
            onChange = Apply,
        })

        W:CreateSeparator(content, 10, -232)

        W:CreateSectionHeader(content, "Preview", 10, -248)

        W:CreateLabel(content,
            "Shows a sample announcement where the real one appears, using your current " ..
            "zone. It is a stand-in frame, so it never interferes with the real zone text.",
            { x = 14, y = -270, color = C.DIM })

        W:CreateButton(content, {
            label = "Show Preview",
            desc = "Display a test zone announcement for a few seconds.",
            x = 14, y = -312,
            width = 130, height = 26,
            func = function() ZoneText:ShowPreview(3) end,
        })

        W:CreateButton(content, {
            label = "Hide",
            desc = "Hide the preview immediately.",
            x = 154, y = -312,
            width = 90, height = 26,
            func = function() ZoneText:HidePreview() end,
        })

        W:CreateSeparator(content, 10, -356)

        W:CreateLabel(content,
            "This does not affect the minimap zone label.",
            { x = 14, y = -372, color = C.DIM })

        if _G.ElvUI then
            W:CreateLabel(content,
                "|cff" .. C.ORANGE_HEX .. "ElvUI also controls these fonts|r " ..
                "(Fonts > World Zone / World Subzone). LingkanUI re-applies its size " ..
                "after ElvUI, so this setting wins while it is enabled.",
                { x = 14, y = -394 })
        end
    end)
end
