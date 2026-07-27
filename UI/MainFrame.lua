local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local WHITE8X8 = [[Interface\Buttons\WHITE8X8]]
local LOGO = [[Interface\AddOns\LingkanUI\Core\Media\Textures\LogoAddon]]

-- ------------------------------------------------------------------------------------
-- Main configuration window
-- ------------------------------------------------------------------------------------

local MainWindow = CreateFrame("Frame", "LingkanUI_MainFrame", UIParent, "BackdropTemplate")
MainWindow:SetSize(950, 650)
MainWindow:SetPoint("CENTER")
MainWindow:SetFrameStrata("HIGH")
MainWindow:SetMovable(true)
MainWindow:SetResizable(true)
-- SetResizeBounds is Dragonflight+; the classic flavors in this TOC still use the
-- older SetMinResize/SetMaxResize pair.
if MainWindow.SetResizeBounds then
    MainWindow:SetResizeBounds(720, 420, 1600, 1000)
else
    if MainWindow.SetMinResize then MainWindow:SetMinResize(720, 420) end
    if MainWindow.SetMaxResize then MainWindow:SetMaxResize(1600, 1000) end
end
MainWindow:EnableMouse(true)
MainWindow:RegisterForDrag("LeftButton")
MainWindow:Hide()

MainWindow:SetBackdrop({
    bgFile = WHITE8X8,
    edgeFile = WHITE8X8,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
MainWindow:SetBackdropColor(C.BG_DARK.r, C.BG_DARK.g, C.BG_DARK.b, 0.95)
MainWindow:SetBackdropBorderColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.7)

-- Keeps at least a corner of the window on screen after a drag
local function ClampToScreen(frame)
    local width, height = frame:GetSize()
    local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
    local minVisibleX, minVisibleY = width * 0.10, height * 0.10

    local left, right = frame:GetLeft(), frame:GetRight()
    local top, bottom = frame:GetTop(), frame:GetBottom()
    if not (left and right and top and bottom) then return end

    local clampedLeft, clampedTop, needsClamp = left, top, false

    if right < minVisibleX then
        clampedLeft, needsClamp = minVisibleX - width, true
    elseif left > screenWidth - minVisibleX then
        clampedLeft, needsClamp = screenWidth - minVisibleX, true
    end

    if top < minVisibleY then
        clampedTop, needsClamp = minVisibleY, true
    elseif bottom > screenHeight - minVisibleY then
        clampedTop, needsClamp = screenHeight - minVisibleY + height, true
    end

    if needsClamp then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", clampedLeft, clampedTop)
    end
end

MainWindow:SetScript("OnDragStart", MainWindow.StartMoving)
MainWindow:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    ClampToScreen(self)
end)
MainWindow:SetScript("OnShow", function(self) ClampToScreen(self) end)

tinsert(UISpecialFrames, MainWindow:GetName())

local TopAccent = MainWindow:CreateTexture(nil, "OVERLAY")
TopAccent:SetHeight(3)
TopAccent:SetPoint("TOPLEFT", 1, -1)
TopAccent:SetPoint("TOPRIGHT", -1, -1)
TopAccent:SetColorTexture(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)

local BottomAccent = MainWindow:CreateTexture(nil, "OVERLAY")
BottomAccent:SetHeight(2)
BottomAccent:SetPoint("BOTTOMLEFT", 1, 1)
BottomAccent:SetPoint("BOTTOMRIGHT", -1, 1)
BottomAccent:SetColorTexture(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.7)

local CloseButton = CreateFrame("Button", nil, MainWindow, "UIPanelCloseButton")
CloseButton:SetPoint("TOPRIGHT", -3, -3)
CloseButton:SetSize(32, 32)

local ResizeHandle = CreateFrame("Button", nil, MainWindow)
ResizeHandle:SetSize(16, 16)
ResizeHandle:SetPoint("BOTTOMRIGHT", -2, 2)
ResizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
ResizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
ResizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
ResizeHandle:SetScript("OnMouseDown", function() MainWindow:StartSizing("BOTTOMRIGHT") end)
ResizeHandle:SetScript("OnMouseUp", function() MainWindow:StopMovingOrSizing() end)

-- ------------------------------------------------------------------------------------
-- Content area
-- ------------------------------------------------------------------------------------

