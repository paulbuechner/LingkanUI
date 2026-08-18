local ADDON_NAME, LingkanUI = ...

-- ------------------------------------------------------------------------------------
-- Chat bubble font size.
--
-- There is no CVar for this -- chatBubbles and chatBubblesParty only switch bubbles on
-- and off. Which lever actually works depends on what is drawing the bubbles:
--
--   nBubble draws its own bubble frames and styles them from nBubbleDB on every bubble
--   it processes, so setting nBubbleDB.fontSize is picked up by the next bubble with no
--   refresh call. While nBubble is loaded, the ChatBubbleFont object below is not what
--   you are looking at.
--
--   Otherwise bubbles use Blizzard's ChatBubbleFont object, which ElvUI also manages
--   (General > Cosmetic > Chat Bubbles) and re-applies from E:UpdateBlizzardFonts().
--
-- Both are driven here so the setting behaves the same either way. Blizzard's own bubble
-- FontStrings are deliberately never touched: on 12.x calling SetFont on them makes the
-- text render as "...", which is why nBubble builds its own frames in the first place.
-- ------------------------------------------------------------------------------------

LingkanUI.ChatBubbles = {}
local ChatBubbles = LingkanUI.ChatBubbles

local MODULE_NAME = "chatBubbles"

local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

ChatBubbles.MIN_SIZE, ChatBubbles.MAX_SIZE = 6, 32

-- Values as they were before we first touched them, so turning the module off hands them
-- back rather than leaving our numbers behind
local original = {}

local function Settings()
    return LingkanUI.db and LingkanUI.db.profile.chatBubbles
end

-- True when nBubble is drawing the bubbles, in which case it owns their appearance
function ChatBubbles:UsingNBubble()
    return type(_G.nBubbleDB) == "table"
end

local function ApplyToNBubble(db, restore)
    local bubbleDB = _G.nBubbleDB
    if type(bubbleDB) ~= "table" then return end

    if original.nbFontSize == nil then original.nbFontSize = bubbleDB.fontSize or false end
    if original.nbSenderSize == nil then original.nbSenderSize = bubbleDB.senderFontSize or false end

    if restore then
        if original.nbFontSize then bubbleDB.fontSize = original.nbFontSize end
        if original.nbSenderSize then bubbleDB.senderFontSize = original.nbSenderSize end
        return
    end

    bubbleDB.fontSize = db.fontSize
    bubbleDB.senderFontSize = db.senderFontSize
end

local function ApplyToFontObject(db, restore)
    local fontObject = _G.ChatBubbleFont
    if not fontObject then return end

    local path, size, flags = fontObject:GetFont()
    if not path then return end

    if original.fontSize == nil then original.fontSize = size or false end

    if restore then
        if original.fontSize then fontObject:SetFont(path, original.fontSize, flags) end
        return
    end

    -- Only the size changes; the face and outline stay whatever Blizzard or ElvUI chose
    fontObject:SetFont(path, db.fontSize, flags)
end

function ChatBubbles:ApplyFontSizes()
    local db = Settings()
    if not db then return end

    if db.enabled then
        DebugPrint(("Applying bubble font sizes: %s / %s (nBubble=%s)"):format(
            db.fontSize, db.senderFontSize, tostring(self:UsingNBubble())))
        ApplyToNBubble(db, false)
        ApplyToFontObject(db, false)
    else
        ApplyToNBubble(db, true)
        ApplyToFontObject(db, true)
    end
end

-- ------------------------------------------------------------------------------------
-- Load
-- ------------------------------------------------------------------------------------

local elvuiHooked = false

function ChatBubbles:Load()
    DebugPrint("Loading module")

    self:ApplyFontSizes()

    -- ElvUI owns ChatBubbleFont and re-applies it on login, profile switches and any
    -- font change, which would otherwise quietly undo our size
    if not elvuiHooked and _G.ElvUI then
        local E = unpack(_G.ElvUI)
        if E and E.UpdateBlizzardFonts then
            elvuiHooked = true
            hooksecurefunc(E, "UpdateBlizzardFonts", function()
                ChatBubbles:ApplyFontSizes()
            end)
            DebugPrint("Hooked ElvUI UpdateBlizzardFonts")
        end
    end
end

function ChatBubbles:Unload()
    local db = Settings()
    if not db then return end

    ApplyToNBubble(db, true)
    ApplyToFontObject(db, true)
end
