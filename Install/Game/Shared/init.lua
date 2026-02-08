-- Installer bootstrap (NaowhUI-style) rebound for LingkanUI.
-- Exposes a global engine table `LUI` so existing `unpack(LUI)` patterns work,
-- but attaches modules to the existing LingkanUI addon object.

local _G = _G

local C_AddOns_GetAddOnEnableState = C_AddOns and C_AddOns.GetAddOnEnableState
local GetAddOnEnableState = _G.GetAddOnEnableState

local _, Engine = ...
local LUI = Engine -- This is the LingkanUI addon object (created in LingkanUI.lua)

-- Provide a stable global "engine" key that won't collide with NaowhUI.
_G.LUI = _G.LUI or {}
_G.LUI[1] = LUI

-- Modules used by the installer system
LUI.Data = LUI.Data or LUI:NewModule("Data")
LUI.Installer = LUI.Installer or LUI:NewModule("Installer")
LUI.Setup = LUI.Setup or LUI:NewModule("Setup", "AceHook-3.0")

-- Flavor flags
LUI.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
LUI.Mists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
LUI.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
LUI.Vanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

function LUI:GetAddOnEnableState(addon, character)
    if C_AddOns_GetAddOnEnableState then
        return C_AddOns_GetAddOnEnableState(addon, character)
    end
    if GetAddOnEnableState then
        return GetAddOnEnableState(addon, character)
    end
end

function LUI:IsAddOnEnabled(addon)
    if LUI.API and LUI.API.IsAddOnEnabled then
        return LUI.API:IsAddOnEnabled(addon, LUI.myname) == true
    end
    return LUI:GetAddOnEnableState(addon, LUI.myname) == 2
end

-- `/lui install` expects this entrypoint.
function LUI.Installer:Show()
    if LUI.RunInstaller then
        return LUI:RunInstaller()
    end
end
