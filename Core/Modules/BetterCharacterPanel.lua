local ADDON_NAME, LingkanUI = ...

-- Create the BetterCharacterPanel module table
LingkanUI.BetterCharacterPanel = {}
local MODULE_NAME = "betterCharacterPanel"

local bcpFrame

local function DebugPrint(msg)
    LingkanUI:DebugPrint(msg, MODULE_NAME)
end

local NUM_SOCKET_TEXTURES = 4;
local ILVL_ENCHANT_TEXT_SCALE = 0.9;
local INSPECT_ILVL_TEXT_SCALE = 0.63;

local shouldDisplayEnchantMissingTextOverride = false

local expansionRequiredSockets = {
    [10] = {
        [INVSLOT_NECK] = 2,
        [INVSLOT_FINGER1] = 2,
        [INVSLOT_FINGER2] = 2,
    },
    [9] = {
        [INVSLOT_NECK] = 3,
    }
}

local expansionEnchantableSlots = {
    [10] = {
        [INVSLOT_BACK] = true,
        [INVSLOT_CHEST] = true,
        [INVSLOT_WRIST] = true,
        [INVSLOT_WRIST] = true,
        [INVSLOT_LEGS] = true,
        [INVSLOT_FEET] = true,
        [INVSLOT_MAINHAND] = true,
        [INVSLOT_FINGER1] = true,
        [INVSLOT_FINGER2] = true,
    },
    [9] = {
        [INVSLOT_HEAD] = true,
        [INVSLOT_BACK] = true,
        [INVSLOT_CHEST] = true,
        [INVSLOT_WRIST] = true,
        [INVSLOT_WAIST] = true,
        [INVSLOT_LEGS] = true,
        [INVSLOT_FEET] = true,
        [INVSLOT_MAINHAND] = true,
        [INVSLOT_FINGER1] = true,
        [INVSLOT_FINGER2] = true,
    },
}

local buttonLayout =
{
    [INVSLOT_HEAD] = "left",
    [INVSLOT_NECK] = "left",
    [INVSLOT_SHOULDER] = "left",
    [INVSLOT_BACK] = "left",
    [INVSLOT_CHEST] = "left",
    [INVSLOT_WRIST] = "left",

    [INVSLOT_HAND] = "right",
    [INVSLOT_WAIST] = "right",
    [INVSLOT_LEGS] = "right",
    [INVSLOT_FEET] = "right",
    [INVSLOT_FINGER1] = "right",
    [INVSLOT_FINGER2] = "right",
    [INVSLOT_TRINKET1] = "right",
    [INVSLOT_TRINKET2] = "right",

    [INVSLOT_MAINHAND] = "center",
    [INVSLOT_OFFHAND] = "center",
};

