local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

local SECTION_HEIGHT = 300

-- The four health indicators, in the order they appear on the page
local INDICATORS = {
    { key = "healthAbsolute", label = "Player - Health Value" },
    { key = "healthPercent",  label = "Player - Health Percent" },
    { key = "targetAbsolute", label = "Target - Health Value" },
    { key = "targetPercent",  label = "Target - Health Percent" },
}

local function Apply()
    LingkanUI.Interface:ApplyInterfaceSettings()
end

-- Builds one collapsible block of controls for a single indicator
local function BuildIndicatorSection(content, anchorTo, indicator)
    local db = LingkanUI.db.profile.interface[indicator.key]
    local FontList = LingkanUI.FontList

    local wrapper, body = W:CreateCollapsibleSection(content, {
        text = indicator.label,
        x = 14, y = -84,
        height = SECTION_HEIGHT,
        startOpen = false,
    })

    if anchorTo then
        wrapper:ClearAllPoints()
        wrapper:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -6)
        wrapper:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    end

    local function IsOff() return not db.enabled end

    W:CreateCheckbox(body, {
        label = "Enabled",
        desc = "Show this indicator.",
        db = db, key = "enabled",
        x = 10, y = -6,
        isMaster = true,
        onChange = Apply,
    })

    W:CreateFontDropdown(body, {
        label = "Font",
        desc = "Font used for this indicator.",
        db = db, key = "font",
        x = 10, y = -34,
        width = 200,
        disabled = IsOff,
        onChange = Apply,
    })

    W:CreateDropdown(body, {
        label = "Outline",
        desc = "Outline style applied to the text.",
        db = db, key = "outline",
        values = FontList.OUTLINES,
        order = FontList.OUTLINE_ORDER,
        x = 230, y = -34,
        width = 180,
        disabled = IsOff,
        onChange = Apply,
    })

    W:CreateSlider(body, {
        label = "Font Size",
        db = db, key = "fontsize",
        min = 6, max = 36, step = 1,
        x = 10, y = -90,
        width = 200,
        disabled = IsOff,
        onChange = Apply,
    })

    W:CreateDropdown(body, {
        label = "Anchor From",
        desc = "Anchor point on the text itself.",
        db = db, key = "anchorFrom",
        values = FontList.ANCHORS,
        order = FontList.ANCHOR_ORDER,
        x = 10, y = -142,
        width = 200,
        disabled = IsOff,
        onChange = Apply,
    })

    W:CreateDropdown(body, {
        label = "Anchor To",
        desc = "Anchor point on the health bar.",
        db = db, key = "anchorTo",
        values = FontList.ANCHORS,
        order = FontList.ANCHOR_ORDER,
        x = 230, y = -142,
        width = 180,
        disabled = IsOff,
        onChange = Apply,
    })

    W:CreateSlider(body, {
        label = "Offset X",
        desc = "Horizontal offset from the anchor point.",
        db = db, key = "offsetX",
        min = -200, max = 200, step = 1,
        x = 10, y = -198,
        width = 200,
        disabled = IsOff,
        onChange = Apply,
    })

    W:CreateSlider(body, {
        label = "Offset Y",
        desc = "Vertical offset from the anchor point.",
        db = db, key = "offsetY",
        min = -200, max = 200, step = 1,
        x = 10, y = -248,
        width = 200,
        disabled = IsOff,
        onChange = Apply,
    })

    body:SetHeight(SECTION_HEIGHT)
    wrapper:RecalcHeight()
    return wrapper
end

function LingkanUI:InitUnitIndicators()
    local parent = LingkanUI.MainFrame.Content

    W:CachedPanel(cache, "unitIndicators", parent, function(panel)
        local scrollFrame, content = W:CreateScrollFrame(panel, 1400)

        W:CreatePageHeader(content,
            { { "UNIT ", C.BLUE }, { "INDICATORS", C.ORANGE } },
            "Health text anchored to the player and target health bars.")

        local previous = nil
        for _, indicator in ipairs(INDICATORS) do
            previous = BuildIndicatorSection(content, previous, indicator)
        end

        -- Grow the scroll child to fit whichever sections are expanded
        local function ResizeContent()
            local total = 84
            for _, child in ipairs({ content:GetChildren() }) do
                if child.RecalcHeight then
                    total = total + child:GetHeight() + 6
                end
            end
            content:SetHeight(math.max(total + 20, 200))
            if scrollFrame.UpdateScrollRange then scrollFrame.UpdateScrollRange() end
        end

        -- Recalculate whenever a section is expanded or collapsed
        for _, child in ipairs({ content:GetChildren() }) do
            if child.header then
                child.header:HookScript("OnClick", function()
                    C_Timer.After(0, ResizeContent)
                end)
            end
        end

        ResizeContent()
    end)
end
