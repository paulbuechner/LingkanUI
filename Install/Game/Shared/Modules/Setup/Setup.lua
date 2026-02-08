local LUI = unpack(LUI)
local SE = LUI:GetModule("Setup")

function SE:Setup(addon, ...)
    local setup = self[addon]

    setup(addon, ...)
end

function SE.CompleteSetup(addon)
    local PluginInstallStepComplete = PluginInstallStepComplete

    if PluginInstallStepComplete then
        if PluginInstallStepComplete:IsShown() then
            PluginInstallStepComplete:Hide()
        end

        PluginInstallStepComplete.message = "Success"

        PluginInstallStepComplete:Show()
    end

    if not LUI.db.global.profiles then
        LUI.db.global.profiles = {}
    end

    LUI.db.global.profiles[addon] = true
end

function SE.IsProfileExisting(table)
    local db = LibStub("AceDB-3.0"):New(table)
    local profiles = db:GetProfiles()

    for i = 1, #profiles do
        if profiles[i] == "LingkanUI" then
            return true
        end
    end
end

function SE.RemoveFromDatabase(addon)
    LUI.db.global.profiles[addon] = nil

    if LUI.db.global.profiles and #LUI.db.global.profiles == 0 then
        for k in pairs(LUI.db.char) do
            k = nil
        end

        LUI.db.global.profiles = nil
    end
end