local scanningTooltip, enchantReplacementTable;
local GetItemEnchantAsText, GetSocketTextures, ProcessEnchantText, CanEnchantSlot;
if (LingkanUI.Version.isMop) then
    buttonLayout[INVSLOT_RANGED] = "center";
    scanningTooltip = CreateFrame("GameTooltip", "BCPScanningTooltip", nil, "GameTooltipTemplate");
    scanningTooltip:SetOwner(UIParent, "ANCHOR_NONE");

    enchantReplacementTable =
    {
        [LingkanUI:GT("LID_ENCH_STAMINA")] = "Stam",
        [LingkanUI:GT("LID_ENCH_INTELLECT")] = "Int",
        [LingkanUI:GT("LID_ENCH_AGILITY")] = "Agi",
        [LingkanUI:GT("LID_ENCH_STRENGTH")] = "Str",

        [LingkanUI:GT("LID_ENCH_MASTERY")] = "Mast",
        [LingkanUI:GT("LID_ENCH_VERSATILITY")] = "Vers",
        [LingkanUI:GT("LID_ENCH_CRITICAL_STRIKE")] = "Crit",
        [LingkanUI:GT("LID_ENCH_HASTE")] = "Haste",
        [LingkanUI:GT("LID_ENCH_AVOIDANCE")] = "Avoid",

        [LingkanUI:GT("LID_ENCH_RATING_UPPER")] = "",
        [LingkanUI:GT("LID_ENCH_RATING_LOWER")] = "",

        [LingkanUI:GT("LID_ENCH_MINOR")] = "Min",
        [LingkanUI:GT("LID_ENCH_MOVEMENT")] = "Move",

        [LingkanUI:GT("LID_ENCH_AND_SPACED")] = " ",
        ["+"] = "", -- ensure plus stripped here too for MoP branch
    };

    local function hasEnchant(itemLink)
        if (not itemLink) then
            return false;
        end

        local itemString = itemLink:match("item[%-?%d:]+");
        if (not itemString) then
            return false;
        end

        local _, _, enchantId = strsplit(":", itemString);
        return enchantId and enchantId ~= "";
    end


    function GetItemEnchantAsText(unit, slot)
        scanningTooltip:ClearLines();
        scanningTooltip:SetInventoryItem(unit, slot);
        local itemLink = GetInventoryItemLink(unit, slot);

        if (not hasEnchant(itemLink)) then
            return nil, nil;
        end

        for i = scanningTooltip:NumLines(), 3, -1 do
            local fontString = _G["BCPScanningTooltipTextLeft" .. i]
            if (fontString and fontString:GetObjectType() == "FontString") then
                local text = fontString:GetText(); -- string or nil
                if (text) then
                    local startsWithPlus = string.find(text, "^%+");
                    local r, g, b, a = fontString:GetTextColor();
                    -- nice red blizzard
                    if (r == 1 and (string.format("%.3f", g) == "0.125" and string.format("%.3f", b) == "0.125" and a == 1)) then
                        if (startsWithPlus) then
                            return nil, ProcessEnchantText(text);
                        end
                    elseif (r == 0 and g == 1 and b == 0 and a == 1) then
                        if (not string.find(text, "<") and not string.find(text, "Equip: ") and not string.find(text, "Socket Bonus:") and not string.find(text, "Use: ")) then
                            if (startsWithPlus) then
                                return nil, ProcessEnchantText(text);
                            elseif ((slot == INVSLOT_MAINHAND or slot == INVSLOT_OFFHAND or slot == INVSLOT_BACK)) then
                                return nil, ProcessEnchantText(text);
                            end
                        end
                    end
                end
            end
        end
    end

    function GetSocketTextures(unit, slot)
        scanningTooltip:ClearLines();
        scanningTooltip:SetInventoryItem(unit, slot);

        local textures = {};

        for i = 1, 10 do
            local texture = _G["BCPScanningTooltipTexture" .. i];
            if (texture and texture:IsShown()) then
                table.insert(textures, texture:GetTexture());
            end
        end

        return textures;
    end

    local slotsThatHaveEnchants = {
        [INVSLOT_SHOULDER] = true,
        [INVSLOT_BACK] = true,
        [INVSLOT_CHEST] = true,
        [INVSLOT_WRIST] = true,
        [INVSLOT_LEGS] = true,
        [INVSLOT_HAND] = true,
        [INVSLOT_FEET] = true,
        [INVSLOT_MAINHAND] = true,
        [INVSLOT_OFFHAND] = true,
    };

    function CanEnchantSlot(unit, slot)
        local class = select(2, UnitClass(unit));
        if (class == "HUNTER" and slot == INVSLOT_RANGED) then
            return true;
        end

        return slotsThatHaveEnchants[slot];
    end
