local _, LingkanUI = ...

LingkanUI.Install = LingkanUI.Install or {}
local Install = LingkanUI.Install

Install.Addons = Install.Addons or {}
local Addons = Install.Addons

local function MergeTable(destination, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            local destChild = destination[key]
            if type(destChild) ~= "table" then
                destChild = {}
                destination[key] = destChild
            end
            MergeTable(destChild, value)
        else
            destination[key] = value
        end
    end
end

function Addons:GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()

    if realm and realm ~= "" then
        return string.format("%s - %s", name, realm)
    end

    return name
end

-- Generic helper for addons that store profiles in an AceDB-style SavedVariables table:
--   <DB>.profileKeys["Name - Realm"] = "ProfileName"
--   <DB>.profiles["ProfileName"] = { ... }
function Addons:ApplyAceDBProfile(savedVariablesName, profileName, profileData)
    if not savedVariablesName or savedVariablesName == "" then
        return false, "Missing SavedVariables name"
    end

    local db = _G[savedVariablesName]
    if type(db) ~= "table" then
        return false, string.format("SavedVariables '%s' not loaded", tostring(savedVariablesName))
    end

    local charKey = self:GetCharacterKey()

    db.profileKeys = db.profileKeys or {}
    db.profiles = db.profiles or {}

    db.profileKeys[charKey] = profileName

    local profile = db.profiles[profileName]
    if type(profile) ~= "table" then
        profile = {}
        db.profiles[profileName] = profile
    end

    if type(profileData) == "table" then
        MergeTable(profile, profileData)
    end

    return true
end

function Addons:ApplyElvUIProfile(profileName, profileData)
    return self:ApplyAceDBProfile("ElvDB", profileName, profileData)
end

function Addons:ApplyBigWigsProfile(profileName, profileData)
    return self:ApplyAceDBProfile("BigWigs3DB", profileName, profileData)
end

-- Best-effort scaffold. If the addon uses a different SavedVariables name, change it here.
function Addons:ApplyBetterCooldownManagerProfile(profileName, profileData)
    return self:ApplyAceDBProfile("BetterCooldownManagerDB", profileName, profileData)
end
