local ADDON_NAME, LingkanUI = ...

-- Create the Interface module
LingkanUI.Interface = {}

-- Module name for debug output
local MODULE_NAME = "interface"

-- Module-specific debug function
local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

-- Indicator helpers (player/target health strings)
local function ResolveFontPath(fontKey)
    local fontPath = fontKey
    if not fontPath or fontPath == "" then
        fontPath = "Fonts\\FRIZQT__.TTF"
    end

    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM and fontPath then
        local mediaKey = (LSM.MediaType and LSM.MediaType.FONT) or "font"
        local fetched = LSM:Fetch(mediaKey, fontPath)
        if fetched then
            fontPath = fetched
        end
    end

    return fontPath
end

local function GetPlayerHealthbar()
    return ElvUF_Player_Healthbar
        or _G["ElvUF_Player_Healthbar"]
        or (_G["PlayerFrame"] and _G["PlayerFrame"].healthbar)
end

local function GetTargetHealthbar()
    return ElvUF_Target_Healthbar
        or _G["ElvUF_Target_Healthbar"]
        or (_G["TargetFrame"] and _G["TargetFrame"].healthbar)
end

local function ApplyFontStringStyle(fs, cfg, anchorTarget)
    if not (fs and cfg) then return end

    local fontPath = ResolveFontPath(cfg.font)
    local fontSize = cfg.fontsize or 12
    local outlineFlag = (cfg.outline and cfg.outline ~= "NONE") and cfg.outline or nil
    fs:SetFont(fontPath, fontSize, outlineFlag)

    fs:SetTextColor(1, 1, 1)
    fs:ClearAllPoints()

    local anchorFrom = cfg.anchorFrom or "TOPLEFT"
    local anchorTo = cfg.anchorTo or anchorFrom
    local x = cfg.offsetX or 0
    local y = cfg.offsetY or 0
    fs:SetPoint(anchorFrom, anchorTarget or UIParent, anchorTo, x, y)
end

local function SafeSetFormattedText(fs, fmt, ...)
    local args = { ... }
    local unpackFn = unpack or (table and table.unpack)
    return pcall(function() fs:SetFormattedText(fmt, unpackFn(args)) end)
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function SetTargetTextColor(frame, r, g, b)
    if not (frame and frame.fs) then return end
    frame._tr, frame._tg, frame._tb = r, g, b
    if not frame._colorInit then
        frame._colorInit = true
        frame.fs:SetTextColor(r, g, b)
    end
end

local function AnimateTargetTextColor(frame, elapsed)
    if not (frame and frame.fs and frame._tr) then return end
    if not frame.fs:IsShown() then return end

    local cr, cg, cb = frame.fs:GetTextColor()
    local duration = 0.15
    local t = (elapsed or 0) / duration
    if t > 1 then t = 1 end

    local nr = Lerp(cr, frame._tr, t)
    local ng = Lerp(cg, frame._tg, t)
    local nb = Lerp(cb, frame._tb, t)
    frame.fs:SetTextColor(nr, ng, nb)
end

-- Range helpers (best-effort; some APIs only work for friendly units)
local OUT_OF_RANGE_YARDS = 25
local RangeCheck = LibStub("LibRangeCheck-3.0")

local function IsUnitOutOfRange(unit)
    if not unit or not UnitExists(unit) then return false end

    -- Primary: LibRangeCheck-3.0 (works for both friend/enemy via spell/item/interact checks)
    if RangeCheck and RangeCheck.GetRange then
        local minRange, maxRange = RangeCheck:GetRange(unit)
        -- If we can estimate a minimum range beyond our threshold, it's definitely out of range.
        if minRange and minRange > OUT_OF_RANGE_YARDS then
            return true
        end
        -- Otherwise (unknown/overlapping range buckets), don't grey out.
        return false
    end

    -- Fallback: native friendly-unit range API when it provides a checked value.
    if UnitInRange then
        local inRange, checked = UnitInRange(unit)
        if checked ~= nil then
            return not inRange
        end
    end

    return false
end

