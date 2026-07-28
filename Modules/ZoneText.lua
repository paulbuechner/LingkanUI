local ADDON_NAME, LingkanUI = ...

-- Controls the size of the large zone announcement in the centre of the screen
-- (ZoneTextFont / SubZoneTextFont). This is not the minimap zone label, which is a
-- separate font object and is left alone.

LingkanUI.ZoneText = {}
local ZoneText = LingkanUI.ZoneText

local MODULE_NAME = "zoneText"

local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

ZoneText.MIN_SIZE, ZoneText.MAX_SIZE = 10, 64

-- Blizzard's stock sizes, captured before anything overrides them, so turning the
-- module off can hand the fonts back in their original state.
local original = {}

local function CaptureOriginal(key, fontObject)
    if not fontObject or original[key] then return end

    local path, size, flags = fontObject:GetFont()
    if path and size then
        original[key] = { path = path, size = size, flags = flags }
    end
end

local function ApplySize(fontObject, key, size)
    if not fontObject then return end

    CaptureOriginal(key, fontObject)

    local path, _, flags = fontObject:GetFont()
    if not path then return end

    -- Preserve the font face and outline chosen by Blizzard or ElvUI; only resize
    fontObject:SetFont(path, size, flags)
end

local function RestoreSize(fontObject, key)
    local saved = original[key]
    if not (fontObject and saved) then return end

    local path, _, flags = fontObject:GetFont()
    fontObject:SetFont(path or saved.path, saved.size, flags or saved.flags)
end

-- Applies the configured sizes, or restores the originals when disabled
function ZoneText:ApplyFontSizes()
    local db = LingkanUI.db and LingkanUI.db.profile.zoneText
    if not db then return end

    local zoneFont = _G.ZoneTextFont
    local subZoneFont = _G.SubZoneTextFont

    CaptureOriginal("zone", zoneFont)
    CaptureOriginal("subzone", subZoneFont)

    if db.enabled then
        DebugPrint(("Applying zone text sizes: %s / %s"):format(db.zoneSize, db.subZoneSize))
        ApplySize(zoneFont, "zone", db.zoneSize)
        ApplySize(subZoneFont, "subzone", db.subZoneSize)
    else
        RestoreSize(zoneFont, "zone")
        RestoreSize(subZoneFont, "subzone")
    end
end

-- ------------------------------------------------------------------------------------
-- Preview
--
-- Deliberately a frame of our own rather than Blizzard's ZoneTextFrame: it inherits the
-- same font objects, so it renders identically, but it can never leave the real zone
-- announcement stuck on screen.
-- ------------------------------------------------------------------------------------

local previewFrame

local function BuildPreview()
    if previewFrame then return previewFrame end

    previewFrame = CreateFrame("Frame", "LingkanUI_ZoneTextPreview", UIParent)
    previewFrame:SetSize(512, 80)
    previewFrame:SetFrameStrata("HIGH")

    -- Sit exactly where the real announcement appears when we can; otherwise fall back
    -- to Blizzard's default anchor for it.
    if _G.ZoneTextFrame then
        previewFrame:SetPoint("TOP", _G.ZoneTextFrame, "TOP", 0, 0)
    else
        previewFrame:SetPoint("TOP", UIParent, "TOP", 0, -77)
    end

    local zoneLine = previewFrame:CreateFontString(nil, "OVERLAY")
    zoneLine:SetFontObject("ZoneTextFont")
    zoneLine:SetPoint("TOP", previewFrame, "TOP", 0, 0)
    previewFrame.zoneLine = zoneLine

    local subZoneLine = previewFrame:CreateFontString(nil, "OVERLAY")
    subZoneLine:SetFontObject("SubZoneTextFont")
    subZoneLine:SetPoint("TOP", zoneLine, "BOTTOM", 0, -4)
    previewFrame.subZoneLine = subZoneLine

    previewFrame:Hide()
    return previewFrame
end

function ZoneText:ShowPreview(duration)
    local frame = BuildPreview()

    -- Re-assert the font objects in case they were created before the last size change
    frame.zoneLine:SetFontObject("ZoneTextFont")
    frame.subZoneLine:SetFontObject("SubZoneTextFont")

    local zone = GetZoneText()
    if not zone or zone == "" then zone = "Zone Name" end

    local subZone = GetSubZoneText()
    if not subZone or subZone == "" then subZone = "Subzone Name" end

    frame.zoneLine:SetText(zone)
    frame.subZoneLine:SetText(subZone)

    if self.previewTimer then
        self.previewTimer:Cancel()
        self.previewTimer = nil
    end

    UIFrameFadeRemoveFrame(frame)
    frame:SetAlpha(1)
    frame:Show()

    self.previewTimer = C_Timer.NewTimer(duration or 3, function()
        ZoneText.previewTimer = nil
        if UIFrameFadeOut then
            UIFrameFadeOut(frame, 0.75, 1, 0)
            C_Timer.After(0.8, function() frame:Hide() end)
        else
            frame:Hide()
        end
    end)
end

function ZoneText:HidePreview()
    if self.previewTimer then
        self.previewTimer:Cancel()
        self.previewTimer = nil
    end
    if previewFrame then
        UIFrameFadeRemoveFrame(previewFrame)
        previewFrame:Hide()
    end
end

-- ------------------------------------------------------------------------------------
-- Load
-- ------------------------------------------------------------------------------------

local elvuiHooked = false

function ZoneText:Load()
    DebugPrint("Loading module")

    self:ApplyFontSizes()

    -- ElvUI owns these font objects through E:UpdateBlizzardFonts() and re-applies them
    -- on login, profile switches and any font setting change, which would silently undo
    -- our size. Re-apply after it runs.
    if not elvuiHooked and _G.ElvUI then
        local E = unpack(_G.ElvUI)
        if E and E.UpdateBlizzardFonts then
            elvuiHooked = true
            hooksecurefunc(E, "UpdateBlizzardFonts", function()
                ZoneText:ApplyFontSizes()
            end)
            DebugPrint("Hooked ElvUI UpdateBlizzardFonts")
        end
    end
end

function ZoneText:Unload()
    self:HidePreview()
    RestoreSize(_G.ZoneTextFont, "zone")
    RestoreSize(_G.SubZoneTextFont, "subzone")
end
