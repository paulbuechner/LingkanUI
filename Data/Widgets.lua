local ADDON_NAME, LingkanUI = ...

-- ------------------------------------------------------------------------------------
-- Widget library for the LingkanUI configuration window.
--
-- Every control is positioned absolutely against its parent's TOPLEFT via opts.x/opts.y,
-- which keeps the config pages easy to read and reorder.
--
-- Data binding: pass either (db, key) for a direct table binding, or explicit
-- get/set functions. onChange always fires after the value has been written.
-- ------------------------------------------------------------------------------------

local C = LingkanUI.COLORS
local WHITE8X8 = [[Interface\Buttons\WHITE8X8]]

local Widgets = {}
LingkanUI.Widgets = Widgets

-- All live controls, so a single change can refresh values and disabled states
-- everywhere (panels are cached, so this list stays small and bounded).
local controls = {}

Widgets.Colorize = LingkanUI.Colorize

-- ------------------------------------------------------------------------------------
-- Internal helpers
-- ------------------------------------------------------------------------------------

local function ReadValue(opts)
    if opts.get then return opts.get() end
    if opts.db and opts.key then return opts.db[opts.key] end
    return nil
end

local function WriteValue(opts, value)
    if opts.set then
        opts.set(value)
    elseif opts.db and opts.key then
        opts.db[opts.key] = value
    end
    if opts.onChange then opts.onChange(value) end
    Widgets:RefreshAll()
end

local function IsDisabled(opts)
    if type(opts.disabled) == "function" then return opts.disabled() and true or false end
    return opts.disabled and true or false
end

local function Register(control)
    controls[#controls + 1] = control
    return control
end

-- Re-reads every control's value and disabled state from the database
function Widgets:RefreshAll()
    for i = 1, #controls do
        local control = controls[i]
        if control.LUIRefresh then
            local ok, err = pcall(control.LUIRefresh, control)
            if not ok then
                LingkanUI:DebugPrint("Widget refresh failed: " .. tostring(err), "general")
            end
        end
    end
end

local function ApplyBackdrop(frame, bg, border)
    frame:SetBackdrop({
        bgFile = WHITE8X8,
        edgeFile = WHITE8X8,
        edgeSize = 1,
    })
    if bg then frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a or 1) end
    if border then frame:SetBackdropBorderColor(border.r, border.g, border.b, border.a or 1) end
end
Widgets.ApplyBackdrop = ApplyBackdrop

-- Shared tooltip behaviour for controls with a `desc`
local function AttachTooltip(frame, title, desc)
    if not desc or desc == "" then return end
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if title and title ~= "" then
            GameTooltip:AddLine(title, 1, 1, 1)
        end
        GameTooltip:AddLine(desc, C.GRAY.r, C.GRAY.g, C.GRAY.b, true)
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
Widgets.AttachTooltip = AttachTooltip

-- ------------------------------------------------------------------------------------
-- Structure
-- ------------------------------------------------------------------------------------

-- Hides every child and region of a frame (used before rebuilding a page)
function Widgets.ClearFrame(frame)
    if not frame then return end
    for _, child in ipairs({ frame:GetChildren() }) do
        child:Hide()
    end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region.Hide then region:Hide() end
    end
end

-- Builds a page once and reuses it afterwards. `cache` is a per-config-file table.
function Widgets:CachedPanel(cache, key, parent, buildFn)
    local panel = cache[key]
    if panel then
        panel:Show()
        Widgets:RefreshAll()
        return panel
    end

    panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)
    cache[key] = panel

    buildFn(panel)
    Widgets:RefreshAll()
    return panel
end

