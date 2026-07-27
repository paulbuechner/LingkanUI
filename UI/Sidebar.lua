local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local WHITE8X8 = [[Interface\Buttons\WHITE8X8]]

local GROUP_HEIGHT, CHILD_HEIGHT = 34, 30
local HEADER_HEIGHT = 70

-- ------------------------------------------------------------------------------------
-- Sidebar container
-- ------------------------------------------------------------------------------------

local Sidebar = CreateFrame("Frame", "LingkanUI_Sidebar", LingkanUI.MainFrame, "BackdropTemplate")
Sidebar:SetWidth(200)
Sidebar:SetPoint("TOPLEFT", LingkanUI.MainFrame, "TOPLEFT", 1, -1)
Sidebar:SetPoint("BOTTOMLEFT", LingkanUI.MainFrame, "BOTTOMLEFT", 1, 1)
Sidebar:SetBackdrop({ bgFile = WHITE8X8 })
Sidebar:SetBackdropColor(C.BG_DARK.r, C.BG_DARK.g, C.BG_DARK.b, 1)

local Divider = Sidebar:CreateTexture(nil, "OVERLAY")
Divider:SetWidth(1)
Divider:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0, -HEADER_HEIGHT)
Divider:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", 0, 0)
Divider:SetColorTexture(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.4)

-- Header doubles as the "go home" button
local Header = CreateFrame("Button", nil, Sidebar, "BackdropTemplate")
Header:SetSize(200, HEADER_HEIGHT)
Header:SetPoint("TOP", Sidebar, "TOP", 0, 0)
Header:SetBackdrop({ bgFile = WHITE8X8 })
Header:SetBackdropColor(0.01, 0.01, 0.01, 0.9)

local HeaderAccent = Header:CreateTexture(nil, "OVERLAY")
HeaderAccent:SetHeight(3)
HeaderAccent:SetPoint("TOPLEFT")
HeaderAccent:SetPoint("TOPRIGHT")
HeaderAccent:SetColorTexture(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)

local AddonTitle = Header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
AddonTitle:SetPoint("TOP", Header, "TOP", 0, -20)
AddonTitle:SetText("|cff" .. C.BLUE_HEX .. "LINGKAN|r |cff" .. C.ORANGE_HEX .. "UI|r")

local VersionText = Header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
VersionText:SetPoint("TOP", AddonTitle, "BOTTOM", 0, -5)
VersionText:SetText(string.format("|cff%s%s|r |cff%s%s|r",
    C.ORANGE_HEX, LingkanUI.versionStage or "", C.GRAY_HEX, LingkanUI.versionNumber or ""))

local HeaderSeparator = Header:CreateTexture(nil, "OVERLAY")
HeaderSeparator:SetHeight(2)
HeaderSeparator:SetPoint("BOTTOMLEFT")
HeaderSeparator:SetPoint("BOTTOMRIGHT")
HeaderSeparator:SetColorTexture(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.5)

-- ------------------------------------------------------------------------------------
-- Scrolling menu
-- ------------------------------------------------------------------------------------

local MenuScroll = CreateFrame("ScrollFrame", nil, Sidebar)
MenuScroll:SetPoint("TOPLEFT", Header, "BOTTOMLEFT", 0, 0)
MenuScroll:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", 0, 0)

local MenuContent = CreateFrame("Frame", nil, MenuScroll)
MenuContent:SetSize(200, 1)
MenuScroll:SetScrollChild(MenuContent)

MenuScroll:EnableMouseWheel(true)
MenuScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxScroll = math.max(0, MenuContent:GetHeight() - self:GetHeight())
    local newPosition = math.max(0, math.min(self:GetVerticalScroll() - (delta * 40), maxScroll))
    self:SetVerticalScroll(newPosition)
end)

local ActiveIndicator = MenuContent:CreateTexture(nil, "OVERLAY")
ActiveIndicator:SetWidth(4)
ActiveIndicator:SetColorTexture(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
ActiveIndicator:Hide()

local groups = {}
local groupStates = {}
local tabRegistry = {}
local selectedButton = nil

local function RecalculateLayout()
    local yOffset = 0

    for _, group in ipairs(groups) do
        group.header:ClearAllPoints()
        group.header:SetPoint("TOP", MenuContent, "TOP", 0, yOffset)
        yOffset = yOffset - (GROUP_HEIGHT + 4)

        if groupStates[group.name] then
            for _, child in ipairs(group.children) do
                child:ClearAllPoints()
                child:SetPoint("TOP", MenuContent, "TOP", 0, yOffset)
                child:Show()
                yOffset = yOffset - (CHILD_HEIGHT + 2)
            end
        else
            for _, child in ipairs(group.children) do
                child:Hide()
            end
        end
    end

    MenuContent:SetHeight(math.abs(yOffset) + 20)
    MenuScroll:UpdateScrollChildRect()

    ActiveIndicator:SetShown(selectedButton ~= nil and selectedButton:IsShown())
end

local function SwitchTab(button, initFunction, tabKey)
    local content = LingkanUI.MainFrame and LingkanUI.MainFrame.Content
    if not content then return end

    LingkanUI.MainFrame:ResetContent()
    content:Show()

    selectedButton = button
    if button then
        ActiveIndicator:ClearAllPoints()
        ActiveIndicator:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        ActiveIndicator:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        ActiveIndicator:SetShown(button:IsShown())
    else
        ActiveIndicator:Hide()
    end

    if initFunction then initFunction() end

    if tabKey and LingkanUI.db and LingkanUI.db.profile.config then
        LingkanUI.db.profile.config.lastTab = tabKey
    end
end

local function CreateGroupHeader(label, groupName)
    local button = CreateFrame("Button", nil, MenuContent, "BackdropTemplate")
    button:SetSize(196, GROUP_HEIGHT)
    button:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
    button:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.25)
    button:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.5)

    local toggleIcon = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toggleIcon:SetPoint("LEFT", 10, 0)
    toggleIcon:SetText("+")
    toggleIcon:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)
    button.toggleIcon = toggleIcon

    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", toggleIcon, "RIGHT", 6, 0)
    text:SetText(label)
    text:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.3)
        self:SetBackdropBorderColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.8)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.25)
        self:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.5)
    end)
    button:SetScript("OnClick", function(self)
        groupStates[groupName] = not groupStates[groupName]
        self.toggleIcon:SetText(groupStates[groupName] and "-" or "+")
        RecalculateLayout()
    end)

    return button