else
    enchantReplacementTable = {
        [LingkanUI:GT("LID_ENCH_STAMINA")]                    = "Stam",
        [LingkanUI:GT("LID_ENCH_INTELLECT")]                  = "Int",
        [LingkanUI:GT("LID_ENCH_AGILITY")]                    = "Agi",
        [LingkanUI:GT("LID_ENCH_STRENGTH")]                   = "Str",
        [LingkanUI:GT("LID_ENCH_MASTERY")]                    = "Mast",
        [LingkanUI:GT("LID_ENCH_VERSATILITY")]                = "Vers",
        [LingkanUI:GT("LID_ENCH_CRITICAL_STRIKE")]            = "Crit",
        [LingkanUI:GT("LID_ENCH_HASTE")]                      = "Haste",
        [LingkanUI:GT("LID_ENCH_AVOIDANCE")]                  = "Avoid",
        [LingkanUI:GT("LID_ENCH_MINOR_SPEED_INCREASE")]       = "Speed",
        [LingkanUI:GT("LID_ENCH_HOMEBOUND_SPEED")]            = "Speed & HS Red.",
        [LingkanUI:GT("LID_ENCH_PLAINSRUNNERS_BREEZE")]       = "Speed",
        [LingkanUI:GT("LID_ENCH_GRACEFUL_AVOID")]             = "Avoid",
        [LingkanUI:GT("LID_ENCH_REGENERATIVE_LEECH")]         = "Leech",
        [LingkanUI:GT("LID_ENCH_WATCHERS_LOAM")]              = "Stam",
        [LingkanUI:GT("LID_ENCH_RIDERS_REASSURANCE")]         = "Mount Speed",
        [LingkanUI:GT("LID_ENCH_ACCELERATED_AGILITY")]        = "Speed & Agi",
        [LingkanUI:GT("LID_ENCH_RESERVE_OF_INT")]             = "Mana & Int",
        [LingkanUI:GT("LID_ENCH_SUSTAINED_STR")]              = "Stam & Str",
        [LingkanUI:GT("LID_ENCH_WAKING_STATS")]               = "Primary Stat",
        [LingkanUI:GT("LID_ENCH_CAVALRYS_MARCH")]             = "Mount Speed",
        [LingkanUI:GT("LID_ENCH_SCOUTS_MARCH")]               = "Speed",
        [LingkanUI:GT("LID_ENCH_DEFENDERS_MARCH")]            = "Stam",
        [LingkanUI:GT("LID_ENCH_STORMRIDERS_AGI")]            = "Agi & Speed",
        [LingkanUI:GT("LID_ENCH_COUNCILS_INTELLECT")]         = "Int & Mana",
        [LingkanUI:GT("LID_ENCH_CRYSTALLINE_RADIANCE")]       = "Primary Stat",
        [LingkanUI:GT("LID_ENCH_OATHSWORNS_STRENGTH")]        = "Str & Stam",
        [LingkanUI:GT("LID_ENCH_CHANT_ARMORED_AVOID")]        = "Avoid",
        [LingkanUI:GT("LID_ENCH_CHANT_ARMORED_LEECH")]        = "Leech",
        [LingkanUI:GT("LID_ENCH_CHANT_ARMORED_SPEED")]        = "Speed",
        [LingkanUI:GT("LID_ENCH_CHANT_WINGED_GRACE")]         = "Avoid & FallDmg",
        [LingkanUI:GT("LID_ENCH_CHANT_LEECHING_FANGS")]       = "Leech & Recup",
        [LingkanUI:GT("LID_ENCH_CHANT_BURROWING_RAPIDITY")]   = "Speed & HScd",
        [LingkanUI:GT("LID_ENCH_CURSED_HASTE")]               = "Haste & \124cffcc0000-Vers\124r",
        [LingkanUI:GT("LID_ENCH_CURSED_CRIT")]                = "Crit & \124cffcc0000-Haste\124r",
        [LingkanUI:GT("LID_ENCH_CURSED_MASTERY")]             = "Mast & \124cffcc0000-Crit\124r",
        [LingkanUI:GT("LID_ENCH_CURSED_VERSATILITY")]         = "Vers & \124cffcc0000-Mast\124r",
        [LingkanUI:GT("LID_ENCH_SHADOWED_BELT_CLASP")]        = "Stamina",
        [LingkanUI:GT("LID_ENCH_INCANDESCENT_ESSENCE")]       = "Essence",
        -- Weapon enchants
        [LingkanUI:GT("LID_ENCH_AUTHORITY_OF_RADIANT_POWER")] = "Radiant Power",
        [LingkanUI:GT("LID_ENCH_AUTHORITY_OF_THE_DEPTHS")]    = "Depths",
        -- Misc
        ["+"]                                                 = "",
    };

    local enchantPattern = ENCHANTED_TOOLTIP_LINE:gsub('%%s', '(.*)');
    local enchantAtlasPattern = "(.*)%s*|A:(.*):20:20|a";
    local enchantColoredPatten = "|cn(.*):(.*)|r";

    function GetItemEnchantAsText(unit, slot)
        local data = C_TooltipInfo.GetInventoryItem(unit, slot);
        for _, line in ipairs(data.lines) do
            local text = line.leftText;
            local enchantText = string.match(text, enchantPattern);
            if (enchantText) then
                local maybeEnchantText, atlas;
                local maybeEnchantColor, maybeEnchantTextColored = enchantText:match(enchantColoredPatten);
                if (maybeEnchantColor) then
                    enchantText = maybeEnchantTextColored;
                else
                    maybeEnchantText, atlas = enchantText:match(enchantAtlasPattern);
                    enchantText = maybeEnchantText or enchantText;
                end

                return atlas, ProcessEnchantText(enchantText)
            end
        end

        return nil, nil;
    end

    function GetSocketTextures(unit, slot)
        local data = C_TooltipInfo.GetInventoryItem(unit, slot);
        local textures = {};
        for i, line in ipairs(data.lines) do
            if line.type == 3 then
                local gemIcon = rawget(line, "gemIcon")
                local socketType = rawget(line, "socketType")
                if gemIcon then
                    table.insert(textures, gemIcon)
                elseif socketType then
                    table.insert(textures, string.format("Interface\\ItemSocketingFrame\\UI-EmptySocket-%s", socketType))
                end
            end
        end

        return textures;
    end

    function CanEnchantSlot(unit, slot)
        local expansion = LingkanUI.API:GetExpansionForLevel(UnitLevel(unit));
        local slotsThatHaveEnchants = expansion and expansionEnchantableSlots[expansion] or {};

        -- all classes have something that increases power or survivability on chest/cloak/weapons/rings/wrist/boots/legs
        if (slotsThatHaveEnchants[slot]) then
            return true;
        end

        -- Offhand filtering smile :)
        if (slot == INVSLOT_OFFHAND) then
            local offHandItemLink = GetInventoryItemLink(unit, slot);
            if (offHandItemLink) then
                local itemEquipLoc = select(4, LingkanUI.API:GetItemInfoInstant(offHandItemLink));
                return itemEquipLoc ~= "INVTYPE_HOLDABLE" and itemEquipLoc ~= "INVTYPE_SHIELD";
            end
            return false;
        end

        return false;
    end
