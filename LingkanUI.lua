local ADDON_NAME, LingkanUI = ...

LingkanUI = LibStub("AceAddon-3.0"):NewAddon(LingkanUI, "LingkanUI", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

-- ---------------------------------------- Globals ----------------------------------------

local WoW10 = select(4, GetBuildInfo()) >= 100000

-- ---------------------------------------- Debug Functions ----------------------------------------

-- Debug print function that only prints when debug mode is enabled
function LingkanUI:DebugPrint(message, module)
    local debugEnabled = false

    if self.db and self.db.profile then
        if self.db.profile.general.developerMode then
            debugEnabled = true
        elseif module and self.db.profile[module] and self.db.profile[module].debug then
            debugEnabled = true
        end
    end

    if debugEnabled then
        local moduleTag = module and (" [" .. string.upper(module) .. "]") or ""
        self:Print("[DEBUG]" .. moduleTag .. " " .. tostring(message))
    end
end

-- ------------------------------------------ Main -----------------------------------------

function LingkanUI.OnInitialize()
    -- Initialize database
    LingkanUI.db = LibStub("AceDB-3.0"):New("LingkanUIDB", LingkanUI.defaults, true)

    -- Initialize debug mode from saved settings (keeping for backward compatibility)
    LingkanUI.debug = LingkanUI.db.profile.general.developerMode

    -- Register options with AceConfig
    LibStub("AceConfig-3.0"):RegisterOptionsTable("LingkanUI", LingkanUI.options)
    LingkanUI.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LingkanUI", "LingkanUI")

    -- Register slash command
    LingkanUI:RegisterChatCommand("lingkanui", "SlashCommand")
    LingkanUI:RegisterChatCommand("lui", "SlashCommand")

    -- Register debug commands if debug mode is enabled
    if LingkanUI.db.profile.general.developerMode then
        LingkanUI:RegisterDebugCommands()
    end

    -- Console
    SetConsoleKey("*") -- https://wowpedia.fandom.com/wiki/Console

    -- CVars (https://wowpedia.fandom.com/wiki/Console_variables)
    SetCVar("CameraReduceUnexpectedMovement", 1)
    -- SetCVar("RenderScale", 0.999)       -- https://www.reddit.com/r/wow/comments/z69guk/quick_tip_to_make_the_new_dragonflight_zones_look/
    SetCVar("ResampleAlwaysSharpen", 1) -- https://www.reddit.com/r/wow/comments/z69guk/quick_tip_to_make_the_new_dragonflight_zones_look/

    -- Resize Extra Action Button
    if WoW10 then ExtraActionButton1:SetScale(0.8) end

    -- Reanchor EndCaps Example
    -- MainMenuBar.EndCaps.RightEndCap:ClearAllPoints()
    -- MainMenuBar.EndCaps.RightEndCap:SetPoint("BOTTOMLEFT", MainMenuBar, "BOTTOMRIGHT", 412, -22)

    LingkanUI:Print("Initialized successfully!" .. (LingkanUI.db.profile.general.developerMode and " (Developer mode active)" or ""))
end

--------------------------------------- Slash Commands ---------------------------------------

function LingkanUI:SlashCommand(input)
    if not input or input:trim() == "" then
        -- Open options panel
        if WoW10 then
            -- Retail/Dragonflight and newer
            Settings.OpenToCategory("LingkanUI")
        else
            -- Classic versions - use AceConfigDialog directly
            LibStub("AceConfigDialog-3.0"):Open("LingkanUI")
        end
    else
        LingkanUI:Print("Usage: /lingkanui or /lui - Opens the options panel")
    end
end

--------------------------------------- Debug Commands ---------------------------------------

function LingkanUI:RegisterDebugCommands()
    self:RegisterChatCommand("debuginfo", "PrintDebugInfo")
end

function LingkanUI:UnregisterDebugCommands()
    self:UnregisterChatCommand("debuginfo")
end

function LingkanUI:PrintDebugInfo()
    self:Print("=== LingkanUI Debug Information ===")
    self:Print("WoW10: " .. tostring(WoW10))
    self:Print("Build: " .. tostring(select(4, GetBuildInfo())))
    self:Print("Developer mode: " .. tostring(self.db.profile.general.developerMode))
    self:Print("Database loaded: " .. tostring(self.db ~= nil))

    if self.db then
        self:Print("=== Modules ===")

        self:Print("Sheathing")
        self:Print("    enabled: " .. tostring(self.db.profile.sheath.enabled))
        self:Print("    mode: " .. tostring(self.db.profile.sheath.mode))
        self:Print("    debug: " .. tostring(self.db.profile.sheath.debug))

        self:Print("TabTargetArenaFix")
        self:Print("    enabled: " .. tostring(self.db.profile.tabTargetArenaFix.enabled))
        self:Print("    debug: " .. tostring(self.db.profile.tabTargetArenaFix.debug))

        if WoW10 then
            self:Print("RoleIcons")
            self:Print("    enabled: " .. tostring(self.db.profile.roleIcons.enabled))
            self:Print("    debug: " .. tostring(self.db.profile.roleIcons.debug))
        end
    end
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

    -- Initialize sheath handler if enabled
    if self.db.profile.sheath.enabled then
        LingkanUI.Sheathing:EnableSheathHandler()
    end

    -- Initialize TabTargetArenaFix if enabled
    if self.db.profile.tabTargetArenaFix.enabled then
        LingkanUI.TabTargetArenaFix:EnableTabTargetArenaFix()
    end

    -- Initialize RoleIcons if enabled (retail only)
    if WoW10 and self.db.profile.roleIcons.enabled then
        LingkanUI.RoleIcons:Enable()
    end
end

LingkanUI:RegisterEvent("PLAYER_ENTERING_WORLD", "CustomizingHandler")

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
