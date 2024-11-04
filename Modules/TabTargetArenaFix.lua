local _, LingkanUI = ...

local function TabTargetArenaFix()
    -- https://www.curseforge.com/wow/addons/tabtargetarenafix
    -- Fix the tab targeting in PVP to only target enemy players to avoid accidentally targeting pets, totems, etc.

    if select(2, IsInInstance()) == "arena" then
        SetBinding("TAB", "TARGETNEARESTENEMYPLAYER"); LingkanUI:Print("Tab targetting is now set to target enemy players in arenas.")
    else
        SetBinding("TAB", "TARGETNEARESTENEMY"); LingkanUI:Print("Tab targetting is now set to target enemy units.")
    end
end

function LingkanUI.LoadTabTargetArenaFix()
    LingkanUI:RegisterEvent("PLAYER_ENTERING_WORLD", function() TabTargetArenaFix() end)
end
