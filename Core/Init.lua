local ADDON_NAME, LingkanUI = ...

-- ------------------------------------------------------------------------------------
-- Module registry
--
-- Single source of truth for the config search index. `db` is the profile key,
-- `tab` is the sidebar tab opened when a search result is clicked.
-- ------------------------------------------------------------------------------------

LingkanUI.MODULE_REGISTRY = {
    { db = "general",              tab = "general",         name = "General" },
    { db = "interface",            tab = "unit_indicators", name = "Unit Indicators" },
    { db = "betterCharacterPanel", tab = "character_panel", name = "Character Panel" },
    { db = "roleIcons",            tab = "role_icons",      name = "Role Icons" },
    { db = "zoneText",             tab = "zone_text",       name = "Zone Text" },
    { db = "sheath",               tab = "sheathing",       name = "Sheathing" },
    { db = "lean",                 tab = "leaning",         name = "Leaning" },
    { db = "tabTargetArenaFix",    tab = "tab_target",      name = "Tab Target Arena Fix" },
    { db = "naowhUI",              tab = "addon_tweaks",    name = "Addon Tweaks" },
    { db = "profiles",             tab = "profiles",        name = "Profiles" },
    { db = "installer",            tab = "installer",       name = "Installer" },
}

-- Extra search terms per module, so searching "health" finds Unit Indicators etc.
LingkanUI.MODULE_KEYWORDS = {
    general              = { "developer", "debug", "ui errors" },
    interface            = { "health", "percent", "indicator", "player", "target", "font", "offset" },
    betterCharacterPanel = { "item level", "ilvl", "enchant", "socket", "gem", "durability", "scale" },
    roleIcons            = { "role", "tank", "healer", "damage", "raid", "chat", "class icon" },
    zoneText             = { "zone", "subzone", "area", "font size", "announcement", "text size" },
    sheath               = { "weapon", "sheath", "unsheath", "melee", "ranged" },
    lean                 = { "lean", "emote", "idle" },
    tabTargetArenaFix    = { "tab", "target", "arena", "pvp", "keybind" },
    naowhUI              = { "damage meter", "details", "opacity", "background", "naowh",
                             "ellesmere", "dark mode", "transparency" },
    profiles             = { "import", "export", "profile", "share", "backup" },
    installer            = { "install", "setup", "elvui", "profile setup" },
}

-- ------------------------------------------------------------------------------------
-- Lifecycle
-- ------------------------------------------------------------------------------------

-- Called from Core.lua once ADDON_LOADED has created the database
function LingkanUI:OnInitialize()
    LingkanUI.myname = UnitName("player")

    -- Console (https://wowpedia.fandom.com/wiki/Console)
    SetConsoleKey("*")

    -- CVars (https://wowpedia.fandom.com/wiki/Console_variables)
    SetCVar("CameraReduceUnexpectedMovement", 1)
    -- https://www.reddit.com/r/wow/comments/z69guk/quick_tip_to_make_the_new_dragonflight_zones_look/
    SetCVar("ResampleAlwaysSharpen", 1)

    -- Resize Extra Action Button
    if LingkanUI.Version.isRetail and _G.ExtraActionButton1 then
        _G.ExtraActionButton1:SetScale(0.8)
    end

    if LingkanUI.MinimapButton and LingkanUI.MinimapButton.Init then
        LingkanUI.MinimapButton:Init()
    end

    LingkanUI:Print("Initialized successfully!" ..
        (LingkanUI.db.profile.general.developerMode and " (Developer mode active)" or ""))
end

function LingkanUI:PLAYER_ENTERING_WORLD()
    -----------------------------------------------------
    --- Modules
    -----------------------------------------------------
    LingkanUI.Interface:Load()

    if self.db.profile.sheath.enabled then
        LingkanUI.Sheathing:Load()
    end

    if self.db.profile.tabTargetArenaFix.enabled then
        LingkanUI.TabTargetArenaFix:Load()
    end

    if self.db.profile.betterCharacterPanel.enabled then
        LingkanUI.BetterCharacterPanel:Load()
    end

    -- Panel scale is a plain display preference, so it applies even with the module off
    LingkanUI.BetterCharacterPanel:ApplyScale()

    -- Always loads: it hooks ElvUI's font pass and no-ops until the override is enabled
    LingkanUI.ZoneText:Load()

    -- RETAIL ONLY
    if LingkanUI.Version.isRetail then
        if self.db.profile.roleIcons.enabled then
            LingkanUI.RoleIcons:Load()
        end

        if self.db.profile.lean.enabled then
            LingkanUI.Leaning:Load()
        end
    end

    -----------------------------------------------------
    --- Customizing
    -----------------------------------------------------
    -- Bartender4
    -- LingkanUI.Customizing.LoadBartender4() -- Currently handled via "Gryphons and Wyverns" WA -> Actions -> On Init

    -- ElvUI

    -- AddOnSkins
    LingkanUI.Customizing.LoadAddOnSkins()

    -- NaowhUI (damage meter background opacity)
    LingkanUI.Customizing.LoadNaowhUI()
end

function LingkanUI:FIRST_FRAME_RENDERED()
    -- Refreshes the Remix flag, which needs a player aura and so cannot be resolved
    -- at file load time like the other version flags.
    LingkanUI.Version:Init()
end

LingkanUI:RegisterEvent("PLAYER_ENTERING_WORLD")
LingkanUI:RegisterEvent("FIRST_FRAME_RENDERED")
