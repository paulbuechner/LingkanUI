local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

function LingkanUI:InitChatBubbles()
    local parent = LingkanUI.MainFrame.Content
    local db = LingkanUI.db.profile.chatBubbles
    local ChatBubbles = LingkanUI.ChatBubbles

    local function IsOff() return not db.enabled end
    local function Apply() ChatBubbles:ApplyFontSizes() end

    W:CachedPanel(cache, "chatBubbles", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 460)

        W:CreatePageHeader(content,
            { { "CHAT ", C.BLUE }, { "BUBBLES", C.ORANGE } },
            "Size of the text in speech bubbles above characters.")

        W:CreateCheckbox(content, {
            label = "Override Bubble Font Size",
            desc = "Take control of the chat bubble text size. Turning this off restores " ..
                "whatever the sizes were before.",
            db = db, key = "enabled",
            x = 14, y = -84,
            isMaster = true,
            onChange = Apply,
        })

        W:CreateSlider(content, {
            label = "Message Size",
            desc = "Font size of the message text inside the bubble.",
            db = db, key = "fontSize",
            min = ChatBubbles.MIN_SIZE, max = ChatBubbles.MAX_SIZE, step = 1,
            x = 14, y = -120,
            width = 260,
            disabled = IsOff,
            onChange = Apply,
        })

        W:CreateSlider(content, {
            label = "Sender Name Size",
            desc = "Font size of the sender's name. Only nBubble draws a separate name line.",
            db = db, key = "senderFontSize",
            min = ChatBubbles.MIN_SIZE, max = ChatBubbles.MAX_SIZE, step = 1,
            x = 14, y = -176,
            width = 260,
            disabled = function() return IsOff() or not ChatBubbles:UsingNBubble() end,
            onChange = Apply,
        })

        W:CreateSeparator(content, 10, -234)

        local status = W:CreateLabel(content, "", { x = 14, y = -250 })

        local function UpdateStatus()
            if ChatBubbles:UsingNBubble() then
                status:SetText("|cff" .. C.GREEN_HEX .. "nBubble is drawing the bubbles|r |cff" ..
                    C.DIM_HEX .. "- the size is written to its settings and applies to the next bubble.|r")
            else
                status:SetText("|cff" .. C.BLUE_HEX .. "Using Blizzard's ChatBubbleFont|r |cff" ..
                    C.DIM_HEX .. "- shared with ElvUI's Chat Bubbles font setting.|r")
            end
        end

        panel:HookScript("OnShow", UpdateStatus)
        UpdateStatus()

        W:CreateLabel(content,
            "There is no console variable for this. chatBubbles and chatBubblesParty only " ..
            "turn bubbles on and off, so the size has to be set on whichever addon is " ..
            "drawing them - this does that for you.",
            { x = 14, y = -280, color = C.DIM })

        W:CreateLabel(content,
            "While this is enabled it owns the setting: changing the size in nBubble's or " ..
            "ElvUI's own options will be overwritten.",
            { x = 14, y = -336, color = C.DIM })
    end)
end
