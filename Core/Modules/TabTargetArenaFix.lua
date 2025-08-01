local _, LingkanUI = ...

-- Create the TabTargetArenaFix module
LingkanUI.TabTargetArenaFix = {}

-- Module name for debug output
local MODULE_NAME = "Tab Target Arena Fix"

-- Module-specific debug function
local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

local function TabTargetArenaFix()
    -- Check if TabTargetArenaFix is enabled
    if not LingkanUI.db.profile.tabTargetArenaFix.enabled then
        DebugPrint("TabTargetArenaFix called but feature is disabled")
        return
    end

    DebugPrint("TabTargetArenaFix executing...")

    -- https://www.curseforge.com/wow/addons/tabtargetarenafix
    -- Fix the tab targeting in PVP to only target enemy players to avoid accidentally targeting pets, totems, etc.

    if select(2, IsInInstance()) == "arena" then
        SetBinding("TAB", "TARGETNEARESTENEMYPLAYER")
        if LingkanUI.db.profile.tabTargetArenaFix.showMessages then
            LingkanUI:Print("Tab targetting is now set to target enemy players in arenas.")
        end
        DebugPrint("Set tab targeting to TARGETNEARESTENEMYPLAYER (arena)")
    else
        SetBinding("TAB", "TARGETNEARESTENEMY")
        if LingkanUI.db.profile.tabTargetArenaFix.showMessages then
            LingkanUI:Print("Tab targetting is now set to target enemy units.")
        end
        DebugPrint("Set tab targeting to TARGETNEARESTENEMY (non-arena)")
    end
end

function LingkanUI.TabTargetArenaFix:EnableTabTargetArenaFix()
    LingkanUI:RegisterEvent("PLAYER_ENTERING_WORLD", function() TabTargetArenaFix() end)

    -- Apply immediately if already in game
    if IsLoggedIn() then
        TabTargetArenaFix()
    end
end

function LingkanUI.TabTargetArenaFix:DisableTabTargetArenaFix()
    -- Reset to default tab targeting behavior
    SetBinding("TAB", "TARGETNEARESTENEMY")
    DebugPrint("Reset tab targeting to default behavior")
end