-- Scrollable body for a page. Returns the scroll frame and its content child.
function Widgets:CreateScrollFrame(parent, contentHeight)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetPoint("TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -22, 4)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, contentHeight or 600)
    scrollFrame:SetScrollChild(content)

    -- Keep the content as wide as the viewport so RIGHT anchors behave
    scrollFrame:SetScript("OnSizeChanged", function(self, width)
        content:SetWidth(width)
    end)
    content:SetWidth(scrollFrame:GetWidth() > 0 and scrollFrame:GetWidth() or 700)

    local scrollBar = CreateFrame("Slider", nil, scrollFrame, "BackdropTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 0)
    scrollBar:SetWidth(10)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValue(0)
    ApplyBackdrop(scrollBar, { r = 0, g = 0, b = 0, a = 0.4 },
        { r = C.DARK_BLUE.r, g = C.DARK_BLUE.g, b = C.DARK_BLUE.b, a = 0.4 })

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE8X8)
    thumb:SetVertexColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.8)
    thumb:SetSize(10, 40)
    scrollBar:SetThumbTexture(thumb)

    local function UpdateScrollRange()
        local range = math.max(0, content:GetHeight() - scrollFrame:GetHeight())
        scrollBar:SetMinMaxValues(0, range)
        scrollBar:SetShown(range > 0)
        if scrollFrame:GetVerticalScroll() > range then
            scrollFrame:SetVerticalScroll(range)
        end
    end

    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, content:GetHeight() - self:GetHeight())
        local newValue = math.min(range, math.max(0, self:GetVerticalScroll() - delta * 40))
        scrollBar:SetValue(newValue)
    end)

    content:SetScript("OnSizeChanged", UpdateScrollRange)
    scrollFrame:HookScript("OnShow", UpdateScrollRange)
    scrollFrame:HookScript("OnSizeChanged", UpdateScrollRange)
    C_Timer.After(0, UpdateScrollRange)

    scrollFrame.content = content
    scrollFrame.UpdateScrollRange = UpdateScrollRange
    return scrollFrame, content
end

-- Two-tone page title with subtitle, e.g. {{"UNIT ", C.BLUE}, {"INDICATORS", C.ORANGE}}
function Widgets:CreatePageHeader(parent, titleParts, subtitle)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    header:SetHeight(subtitle and 46 or 30)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT")

    local text = ""
    for _, part in ipairs(titleParts) do
        local color = part[2] or C.WHITE
        text = text .. string.format("|cff%02x%02x%02x%s|r",
            color.r * 255, color.g * 255, color.b * 255, part[1])
    end
    title:SetText(text)

    if subtitle then
        local sub = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        sub:SetPoint("RIGHT", header, "RIGHT", 0, 0)
        sub:SetJustifyH("LEFT")
        sub:SetText(subtitle)
        header.subtitle = sub
    end

    local accent = header:CreateTexture(nil, "OVERLAY")
    accent:SetHeight(1)
    accent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, -4)
    accent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, -4)
    accent:SetColorTexture(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.5)

    header.title = title
    return header
end

function Widgets:CreateSectionHeader(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", x or 10, y or 0)
    label:SetText(text)
    label:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)
    return label
end

function Widgets:CreateLabel(parent, text, opts)
    opts = opts or {}
    local label = parent:CreateFontString(nil, "OVERLAY", opts.font or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", opts.x or 10, opts.y or 0)
    if opts.width then
        label:SetWidth(opts.width)
    else
        label:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    end
    label:SetJustifyH(opts.justify or "LEFT")
    label:SetText(text)
    local color = opts.color or C.GRAY
    label:SetTextColor(color.r, color.g, color.b)
    return label
end

function Widgets:CreateSeparator(parent, x, y, width)
    local line = parent:CreateTexture(nil, "OVERLAY")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", x or 10, y or 0)
    if width then
        line:SetWidth(width)
    else
        line:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    end
    line:SetColorTexture(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.35)
    return line
end

-- Collapsible group. Returns the wrapper (position this) and the content frame
-- (put controls in this). Call wrapper:RecalcHeight() after setting content height.
function Widgets:CreateCollapsibleSection(parent, opts)
    opts = opts or {}

    local wrapper = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    wrapper:SetPoint("TOPLEFT", opts.x or 10, opts.y or 0)
    if opts.width then
        wrapper:SetWidth(opts.width)
    else
        wrapper:SetPoint("RIGHT", parent, "RIGHT", opts.rightInset or -10, 0)
    end

    local headerButton = CreateFrame("Button", nil, wrapper, "BackdropTemplate")
    headerButton:SetHeight(26)
    headerButton:SetPoint("TOPLEFT")
    headerButton:SetPoint("TOPRIGHT")
    ApplyBackdrop(headerButton,
        { r = C.BLUE.r, g = C.BLUE.g, b = C.BLUE.b, a = 0.18 },
        { r = C.BLUE.r, g = C.BLUE.g, b = C.BLUE.b, a = 0.40 })

    local toggleIcon = headerButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toggleIcon:SetPoint("LEFT", 8, 0)
    toggleIcon:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)

    local headerText = headerButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerText:SetPoint("LEFT", toggleIcon, "RIGHT", 6, 0)
    headerText:SetText(opts.text or "")
    headerText:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)

    local content = CreateFrame("Frame", nil, wrapper)
    content:SetPoint("TOPLEFT", headerButton, "BOTTOMLEFT", 0, -4)
    content:SetPoint("TOPRIGHT", headerButton, "BOTTOMRIGHT", 0, -4)
    content:SetHeight(opts.height or 60)

    local open = opts.startOpen and true or false

    function wrapper:RecalcHeight()
        if open then
            wrapper:SetHeight(26 + 4 + content:GetHeight() + 6)
        else
            wrapper:SetHeight(26 + 6)
        end
    end

    local function ApplyState()
        toggleIcon:SetText(open and "-" or "+")
        content:SetShown(open)
        wrapper:RecalcHeight()
        if opts.onToggle then opts.onToggle(open) end
    end

    headerButton:SetScript("OnClick", function()
        open = not open
        ApplyState()
    end)

    headerButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.25)
        self:SetBackdropBorderColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.7)
    end)
    headerButton:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.18)
        self:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.40)
    end)

    ApplyState()

    wrapper.content = content
    wrapper.header = headerButton
    wrapper.SetOpen = function(_, value) open = value and true or false; ApplyState() end
    wrapper.IsOpen = function() return open end
    return wrapper, content