end

local function escapePattern(text)
    return text:gsub("(%W)", "%%%1")
end

function ProcessEnchantText(enchantText)
    -- Strip numbers and any trailing whitespace to prevent double spaces
    enchantText = enchantText:gsub("%d+%s*", "")
    -- Clean up any remaining multiple whitespaces
    enchantText = enchantText:gsub("%s+", " ")
    -- Trim leading/trailing whitespace
    enchantText = enchantText:gsub("^%s*(.-)%s*$", "%1")

    -- Collect keys and sort by length descending for longest match first to avoid partial early replacements
    local keys = {}
    for k in pairs(enchantReplacementTable) do table.insert(keys, k) end
    table.sort(keys, function(a, b)
        local la, lb = #a, #b
        if la == lb then
            return a < b -- deterministic fallback
        end
        return la > lb
    end)

    for _, seek in ipairs(keys) do
        local replacement = enchantReplacementTable[seek]
        -- Escape Lua pattern magic so we do literal matching
        local pattern = escapePattern(seek)
        enchantText = enchantText:gsub(pattern, replacement)
    end

    return enchantText
end

local function ColorGradient(perc, ...)
    if perc >= 1 then
        local r, g, b = select(select('#', ...) - 2, ...);
        return r, g, b;
    elseif perc <= 0 then
        local r, g, b = ...;
        return r, g, b;
    end

    local num = select('#', ...) / 3;

    local segment, relperc = math.modf(perc * (num - 1));
    local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, ...);

    return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc;
end

local function ColorGradientHP(perc)
    return ColorGradient(perc, 1, 0, 0, 1, 1, 0, 0, 1, 0);
end



local function AnchorTextureLeftOfParent(parent, textures)
    textures[1]:SetPoint("RIGHT", parent, "LEFT", -3, 1);
    for i = 2, NUM_SOCKET_TEXTURES do
        textures[i]:SetPoint("RIGHT", textures[i - 1], "LEFT", -2, 0);
    end
end

local function AnchorTextureRightOfParent(parent, textures)
    textures[1]:SetPoint("LEFT", parent, "RIGHT", 3, 1);
    for i = 2, NUM_SOCKET_TEXTURES do
        textures[i]:SetPoint("LEFT", textures[i - 1], "RIGHT", 2, 0);
    end
end

local function CreateAdditionalDisplayForButton(button)
    local parent = button:GetParent();
    local additionalFrame = CreateFrame("frame", nil, parent);
    additionalFrame:SetWidth(100);

    additionalFrame.ilvlDisplay = additionalFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline");

    additionalFrame.enchantDisplay = additionalFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline");
    additionalFrame.enchantDisplay:SetTextColor(0, 1, 0, 1);

    additionalFrame.durabilityDisplay = CreateFrame("StatusBar", nil, additionalFrame);
    additionalFrame.durabilityDisplay:SetMinMaxValues(0, 1);
    additionalFrame.durabilityDisplay:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar");
    additionalFrame.durabilityDisplay:GetStatusBarTexture():SetHorizTile(false);
    additionalFrame.durabilityDisplay:GetStatusBarTexture():SetVertTile(false);
    additionalFrame.durabilityDisplay:SetHeight(40);
    additionalFrame.durabilityDisplay:SetWidth(2.3);
    additionalFrame.durabilityDisplay:SetOrientation("VERTICAL");

    additionalFrame.socketDisplay = {};

    for i = 1, NUM_SOCKET_TEXTURES do
        additionalFrame.socketDisplay[i] = additionalFrame:CreateTexture();
        additionalFrame.socketDisplay[i]:SetWidth(14);
        additionalFrame.socketDisplay[i]:SetHeight(14);
    end

    return additionalFrame;
end

local function positionLeft(button)
    local additionalFrame = button.BCPDisplay;

    additionalFrame:SetPoint("TOPLEFT", button, "TOPRIGHT");
    additionalFrame:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT");

    additionalFrame.ilvlDisplay:SetPoint("BOTTOMLEFT", additionalFrame, "BOTTOMLEFT", 10, 2);
    additionalFrame.enchantDisplay:SetPoint("TOPLEFT", additionalFrame, "TOPLEFT", 10, -7);

    additionalFrame.durabilityDisplay:SetPoint("TOPLEFT", button, "TOPLEFT", -6, 0);
    additionalFrame.durabilityDisplay:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -6, 0);

    AnchorTextureRightOfParent(additionalFrame.ilvlDisplay, additionalFrame.socketDisplay);
end

