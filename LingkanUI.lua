local ADDON_NAME, LingkanUI = ...

LingkanUI = LibStub("AceAddon-3.0"):NewAddon(LingkanUI, "LingkanUI", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

-- ---------------------------------------- Debug Functions ----------------------------------------

-- Debug print function that only prints when debug mode is enabled
function LingkanUI:DebugPrint(message, module)
    if not (module and self.db and self.db.profile) then
        return
    end

    local debugEnabled = (self.db.profile[module] and self.db.profile[module].debug) or -- Module specific
        (self.db.profile.general[module] and self.db.profile.general[module].debug)     -- General Settings

    if debugEnabled then
        local moduleTag = module and (" [" .. string.upper(module) .. "]") or ""
        self:Print("[DEBUG]" .. moduleTag .. " " .. tostring(message))
    end
end

function LingkanUI:AddToInspector(data, strName)
    if DevTool and self.debug then
        DevTool:AddData(data, strName)
    end
end

-- ------------------------------------------ Main -----------------------------------------

function LingkanUI.OnInitialize()
    LingkanUI.myname = UnitName("player")

    -- Initialize database
    LingkanUI.db = LibStub("AceDB-3.0"):New("LingkanUIDB", LingkanUI.defaults, true)

    -- Register options with AceConfig
    LibStub("AceConfig-3.0"):RegisterOptionsTable("LingkanUI", LingkanUI.options)
    LingkanUI.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LingkanUI", "LingkanUI")

    -- Register slash command
    LingkanUI:RegisterChatCommand("lingkanui", "SlashCommand")
    LingkanUI:RegisterChatCommand("lui", "SlashCommand")

    -- Console
    SetConsoleKey("*") -- https://wowpedia.fandom.com/wiki/Console

    -- CVars (https://wowpedia.fandom.com/wiki/Console_variables)
    SetCVar("CameraReduceUnexpectedMovement", 1)
    -- SetCVar("RenderScale", 0.999)       -- https://www.reddit.com/r/wow/comments/z69guk/quick_tip_to_make_the_new_dragonflight_zones_look/
    SetCVar("ResampleAlwaysSharpen", 1) -- https://www.reddit.com/r/wow/comments/z69guk/quick_tip_to_make_the_new_dragonflight_zones_look/

    -- Resize Extra Action Button
    if LingkanUI.Version.isRetail then ExtraActionButton1:SetScale(0.8) end

    -- Reanchor EndCaps Example
    -- MainMenuBar.EndCaps.RightEndCap:ClearAllPoints()
    -- MainMenuBar.EndCaps.RightEndCap:SetPoint("BOTTOMLEFT", MainMenuBar, "BOTTOMRIGHT", 412, -22)

    LingkanUI:Print("Initialized successfully!" .. (LingkanUI.db.profile.general.developerMode and " (Developer mode active)" or ""))
end

--------------------------------------- Slash Commands ---------------------------------------

function LingkanUI:SlashCommand(input)
    input = input or ""
    input = input:trim()

    if input == "" then
        -- Open options panel
        if LingkanUI.Version.isRetail then
            -- Retail/Dragonflight and newer
            Settings.OpenToCategory(LingkanUI.optionsFrame.name)
        else
            -- Classic versions - use AceConfigDialog directly
            LibStub("AceConfigDialog-3.0"):Open("LingkanUI")
        end
    else
        local cmd = input:match("^(%S+)")
        cmd = cmd and cmd:lower() or ""

        if cmd == "install" then
            if LingkanUI.Installer and LingkanUI.Installer.Show then
                LingkanUI.Installer:Show()
            else
                LingkanUI:Print("Installer not loaded")
            end
            return
        end

        LingkanUI:Print("Usage:")
        LingkanUI:Print("  /lui - Opens the options panel")
        LingkanUI:Print("  /lui install - Opens the installer")
    end
end

------------------------------------------- Events -------------------------------------------

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
end

function LingkanUI:FIRST_FRAME_RENDERED()
    -- Initialize version detection
    -- NOTE: Remix Mode detection requires first frame rendered (buff check)
    LingkanUI.Version:Init()
end

LingkanUI:RegisterEvent("PLAYER_ENTERING_WORLD")
LingkanUI:RegisterEvent("FIRST_FRAME_RENDERED")
