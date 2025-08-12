local ADDON_NAME, LingkanUI = ...

-- Create the Leaning module
LingkanUI.Leaning = {}

-- Module name for debug output
local MODULE_NAME = "leaning"

-- Module-specific debug function
local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

--------------------------------------- LeanHandler ---------------------------------------

function LingkanUI.Leaning:Load()
    LingkanUI:RegisterEvent("PLAYER_ENTERING_WORLD", "LeanHandler")
    LingkanUI:RegisterEvent("UNIT_TARGET", "LeanHandler")
    LingkanUI:RegisterEvent("UNIT_MODEL_CHANGED", "LeanHandler")

    -- Apply lean setting immediately
    C_Timer.After(1, function()
        LingkanUI:LeanHandler()
    end)
end

function LingkanUI.Leaning:Unload()
    LingkanUI:UnregisterEvent("PLAYER_ENTERING_WORLD")
    LingkanUI:UnregisterEvent("UNIT_TARGET")
    LingkanUI:UnregisterEvent("UNIT_MODEL_CHANGED")
end

function LingkanUI:LeanHandler()
    -- Check if lean control is enabled
    if not self.db.profile.lean.enabled then
        DebugPrint("Lean handler called but lean control is disabled")
        return
    end

    DebugPrint("Lean handler executing...")

    -- Get current character name and whisper /lean command to self
    DebugPrint("Executing /lean command")
    DoEmote("LEAN", "none")
end