end

-- ------------------------------------------------------------------------------------
-- Controls
-- ------------------------------------------------------------------------------------

-- Flat themed checkbox (no Blizzard template, so it cannot drift across patches)
function Widgets:CreateCheckbox(parent, opts)
    local box = CreateFrame("Button", nil, parent, "BackdropTemplate")
    box:SetSize(18, 18)
    box:SetPoint("TOPLEFT", opts.x or 10, opts.y or 0)
    ApplyBackdrop(box,
        { r = C.BG_PANEL.r, g = C.BG_PANEL.g, b = C.BG_PANEL.b, a = 0.9 },
        { r = C.DARK_BLUE.r, g = C.DARK_BLUE.g, b = C.DARK_BLUE.b, a = 0.8 })

    local fill = box:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT", 4, -4)
    fill:SetPoint("BOTTOMRIGHT", -4, 4)
    fill:SetColorTexture(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
    fill:Hide()

    local label = box:CreateFontString(nil, "OVERLAY",
        opts.isMaster and "GameFontNormal" or "GameFontHighlightSmall")
    label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    label:SetJustifyH("LEFT")
    label:SetText(opts.label or "")
    if opts.isMaster then
        label:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)
    end

    box.label = label

    box:SetScript("OnClick", function(self)
        if IsDisabled(opts) then return end
        WriteValue(opts, not ReadValue(opts))
    end)

    box:SetScript("OnEnter", function(self)
        if not IsDisabled(opts) then
            self:SetBackdropBorderColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
        end
    end)
    box:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.8)
    end)

    AttachTooltip(box, opts.label, opts.desc)

    function box:LUIRefresh()
        local checked = ReadValue(opts) and true or false
        fill:SetShown(checked)

        local disabled = IsDisabled(opts)
        self:EnableMouse(not disabled)
        if disabled then
            fill:SetVertexColor(C.DIM.r, C.DIM.g, C.DIM.b, 1)
            label:SetTextColor(C.DIM.r, C.DIM.g, C.DIM.b)
        else
            fill:SetVertexColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
            if opts.isMaster then
                label:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)
            else
                label:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)
            end
        end
    end

    box:LUIRefresh()
    return Register(box)
end

