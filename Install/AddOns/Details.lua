local _, LingkanUI = ...

LingkanUI.Install = LingkanUI.Install or {}
local Install = LingkanUI.Install

Install.Addons = Install.Addons or {}
local Addons = Install.Addons

local function NormalizeProfileData(data)
    if type(data) == "table" and type(data[1]) == "string" and data[1] ~= "" and next(data, 1) == nil then
        return data[1]
    end
    return data
end

function Addons:ApplyDetailsProfile(profileName, profileData)
    local encoded = NormalizeProfileData(profileData)

    if type(encoded) == "string" and encoded ~= "" then
        local data = DetailsFramework:Trim(encoded)
        local decompressedData = Details:DecompressData(data, "print")

        Details:EraseProfile(profileName)
        Details:ImportProfile(encoded, profileName, false, false, true)

        for i, v in Details:ListInstances() do
            DetailsFramework.table.copy(v.hide_on_context, decompressedData.profile.instances[i].hide_on_context)
        end

        return true
    end

    if Details:GetProfile(profileName) then
        Details:ApplyProfile(profileName)
        return true
    end

    return false, "Details profile missing"
end
