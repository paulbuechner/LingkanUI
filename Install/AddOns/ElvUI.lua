local _, LingkanUI = ...

LingkanUI.Install = LingkanUI.Install or {}
local Install = LingkanUI.Install

Install.Addons = Install.Addons or {}
local Addons = Install.Addons

local function DecodeAndImport(DI, encoded, profileName)
    local profileType, _, data = DI:Decode(encoded)
    if not data or type(data) ~= "table" then
        return false, "ElvUI decode failed"
    end

    DI:SetImportedProfile(profileType, profileName, data, true)
    return true
end

local function ExtractElvUIExportParts(profileData)
    if type(profileData) == "string" then
        return profileData, nil, nil, nil, nil
    end

    if type(profileData) == "table" then
        -- Order: 1) profile 2) private 3) global 4) aura 5) uiScale (optional)
        return profileData[1], profileData[2], profileData[3], profileData[4], profileData[5]
    end

    return nil, nil, nil, nil, nil
end

function Addons:ApplyElvUIProfile(profileName, profileData)
    local profileExport, privateExport, globalExport, aurasExport, uiScale = ExtractElvUIExportParts(profileData)

    if type(profileExport) == "string" and profileExport ~= "" then
        local E = unpack(_G.ElvUI)
        local DI = E.Distributor

        local ok, err = DecodeAndImport(DI, profileExport, profileName)
        if not ok then
            return false, err
        end

        if type(privateExport) == "string" and privateExport ~= "" then
            ok, err = DecodeAndImport(DI, privateExport, profileName)
            if not ok then
                return false, err
            end
        end

        if type(globalExport) == "string" and globalExport ~= "" then
            ok, err = DecodeAndImport(DI, globalExport, profileName)
            if not ok then
                return false, err
            end
        end

        if type(aurasExport) == "string" and aurasExport ~= "" then
            ok, err = DecodeAndImport(DI, aurasExport, profileName)
            if not ok then
                return false, err
            end
        end

        E:SetupCVars(true)
        if uiScale then
            E.data.global.general.UIScale = uiScale
        end

        return true
    end

    -- If it's not an ElvUI export string (or string list), treat it as AceDB table profile.
    return self:ApplyAceDBProfile("ElvDB", profileName, profileData)
end
