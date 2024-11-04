local ADDON_NAME, LingkanUI = ...

LingkanUI = LibStub("AceAddon-3.0"):NewAddon(LingkanUI, "LingkanUI", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

-- ---------------------------------------- Globals ----------------------------------------

local WoW10 = select(4, GetBuildInfo()) >= 100000

-- ------------------------------------------ Main -----------------------------------------

function LingkanUI.OnInitialize()
    -- Console
    SetConsoleKey("*") -- https://wowpedia.fandom.com/wiki/Console

    -- CVars (https://wowpedia.fandom.com/wiki/Console_variables)
    SetCVar("CameraReduceUnexpectedMovement", 1)
    -- SetCVar("RenderScale", 0.999)       -- https://www.reddit.com/r/wow/comments/z69guk/quick_tip_to_make_the_new_dragonflight_zones_look/
    SetCVar("ResampleAlwaysSharpen", 1) -- https://www.reddit.com/r/wow/comments/z69guk/quick_tip_to_make_the_new_dragonflight_zones_look/

    -- Resize Extra Action Button
    ExtraActionButton1:SetScale(0.8)

    -- Reanchor EndCaps Example
    -- MainMenuBar.EndCaps.RightEndCap:ClearAllPoints()
    -- MainMenuBar.EndCaps.RightEndCap:SetPoint("BOTTOMLEFT", MainMenuBar, "BOTTOMRIGHT", 412, -22)

    -- Modules
    LingkanUI.LoadTabTargetArenaFix()

    LingkanUI:Print("Initialized successfully!")
end

--------------------------------------- ADDON_LOADED ---------------------------------------

-- function LingkanUI:ADDON_LOADED(event, addon)
--     if addon == ADDON_NAME then
--         -- ...
--     end
-- end

-- LingkanUI:RegisterEvent("ADDON_LOADED")

--------------------------------------- Customizing ---------------------------------------

function LingkanUI:CustomizingHandler()
    -- Bartender4
    -- LingkanUI.Customizing.LoadBartender4() -- Currently handled via "Gryphons and Wyverns" WA -> Actions -> On Init

    -- ElvUI
end

LingkanUI:RegisterEvent("PLAYER_ENTERING_WORLD", "CustomizingHandler")

--------------------------------------- SheatHandler ---------------------------------------

function LingkanUI:SheatHandler()
    ---@alias KEEP_SHEATED string: Whether to keep the weapon sheathed
    KEEP_SHEATED = "KEEP_SHEATED"
    ---@alias KEEP_UNSHEATED string: Whether to keep the weapon unsheathed
    KEEP_UNSHEATED = "KEEP_UNSHEATED"
    ---@alias SHEAT_TYPE
    ---| `KEEP_SHEATED`
    ---| `KEEP_UNSHEATED`

    -- https://www.curseforge.com/wow/addons/stay-sheathed-lite
    -- Wheather to keep the weapon sheathed or unsheathed
    ---@param sheatType SHEAT_TYPE: Whether to keep the weapon sheathed (`KEEP_SHEATED`) or unsheathed (`KEEP_UNSHEATED`)
    ---@param meleeOrRanged? number: Whether to only apply to melee (1) or ranged (2) weapons (default: `nil` - both). Only applies to `KEEP_SHEATED`
    local function SheatHandler(sheatType, meleeOrRanged)
        --[[ --this will be for later, rework planned soon(tm)
        local  class1, class2, class3 = UnitClass("player")
        if class2 == "MONK" then
            return
        end
        ]]

        -- Variable guard
        if (sheatType ~= KEEP_SHEATED and sheatType ~= KEEP_UNSHEATED) or
            (meleeOrRanged ~= nil and meleeOrRanged ~= 1 and meleeOrRanged ~= 2) then
            LingkanUI:Print("Invalid arguments for SheatHandler")
            return
        end

        local sheathState = GetSheathState() -- Returns which type of weapon the player currently has unsheathed. (1 - none, 2 - melee, 3 - ranged)
        if sheatType == KEEP_SHEATED and (sheathState == 2 or sheathState == 3) and
            (meleeOrRanged == nil or sheathState == meleeOrRanged + 1) then
            ToggleSheath()
        elseif sheatType == KEEP_UNSHEATED and sheathState == 1 then
            ToggleSheath()
        end
    end

    C_Timer.After(10, function()
        SheatHandler(KEEP_UNSHEATED)
    end)
end

-- LingkanUI:RegisterEvent("UNIT_TARGET", "SheatHandler")
-- LingkanUI:RegisterEvent("UNIT_MODEL_CHANGED", "SheatHandler")

--------------------------------------- ResizeWardrobe ---------------------------------------

function LingkanUI:ResizeWardrobeHandler()
    -- https://github.com/eSkiSo/TransmogrifyResize
    if CollectionsJournal ~= nil then
        CollectionsJournal:SetWidth(750);
        CollectionsJournal:SetHeight(600);

        -- CollectionsJournal:ClearAllPoints();
        -- CollectionsJournal:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    end

    WardrobeFrame:SetUserPlaced(true);
end

if WoW10 then
    -- LingkanUI:RegisterEvent("TRANSMOG_SEARCH_UPDATED", "ResizeWardrobeHandler")
end