-- Slider with a live value box. Supports opts.isPercent, min, max, step.
function Widgets:CreateSlider(parent, opts)
    local width = opts.width or 260
    local step = opts.step or 1
    local minValue, maxValue = opts.min or 0, opts.max or 100

    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", opts.x or 10, opts.y or 0)
    container:SetSize(width + 70, 44)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT")
    label:SetText(opts.label or "")

    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
    slider:SetSize(width, 12)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    ApplyBackdrop(slider,
        { r = 0, g = 0, b = 0, a = 0.5 },
        { r = C.DARK_BLUE.r, g = C.DARK_BLUE.g, b = C.DARK_BLUE.b, a = 0.6 })

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE8X8)
    thumb:SetVertexColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
    thumb:SetSize(8, 18)
    slider:SetThumbTexture(thumb)

    local valueBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    valueBox:SetSize(58, 20)
    valueBox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueBox:SetAutoFocus(false)
    valueBox:SetJustifyH("CENTER")
    valueBox:SetFontObject("GameFontHighlightSmall")
    valueBox:SetMaxLetters(8)
    ApplyBackdrop(valueBox,
        { r = C.BG_PANEL.r, g = C.BG_PANEL.g, b = C.BG_PANEL.b, a = 0.9 },
        { r = C.DARK_BLUE.r, g = C.DARK_BLUE.g, b = C.DARK_BLUE.b, a = 0.6 })

    local updating = false

    local function Display(value)
        if opts.isPercent then
            return string.format("%d%%", math.floor(value * 100 + 0.5))
        elseif step < 1 then
            return string.format("%.2f", value)
        end
        return tostring(math.floor(value + 0.5))
    end

    local function Commit(value)
        value = math.max(minValue, math.min(maxValue, value))
        -- Snap to the configured step so stored values stay clean
        value = math.floor((value - minValue) / step + 0.5) * step + minValue
        WriteValue(opts, value)
    end

    slider:SetScript("OnValueChanged", function(self, value)
        if updating then return end
        valueBox:SetText(Display(value))
        Commit(value)
    end)

    valueBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText():gsub("%%", "")
        local value = tonumber(text)
        if value then
            if opts.isPercent then value = value / 100 end
            Commit(value)
        end
        self:ClearFocus()
        Widgets:RefreshAll()
    end)
    valueBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        Widgets:RefreshAll()
    end)

    AttachTooltip(slider, opts.label, opts.desc)

    function container:LUIRefresh()
        local value = tonumber(ReadValue(opts)) or minValue
        updating = true
        slider:SetValue(math.max(minValue, math.min(maxValue, value)))
        updating = false
        if not valueBox:HasFocus() then
            valueBox:SetText(Display(value))
        end

        local disabled = IsDisabled(opts)
        slider:EnableMouse(not disabled)
        valueBox:EnableMouse(not disabled)
        valueBox:SetEnabled(not disabled)
        if disabled then
            thumb:SetVertexColor(C.DIM.r, C.DIM.g, C.DIM.b, 1)
            label:SetTextColor(C.DIM.r, C.DIM.g, C.DIM.b)
        else
            thumb:SetVertexColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
            label:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)
        end
    end

    container.slider = slider
    container:LUIRefresh()
    return Register(container)
end

