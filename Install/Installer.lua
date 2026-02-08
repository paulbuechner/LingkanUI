local ADDON_NAME, LingkanUI = ...

LingkanUI.Installer = LingkanUI.Installer or {}

function LingkanUI.Installer:DetectFlavorKey()
    return LingkanUI.Version:GetFlavorKey()
end

function LingkanUI.Installer:GetFlavorOptions()
    return LingkanUI.Install:GetPackOptions()
end

function LingkanUI.Installer:ApplyFlavor(flavorKey)
    return LingkanUI.Install:ApplyPack(flavorKey)
end

function LingkanUI.Installer:ApplyFlavorNoSteps(flavorKey)
    return LingkanUI.Install:ApplyPack(flavorKey, { runSteps = false })
end

local function EnsureReloadPopup()
    if StaticPopupDialogs["LINGKANUI_INSTALL_RELOAD"] then
        return
    end

    StaticPopupDialogs["LINGKANUI_INSTALL_RELOAD"] = {
        text = "LingkanUI installation applied. Reload UI now?",
        button1 = _G.RELOADUI or "Reload UI",
        button2 = _G.CANCEL or "Later",
        OnAccept = function()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function LingkanUI.Installer:ShowElvUIInstaller()
    if InCombatLockdown() then
        return false, "Cannot run installer in combat"
    end

    if not LingkanUI.API:IsAddOnLoaded("ElvUI") then
        return false, "ElvUI not loaded"
    end

    local E = unpack(_G.ElvUI)
    local PI = E:GetModule("PluginInstaller")

    if not self.elvInstaller then
        local headerImage = "Interface\\AddOns\\LingkanUI\\Artwork\\WyvernLeft.tga"

        self.elvInstaller = {
            Title = "LingkanUI Installation",
            Name = "LingkanUI",
            tutorialImage = headerImage,
            StepTitles = {
                "Welcome",
                "ElvUI",
                "BetterCooldownManager",
                "BigWigs",
                "Details",
                "Installation Complete",
            },
            Pages = {
                [1] = function()
                    PluginInstallFrame.SubTitle:SetText("Welcome to LingkanUI")
                    PluginInstallFrame.Desc1:SetText("Click 'Install' to apply the LingkanUI pack for your client.")
                    PluginInstallFrame.Desc2:SetText("Addon profiles are applied step-by-step in the next pages.")

                    PluginInstallFrame.Option1:Show()
                    PluginInstallFrame.Option1:SetText("Install")
                    PluginInstallFrame.Option1:SetScript("OnClick", function()
                        local ok, err = self:ApplyFlavorNoSteps(self:DetectFlavorKey())
                        if not ok then
                            LingkanUI:Print("Install failed: " .. tostring(err))
                            return
                        end
                        EnsureReloadPopup()
                        StaticPopup_Show("LINGKANUI_INSTALL_RELOAD")
                    end)
                end,
                [2] = function()
                    PluginInstallFrame.SubTitle:SetText("ElvUI")
                    if not LingkanUI.API:IsAddOnEnabled("ElvUI") then
                        PluginInstallFrame.Desc1:SetText("Enable ElvUI to unlock this step")
                        PluginInstallFrame.Option1:Hide()
                        return
                    end

                    PluginInstallFrame.Desc1:SetText("Click 'Apply Profile' to install the ElvUI profile.")
                    PluginInstallFrame.Option1:Show()
                    PluginInstallFrame.Option1:SetText("Apply Profile")
                    PluginInstallFrame.Option1:SetScript("OnClick", function()
                        local ok, err = LingkanUI.Install:ApplyAddonProfile(self:DetectFlavorKey(), "ElvUI")
                        if not ok then
                            LingkanUI:Print("ElvUI profile failed: " .. tostring(err))
                            return
                        end
                        EnsureReloadPopup()
                        StaticPopup_Show("LINGKANUI_INSTALL_RELOAD")
                    end)
                end,
                [3] = function()
                    PluginInstallFrame.SubTitle:SetText("BetterCooldownManager")
                    if not LingkanUI.API:IsAddOnEnabled("BetterCooldownManager") then
                        PluginInstallFrame.Desc1:SetText("Enable BetterCooldownManager to unlock this step")
                        PluginInstallFrame.Option1:Hide()
                        return
                    end

                    PluginInstallFrame.Desc1:SetText("Click 'Apply Profile' to install the BetterCooldownManager profile.")
                    PluginInstallFrame.Option1:Show()
                    PluginInstallFrame.Option1:SetText("Apply Profile")
                    PluginInstallFrame.Option1:SetScript("OnClick", function()
                        local ok, err = LingkanUI.Install:ApplyAddonProfile(self:DetectFlavorKey(), "BetterCooldownManager")
                        if not ok then
                            LingkanUI:Print("BetterCooldownManager profile failed: " .. tostring(err))
                            return
                        end
                        EnsureReloadPopup()
                        StaticPopup_Show("LINGKANUI_INSTALL_RELOAD")
                    end)
                end,
                [4] = function()
                    PluginInstallFrame.SubTitle:SetText("BigWigs")
                    if not LingkanUI.API:IsAddOnEnabled("BigWigs") then
                        PluginInstallFrame.Desc1:SetText("Enable BigWigs to unlock this step")
                        PluginInstallFrame.Option1:Hide()
                        return
                    end

                    PluginInstallFrame.Desc1:SetText("Click 'Apply Profile' to install the BigWigs profile.")
                    PluginInstallFrame.Option1:Show()
                    PluginInstallFrame.Option1:SetText("Apply Profile")
                    PluginInstallFrame.Option1:SetScript("OnClick", function()
                        local ok, err = LingkanUI.Install:ApplyAddonProfile(self:DetectFlavorKey(), "BigWigs")
                        if not ok then
                            LingkanUI:Print("BigWigs profile failed: " .. tostring(err))
                            return
                        end
                        EnsureReloadPopup()
                        StaticPopup_Show("LINGKANUI_INSTALL_RELOAD")
                    end)
                end,
                [5] = function()
                    PluginInstallFrame.SubTitle:SetText("Details")
                    if not LingkanUI.API:IsAddOnEnabled("Details") then
                        PluginInstallFrame.Desc1:SetText("Enable Details to unlock this step")
                        PluginInstallFrame.Option1:Hide()
                        return
                    end

                    PluginInstallFrame.Desc1:SetText("Click 'Apply Profile' to install the Details profile.")
                    PluginInstallFrame.Option1:Show()
                    PluginInstallFrame.Option1:SetText("Apply Profile")
                    PluginInstallFrame.Option1:SetScript("OnClick", function()
                        local ok, err = LingkanUI.Install:ApplyAddonProfile(self:DetectFlavorKey(), "Details")
                        if not ok then
                            LingkanUI:Print("Details profile failed: " .. tostring(err))
                            return
                        end
                        EnsureReloadPopup()
                        StaticPopup_Show("LINGKANUI_INSTALL_RELOAD")
                    end)
                end,
                [6] = function()
                    PluginInstallFrame.SubTitle:SetText("Installation Complete")
                    PluginInstallFrame.Desc1:SetText("Click 'Reload UI' to complete installation.")

                    PluginInstallFrame.Option1:Show()
                    PluginInstallFrame.Option1:SetText(_G.RELOADUI or "Reload UI")
                    PluginInstallFrame.Option1:SetScript("OnClick", function()
                        ReloadUI()
                    end)
                end,
            },
        }
    end

    -- Re-queue each time to ensure the installer opens and is on top
    PI:Queue(self.elvInstaller)
    return true
end

function LingkanUI.Installer:Show()
    local ok, err = self:ShowElvUIInstaller()
    if ok then
        return
    end

    LingkanUI:Print("ElvUI is required for the installer." .. (err and (" (" .. tostring(err) .. ")") or "") .. " Enable ElvUI and run /lui install again.")
end
