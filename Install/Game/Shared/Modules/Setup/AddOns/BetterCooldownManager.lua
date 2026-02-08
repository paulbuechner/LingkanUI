local LUI = unpack(LUI)
local SE = LUI:GetModule("Setup")

function SE.BetterCooldownManager(addon, import, resolution)
    local D = LUI:GetModule("Data")

    local profile = "bettercooldownmanager" .. (resolution or "")
    local BCDMDB = BCDMDB
    local db

    if import then
        BCDMG:ImportBCDM(D[profile], "LingkanUI")

        SE.CompleteSetup(addon)

        LUI.db.char.loaded = true
        LUI.db.global.version = LUI.version

        return
    end

    if not SE.IsProfileExisting(BCDMDB) then
        SE.RemoveFromDatabase(addon)

        return
    end

    db = LibStub("AceDB-3.0"):New(BCDMDB)

    db:SetProfile("LingkanUI")
end
