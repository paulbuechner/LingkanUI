local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS

LingkanUI.MinimapButton = {}
local MinimapButton = LingkanUI.MinimapButton

local ICON = [[Interface\AddOns\LingkanUI\Core\Media\Textures\LogoAddon]]

-- Called from LingkanUI:OnInitialize once the database exists
function MinimapButton:Init()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local DBIcon = LibStub("LibDBIcon-1.0", true)
    if not (LDB and DBIcon) then return end

    if self.dataObject then return end

    self.dataObject = LDB:NewDataObject(ADDON_NAME, {
        type = "launcher",
        text = "LingkanUI",
        icon = ICON,
        OnClick = function(_, button)
            if button == "RightButton" then
                if LingkanUI.OpenTab then LingkanUI:OpenTab("general") end
                if not LingkanUI.MainFrame:IsShown() then
                    LingkanUI:ToggleConfig()
                end
            else
                LingkanUI:ToggleConfig()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(LingkanUI.TITLE)
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine("Left Click", "Toggle configuration",
                C.GRAY.r, C.GRAY.g, C.GRAY.b, 1, 1, 1)
            tooltip:AddDoubleLine("Right Click", "Open General settings",
                C.GRAY.r, C.GRAY.g, C.GRAY.b, 1, 1, 1)
        end,
    })

    -- LibDBIcon owns this table and writes minimapPos/hide into it
    DBIcon:Register(ADDON_NAME, self.dataObject, LingkanUI.db.profile.minimap)
    self.icon = DBIcon
end

function MinimapButton:SetShown(shown)
    if not self.icon then return end

    LingkanUI.db.profile.minimap.hide = not shown
    if shown then
        self.icon:Show(ADDON_NAME)
    else
        self.icon:Hide(ADDON_NAME)
    end
end
