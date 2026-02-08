local LUI = unpack(LUI)

function LUI.SetFrameStrata(frame, strata)
    frame:SetFrameStrata(strata)
end

function LUI:RunInstaller()
    local I = LUI:GetModule("Installer")
    local E, PI

    if InCombatLockdown() then
        return
    end

    -- Respect LingkanUI's rule: never auto-load external addons.
    if not LUI:IsAddOnEnabled("ElvUI") then
        LUI:Print("ElvUI is required for the installer. Enable ElvUI and try again.")
        return
    end

    if LUI.API and LUI.API.IsAddOnLoaded and not LUI.API:IsAddOnLoaded("ElvUI") then
        LUI:Print("ElvUI is enabled but not loaded. Log in with ElvUI loaded and try again.")
        return
    end

    E = unpack(ElvUI)
    PI = E:GetModule("PluginInstaller")
    PI:Queue(I.installer)
end

function LUI:LoadProfiles()
    local SE = LUI:GetModule("Setup")

    if not (self.db and self.db.global and self.db.global.profiles) then
        self:Print("No installed profiles found.")
        return
    end

    for k in pairs(self.db.global.profiles) do
        if self:IsAddOnEnabled(k) then
            SE:Setup(k)
        end
    end

    self.db.char.loaded = true
    ReloadUI()
end