local function positionRight(button)
    local additionalFrame = button.BCPDisplay;

    additionalFrame:SetPoint("TOPRIGHT", button, "TOPLEFT");
    additionalFrame:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT");

    additionalFrame.ilvlDisplay:SetPoint("BOTTOMRIGHT", additionalFrame, "BOTTOMRIGHT", -10, 2);
    additionalFrame.enchantDisplay:SetPoint("TOPRIGHT", additionalFrame, "TOPRIGHT", -10, -7);

    additionalFrame.durabilityDisplay:SetWidth(1.2);
    additionalFrame.durabilityDisplay:SetPoint("TOPRIGHT", button, "TOPRIGHT", 4, 0);
    additionalFrame.durabilityDisplay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, 0);

    AnchorTextureLeftOfParent(additionalFrame.ilvlDisplay, additionalFrame.socketDisplay);
end

local function positionCenter(button)
    local additionalFrame = button.BCPDisplay;

    additionalFrame:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -100, 0);
    additionalFrame:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -100);

    additionalFrame.durabilityDisplay:SetHeight(2);
    additionalFrame.durabilityDisplay:SetWidth(40);
    additionalFrame.durabilityDisplay:SetOrientation("HORIZONTAL");
    additionalFrame.durabilityDisplay:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, -2);
    additionalFrame.durabilityDisplay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, -2);

    additionalFrame.ilvlDisplay:SetPoint("BOTTOM", button, "TOP", 0, 7);

    local buttonId = button:GetID();
    if (LingkanUI.Version.isMop) then
        if (buttonId == INVSLOT_MAINHAND) then
            additionalFrame.enchantDisplay:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", -5, 0);

            additionalFrame.socketDisplay[1]:SetPoint("RIGHT", button, "LEFT", -5, 0);
            for i = 2, NUM_SOCKET_TEXTURES do
                additionalFrame.socketDisplay[i]:SetPoint("RIGHT", additionalFrame.socketDisplay[i - 1], "LEFT", -2, 0);
            end
        elseif (buttonId == INVSLOT_RANGED) then
            additionalFrame.enchantDisplay:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", 5, 0);

            additionalFrame.socketDisplay[1]:SetPoint("LEFT", button, "RIGHT", 5, 0);
            for i = 2, NUM_SOCKET_TEXTURES do
                additionalFrame.socketDisplay[i]:SetPoint("LEFT", additionalFrame.socketDisplay[i - 1], "RIGHT", 2, 0);
            end
        else
            additionalFrame.enchantDisplay:SetPoint("BOTTOM", button, "TOP", 0, 20);
            AnchorTextureLeftOfParent(additionalFrame.ilvlDisplay, additionalFrame.socketDisplay);
        end
    else
        if (button:GetID() == INVSLOT_MAINHAND) then
            additionalFrame.enchantDisplay:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", -5, 0);
            AnchorTextureLeftOfParent(additionalFrame.ilvlDisplay, additionalFrame.socketDisplay);
        else
            additionalFrame.enchantDisplay:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", 5, 0);
            AnchorTextureRightOfParent(additionalFrame.ilvlDisplay, additionalFrame.socketDisplay);
        end
    end
end

local function AnchorAdditionalDisplay(button)
    local layout = buttonLayout[button:GetID()];
    if (layout == "left") then
        positionLeft(button);
    elseif (layout == "right") then
        positionRight(button);
    elseif (layout == "center") then
        positionCenter(button);
    end
end

