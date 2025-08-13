local ADDON_NAME, LingkanUI = ...

-- Create the Leaning module
LingkanUI.Leaning = {}

-- Module name for debug output
local MODULE_NAME = "lean"

-- Module-specific debug function
local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

------------------------------------- Local Functions -------------------------------------

-- Movement tracking variables
local lastX, lastY = 0, 0
local movementTimer = nil
local stopTimer = nil

local function CheckMovement()
    if not LingkanUI.db.profile.lean.enabled then
        return
    end

    local x, y = UnitPosition("player")
    if not x or not y then
        return
    end

    -- Round to 2 decimal places for more reliable comparison
    x = math.floor(x * 100 + 0.5) / 100
    y = math.floor(y * 100 + 0.5) / 100

    DebugPrint("Player position is (" .. x .. ", " .. y .. "), last known position is (" .. lastX .. ", " .. lastY .. ")")
    DebugPrint("Difference: (" .. (x - lastX) .. ", " .. (y - lastY) .. ")")

    -- Check if position changed with tolerance
    local threshold = 0.1
    if math.abs(x - lastX) > threshold or math.abs(y - lastY) > threshold then
        -- Player moved, update position and reset stop timer
        lastX, lastY = x, y
        if stopTimer then
            stopTimer:Cancel()
            stopTimer = nil
        end
    else
        -- Player hasn't moved, start/continue stop timer
        if not stopTimer then
            stopTimer = C_Timer.NewTimer(0.21, function()
                LingkanUI:LeanHandler()
            end)
        end
    end
end

-- Local movement tracking functions
local function StartMovementTracking()
    -- Track player position every 0.1 seconds
    movementTimer = C_Timer.NewTicker(0.1, function()
        CheckMovement()
    end)
end

local function StopMovementTracking()
    if movementTimer then
        movementTimer:Cancel()
        movementTimer = nil
    end
    if stopTimer then
        stopTimer:Cancel()
        stopTimer = nil
    end
end


--------------------------------------- LeanHandler ---------------------------------------

function LingkanUI.Leaning:Load()
    -- Start movement tracking
    StartMovementTracking()
end

function LingkanUI.Leaning:Unload()
    -- Stop movement tracking
    StopMovementTracking()
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