end

local function CreateChildButton(label, onClick, tabKey)
    local button = CreateFrame("Button", nil, MenuContent, "BackdropTemplate")
    button:SetSize(186, CHILD_HEIGHT)
    button:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
    button:SetBackdropColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.15)
    button:SetBackdropBorderColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.25)

    local bullet = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bullet:SetPoint("LEFT", 18, 0)
    bullet:SetText("\194\187")
    bullet:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)

    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", bullet, "RIGHT", 6, 0)
    text:SetPoint("RIGHT", -6, 0)
    text:SetJustifyH("LEFT")
    text:SetText(label)
    text:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.3)
        self:SetBackdropBorderColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.8)
        text:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)
        bullet:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.15)
        self:SetBackdropBorderColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.25)
        text:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)
        bullet:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)
    end)
    button:SetScript("OnClick", function(self)
        SwitchTab(self, onClick, tabKey)
    end)

    button.tabKey = tabKey
    return button
end

local function CreateGroup(name, label, childDefinitions)
    local header = CreateGroupHeader(label, name)
    local children = {}

    for _, definition in ipairs(childDefinitions) do
        local child = CreateChildButton(definition.label, definition.onClick, definition.key)
        children[#children + 1] = child
        if definition.key then
            tabRegistry[definition.key] = {
                button = child,
                groupName = name,
                initFunc = definition.onClick,
            }
        end
    end

    groupStates[name] = false
    groups[#groups + 1] = { name = name, header = header, children = children }
end

-- Calls an Init function by name only if the config file that defines it loaded
local function Page(initName)
    return function()
        local init = LingkanUI[initName]
        if init then
            init(LingkanUI)
        else
            LingkanUI:Print("Config page not loaded: " .. initName)
        end
    end
end

-- ------------------------------------------------------------------------------------
-- Menu definition
-- ------------------------------------------------------------------------------------

CreateGroup("general", "GENERAL", {
    { key = "general", label = "General", onClick = Page("InitGeneral") },
})

CreateGroup("interface", "INTERFACE", {
    { key = "unit_indicators", label = "Unit Indicators", onClick = Page("InitUnitIndicators") },
    { key = "character_panel", label = "Character Panel", onClick = Page("InitCharacterPanel") },
    { key = "role_icons",      label = "Role Icons",      onClick = Page("InitRoleIcons") },
})

CreateGroup("utility", "UTILITY", {
    { key = "sheathing",  label = "Sheathing",            onClick = Page("InitSheathing") },
    { key = "leaning",    label = "Leaning",              onClick = Page("InitLeaning") },
    { key = "tab_target", label = "Tab Target Arena Fix", onClick = Page("InitTabTarget") },
})

CreateGroup("system", "SYSTEM", {
    { key = "profiles",  label = "Profiles",  onClick = Page("InitProfiles") },
    { key = "installer", label = "Installer", onClick = Page("InitInstaller") },
    { key = "about",     label = "About",     onClick = Page("InitAbout") },
})

-- ------------------------------------------------------------------------------------
-- Navigation API
-- ------------------------------------------------------------------------------------

function LingkanUI:OpenTab(tabKey)
    local tabInfo = tabRegistry[tabKey]
    if not tabInfo then
        if LingkanUI.InitHome then LingkanUI:InitHome() end
        return
    end

    -- Expand only the group that owns the target tab
    for _, group in ipairs(groups) do
        local shouldOpen = (group.name == tabInfo.groupName)
        groupStates[group.name] = shouldOpen
        group.header.toggleIcon:SetText(shouldOpen and "-" or "+")
    end
    RecalculateLayout()

    SwitchTab(tabInfo.button, tabInfo.initFunc, tabKey)
end

function LingkanUI:GoHome()
    for _, group in ipairs(groups) do
        groupStates[group.name] = false
        group.header.toggleIcon:SetText("+")
    end
    RecalculateLayout()

    selectedButton = nil
    ActiveIndicator:Hide()

    LingkanUI.MainFrame:ResetContent()
    if LingkanUI.InitHome then LingkanUI:InitHome() end

    if LingkanUI.db and LingkanUI.db.profile.config then
        LingkanUI.db.profile.config.lastTab = nil
    end
end

Header:SetScript("OnClick", function() LingkanUI:GoHome() end)
Header:SetScript("OnEnter", function(self) self:SetBackdropColor(0.05, 0.05, 0.05, 0.9) end)
Header:SetScript("OnLeave", function(self) self:SetBackdropColor(0.01, 0.01, 0.01, 0.9) end)

RecalculateLayout()