local ContentArea = CreateFrame("Frame", nil, MainWindow, "BackdropTemplate")
ContentArea:SetPoint("TOPLEFT", 202, -5)
ContentArea:SetPoint("BOTTOMRIGHT", -2, 2)
ContentArea:SetBackdrop({
    bgFile = WHITE8X8,
    edgeFile = WHITE8X8,
    edgeSize = 1,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
ContentArea:SetBackdropColor(0, 0, 0, 0.3)
ContentArea:SetBackdropBorderColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.35)

MainWindow.Content = ContentArea

-- Hides every cached page. Pages are rebuilt lazily by their Init function.
function MainWindow:ResetContent()
    for _, child in ipairs({ ContentArea:GetChildren() }) do
        child:Hide()
    end
    for _, region in ipairs({ ContentArea:GetRegions() }) do
        if region.Hide then region:Hide() end
    end
end

LingkanUI.MainFrame = MainWindow

-- ------------------------------------------------------------------------------------
-- Reload prompt
--
-- Some options (module enable/disable) install hooksecurefunc hooks that cannot be
-- undone at runtime, so they need a reload. This replaces the old StaticPopup staging
-- system with an inline bar.
-- ------------------------------------------------------------------------------------

local ReloadBar = CreateFrame("Frame", nil, MainWindow, "BackdropTemplate")
ReloadBar:SetHeight(30)
ReloadBar:SetPoint("BOTTOMLEFT", ContentArea, "BOTTOMLEFT", 4, 4)
ReloadBar:SetPoint("BOTTOMRIGHT", ContentArea, "BOTTOMRIGHT", -4, 4)
ReloadBar:SetFrameLevel(ContentArea:GetFrameLevel() + 30)
ReloadBar:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
ReloadBar:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.15)
ReloadBar:SetBackdropBorderColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.7)
ReloadBar:Hide()

local ReloadText = ReloadBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ReloadText:SetPoint("LEFT", 10, 0)
ReloadText:SetText("Some changes need a UI reload to take effect.")
ReloadText:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)

local ReloadButton = CreateFrame("Button", nil, ReloadBar, "BackdropTemplate")
ReloadButton:SetSize(110, 20)
ReloadButton:SetPoint("RIGHT", -8, 0)
ReloadButton:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
ReloadButton:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.3)
ReloadButton:SetBackdropBorderColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.9)
ReloadButton:SetScript("OnClick", ReloadUI)

local ReloadButtonText = ReloadButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ReloadButtonText:SetPoint("CENTER")
ReloadButtonText:SetText(_G.RELOADUI or "Reload UI")

-- Called by config pages after changing an option that needs a reload
function LingkanUI:RequestReload()
    ReloadBar:Show()
end

-- ------------------------------------------------------------------------------------
-- Search
-- ------------------------------------------------------------------------------------

local SEARCH_ROW_HEIGHT, SEARCH_MAX_RESULTS = 22, 8

local SearchBox = CreateFrame("EditBox", nil, MainWindow, "BackdropTemplate")
SearchBox:SetSize(170, 24)
SearchBox:SetPoint("TOPRIGHT", MainWindow, "TOPRIGHT", -40, -10)
SearchBox:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
SearchBox:SetBackdropColor(C.BG_PANEL.r, C.BG_PANEL.g, C.BG_PANEL.b, 0.95)
SearchBox:SetBackdropBorderColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.5)
SearchBox:SetFontObject("GameFontHighlightSmall")
SearchBox:SetTextInsets(22, 6, 0, 0)
SearchBox:SetAutoFocus(false)
SearchBox:SetMaxLetters(50)

local SearchIcon = SearchBox:CreateTexture(nil, "OVERLAY")
SearchIcon:SetSize(13, 13)
SearchIcon:SetPoint("LEFT", 5, 0)
SearchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
SearchIcon:SetVertexColor(0.6, 0.6, 0.6, 0.9)

local SearchPlaceholder = SearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
SearchPlaceholder:SetPoint("LEFT", 22, 0)
SearchPlaceholder:SetPoint("RIGHT", -6, 0)
SearchPlaceholder:SetJustifyH("LEFT")
SearchPlaceholder:SetText("Search")

local SearchResults = CreateFrame("Frame", nil, MainWindow, "BackdropTemplate")
SearchResults:SetWidth(220)
SearchResults:SetPoint("TOPRIGHT", SearchBox, "BOTTOMRIGHT", 0, -2)
SearchResults:SetFrameStrata("DIALOG")
SearchResults:SetFrameLevel(300)
SearchResults:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
SearchResults:SetBackdropColor(C.BG_PANEL.r, C.BG_PANEL.g, C.BG_PANEL.b, 0.98)
SearchResults:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.6)
SearchResults:Hide()

local searchRows = {}

local function GetSearchRow(index)
    if searchRows[index] then return searchRows[index] end

    local row = CreateFrame("Button", nil, SearchResults, "BackdropTemplate")
    row:SetSize(218, SEARCH_ROW_HEIGHT - 2)
    row:SetPoint("TOPLEFT", 1, -((index - 1) * SEARCH_ROW_HEIGHT) - 1)
    row:SetBackdrop({ bgFile = WHITE8X8 })
    row:SetBackdropColor(0, 0, 0, 0)

    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 8, 0)
    text:SetPoint("RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    row.text = text

    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.2)
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0, 0, 0, 0)
    end)

    searchRows[index] = row
    return row
end

local function ClearSearchRows()
    for _, row in ipairs(searchRows) do row:Hide() end
end