local function UpdateAdditionalDisplay(button, unit)
    local additionalFrame = button.BCPDisplay;

    -- This should never happen, but apparently it does sometimes for some reason.
    -- Cant reproduce it, but it happens.
    if (not additionalFrame) then return; end

    local slot = button:GetID();
    local itemLink = GetInventoryItemLink(unit, slot);

    if (not additionalFrame.prevItemLink or itemLink ~= additionalFrame.prevItemLink) then
        local itemILvlText = "";
        if (itemLink) then
            local ilvl = LingkanUI.API:GetDetailedItemLevel(itemLink)
            local quality = LingkanUI.API:GetInventoryItemQuality(unit, slot)
            if (quality) then
                local _, _, _, hex = LingkanUI.API:GetItemQualityColor(quality)
                itemILvlText = "|c" .. hex .. tostring(ilvl) .. "|r";
            else
                itemILvlText = ilvl and tostring(ilvl) or "";
            end
        end
        if not LingkanUI.db or not LingkanUI.db.profile.betterCharacterPanel.showItemLevel then
            additionalFrame.ilvlDisplay:SetText("")
        else
            additionalFrame.ilvlDisplay:SetText(itemILvlText);
        end
        additionalFrame.ilvlDisplay:SetTextScale(ILVL_ENCHANT_TEXT_SCALE);

        local atlas, enchantText
        if itemLink and LingkanUI.db and LingkanUI.db.profile.betterCharacterPanel.showEnchants then
            atlas, enchantText = GetItemEnchantAsText(unit, slot);
        end

        local canEnchant = CanEnchantSlot(unit, slot);

        if (not LingkanUI.db.profile.betterCharacterPanel.showEnchants) then
            additionalFrame.enchantDisplay:SetText("")
        elseif (not enchantText) then
            local shouldDisplayEnchantMissingText = canEnchant and itemLink and IsLevelAtEffectiveMaxLevel(UnitLevel(unit));
            additionalFrame.enchantDisplay:SetText(shouldDisplayEnchantMissingText and shouldDisplayEnchantMissingTextOverride and "|cffff0000No Enchant|r" or "");
        else
            --trim size
            local maxSize = 18;
            local containsColor = string.find(enchantText, "|c");
            if (containsColor) then
                maxSize = maxSize + strlen("|cffffffff|r");
            end
            enchantText = string.sub(enchantText, 1, maxSize);

            local enchantQuality = "";
            if atlas then
                enchantQuality = "|A:" .. atlas .. ":12:12|a";
            end

            -- for symmetry, put quality on the left of offhand
            if slot == INVSLOT_OFFHAND then
                additionalFrame.enchantDisplay:SetText(enchantQuality .. enchantText);
            else
                additionalFrame.enchantDisplay:SetText(enchantText .. enchantQuality);
            end
            additionalFrame.enchantDisplay:SetTextScale(ILVL_ENCHANT_TEXT_SCALE);
        end

        if (not LingkanUI.Version.isRemix) then
            local textures = (itemLink and LingkanUI.db.profile.betterCharacterPanel.showSockets) and GetSocketTextures(unit, slot) or {};
            for i = 1, NUM_SOCKET_TEXTURES do
                local socketTexture = additionalFrame.socketDisplay[i];
                if (#textures >= i and LingkanUI.db.profile.betterCharacterPanel.showSockets) then
                    socketTexture:SetTexture(textures[i]);
                    socketTexture:SetVertexColor(1, 1, 1);
                    socketTexture:Show();
                else
                    if LingkanUI.db.profile.betterCharacterPanel.showSockets then
                        local expansion = LingkanUI.API:GetExpansionForLevel(UnitLevel(unit));
                        local expansionSocketRequirement = expansion and expansionRequiredSockets[expansion];
                        if (expansionSocketRequirement and expansionSocketRequirement[slot] and i <= expansionSocketRequirement[slot]) then
                            socketTexture:SetTexture("Interface\\ItemSocketingFrame\\UI-EmptySocket-Red");
                            socketTexture:SetVertexColor(1, 0, 0);
                            socketTexture:Show();
                        else
                            socketTexture:Hide();
                        end
                    else
                        socketTexture:Hide();
                    end
                end
            end
        end

        additionalFrame.prevItemLink = itemLink;
    end

    local currentDurability, maxDurability = LingkanUI.API:GetInventoryItemDurability(slot);
    local percentDurability = currentDurability and currentDurability / maxDurability;

    if (not additionalFrame.prevDurability or additionalFrame.prevDurability ~= percentDurability) then
        if (LingkanUI.db.profile.betterCharacterPanel.showDurability and UnitIsUnit("player", unit) and percentDurability and percentDurability < 1) then
            additionalFrame.durabilityDisplay:Show();
            additionalFrame.durabilityDisplay:SetValue(percentDurability);
            additionalFrame.durabilityDisplay:SetStatusBarColor(ColorGradientHP(percentDurability));
        else
            additionalFrame.durabilityDisplay:Hide();
        end
        additionalFrame.prevDurability = percentDurability;
    end
end

local function CreateInspectIlvlDisplay()
    local parent = InspectPaperDollItemsFrame;
    if (not parent.ilvlDisplay) then
        parent.ilvlDisplay = parent:CreateFontString(nil, "OVERLAY", LingkanUI.Version.isMop and "GameFontHighlightOutline" or "GameFontHighlightOutline22");
        parent.ilvlDisplay:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -20);
        parent.ilvlDisplay:SetPoint("BOTTOMLEFT", parent, "TOPRIGHT", -65, -83);
    end
end

local LEGENDARY_ITEM_LEVEL = 730;
local STEP_ITEM_LEVEL = 13;

local levelThresholds = {};
for i = 4, 1, -1 do
    levelThresholds[i] = LEGENDARY_ITEM_LEVEL - (STEP_ITEM_LEVEL * (i - 1));
end

local function UpdateInspectIlvlDisplay(unit)
    local ilvl = C_PaperDollInfo.GetInspectItemLevel(unit);
    local color;
    if (ilvl < levelThresholds[4]) then
        color = "fafafa";
    elseif (ilvl < levelThresholds[3]) then
        color = "1eff00";
    elseif (ilvl < levelThresholds[2]) then
        color = "0070dd";
    elseif (ilvl < levelThresholds[1]) then
        color = "a335ee";
    else
        color = "ff8000";
    end

    local parent = InspectPaperDollItemsFrame;
    parent.ilvlDisplay:SetText(string.format("|cff%sGS %d|r", color, ilvl));
    parent.ilvlDisplay:SetTextScale(INSPECT_ILVL_TEXT_SCALE);