-- Themed dropdown. opts.values is either a { key = display } map with optional
-- opts.order, or an array of { value = ..., text = ... }.
function Widgets:CreateDropdown(parent, opts)
    local width = opts.width or 200

    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", opts.x or 10, opts.y or 0)
    container:SetSize(width, 44)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT")
    label:SetText(opts.label or "")

    local button = CreateFrame("Button", nil, container, "BackdropTemplate")
    button:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    button:SetSize(width, 22)
    ApplyBackdrop(button,
        { r = C.BG_PANEL.r, g = C.BG_PANEL.g, b = C.BG_PANEL.b, a = 0.95 },
        { r = C.DARK_BLUE.r, g = C.DARK_BLUE.g, b = C.DARK_BLUE.b, a = 0.7 })

    local valueText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", 8, 0)
    valueText:SetPoint("RIGHT", -20, 0)
    valueText:SetJustifyH("LEFT")

    local arrow = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetText("v")
    arrow:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)

    local list = CreateFrame("Frame", nil, button, "BackdropTemplate")
    list:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    list:SetWidth(width)
    list:SetFrameStrata("DIALOG")
    list:SetFrameLevel(button:GetFrameLevel() + 20)
    ApplyBackdrop(list,
        { r = C.BG_PANEL.r, g = C.BG_PANEL.g, b = C.BG_PANEL.b, a = 0.98 },
        { r = C.BLUE.r, g = C.BLUE.g, b = C.BLUE.b, a = 0.7 })
    list:Hide()

    local entryButtons = {}

    -- Normalises both accepted `values` shapes into an ordered array
    local function BuildEntries()
        local entries = {}
        local values = opts.values
        if type(values) == "function" then values = values() end
        if not values then return entries end

        if values[1] ~= nil and type(values[1]) == "table" then
            for _, entry in ipairs(values) do
                entries[#entries + 1] = { value = entry.value, text = entry.text, font = entry.font }
            end
            return entries
        end

        if opts.order then
            for _, key in ipairs(opts.order) do
                if values[key] ~= nil then
                    entries[#entries + 1] = { value = key, text = values[key] }
                end
            end
            return entries
        end

        local keys = {}
        for key in pairs(values) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b) return tostring(values[a]) < tostring(values[b]) end)
        for _, key in ipairs(keys) do
            entries[#entries + 1] = { value = key, text = values[key] }
        end
        return entries
    end

    local function CloseList()
        list:Hide()
    end

    local function OpenList()
        local entries = BuildEntries()
        local shown = 0

        for index, entry in ipairs(entries) do
            local entryButton = entryButtons[index]
            if not entryButton then
                entryButton = CreateFrame("Button", nil, list, "BackdropTemplate")
                entryButton:SetSize(width - 2, 20)
                entryButton:SetPoint("TOPLEFT", 1, -((index - 1) * 20) - 1)
                entryButton:SetBackdrop({ bgFile = WHITE8X8 })
                entryButton:SetBackdropColor(0, 0, 0, 0)

                local entryText = entryButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                entryText:SetPoint("LEFT", 8, 0)
                entryText:SetPoint("RIGHT", -8, 0)
                entryText:SetJustifyH("LEFT")
                entryButton.text = entryText

                entryButton:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.25)
                end)
                entryButton:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0, 0, 0, 0)
                end)
                entryButtons[index] = entryButton
            end

            entryButton.text:SetText(entry.text)
            -- Font pickers preview each entry in its own font
            if entry.font then
                local ok = pcall(function() entryButton.text:SetFont(entry.font, 12, "") end)
                if not ok then entryButton.text:SetFontObject("GameFontHighlightSmall") end
            else
                entryButton.text:SetFontObject("GameFontHighlightSmall")
            end

            entryButton:SetScript("OnClick", function()
                CloseList()
                WriteValue(opts, entry.value)
            end)
            entryButton:Show()
            shown = index
        end

        for index = shown + 1, #entryButtons do
            entryButtons[index]:Hide()
        end

        if shown == 0 then
            CloseList()
            return
        end

        -- Cap the popup height so long font lists stay usable
        local maxVisible = math.min(shown, opts.maxVisible or 12)
        list:SetHeight(maxVisible * 20 + 2)
        list:Show()
    end

    button:SetScript("OnClick", function()
        if IsDisabled(opts) then return end
        if list:IsShown() then CloseList() else OpenList() end
    end)

    button:SetScript("OnEnter", function(self)
        if not IsDisabled(opts) then
            self:SetBackdropBorderColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
        end
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.7)
    end)

    -- Close when the mouse leaves the popup entirely
    list:SetScript("OnUpdate", function(self)
        if not self:IsMouseOver(10, -10, -10, 10) and not button:IsMouseOver() then
            if not self.hoverGrace then
                self.hoverGrace = GetTime() + 0.4
            elseif GetTime() > self.hoverGrace then
                self.hoverGrace = nil
                CloseList()
            end
        else
            self.hoverGrace = nil
        end
    end)

    AttachTooltip(button, opts.label, opts.desc)

    function container:LUIRefresh()
        local current = ReadValue(opts)
        local display = current and tostring(current) or ""

        for _, entry in ipairs(BuildEntries()) do
            if entry.value == current then
                display = entry.text
                break
            end
        end
        valueText:SetText(display)

        local disabled = IsDisabled(opts)
        button:EnableMouse(not disabled)
        if disabled then
            valueText:SetTextColor(C.DIM.r, C.DIM.g, C.DIM.b)
            label:SetTextColor(C.DIM.r, C.DIM.g, C.DIM.b)
            arrow:SetTextColor(C.DIM.r, C.DIM.g, C.DIM.b)
            CloseList()
        else
            valueText:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)
            label:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)
            arrow:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)
        end
    end

    container.button = button
    container:LUIRefresh()
    return Register(container)
end

-- Dropdown listing every LibSharedMedia font, previewed in its own typeface
function Widgets:CreateFontDropdown(parent, opts)
    local dropdownOpts = {}
    for key, value in pairs(opts) do dropdownOpts[key] = value end

    dropdownOpts.maxVisible = opts.maxVisible or 14
    dropdownOpts.values = function()
        return LingkanUI.FontList and LingkanUI.FontList:GetEntries() or {}
    end

    return Widgets:CreateDropdown(parent, dropdownOpts)
