-- deDE German Deutsch
local _, LingkanUI = ...

function LingkanUI:LangdeDE()
    local tab = {
        -- BetterCharacterPanel
        ["LID_ENCH_STAMINA"] = "Ausdauer",
        ["LID_ENCH_INTELLECT"] = "Intelligenz",
        ["LID_ENCH_AGILITY"] = "Beweglichkeit",
        ["LID_ENCH_STRENGTH"] = "Stärke",
        ["LID_ENCH_MASTERY"] = "Meisterschaft",
        ["LID_ENCH_VERSATILITY"] = "Vielseitigkeit",
        ["LID_ENCH_CRITICAL_STRIKE"] = "Kritischer Treffer",
        ["LID_ENCH_HASTE"] = "Tempo",
        ["LID_ENCH_AVOIDANCE"] = "Vermeidung",
        ["LID_ENCH_MINOR_SPEED_INCREASE"] = "Geringe Tempoerhöhung",
        ["LID_ENCH_HOMEBOUND_SPEED"] = "Heimkehrtempo",
        ["LID_ENCH_PLAINSRUNNERS_BREEZE"] = "Ebenerläuferbrise",
        ["LID_ENCH_GRACEFUL_AVOID"] = "Anmutige Vermeidung",
        ["LID_ENCH_REGENERATIVE_LEECH"] = "Regenerativer Blutungseffekt",
        ["LID_ENCH_WATCHERS_LOAM"] = "Lehm des Wächters",
        ["LID_ENCH_RIDERS_REASSURANCE"] = "Versicherung des Reiters",
        ["LID_ENCH_ACCELERATED_AGILITY"] = "Beschleunigte Beweglichkeit",
        ["LID_ENCH_RESERVE_OF_INT"] = "Int-Reserve",
        ["LID_ENCH_SUSTAINED_STR"] = "Anhaltende Stärke",
        ["LID_ENCH_WAKING_STATS"] = "Erwachende Werte",
        ["LID_ENCH_CAVALRYS_MARCH"] = "Marsch der Kavallerie",
        ["LID_ENCH_SCOUTS_MARCH"] = "Späherschritt",
        ["LID_ENCH_DEFENDERS_MARCH"] = "Marsch des Verteidigers",
        ["LID_ENCH_STORMRIDERS_AGI"] = "Sturmreiter Beweglichkeit",
        ["LID_ENCH_COUNCILS_INTELLECT"] = "Intelligenz des Rats",
        ["LID_ENCH_SUNSET_SPELLTHREAD"] = "+930 Intelligenz und +895 Ausdauer",
        ["LID_ENCH_CRYSTALLINE_RADIANCE"] = "Kristallines Strahlen",
        ["LID_ENCH_OATHSWORNS_STRENGTH"] = "Stärke des Eidgeschworenen",
        ["LID_ENCH_CHANT_ARMORED_AVOID"] = "Gesang der gerüsteten Vermeidung",
        ["LID_ENCH_CHANT_ARMORED_LEECH"] = "Gesang der gerüsteten Blutung",
        ["LID_ENCH_CHANT_ARMORED_SPEED"] = "Gesang der gerüsteten Geschwindigkeit",
        ["LID_ENCH_CHANT_WINGED_GRACE"] = "Gesang der geflügelten Anmut",
        ["LID_ENCH_CHANT_LEECHING_FANGS"] = "Gesang der blutenden Reißzähne",
        ["LID_ENCH_CHANT_BURROWING_RAPIDITY"] = "Gesang der grabenden Schnelligkeit",
        ["LID_ENCH_CURSED_HASTE"] = "Verfluchtes Tempo",
        ["LID_ENCH_CURSED_CRIT"] = "Verfluchter Krit",
        ["LID_ENCH_CURSED_MASTERY"] = "Verfluchte Meisterschaft",
        ["LID_ENCH_CURSED_VERSATILITY"] = "Verfluchte Vielseitigkeit",
        ["LID_ENCH_SHADOWED_BELT_CLASP"] = "Beschattete Gürtelschnalle",
        ["LID_ENCH_INCANDESCENT_ESSENCE"] = "Inkandeszente Essenz",
        -- Weapon enchants
        ["LID_ENCH_AUTHORITY_OF_RADIANT_POWER"] = "Autorität der strahlenden Macht",
        -- Generic fragments (MoP / legacy tooltip parsing)
        ["LID_ENCH_RATING_UPPER"] = "Wertung",
        ["LID_ENCH_RATING_LOWER"] = "wertung",
        ["LID_ENCH_MINOR"] = "Geringe",
        ["LID_ENCH_MOVEMENT"] = "Bewegung",
        ["LID_ENCH_AND_SPACED"] = " und ",
    }

    LingkanUI:UpdateLanguageTab(tab)
end