end

local updateButton = function(button, unit)
    if (not buttonLayout[button:GetID()]) then
        return;
    end

    if (not button.BCPDisplay) then
        button.BCPDisplay = CreateAdditionalDisplayForButton(button);
        AnchorAdditionalDisplay(button);
    end

    if (LingkanUI.Version.isMop) then
        C_Timer.After(0, function()
            UpdateAdditionalDisplay(button, unit);
        end);
    else
        UpdateAdditionalDisplay(button, unit);
    end
end


function LingkanUI.BetterCharacterPanel:MoveTalentButton(talentButton)
    talentButton:SetSize(72, 32);

    talentButton.Left:SetTexture(nil);
    talentButton.Left:SetTexCoord(0, 1, 0, 1);
    talentButton.Left:ClearAllPoints();
    talentButton.Left:SetPoint("TOPLEFT");
    talentButton.Left:SetAtlas("uiframe-tab-left", true);
    talentButton.Left:SetHeight(36);

    talentButton.Right:SetTexture(nil);
    talentButton.Right:SetTexCoord(0, 1, 0, 1);
    talentButton.Right:ClearAllPoints();
    talentButton.Right:SetPoint("TOPRIGHT", 6);
    talentButton.Right:SetAtlas("uiframe-tab-right", true);
    talentButton.Right:SetHeight(36);

    talentButton.Middle:SetTexture(nil);
    talentButton.Middle:SetTexCoord(0, 1, 0, 1);
    talentButton.Middle:ClearAllPoints();
    talentButton.Middle:SetPoint("LEFT", talentButton.Left, "RIGHT");
    talentButton.Middle:SetPoint("RIGHT", talentButton.Right, "LEFT");
    talentButton.Middle:SetAtlas("_uiframe-tab-center", true);
    talentButton.Middle:SetHeight(36);

    talentButton.LeftHighlight = talentButton:CreateTexture();
    talentButton.LeftHighlight:SetAtlas("uiframe-tab-left", true);
    talentButton.LeftHighlight:SetAlpha(0.4);
    talentButton.LeftHighlight:SetBlendMode("ADD");
    talentButton.LeftHighlight:SetPoint("TOPLEFT");
    talentButton.LeftHighlight:Hide();

    talentButton.RightHighlight = talentButton:CreateTexture();
    talentButton.RightHighlight:SetAtlas("uiframe-tab-right", true);
    talentButton.RightHighlight:SetAlpha(0.4);
    talentButton.RightHighlight:SetBlendMode("ADD");
    talentButton.RightHighlight:SetPoint("TOPRIGHT", 6);
    talentButton.RightHighlight:Hide();

    talentButton.MiddleHighlight = talentButton:CreateTexture();
    talentButton.MiddleHighlight:SetAtlas("_uiframe-tab-center", true);
    talentButton.MiddleHighlight:SetAlpha(0.4);
    talentButton.MiddleHighlight:SetBlendMode("ADD");
    talentButton.MiddleHighlight:SetPoint("LEFT", talentButton.Left, "RIGHT");
    talentButton.MiddleHighlight:SetPoint("RIGHT", talentButton.Right, "LEFT");
    talentButton.MiddleHighlight:Hide();

    talentButton:SetNormalFontObject(GameFontNormalSmall);
    talentButton:SetHighlightFontObject(GameFontHighlightSmall);
    talentButton:ClearHighlightTexture();
    talentButton.Text:ClearAllPoints();
    talentButton.Text:SetPoint("CENTER", 0, 2);
    talentButton.Text:SetHeight(10);

    talentButton:HookScript("OnEnter", function(self)
        for _, v in ipairs({ "MiddleHighlight", "LeftHighlight", "RightHighlight" }) do
            self[v]:Show();
        end
    end);

    talentButton:HookScript("OnLeave", function(self)
        for _, v in ipairs({ "MiddleHighlight", "LeftHighlight", "RightHighlight" }) do
            self[v]:Hide();
        end
    end);

    talentButton:SetScript("OnMouseDown", nil);
    talentButton:SetScript("OnMouseUp", nil);
    talentButton:SetScript("OnShow", nil);
    talentButton:SetScript("OnEnable", nil);
    talentButton:SetScript("OnDisable", nil);

    talentButton:ClearAllPoints();
    talentButton:SetPoint("LEFT", InspectFrameTab3, "RIGHT", 3, 0);
end

local inspectHooksInstalled = false