end

function Widgets:CreateButton(parent, opts)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(opts.width or 120, opts.height or 24)
    if opts.point then
        button:SetPoint(opts.point, opts.relativeTo or parent, opts.relativePoint or opts.point,
            opts.x or 0, opts.y or 0)
    else
        button:SetPoint("TOPLEFT", opts.x or 10, opts.y or 0)
    end

    local baseColor = opts.danger and C.RED or C.BLUE
    ApplyBackdrop(button,
        { r = baseColor.r, g = baseColor.g, b = baseColor.b, a = 0.2 },
        { r = baseColor.r, g = baseColor.g, b = baseColor.b, a = 0.6 })

    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    text:SetText(opts.label or "")
    button.text = text

    button:SetScript("OnClick", function()
        if IsDisabled(opts) then return end
        if opts.func then opts.func() end
        Widgets:RefreshAll()
    end)

    button:SetScript("OnEnter", function(self)
        if IsDisabled(opts) then return end
        self:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.3)
        self:SetBackdropBorderColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.9)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(baseColor.r, baseColor.g, baseColor.b, 0.2)
        self:SetBackdropBorderColor(baseColor.r, baseColor.g, baseColor.b, 0.6)
    end)

    AttachTooltip(button, opts.label, opts.desc)

    function button:LUIRefresh()
        local disabled = IsDisabled(opts)
        self:EnableMouse(not disabled)
        if disabled then
            text:SetTextColor(C.DIM.r, C.DIM.g, C.DIM.b)
        else
            text:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)
        end
    end

    button:LUIRefresh()
    return Register(button)
end

function Widgets:CreateTextInput(parent, opts)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", opts.x or 10, opts.y or 0)
    container:SetSize(opts.width or 240, 44)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT")
    label:SetText(opts.label or "")

    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    editBox:SetSize(opts.width or 240, 22)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetTextInsets(6, 6, 0, 0)
    editBox:SetMaxLetters(opts.maxLetters or 64)
    ApplyBackdrop(editBox,
        { r = C.BG_PANEL.r, g = C.BG_PANEL.g, b = C.BG_PANEL.b, a = 0.95 },
        { r = C.DARK_BLUE.r, g = C.DARK_BLUE.g, b = C.DARK_BLUE.b, a = 0.7 })

    editBox:SetScript("OnEnterPressed", function(self)
        WriteValue(opts, self:GetText())
        self:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        Widgets:RefreshAll()
    end)

    function container:LUIRefresh()
        if not editBox:HasFocus() then
            editBox:SetText(tostring(ReadValue(opts) or ""))
        end
        local disabled = IsDisabled(opts)
        editBox:SetEnabled(not disabled)
    end

    container.editBox = editBox
    container:LUIRefresh()
    return Register(container)
end