local function RunSearch(query)
    ClearSearchRows()

    if not query or strtrim(query) == "" then
        SearchResults:Hide()
        return
    end

    query = strlower(strtrim(query))

    local registry = LingkanUI.MODULE_REGISTRY
    local keywords = LingkanUI.MODULE_KEYWORDS
    if not registry then
        SearchResults:Hide()
        return
    end

    local seen, count = {}, 0

    -- Direct name matches first
    for _, entry in ipairs(registry) do
        if count >= SEARCH_MAX_RESULTS then break end
        if not seen[entry.db] and strlower(entry.name):find(query, 1, true) then
            seen[entry.db] = true
            count = count + 1
            local row = GetSearchRow(count)
            row.text:SetText("|cff" .. C.ORANGE_HEX .. "\194\187|r " .. entry.name)
            row:SetScript("OnClick", function()
                SearchBox:SetText("")
                SearchResults:Hide()
                LingkanUI:OpenTab(entry.tab)
            end)
            row:Show()
        end
    end

    -- Then keyword matches, annotated with the term that matched
    for _, entry in ipairs(registry) do
        if count >= SEARCH_MAX_RESULTS then break end
        local entryKeywords = keywords and keywords[entry.db]
        if not seen[entry.db] and entryKeywords then
            for _, keyword in ipairs(entryKeywords) do
                if strlower(keyword):find(query, 1, true) then
                    seen[entry.db] = true
                    count = count + 1
                    local row = GetSearchRow(count)
                    row.text:SetText("|cff" .. C.ORANGE_HEX .. "\194\187|r " .. entry.name ..
                        " |cff" .. C.DIM_HEX .. "\226\128\186 " .. keyword .. "|r")
                    row:SetScript("OnClick", function()
                        SearchBox:SetText("")
                        SearchResults:Hide()
                        LingkanUI:OpenTab(entry.tab)
                    end)
                    row:Show()
                    break
                end
            end
        end
    end

    if count == 0 then
        local row = GetSearchRow(1)
        row.text:SetText("|cff" .. C.DIM_HEX .. "No results found.|r")
        row:SetScript("OnClick", nil)
        row:Show()
        count = 1
    end

    SearchResults:SetHeight(count * SEARCH_ROW_HEIGHT + 2)
    SearchResults:Show()
end

SearchBox:SetScript("OnEditFocusGained", function(self)
    SearchPlaceholder:Hide()
    SearchIcon:Hide()
    self:SetTextInsets(6, 6, 0, 0)
    self:SetBackdropBorderColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.9)
    if self:GetText() ~= "" then RunSearch(self:GetText()) end
end)

SearchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then
        SearchPlaceholder:Show()
        SearchIcon:Show()
        self:SetTextInsets(22, 6, 0, 0)
    end
    self:SetBackdropBorderColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.5)
    C_Timer.After(0.15, function()
        if not SearchBox:HasFocus() then SearchResults:Hide() end
    end)
end)

SearchBox:SetScript("OnTextChanged", function(self) RunSearch(self:GetText()) end)
SearchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
SearchBox:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    SearchResults:Hide()
    self:ClearFocus()
end)

-- ------------------------------------------------------------------------------------
-- Public entry points
-- ------------------------------------------------------------------------------------

function LingkanUI:ToggleConfig()
    if MainWindow:IsShown() then
        MainWindow:Hide()
        return
    end

    MainWindow:Show()
    MainWindow:ResetContent()

    local lastTab = LingkanUI.db and LingkanUI.db.profile.config
        and LingkanUI.db.profile.config.lastTab

    if lastTab and LingkanUI.OpenTab then
        LingkanUI:OpenTab(lastTab)
    elseif LingkanUI.InitHome then
        LingkanUI:InitHome()
    end
end

-- ------------------------------------------------------------------------------------
-- Blizzard settings stub: a single button that opens the real window
-- ------------------------------------------------------------------------------------

do
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local panel = CreateFrame("Frame")
        panel.name = "LingkanUI"

        local background = panel:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(C.BG_DARK.r, C.BG_DARK.g, C.BG_DARK.b, 0.6)

        local icon = panel:CreateTexture(nil, "ARTWORK")
        icon:SetSize(64, 64)
        icon:SetPoint("TOP", 0, -40)
        icon:SetTexture(LOGO)

        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", icon, "BOTTOM", 0, -12)
        title:SetText(LingkanUI.TITLE)

        local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        subtitle:SetPoint("TOP", title, "BOTTOM", 0, -6)
        subtitle:SetText("Personal UI suite and quality of life tweaks")

        local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        openButton:SetSize(180, 32)
        openButton:SetPoint("TOP", subtitle, "BOTTOM", 0, -20)
        openButton:SetText("Open LingkanUI")
        openButton:SetScript("OnClick", function()
            -- Deferred so the Blizzard settings frame can close first
            C_Timer.After(0, function() LingkanUI:ToggleConfig() end)
        end)

        local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        hint:SetPoint("TOP", openButton, "BOTTOM", 0, -10)
        hint:SetText("or type  /lui  in chat")

        local category = Settings.RegisterCanvasLayoutCategory(panel, "LingkanUI")
        category.ID = "LingkanUI"
        Settings.RegisterAddOnCategory(category)

        LingkanUI.settingsCategory = category
    end
end