function LingkanUI.BetterCharacterPanel:INSPECT_READY(inspecteeGUID)
    local talentButton = InspectPaperDollItemsFrame and InspectPaperDollItemsFrame.InspectTalents
    if (talentButton) then
        self:MoveTalentButton(talentButton);
    end

    if inspectHooksInstalled then return end -- already hooked
    if not InspectFrame or not InspectFrame.unit then return end

    DebugPrint("Hooking into Inspect frame (initial install)")

    hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(button)
        updateButton(button, InspectFrame.unit)
    end)

    hooksecurefunc("InspectPaperDollFrame_SetLevel", function()
        CreateInspectIlvlDisplay();
        if (not LingkanUI.Version.isMop) then
            UpdateInspectIlvlDisplay(InspectFrame.unit);
        end
    end)

    inspectHooksInstalled = true
end

local characterSlots = {
    "CharacterHeadSlot",
    "CharacterNeckSlot",
    "CharacterShoulderSlot",
    "CharacterChestSlot",
    "CharacterWaistSlot",
    "CharacterLegsSlot",
    "CharacterFeetSlot",
    "CharacterWristSlot",
    "CharacterHandsSlot",
    "CharacterFinger0Slot",
    "CharacterFinger1Slot",
    "CharacterTrinket0Slot",
    "CharacterTrinket1Slot",
    "CharacterBackSlot",
    "CharacterMainHandSlot",
    "CharacterSecondaryHandSlot",
};

local function updateAllCharacterSlots()
    for _, slot in ipairs(characterSlots) do
        local button = _G[slot];
        if (button) then
            UpdateAdditionalDisplay(button, "player");
        end
    end
end

local lastUpdate = 0;
function LingkanUI.BetterCharacterPanel:SOCKET_INFO_UPDATE()
    if (CharacterFrame:IsShown()) then
        local time = GetTime();
        if (time ~= lastUpdate) then
            updateAllCharacterSlots();
            lastUpdate = time;
        end
    end
end

-- fired when enchants are applied
function LingkanUI.BetterCharacterPanel:UNIT_INVENTORY_CHANGED(unit)
    if (unit == "player") then
        LingkanUI.BetterCharacterPanel:SOCKET_INFO_UPDATE()
    end
end

-- cache list
local gemsWeCareAbout = {
    192991, -- Increased Primary Stat and Versatility
    192985, -- Increased Primary Stat and Haste
    192982, -- Increased Primary Stat and Critical Strike
    192988, -- Increased Primary Stat and Mastery

    192945, -- Increased Haste and Critical Strike
    192948, -- Increased Haste and Mastery
    192952, -- Increased Haste and Versatility
    192955, -- Increased Haste

    192961, -- Increased Mastery and Haste
    192958, -- Increased Mastery and Critical Strike
    192964, -- Increased Mastery and Versatility
    192967, -- Increased Mastery

    192919, -- Increased Critical Strike and Haste
    192925, -- Increased Critical Strike and Versatility
    192922, -- Increased Critical Strike and Mastery
    192928, -- Increased Critical Strike

    192935, -- Increased Versatility and Haste
    192932, -- Increased Versatility and Critical Strike
    192938, -- Increased Versatility and Mastery
    192942, -- Increased Versatility

    192973, -- Increased Stamina and Haste
    192970, -- Increased Stamina and Critical Strike
    192979, -- Increased Stamina and Versatility
    192976, -- Increased Stamina and Mastery
};

-- There is no escaping the cache!!!
function LingkanUI.BetterCharacterPanel:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    for _, gemID in ipairs(gemsWeCareAbout) do
        C_Item.RequestLoadItemDataByID(gemID);
    end
end

local function BCP_OnEvent(self, event, ...)
    if event == "INSPECT_READY" then
        LingkanUI.BetterCharacterPanel:INSPECT_READY(...)
    elseif event == "SOCKET_INFO_UPDATE" then
        LingkanUI.BetterCharacterPanel:SOCKET_INFO_UPDATE()
    elseif event == "UNIT_INVENTORY_CHANGED" then
        LingkanUI.BetterCharacterPanel:UNIT_INVENTORY_CHANGED(...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        LingkanUI.BetterCharacterPanel:PLAYER_ENTERING_WORLD(...)
    end
end

function LingkanUI.BetterCharacterPanel:Load()
    DebugPrint("Loading module")

    bcpFrame = CreateFrame("Frame", ADDON_NAME .. "BCPEventFrame", UIParent)
    bcpFrame:RegisterEvent("INSPECT_READY")
    bcpFrame:RegisterEvent("SOCKET_INFO_UPDATE")
    bcpFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    bcpFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    bcpFrame:SetScript("OnEvent", BCP_OnEvent)

    -- (Own) Player character frame hook
    hooksecurefunc("PaperDollItemSlotButton_Update", function(button) updateButton(button, "player") end)
end

function LingkanUI.BetterCharacterPanel:Unload()
    if not bcpFrame then return end

    DebugPrint("Unloading module")

    bcpFrame:UnregisterAllEvents()
    bcpFrame:SetScript("OnEvent", nil)
    bcpFrame:Hide()
    bcpFrame = nil
end