local function UpdateIndicatorText(interfaceModule, frameKey, cfgKey, unit, isPercent)
    local frame = interfaceModule and interfaceModule[frameKey]
    local fs = frame and frame.fs
    if not fs then return end

    local cfg = LingkanUI.db
        and LingkanUI.db.profile
        and LingkanUI.db.profile.interface
        and LingkanUI.db.profile.interface[cfgKey]
    if not cfg then return end

    if not cfg.enabled then
        fs:Hide()
        return
    end

    if unit == "target" and not UnitExists("target") then
        fs:Hide()
        return
    end

    fs:Show()

    -- Grey out target indicators when target is out of range (best-effort).
    if unit == "target" and IsUnitOutOfRange("target") then
        SetTargetTextColor(frame, 0.6, 0.6, 0.6)
    else
        if unit == "target" then
            SetTargetTextColor(frame, 1, 1, 1)
        else
            fs:SetTextColor(1, 1, 1)
        end
    end

    local val
    if isPercent then
        val = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100) or 0
        if not SafeSetFormattedText(fs, "%d%%", val) then
            SafeSetFormattedText(fs, "%s%%", tostring(val))
        end
        return
    end

    val = UnitHealth(unit)
    if val == nil then val = 0 end

    if canaccessvalue and canaccessvalue(val) then
        if not SafeSetFormattedText(fs, "%d", val) then
            SafeSetFormattedText(fs, "%s", tostring(val))
        end
    else
        SafeSetFormattedText(fs, "%s", tostring(val))
    end
end

local function EnsureIndicatorFrame(interfaceModule, frameKey, cfgKey, unit, isPercent)
    if interfaceModule[frameKey] then return end

    local frame = CreateFrame("Frame", nil, UIParent)
    frame.fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame:SetScript("OnEvent", function()
        UpdateIndicatorText(interfaceModule, frameKey, cfgKey, unit, isPercent)
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    if unit == "target" then
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
    frame:RegisterUnitEvent("UNIT_HEALTH", unit)
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)

    -- Target range changes do not reliably trigger events; poll lightly.
    if unit == "target" then
        frame._rangeElapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
            AnimateTargetTextColor(self, elapsed)
            self._rangeElapsed = (self._rangeElapsed or 0) + (elapsed or 0)
            if self._rangeElapsed >= 0.1 then
                self._rangeElapsed = 0
                UpdateIndicatorText(interfaceModule, frameKey, cfgKey, unit, isPercent)
            end
        end)
    end

    interfaceModule[frameKey] = frame
end

--------------------------------------- Interface Settings Handler ---------------------------------------

function LingkanUI.Interface:Load()
    -- Apply settings immediately
    self:ApplyInterfaceSettings()
end

function LingkanUI.Interface:Unload()
end

function LingkanUI:InterfaceHandler()
    LingkanUI.Interface:ApplyInterfaceSettings()
end

function LingkanUI.Interface:ApplyInterfaceSettings()
    DebugPrint("Applying interface settings...")

    -- Apply UI Errors setting
    if LingkanUI.db.profile.general.interface.hideUIErrors then
        DebugPrint("Hiding UI errors")
        UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    else
        DebugPrint("Showing UI errors")
        UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
    end
    local interfaceProfile = LingkanUI.db
        and LingkanUI.db.profile
        and LingkanUI.db.profile.interface
    if not interfaceProfile then return end

    -- Ensure frames exist
    EnsureIndicatorFrame(self, "healthPercentFrame", "healthPercent", "player", true)
    EnsureIndicatorFrame(self, "healthAbsoluteFrame", "healthAbsolute", "player", false)
    EnsureIndicatorFrame(self, "targetPercentFrame", "targetPercent", "target", true)
    EnsureIndicatorFrame(self, "targetAbsoluteFrame", "targetAbsolute", "target", false)

    -- Apply font/anchor styles (player indicators anchor to player healthbar; target indicators anchor to target healthbar)
    local playerBar = GetPlayerHealthbar()
    ApplyFontStringStyle(self.healthPercentFrame and self.healthPercentFrame.fs, interfaceProfile.healthPercent, playerBar)
    ApplyFontStringStyle(self.healthAbsoluteFrame and self.healthAbsoluteFrame.fs, interfaceProfile.healthAbsolute, playerBar)

    local targetBar = GetTargetHealthbar()
    ApplyFontStringStyle(self.targetPercentFrame and self.targetPercentFrame.fs, interfaceProfile.targetPercent, targetBar)
    ApplyFontStringStyle(self.targetAbsoluteFrame and self.targetAbsoluteFrame.fs, interfaceProfile.targetAbsolute, targetBar)

    -- Force immediate updates (also handles hide/show)
    UpdateIndicatorText(self, "healthPercentFrame", "healthPercent", "player", true)
    UpdateIndicatorText(self, "healthAbsoluteFrame", "healthAbsolute", "player", false)
    UpdateIndicatorText(self, "targetPercentFrame", "targetPercent", "target", true)
    UpdateIndicatorText(self, "targetAbsoluteFrame", "targetAbsolute", "target", false)
end
