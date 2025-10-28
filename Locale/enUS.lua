-- enUS English
local _, LingkanUI = ...

function LingkanUI:UpdateLanguageTab(tab)
    for i, v in pairs(tab) do
        LingkanUI:GetLangTab()[i] = v
    end
end

function LingkanUI:LangenUS()
    local tab = {
        -- BetterCharacterPanel
        ["LID_ENCH_STAMINA"] = "Stamina",
        ["LID_ENCH_INTELLECT"] = "Intellect",
        ["LID_ENCH_AGILITY"] = "Agility",
        ["LID_ENCH_STRENGTH"] = "Strength",
        ["LID_ENCH_MASTERY"] = "Mastery",
        ["LID_ENCH_VERSATILITY"] = "Versatility",
        ["LID_ENCH_CRITICAL_STRIKE"] = "Critical Strike",
        ["LID_ENCH_HASTE"] = "Haste",
        ["LID_ENCH_AVOIDANCE"] = "Avoidance",
        ["LID_ENCH_MINOR_SPEED_INCREASE"] = "Minor Speed Increase",
        ["LID_ENCH_HOMEBOUND_SPEED"] = "Homebound Speed",
        ["LID_ENCH_PLAINSRUNNERS_BREEZE"] = "Plainsrunner's Breeze",
        ["LID_ENCH_GRACEFUL_AVOID"] = "Graceful Avoid",
        ["LID_ENCH_REGENERATIVE_LEECH"] = "Regenerative Leech",
        ["LID_ENCH_WATCHERS_LOAM"] = "Watcher's Loam",
        ["LID_ENCH_RIDERS_REASSURANCE"] = "Rider's Reassurance",
        ["LID_ENCH_ACCELERATED_AGILITY"] = "Accelerated Agility",
        ["LID_ENCH_RESERVE_OF_INT"] = "Reserve of Int",
        ["LID_ENCH_SUSTAINED_STR"] = "Sustained Str",
        ["LID_ENCH_WAKING_STATS"] = "Waking Stats",
        ["LID_ENCH_CAVALRYS_MARCH"] = "Cavalry's March",
        ["LID_ENCH_SCOUTS_MARCH"] = "Scout's March",
        ["LID_ENCH_DEFENDERS_MARCH"] = "Defender's March",
        ["LID_ENCH_STORMRIDERS_AGI"] = "Stormrider's Agi",
        ["LID_ENCH_COUNCILS_INTELLECT"] = "Council's Intellect",
        ["LID_ENCH_SUNSET_SPELLTHREAD"] = "+930 Intellect and +895 Stamina",
        ["LID_ENCH_CRYSTALLINE_RADIANCE"] = "Crystalline Radiance",
        ["LID_ENCH_OATHSWORNS_STRENGTH"] = "Oathsworn's Strength",
        ["LID_ENCH_CHANT_ARMORED_AVOID"] = "Chant of Armored Avoid",
        ["LID_ENCH_CHANT_ARMORED_LEECH"] = "Chant of Armored Leech",
        ["LID_ENCH_CHANT_ARMORED_SPEED"] = "Chant of Armored Speed",
        ["LID_ENCH_CHANT_WINGED_GRACE"] = "Chant of Winged Grace",
        ["LID_ENCH_CHANT_LEECHING_FANGS"] = "Chant of Leeching Fangs",
        ["LID_ENCH_CHANT_BURROWING_RAPIDITY"] = "Chant of Burrowing Rapidity",
        ["LID_ENCH_CURSED_HASTE"] = "Cursed Haste",
        ["LID_ENCH_CURSED_CRIT"] = "Cursed Crit",
        ["LID_ENCH_CURSED_MASTERY"] = "Cursed Mastery",
        ["LID_ENCH_CURSED_VERSATILITY"] = "Cursed Versatility",
        ["LID_ENCH_SHADOWED_BELT_CLASP"] = "Shadowed Belt Clasp",
        ["LID_ENCH_INCANDESCENT_ESSENCE"] = "Incandescent Essence",
        -- Weapon enchants
        ["LID_ENCH_AUTHORITY_OF_RADIANT_POWER"] = "Authority of Radiant Power",
        -- Generic fragments (MoP / legacy tooltip parsing)
        ["LID_ENCH_RATING_UPPER"] = "Rating",
        ["LID_ENCH_RATING_LOWER"] = "rating",
        ["LID_ENCH_MINOR"] = "Minor",
        ["LID_ENCH_MOVEMENT"] = "Movement",
        ["LID_ENCH_AND_SPACED"] = " and ",
    }

    LingkanUI:UpdateLanguageTab(tab)
end
