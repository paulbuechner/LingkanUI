local ADDON_NAME, LingkanUI = ...

-- Central Blizzard API abstraction layer for version differences.
-- Add lightweight wrappers here so modules can avoid direct version branching.

LingkanUI.API = LingkanUI.API or {}
local API = LingkanUI.API

-- Safe item info wrappers (handle C_Item vs global fallbacks)
function API:GetDetailedItemLevel(itemLink)
    if C_Item and C_Item.GetDetailedItemLevelInfo then
        return C_Item.GetDetailedItemLevelInfo(itemLink)
    elseif GetDetailedItemLevelInfo then
        return GetDetailedItemLevelInfo(itemLink)
    end
end

function API:GetItemQualityColor(quality)
    if C_Item and C_Item.GetItemQualityColor then
        local r, g, b, hex = C_Item.GetItemQualityColor(quality)
        return r, g, b, hex
    elseif GetItemQualityColor then
        return GetItemQualityColor(quality)
    end
end

function API:GetItemInfoInstant(itemLink)
    if C_Item and C_Item.GetItemInfoInstant then
        return C_Item.GetItemInfoInstant(itemLink)
    elseif GetItemInfoInstant then
        return GetItemInfoInstant(itemLink)
    elseif GetItemInfo then
        return GetItemInfo(itemLink)
    end
end

function API:GetInventoryItemDurability(slot)
    if C_Item and C_Item.GetInventoryItemDurability then
        return C_Item.GetInventoryItemDurability(slot)
    elseif GetInventoryItemDurability then
        return GetInventoryItemDurability(slot)
    end
end

function API:GetInventoryItemQuality(unit, slot)
    if C_Item and C_Item.GetInventoryItemQuality then
        return C_Item.GetInventoryItemQuality(unit, slot)
    elseif GetInventoryItemQuality then
        return GetInventoryItemQuality(unit, slot)
    end
end

-- Expansion detection helper
function API:GetExpansionForLevel(level)
    if GetExpansionForLevel then
        return GetExpansionForLevel(level)
    end
end

-- Gem / item data preload
function API:RequestLoadItemDataByID(itemID)
    if C_Item and C_Item.RequestLoadItemDataByID then
        return C_Item.RequestLoadItemDataByID(itemID)
    end
end

-- Debug utility through central system
function API:Debug(msg)
    LingkanUI:DebugPrint(msg, "api")
end
