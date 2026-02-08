local _, LingkanUI = ...

-- Version / build detection consolidated here
local build, buildText, buildDate, interface = GetBuildInfo()

local versionUtil = {}

-- Properties (set during Init)
versionUtil.interfaceVersion = interface
versionUtil.build = build
versionUtil.buildText = buildText
versionUtil.buildDate = buildDate
versionUtil.isRetail = false
versionUtil.isClassicEra = false
versionUtil.isMop = false
versionUtil.isRemix = false

-- Centralized installer/client flavor mapping
-- Keys are used by installer packs (Install/Profiles.lua)
versionUtil.FLAVOR_ORDER = { "Retail", "Mists", "Wrath", "TBC", "ClassicEra" }

-- Remix detection (buff spellID 1213439 present on player)
local REMIX_SPELL_ID = 1213439
local function checkRemixStatus()
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(REMIX_SPELL_ID)
        return aura ~= nil
    end
    return false
end

function versionUtil:Init()
    -- Initialize static version flags
    self.isRetail = interface >= 110000
    self.isClassicEra = interface < 40000
    self.isMop = interface >= 50000 and interface < 60000
    self.isRemix = checkRemixStatus()

    -- print("LingkanUI Version Info: ")
    -- print(" Build: " .. tostring(self.build) .. " (" .. tostring(self.buildText) .. ")")
    -- print(" Build Date: " .. tostring(self.buildDate))
    -- print(" Interface Version: " .. tostring(self.interfaceVersion))
    -- print(" isRetail: " .. tostring(self.isRetail))
    -- print(" isClassicEra: " .. tostring(self.isClassicEra))
    -- print(" isMoP: " .. tostring(self.isMop))
    -- print(" isRemix: " .. tostring(self.isRemix))
end

-- Returns a stable flavor key used by installer packs.
-- This is safe to call before :Init() (uses interfaceVersion from GetBuildInfo()).
function versionUtil:GetFlavorKey()
    local interfaceVersion = self.interfaceVersion or select(4, GetBuildInfo()) or 0

    if interfaceVersion >= 110000 then
        return "Retail"
    end

    if interfaceVersion >= 50000 and interfaceVersion < 60000 then
        return "Mists"
    end

    if interfaceVersion >= 30000 and interfaceVersion < 40000 then
        return "Wrath"
    end

    if interfaceVersion >= 20000 and interfaceVersion < 30000 then
        return "TBC"
    end

    return "ClassicEra"
end

-- Optional convenience: expansion bucket by interface major (approximate)
local expansionByInterface = {
    [100000] = "Dragonflight+",
    [90005] = "Shadowlands",
    [80000] = "BfA",
}

function versionUtil:GetExpansionHint()
    -- Find closest lower/equal key
    local best
    for k, _ in pairs(expansionByInterface) do
        if interface >= k then
            if not best or k > best then best = k end
        end
    end
    return best and expansionByInterface[best] or "Unknown"
end

LingkanUI.Version = versionUtil
