local _, LingkanUI = ...

-- Version / build detection consolidated here
local build, buildText, buildDate, interface = GetBuildInfo()

local versionUtil = {}

function versionUtil:GetInterfaceVersion()
    return interface
end

function versionUtil:GetBuild()
    return build, buildText, buildDate
end

function versionUtil:IsRetail()
    return interface >= 110000
end

function versionUtil:IsClassicEra()
    return interface < 40000
end

function versionUtil:IsMop()
    return interface >= 50000 and interface < 60000
end

-- Remix detection (buff spellID 1232454 present on player)
local REMIX_SPELL_ID = 1232454
function versionUtil:IsRemix()
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(REMIX_SPELL_ID)
        return aura ~= nil
    end
    return false
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
