local ADDON_NAME, LingkanUI = ...

-- Supplies the font dropdown with every LibSharedMedia font, so entries can be
-- previewed in their own typeface.

local FontList = {}
LingkanUI.FontList = FontList

function FontList:GetEntries()
    local entries = {}
    local LSM = LibStub("LibSharedMedia-3.0", true)

    if not LSM then
        -- LibSharedMedia is provided by ElvUI in this setup; degrade to the game default
        entries[1] = { value = "Fonts\\FRIZQT__.TTF", text = "Default", font = "Fonts\\FRIZQT__.TTF" }
        return entries
    end

    local mediaType = (LSM.MediaType and LSM.MediaType.FONT) or "font"
    local names = LSM:List(mediaType)
    if not names then return entries end

    for _, name in ipairs(names) do
        entries[#entries + 1] = { value = name, text = name, font = LSM:Fetch(mediaType, name) }
    end

    table.sort(entries, function(a, b) return a.text < b.text end)
    return entries
end

-- Outline styles shared by every font option
FontList.OUTLINES = {
    NONE = "None",
    OUTLINE = "Outline",
    THICKOUTLINE = "Thick Outline",
    ["OUTLINE, MONOCHROME"] = "Outline, Monochrome",
}

FontList.OUTLINE_ORDER = { "NONE", "OUTLINE", "THICKOUTLINE", "OUTLINE, MONOCHROME" }

-- Anchor points shared by the indicator position options
FontList.ANCHORS = {
    TOPLEFT = "Top Left",
    TOP = "Top",
    TOPRIGHT = "Top Right",
    LEFT = "Left",
    CENTER = "Center",
    RIGHT = "Right",
    BOTTOMLEFT = "Bottom Left",
    BOTTOM = "Bottom",
    BOTTOMRIGHT = "Bottom Right",
}

FontList.ANCHOR_ORDER = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}
