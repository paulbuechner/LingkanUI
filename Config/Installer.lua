local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

local LOGO = [[Interface\AddOns\LingkanUI\Core\Media\Textures\LogoAddon]]

-- ------------------------------------------------------------------------------------
-- Installer
-- ------------------------------------------------------------------------------------

function LingkanUI:InitInstaller()
    local parent = LingkanUI.MainFrame.Content

    W:CachedPanel(cache, "installer", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 420)

        W:CreatePageHeader(content,
            { { "INSTALLER", C.BLUE } },
            "Apply the LingkanUI profiles to your other addons.")

        W:CreateLabel(content,
            "The installer walks through ElvUI, BetterCooldownManager, BigWigs, Edit Mode " ..
            "and Details, applying the bundled 1080p or 1440p profiles.",
            { x = 14, y = -84 })

        W:CreateLabel(content,
            "ElvUI must be enabled and loaded, since the installer runs inside ElvUI's plugin installer.",
            { x = 14, y = -128, color = C.DIM })

        W:CreateButton(content, {
            label = "Run Installer",
            desc = "Opens the LingkanUI installation wizard.",
            x = 14, y = -164,
            width = 150, height = 26,
            func = function()
                local installer = LingkanUI:GetModule("Installer", true)
                if installer and installer.Show then
                    LingkanUI.MainFrame:Hide()
                    installer:Show()
                else
                    LingkanUI:Print("Installer not loaded.")
                end
            end,
        })

        W:CreateButton(content, {
            label = "Load Profiles",
            desc = "Re-applies previously installed profiles to this character.",
            x = 174, y = -164,
            width = 150, height = 26,
            func = function()
                if LingkanUI.LoadProfiles then
                    LingkanUI:LoadProfiles()
                else
                    LingkanUI:Print("Installer not loaded.")
                end
            end,
        })

        W:CreateSeparator(content, 10, -210)

        W:CreateLabel(content,
            "You can also run the installer at any time with |cff" .. C.ORANGE_HEX .. "/lui install|r.",
            { x = 14, y = -226, color = C.DIM })
    end)
end

-- ------------------------------------------------------------------------------------
-- About
-- ------------------------------------------------------------------------------------

function LingkanUI:InitAbout()
    local parent = LingkanUI.MainFrame.Content

    W:CachedPanel(cache, "about", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 420)

        W:CreatePageHeader(content,
            { { "ABOUT", C.BLUE } },
            "Version and module overview.")

        local icon = content:CreateTexture(nil, "ARTWORK")
        icon:SetSize(72, 72)
        icon:SetPoint("TOPLEFT", 14, -84)
        icon:SetTexture(LOGO)

        local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, -6)
        title:SetText(LingkanUI.TITLE)

        local version = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
        version:SetText(string.format("|cff%s%s|r  |cff%s%s|r",
            C.ORANGE_HEX, LingkanUI.versionStage or "",
            C.GRAY_HEX, LingkanUI.versionNumber or ""))

        local client = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        client:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -4)
        client:SetText(string.format("Client %s (%s)",
            tostring(LingkanUI.Version.buildText), tostring(LingkanUI.Version.interfaceVersion)))

        W:CreateSectionHeader(content, "Modules", 10, -176)

        local rows = {
            { name = "Unit Indicators", check = function()
                local i = LingkanUI.db.profile.interface
                return i.healthPercent.enabled or i.healthAbsolute.enabled
                    or i.targetPercent.enabled or i.targetAbsolute.enabled
            end },
            { name = "Character Panel", check = function() return LingkanUI.db.profile.betterCharacterPanel.enabled end },
            { name = "Role Icons",      check = function() return LingkanUI.db.profile.roleIcons.enabled end },
            { name = "Sheathing",       check = function() return LingkanUI.db.profile.sheath.enabled end },
            { name = "Leaning",         check = function() return LingkanUI.db.profile.lean.enabled end },
            { name = "Tab Target Fix",  check = function() return LingkanUI.db.profile.tabTargetArenaFix.enabled end },
        }

        local stateLabels = {}

        for index, row in ipairs(rows) do
            local y = -200 - ((index - 1) * 22)

            local label = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("TOPLEFT", 20, y)
            label:SetText(row.name)
            label:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)

            local state = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            state:SetPoint("TOPLEFT", 190, y)
            stateLabels[index] = state
        end

        -- The panel is cached, so refresh the states every time it is shown again
        local function UpdateStates()
            for index, row in ipairs(rows) do
                local ok, enabled = pcall(row.check)
                if ok and enabled then
                    stateLabels[index]:SetText("|cff" .. C.GREEN_HEX .. "Enabled|r")
                else
                    stateLabels[index]:SetText("|cff" .. C.DIM_HEX .. "Disabled|r")
                end
            end
        end

        panel:HookScript("OnShow", UpdateStates)
        UpdateStates()
    end)
end
