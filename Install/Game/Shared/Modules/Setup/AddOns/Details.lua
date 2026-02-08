local LUI = unpack(LUI)
local SE = LUI:GetModule("Setup")

function SE.Details(addon, import, resolution)
    local D = LUI:GetModule("Data")

    local data, decompressedData
    local profile = "details" .. (resolution or "")
    local Details = Details

    if import then
        data = DetailsFramework:Trim(D[profile])
        decompressedData = Details:DecompressData(data, "print")

        Details:EraseProfile("LingkanUI")
        Details:ImportProfile(D[profile], "LingkanUI", false, false, true)

        for i, v in Details:ListInstances() do
            DetailsFramework.table.copy(v.hide_on_context, decompressedData.profile.instances[i].hide_on_context)
        end

        SE.CompleteSetup(addon)

        LUI.db.char.loaded = true
        LUI.db.global.version = LUI.version
    else
        if not Details:GetProfile("LingkanUI") then
            SE.RemoveFromDatabase(addon)

            return
        end

        Details:ApplyProfile("LingkanUI")
    end
end
