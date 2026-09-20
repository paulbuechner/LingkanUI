-------------------------------------------------------------------------------
--  LingkanUI -- WIM skin: Customizing/WIM/Locale.lua
--  Originally the standalone addon EllesmereSkin_WIM v1.2.0 by Laurent.
--  FR / EN strings. Kept tiny on purpose: a skin has almost no user-facing text.
-------------------------------------------------------------------------------
local _, LingkanUI = ...

-- This was a standalone addon (EllesmereSkin_WIM) before it moved in here. Its
-- files talk to each other through ns.L / ns.Theme / ns.Pixel / ns.Shell, and
-- those names are far too generic to hang off the namespace every other
-- LingkanUI module shares -- so they keep their own sub-namespace and the file
-- bodies are otherwise untouched.
LingkanUI.WIMSkin = LingkanUI.WIMSkin or {}
local ns = LingkanUI.WIMSkin

-- Retail only, which is the support matrix the standalone TOC declared
-- (Interface 120001/120005/120007). WIM runs on Classic too, but this uses
-- modern-only APIs -- BackdropTemplateMixin, the colour-table SetGradient
-- signature -- and LingkanUI itself ships for Classic Era and MoP Classic.
--
-- Repeated at the top of all five files on purpose: each is a separate chunk,
-- so there is no shared early return to inherit.
if not (LingkanUI.Version and LingkanUI.Version.isRetail) then return end
if not _G.WIM then return end

local L = {}
ns.L = L

-- enUS / default -------------------------------------------------------------
L["SKIN_TITLE"]       = "EllesmereUI"
L["SKIN_TITLE_LIGHT"] = "EllesmereUI - Light"
L["SKIN_NOTES"]       = "Pixel-perfect EllesmereUI style for WIM."
L["EUI_DETECTED"]     = "EllesmereUI detected -- using its live theme and border engine."
L["EUI_STANDALONE"]   = "EllesmereUI not found -- using built-in standalone theme."
L["APPLY_HINT"]       = "Select the '%s' skin in WIM options (/wim -> Skin).";

-- frFR -----------------------------------------------------------------------
if GetLocale() == "frFR" then
    L["SKIN_NOTES"]     = "Style EllesmereUI pixel-perfect pour WIM."
    L["EUI_DETECTED"]   = "EllesmereUI detecte -- utilisation de son theme et de son moteur de bordures."
    L["EUI_STANDALONE"] = "EllesmereUI introuvable -- utilisation du theme autonome integre."
    L["APPLY_HINT"]     = "Selectionnez le skin '%s' dans les options de WIM (/wim -> Skin).";
end

-- Fall back to the key itself for anything missing, so a typo shows up as the
-- key rather than a nil concat error.
setmetatable(L, { __index = function(_, k) return k end })
