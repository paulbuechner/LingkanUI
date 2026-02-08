local LUI = unpack(LUI)
local SE = LUI:GetModule("Setup")

local function ImportBigWigs(addon, resolution)
    local D = LUI:GetModule("Data")

    local profile = "bigwigs" .. (resolution or "")

    BigWigsAPI.RegisterProfile(LUI.title, D[profile], "LingkanUI", function(callback)
        if not callback then
            return
        end

        SE.CompleteSetup(addon)

        LUI.db.char.loaded = true
        LUI.db.global.version = LUI.version
    end)
end

function SE.BigWigs(addon, import, resolution)
    local BigWigs3DB = BigWigs3DB
    local db

    if import then
        ImportBigWigs(addon, resolution)
    else
        if not SE.IsProfileExisting(BigWigs3DB) then
            SE.RemoveFromDatabase(addon)

            return
        end

        db = LibStub("AceDB-3.0"):New(BigWigs3DB)

        db:SetProfile("LingkanUI")
    end
end
