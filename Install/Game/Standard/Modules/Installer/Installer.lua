local LUI = unpack(LUI)

if not LUI.Retail then
    return
end

local I = LUI:GetModule("Installer")
local SE = LUI:GetModule("Setup")

I.installer = {
    Title = format("%s %s", LUI.title, "Installation"),
    Name = LUI.title,
    tutorialImage = "Interface\\AddOns\\LingkanUI\\Core\\Media\\Textures\\LogoTop.tga",
    Pages = {
        [1] = function()
            PluginInstallFrame.SubTitle:SetFormattedText("Welcome to %s", LUI.title)

            if not (LUI.db and LUI.db.global and LUI.db.global.profiles) then
                PluginInstallFrame.Desc1:SetText("To start the installation process, click on 'Continue'")

                return
            end

            PluginInstallFrame.Desc1:SetText("To load your installed profiles onto this character, click on 'Load Profiles'")
            PluginInstallFrame.Desc3:SetText("To start the installation process again, click on 'Continue'")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() LUI:LoadProfiles() end)
            PluginInstallFrame.Option1:SetText("Load Profiles")
        end,
        [2] = function()
            PluginInstallFrame.SubTitle:SetText("ElvUI")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("ElvUI", true, "1080p") end)
            PluginInstallFrame.Option1:SetText("1080p")
            PluginInstallFrame.Option2:Show()
            PluginInstallFrame.Option2:SetScript("OnClick", function() SE:Setup("ElvUI", true, "1440p") end)
            PluginInstallFrame.Option2:SetText("1440p")
        end,
        [3] = function()
            PluginInstallFrame.SubTitle:SetText("BetterCooldownManager")

            if not LUI:IsAddOnEnabled("BetterCooldownManager") then
                PluginInstallFrame.Desc1:SetText("Enable BetterCooldownManager to unlock this step")

                return
            end

            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("BetterCooldownManager", true, "1080p") end)
            PluginInstallFrame.Option1:SetText("1080p")
            PluginInstallFrame.Option2:Show()
            PluginInstallFrame.Option2:SetScript("OnClick", function() SE:Setup("BetterCooldownManager", true, "1440p") end)
            PluginInstallFrame.Option2:SetText("1440p")
        end,
        [4] = function()
            PluginInstallFrame.SubTitle:SetText("BigWigs")

            if not LUI:IsAddOnEnabled("BigWigs") then
                PluginInstallFrame.Desc1:SetText("Enable BigWigs to unlock this step")

                return
            end

            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("BigWigs", true, "1080p") end)
            PluginInstallFrame.Option1:SetText("1080p")
            PluginInstallFrame.Option2:Show()
            PluginInstallFrame.Option2:SetScript("OnClick", function() SE:Setup("BigWigs", true, "1440p") end)
            PluginInstallFrame.Option2:SetText("1440p")
        end,
        [5] = function()
            PluginInstallFrame.SubTitle:SetText("Blizzard_EditMode")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("Blizzard_EditMode", true, "1080p") end)
            PluginInstallFrame.Option1:SetText("1080p")
            PluginInstallFrame.Option2:Show()
            PluginInstallFrame.Option2:SetScript("OnClick", function() SE:Setup("Blizzard_EditMode", true, "1440p") end)
            PluginInstallFrame.Option2:SetText("1440p")
        end,
        [6] = function()
            PluginInstallFrame.SubTitle:SetText("Details")

            if not LUI:IsAddOnEnabled("Details") then
                PluginInstallFrame.Desc1:SetText("Enable Details to unlock this step")

                return
            end

            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() SE:Setup("Details", true, "1080p") end)
            PluginInstallFrame.Option1:SetText("1080p")
            PluginInstallFrame.Option2:Show()
            PluginInstallFrame.Option2:SetScript("OnClick", function() SE:Setup("Details", true, "1440p") end)
            PluginInstallFrame.Option2:SetText("1440p")
        end,
        [7] = function()
            PluginInstallFrame.SubTitle:SetText("Installation Complete")
            PluginInstallFrame.Desc1:SetText("You have completed the installation process")
            PluginInstallFrame.Desc2:SetText("Please click on 'Reload' to save your settings and reload your UI")
            PluginInstallFrame.Option1:Show()
            PluginInstallFrame.Option1:SetScript("OnClick", function() ReloadUI() end)
            PluginInstallFrame.Option1:SetText("Reload")
        end
    },
    StepTitles = {
        [1] = "Welcome",
        [2] = "ElvUI",
        [3] = "BetterCooldownManager",
        [4] = "BigWigs",
        [5] = "Blizzard_EditMode",
        [6] = "Details",
        [7] = "Installation Complete"
    },
    StepTitlesColor = { 1, 1, 1 },
    StepTitlesColorSelected = { 0, 179 / 255, 1 },
    StepTitleWidth = 200,
    StepTitleButtonWidth = 180,
    StepTitleTextJustification = "RIGHT"
}
