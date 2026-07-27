local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local cache = {}

local LOGO = [[Interface\AddOns\LingkanUI\Core\Media\Textures\LogoAddon]]

function LingkanUI:InitHome()
    local parent = LingkanUI.MainFrame.Content

    LingkanUI.Widgets:CachedPanel(cache, "home", parent, function(panel)
        local iconFrame = CreateFrame("Frame", nil, panel)
        iconFrame:SetSize(200, 200)
        iconFrame:SetPoint("CENTER", 0, 40)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(LOGO)
        icon:SetAlpha(0.45)

        local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        subtitle:SetPoint("TOP", iconFrame, "BOTTOM", 0, -15)
        subtitle:SetText("Select a category on the left to begin.")
        subtitle:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b)

        local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        hint:SetPoint("TOP", subtitle, "BOTTOM", 0, -8)
        hint:SetText("/lui to toggle this window  |  /lui install for the setup wizard")
    end)
end
