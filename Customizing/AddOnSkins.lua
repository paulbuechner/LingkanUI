local _, LingkanUI = ...

LingkanUI.Customizing = LingkanUI.Customizing or {}

-- AddOnSkins (no longer maintained) breaks LibDBIcon's shared minimap-button tooltip
-- (LibDBIconTooltip) when running alongside ElvUI:
--   1. Its Libraries skin runs S:HandleTooltip -> HandleBlizzardRegions, whose strip
--      list contains 'Center'. On this tooltip, frame.Center is the BackdropTemplate
--      background texture created by ElvUI's styling - hiding it makes the tooltip
--      permanently transparent, since Blizzard's ApplyBackdrop never re-shows
--      existing backdrop pieces.
--   2. Its OnShow hook re-applies the AddOnSkins template on every show, overriding
--      ElvUI's tooltip style.
-- Re-apply ElvUI's style one frame after each show (after AddOnSkins' hook has run)
-- and re-show the hidden Center texture.
function LingkanUI.Customizing.LoadAddOnSkins()
    if LingkanUI.Customizing._libDBIconTooltipHooked then return end

    local tooltip = _G.LibDBIconTooltip
    local E = _G.ElvUI and unpack(_G.ElvUI)
    if not (_G.AddOnSkins and E and tooltip) then return end

    local TT = E:GetModule("Tooltip", true)
    if not (TT and TT.SetStyle) then return end

    LingkanUI.Customizing._libDBIconTooltipHooked = true

    tooltip:HookScript("OnShow", function(tt)
        C_Timer.After(0, function()
            if not tt:IsShown() or tt:IsForbidden() then return end
            pcall(TT.SetStyle, TT, tt)
            if tt.Center and not tt.Center:IsShown() then tt.Center:Show() end
        end)
    end)
end