-- Editable dropdown: type a value, or pick an existing one from the arrow.
-- `values` follows the same shape as CreateDropdown.
function Widgets:CreateComboBox(parent, opts)
    local width = opts.width or 200

    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", opts.x or 10, opts.y or 0)
    container:SetSize(width, 44)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT")
    label:SetText(opts.label or "")

    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    editBox:SetSize(width, 22)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetTextInsets(6, 22, 0, 0)
    editBox:SetMaxLetters(opts.maxLetters or 64)
    ApplyBackdrop(editBox,
        { r = C.BG_PANEL.r, g = C.BG_PANEL.g, b = C.BG_PANEL.b, a = 0.95 },
        { r = C.DARK_BLUE.r, g = C.DARK_BLUE.g, b = C.DARK_BLUE.b, a = 0.7 })

    local arrow = CreateFrame("Button", nil, editBox)
    arrow:SetSize(18, 20)
    arrow:SetPoint("RIGHT", -1, 0)

    local arrowText = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrowText:SetPoint("CENTER")
    arrowText:SetText("v")
    arrowText:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)

    local list = CreateFrame("Frame", nil, editBox, "BackdropTemplate")
    list:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -2)
    list:SetWidth(width)
    list:SetFrameStrata("DIALOG")
    list:SetFrameLevel(editBox:GetFrameLevel() + 20)
    ApplyBackdrop(list,
        { r = C.BG_PANEL.r, g = C.BG_PANEL.g, b = C.BG_PANEL.b, a = 0.98 },
        { r = C.BLUE.r, g = C.BLUE.g, b = C.BLUE.b, a = 0.7 })
    list:Hide()

    local entryButtons = {}

    local function Commit(value)
        WriteValue(opts, value)
    end

    local function CloseList() list:Hide() end

    local function OpenList()
        local values = opts.values
        if type(values) == "function" then values = values() end
        values = values or {}

        local shown = 0
        for index, entry in ipairs(values) do
            local button = entryButtons[index]
            if not button then
                button = CreateFrame("Button", nil, list, "BackdropTemplate")
                button:SetSize(width - 2, 20)
                button:SetPoint("TOPLEFT", 1, -((index - 1) * 20) - 1)
                button:SetBackdrop({ bgFile = WHITE8X8 })
                button:SetBackdropColor(0, 0, 0, 0)

                local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("LEFT", 8, 0)
                text:SetPoint("RIGHT", -8, 0)
                text:SetJustifyH("LEFT")
                button.text = text

                button:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.25)
                end)
                button:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0, 0, 0, 0)
                end)
                entryButtons[index] = button
            end

            button.text:SetText(entry.text)
            button:SetScript("OnClick", function()
                CloseList()
                editBox:SetText(tostring(entry.value))
                editBox:ClearFocus()
                Commit(entry.value)
            end)
            button:Show()
            shown = index
        end

        for index = shown + 1, #entryButtons do entryButtons[index]:Hide() end
        if shown == 0 then CloseList() return end

        list:SetHeight(math.min(shown, opts.maxVisible or 12) * 20 + 2)
        list:Show()
    end

    arrow:SetScript("OnClick", function()
        if IsDisabled(opts) then return end
        if list:IsShown() then CloseList() else OpenList() end
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        CloseList()
        Commit(self:GetText())
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        Commit(self:GetText())
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        CloseList()
        self:ClearFocus()
        Widgets:RefreshAll()
    end)

    list:SetScript("OnUpdate", function(self)
        if not self:IsMouseOver(10, -10, -10, 10) and not editBox:IsMouseOver() then
            if not self.hoverGrace then
                self.hoverGrace = GetTime() + 0.4
            elseif GetTime() > self.hoverGrace then
                self.hoverGrace = nil
                CloseList()
            end
        else
            self.hoverGrace = nil
        end
    end)

    AttachTooltip(editBox, opts.label, opts.desc)

    function container:LUIRefresh()
        if not editBox:HasFocus() then
            editBox:SetText(tostring(ReadValue(opts) or ""))
        end

        local disabled = IsDisabled(opts)
        editBox:SetEnabled(not disabled)
        arrow:EnableMouse(not disabled)
        if disabled then
            CloseList()
            label:SetTextColor(C.DIM.r, C.DIM.g, C.DIM.b)
            arrowText:SetTextColor(C.DIM.r, C.DIM.g, C.DIM.b)
        else
            label:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b)
            arrowText:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)
        end
    end

    container.editBox = editBox
    container:LUIRefresh()
    return Register(container)
end

-- Scrollable multi-line box, used for profile import/export strings
function Widgets:CreateMultiLineInput(parent, opts)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", opts.x or 10, opts.y or 0)
    container:SetSize(opts.width or 420, (opts.height or 120) + 20)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT")
    label:SetText(opts.label or "")

    local backdrop = CreateFrame("Frame", nil, container, "BackdropTemplate")
    backdrop:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    backdrop:SetSize(opts.width or 420, opts.height or 120)
    ApplyBackdrop(backdrop,
        { r = C.BG_PANEL.r, g = C.BG_PANEL.g, b = C.BG_PANEL.b, a = 0.95 },
        { r = C.DARK_BLUE.r, g = C.DARK_BLUE.g, b = C.DARK_BLUE.b, a = 0.7 })

    local scrollFrame = CreateFrame("ScrollFrame", nil, backdrop, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 6)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth((opts.width or 420) - 34)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scrollFrame:SetScrollChild(editBox)

    if opts.onTextChanged then
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then opts.onTextChanged(self:GetText()) end
        end)
    end

    container.editBox = editBox
    container.GetText = function() return editBox:GetText() end
    container.SetText = function(_, text)
        editBox:SetText(text or "")
        editBox:SetCursorPosition(0)
    end
    container.SelectAll = function()
        editBox:SetFocus()
        editBox:HighlightText()
    end

    return container
end
