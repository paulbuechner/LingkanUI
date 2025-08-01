local ADDON_NAME, LingkanUI = ...

-- Create the Sheathing module
LingkanUI.Sheathing = {}

-- Module name for debug output
local MODULE_NAME = "sheath"

-- Module-specific debug function
local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

--------------------------------------- SheatHandler ---------------------------------------

-- German locale weapon collections
local meleeWeaponTypes = {
    ["Einhandäxte"] = true,          -- One-Handed Axes
    ["Zweihandäxte"] = true,         -- Two-Handed Axes
    ["Einhandstreitkolben"] = true,  -- One-Handed Maces
    ["Zweihandstreitkolben"] = true, -- Two-Handed Maces
    ["Stangeenwaffen"] = true,       -- Polearms
    ["Einhandschwerter"] = true,     -- One-Handed Swords
    ["Zweihandschwerter"] = true,    -- Two-Handed Swords
    ["Kriegsgleven"] = true,         -- Warglaives
    ["Stäbe"] = true,                -- Staves
    ["Bärenklauen"] = true,          -- Bear Claws
    ["Katzenklauen"] = true,         -- Cat Claws
    ["Faustwaffen"] = true,          -- Fist Weapons
    ["Dolche"] = true,               -- Daggers
    ["Speere"] = true,               -- Spears
}

local rangedWeaponTypes = {
    ["Bögen"] = true,        -- Bows
    ["Schusswaffen"] = true, -- Guns
    ["Wurfwaffen"] = true,   -- Thrown
    ["Armbrüste"] = true,    -- Crossbows
    ["Zauberstäbe"] = true,  -- Wands
}

function LingkanUI.Sheathing:EnableSheathHandler()
    LingkanUI:RegisterEvent("PLAYER_ENTERING_WORLD", "SheatHandler")
    LingkanUI:RegisterEvent("UNIT_TARGET", "SheatHandler")
    LingkanUI:RegisterEvent("UNIT_MODEL_CHANGED", "SheatHandler")

    -- Apply sheath setting immediately
    C_Timer.After(1, function()
        LingkanUI:SheatHandler()
    end)
end

function LingkanUI.Sheathing:DisableSheathHandler()
    LingkanUI:UnregisterEvent("PLAYER_ENTERING_WORLD")
    LingkanUI:UnregisterEvent("UNIT_TARGET")
    LingkanUI:UnregisterEvent("UNIT_MODEL_CHANGED")
end

function LingkanUI:SheatHandler()
    -- Check if sheath control is enabled
    if not self.db.profile.sheath.enabled then
        DebugPrint("Sheath handler called but sheath control is disabled")
        return
    end

    DebugPrint("Sheath handler executing...")

    ---@alias KEEP_SHEATED string: Whether to keep the weapon sheathed
    KEEP_SHEATED = "KEEP_SHEATED"
    ---@alias KEEP_UNSHEATED string: Whether to keep the weapon unsheathed
    KEEP_UNSHEATED = "KEEP_UNSHEATED"
    ---@alias SHEAT_TYPE
    ---| `KEEP_SHEATED`
    ---| `KEEP_UNSHEATED`

    -- https://www.curseforge.com/wow/addons/stay-sheathed-lite
    -- Whether to keep the weapon sheathed or unsheathed
    ---@param sheatType SHEAT_TYPE: Whether to keep the weapon sheathed (`KEEP_SHEATED`) or unsheathed (`KEEP_UNSHEATED`)
    ---@param meleeOrRanged? number: Whether to only apply to melee (1) or ranged (2) weapons (default: `nil` - both). Only applies to `KEEP_SHEATED`
    local function SheatHandler(sheatType, meleeOrRanged)
        local sheathState = GetSheathState() -- Returns which type of weapon the player currently has unsheathed. (1 - none, 2 - melee, 3 - ranged)

        DebugPrint("Current sheath state: " .. sheathState .. ", desired: " .. sheatType .. ", weapon filter: " .. tostring(meleeOrRanged))

        -- Get weapon info to determine weapon type
        local mainHandLink = GetInventoryItemLink("player", GetInventorySlotInfo("MAINHANDSLOT"))
        local weaponSubType = nil
        if mainHandLink then
            local _, _, _, _, _, _, itemSubType = C_Item.GetItemInfo(mainHandLink)
            weaponSubType = itemSubType
            DebugPrint("Weapon subtype: " .. tostring(weaponSubType))
        end

        if sheatType == KEEP_SHEATED and (sheathState == 2 or sheathState == 3) then
            if meleeOrRanged == 1 and sheathState == 2 then
                DebugPrint("Sheathing melee weapon")
                ToggleSheath()
            elseif meleeOrRanged == 2 and sheathState == 3 then
                DebugPrint("Sheathing ranged weapon")
                ToggleSheath()
            end
        elseif sheatType == KEEP_UNSHEATED and sheathState == 1 then
            if meleeOrRanged == 1 then
                -- Only unsheath if it's a melee weapon
                if weaponSubType and meleeWeaponTypes[weaponSubType] then
                    DebugPrint("Unsheathing melee weapon: " .. weaponSubType)
                    ToggleSheath()
                else
                    DebugPrint("Skipping unsheath - not a melee weapon: " .. tostring(weaponSubType))
                end
            elseif meleeOrRanged == 2 then
                -- Only unsheath if it's a ranged weapon
                if weaponSubType and rangedWeaponTypes[weaponSubType] then
                    DebugPrint("Unsheathing ranged weapon: " .. weaponSubType)
                    ToggleSheath()
                else
                    DebugPrint("Skipping unsheath - not a ranged weapon: " .. tostring(weaponSubType))
                end
            end
        end
    end

    -- Get settings from database
    local sheatType = self.db.profile.sheath.mode
    local meleeOrRanged = nil
    if self.db.profile.sheath.meleeOnly then
        meleeOrRanged = 1
    elseif self.db.profile.sheath.rangedOnly then
        meleeOrRanged = 2
    end

    SheatHandler(sheatType, meleeOrRanged)
end
