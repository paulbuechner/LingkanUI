local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local WHITE8X8 = [[Interface\Buttons\WHITE8X8]]
local cache = {}

local ROW_HEIGHT = 20
local MAX_VISIBLE_ROWS = 400 -- guards against expanding a group with thousands of keys

-- Page-local view state. The diff itself is rebuilt on demand rather than stored, so it
-- can never go stale against the profiles.
local diffGroups, diffTotal = nil, 0
local expanded, filterText = {}, ""
local lockedExpanded = true
local lockedGroupExpanded = {}
local rowPool, visibleRows = {}, {}
local Refresh -- forward declaration

local function Merge() return LingkanUI.EUIProfileMerge end
local function Settings() return LingkanUI.db.profile.euiMerge end

-- With "merge in place" ticked the destination is whatever is being merged into
local function Destination()
    local db = Settings()
    if db.mergeInPlace then return db.targetProfile end
    return db.destinationProfile
end

local function IsSelected(pathKey) return Settings().selected[pathKey] and true or false end
local function IsLocked(pathKey) return Settings().locked[pathKey] and true or false end

-- A locked setting can never be selected, so locking clears any pending selection
local function SetLocked(pathKey, value)
    Settings().locked[pathKey] = value or nil
    if value then Settings().selected[pathKey] = nil end
end

local function SetSelected(pathKey, value)
    if value and IsLocked(pathKey) then return end
    Settings().selected[pathKey] = value or nil
end

local function EntryMatchesFilter(group, entry)
    if filterText == "" then return true end
    local needle = filterText:lower()
    return (entry.label:lower():find(needle, 1, true) ~= nil)
        or (group.label:lower():find(needle, 1, true) ~= nil)
end

-- Counts across the whole diff, ignoring the filter
local function Tally()
    local selected, locked = 0, 0
    if not diffGroups then return selected, locked end

    for _, group in ipairs(diffGroups) do
        for _, entry in ipairs(group.entries) do
            local pathKey = Merge().PathKey(entry.path)
            if IsLocked(pathKey) then
                locked = locked + 1
            elseif IsSelected(pathKey) then
                selected = selected + 1
            end
        end
    end
    return selected, locked
end

-- ------------------------------------------------------------------------------------
-- Row pool
-- ------------------------------------------------------------------------------------

local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * ROW_HEIGHT))
    row:SetBackdrop({ bgFile = WHITE8X8 })
    row:SetBackdropColor(0, 0, 0, 0)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local box = CreateFrame("Button", nil, row, "BackdropTemplate")
    box:SetSize(13, 13)
    box:SetPoint("LEFT", 4, 0)
    box:SetBackdrop({ bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = 1 })
    box:SetBackdropColor(C.BG_PANEL.r, C.BG_PANEL.g, C.BG_PANEL.b, 0.9)
    box:SetBackdropBorderColor(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.8)
    box:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.box = box

    local fill = box:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    fill:SetColorTexture(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
    row.fill = fill

    local toggle = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toggle:SetPoint("LEFT", box, "RIGHT", 6, 0)
    toggle:SetTextColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b)
    row.toggle = toggle

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", toggle, "RIGHT", 4, 0)
    label:SetJustifyH("LEFT")
    row.label = label

    local values = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    values:SetPoint("RIGHT", -6, 0)
    values:SetJustifyH("RIGHT")
    row.values = values

    local line = row:CreateTexture(nil, "OVERLAY")
    line:SetHeight(1)
    line:SetPoint("LEFT", 4, 0)
    line:SetPoint("RIGHT", -4, 0)
    line:SetColorTexture(C.DARK_BLUE.r, C.DARK_BLUE.g, C.DARK_BLUE.b, 0.5)
    line:Hide()
    row.line = line

    row:SetScript("OnEnter", function(self)
        if self.hoverable then self:SetBackdropColor(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 0.12) end
    end)
    row:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)

    rowPool[index] = row
    return row
end

local function ResetRow(row)
    row.hoverable = true
    row.line:Hide()
    row.box:Show()
    row.toggle:SetText("")
    row.values:SetText("")
    row.box:SetScript("OnClick", nil)
    row:SetScript("OnClick", nil)
    row.label:SetFontObject("GameFontHighlightSmall")
end

-- ------------------------------------------------------------------------------------
-- Visible row list
-- ------------------------------------------------------------------------------------

local function BuildVisibleRows()
    wipe(visibleRows)
    if not diffGroups then return end

    -- Locked settings, shown again at the top so what has been pinned is visible at a
    -- glance without hunting through the tree
    local lockedGroups = {}
    for _, group in ipairs(diffGroups) do
        local entries = {}
        for _, entry in ipairs(group.entries) do
            if IsLocked(Merge().PathKey(entry.path)) then entries[#entries + 1] = entry end
        end
        if #entries > 0 then
            lockedGroups[#lockedGroups + 1] = { group = group, entries = entries }
        end
    end

    if #lockedGroups > 0 then
        local lockedCount = 0
        for _, bundle in ipairs(lockedGroups) do lockedCount = lockedCount + #bundle.entries end

        visibleRows[#visibleRows + 1] = { kind = "header", count = lockedCount }

        if lockedExpanded then
            for _, bundle in ipairs(lockedGroups) do
                local key = bundle.group.key
                if lockedGroupExpanded[key] == nil then lockedGroupExpanded[key] = false end

                visibleRows[#visibleRows + 1] = { kind = "lockedGroup", group = bundle.group,
                    matches = #bundle.entries }

                if lockedGroupExpanded[key] then
                    for _, entry in ipairs(bundle.entries) do
                        visibleRows[#visibleRows + 1] = { kind = "entry", group = bundle.group,
                            entry = entry, locked = true, inLockedList = true }
                    end
                end
            end
        end

        visibleRows[#visibleRows + 1] = { kind = "divider" }
    end

    -- The diff itself. A group whose every difference is locked has nothing left to
    -- merge, so it only appears in the locked list above.
    for _, group in ipairs(diffGroups) do
        local matches, mergeable = 0, 0
        for _, entry in ipairs(group.entries) do
            if EntryMatchesFilter(group, entry) then
                matches = matches + 1
                if not IsLocked(Merge().PathKey(entry.path)) then mergeable = mergeable + 1 end
            end
        end

        if mergeable > 0 then
            visibleRows[#visibleRows + 1] = { kind = "group", group = group, matches = matches }

            if expanded[group.key] then
                for _, entry in ipairs(group.entries) do
                    if EntryMatchesFilter(group, entry) then
                        visibleRows[#visibleRows + 1] = { kind = "entry", group = group, entry = entry,
                            locked = IsLocked(Merge().PathKey(entry.path)) }
                    end
                end
            end
        end
    end
end

-- ------------------------------------------------------------------------------------
-- Rendering
-- ------------------------------------------------------------------------------------

local function RenderRows(listContent)
    local shown = math.min(#visibleRows, MAX_VISIBLE_ROWS)

    for index = 1, shown do
        local item = visibleRows[index]
        local row = rowPool[index] or CreateRow(listContent, index)
        ResetRow(row)
        row:Show()

        if item.kind == "header" then
            row.hoverable = true
            row.box:Hide()
            row.toggle:SetText(lockedExpanded and "-" or "+")
            row.label:SetFontObject("GameFontNormalSmall")
            row.label:SetText(string.format("|cff%sLOCKED|r  |cff%s%d kept as mine|r",
                C.RED_HEX, C.DIM_HEX, item.count))
            row.values:SetText("|cff" .. C.DIM_HEX .. "right-click a row or group to unlock|r")
            row:SetScript("OnClick", function()
                lockedExpanded = not lockedExpanded
                Refresh()
            end)

        elseif item.kind == "divider" then
            row.hoverable = false
            row.box:Hide()
            row.label:SetText("")
            row.line:Show()

        elseif item.kind == "lockedGroup" then
            local key = item.group.key
            row.box:Hide()
            row.toggle:SetText(lockedGroupExpanded[key] and "-" or "+")
            row.label:SetFontObject("GameFontNormalSmall")
            local groupTotal = #item.group.entries
            local wholeGroup = (item.matches == groupTotal)
            row.label:SetText(string.format("|cff%s%s|r  |cff%s%s|r",
                wholeGroup and C.RED_HEX or C.GRAY_HEX, item.group.label, C.DIM_HEX,
                wholeGroup and ("all " .. groupTotal)
                    or string.format("%d of %d", item.matches, groupTotal)))
            row:SetScript("OnClick", function(_, button)
                if button == "RightButton" then
                    -- Unlock the whole group straight from the summary
                    for _, entry in ipairs(item.group.entries) do
                        SetLocked(Merge().PathKey(entry.path), false)
                    end
                else
                    lockedGroupExpanded[key] = not lockedGroupExpanded[key]
                end
                Refresh()
            end)

        elseif item.kind == "group" then
            local group = item.group
            local selectedInGroup, lockedInGroup = 0, 0
            for _, entry in ipairs(group.entries) do
                local pathKey = Merge().PathKey(entry.path)
                if IsLocked(pathKey) then
                    lockedInGroup = lockedInGroup + 1
                elseif IsSelected(pathKey) then
                    selectedInGroup = selectedInGroup + 1
                end
            end
            local selectable = #group.entries - lockedInGroup

            -- A fully locked group is filtered out of this tree entirely, so any group
            -- shown here has at least one mergeable difference
            local lockNote = (lockedInGroup > 0)
                and string.format("  |cff%s%d locked|r", C.RED_HEX, lockedInGroup) or ""

            row.toggle:SetText(expanded[group.key] and "-" or "+")
            row.label:SetFontObject("GameFontNormalSmall")
            row.label:SetText(string.format("|cff%s%s|r  |cff%s%d|r%s",
                C.ORANGE_HEX, group.label, C.DIM_HEX, item.matches, lockNote))
            row.values:SetText(selectedInGroup > 0
                and string.format("|cff%s%d selected|r", C.GREEN_HEX, selectedInGroup) or "")

            row.fill:SetShown(selectedInGroup > 0)
            if selectedInGroup > 0 and selectedInGroup < selectable then
                row.fill:SetColorTexture(C.BLUE.r, C.BLUE.g, C.BLUE.b, 1)
            else
                row.fill:SetColorTexture(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
            end

            local function GroupClick(_, button)
                if button == "RightButton" then
                    -- Lock or unlock the whole group
                    local lockAll = (lockedInGroup < #group.entries)
                    for _, entry in ipairs(group.entries) do
                        SetLocked(Merge().PathKey(entry.path), lockAll)
                    end
                else
                    local takeAll = (selectedInGroup < selectable)
                    for _, entry in ipairs(group.entries) do
                        if EntryMatchesFilter(group, entry) then
                            SetSelected(Merge().PathKey(entry.path), takeAll)
                        end
                    end
                end
                Refresh()
            end

            row.box:SetScript("OnClick", GroupClick)
            row:SetScript("OnClick", function(_, button)
                if button == "RightButton" then
                    GroupClick(nil, button)
                else
                    expanded[group.key] = not expanded[group.key]
                    Refresh()
                end
            end)

        else -- entry
            local entry = item.entry
            local pathKey = Merge().PathKey(entry.path)
            local locked = item.locked
            local yours, theirs = Merge().DescribePair(entry.target, entry.source)

            row.label:SetText(string.format("%s%s%s",
                item.inLockedList and "      " or "    ",
                locked and ("|cff" .. C.RED_HEX .. "[locked]|r ") or "",
                locked and ("|cff" .. C.DIM_HEX .. entry.label .. "|r") or entry.label))

            row.values:SetText(string.format("%s  |cff%s->|r  |cff%s%s|r",
                locked and ("|cff" .. C.DIM_HEX .. yours .. "|r") or yours,
                C.DIM_HEX,
                locked and C.DIM_HEX or C.BLUE_HEX, theirs))

            if locked then
                row.fill:Show()
                row.fill:SetColorTexture(C.RED.r, C.RED.g, C.RED.b, 1)
            else
                row.fill:SetShown(IsSelected(pathKey))
                row.fill:SetColorTexture(C.ORANGE.r, C.ORANGE.g, C.ORANGE.b, 1)
            end

            local function EntryClick(_, button)
                local group = item.group
                if group.atomic then
                    -- These sections reference each other, so they are taken or left as
                    -- a set; toggling one member toggles all of them
                    if button == "RightButton" then
                        local lockAll = not IsLocked(pathKey)
                        for _, other in ipairs(group.entries) do
                            SetLocked(Merge().PathKey(other.path), lockAll)
                        end
                    elseif not IsLocked(pathKey) then
                        local takeAll = not IsSelected(pathKey)
                        for _, other in ipairs(group.entries) do
                            SetSelected(Merge().PathKey(other.path), takeAll)
                        end
                    end
                elseif button == "RightButton" then
                    SetLocked(pathKey, not IsLocked(pathKey))
                elseif not IsLocked(pathKey) then
                    SetSelected(pathKey, not IsSelected(pathKey))
                end
                Refresh()
            end

            row.box:SetScript("OnClick", EntryClick)
            row:SetScript("OnClick", EntryClick)
        end
    end

    for index = shown + 1, #rowPool do
        rowPool[index]:Hide()
    end

    listContent:SetHeight(math.max(shown * ROW_HEIGHT, 1))
    return shown
end

-- ------------------------------------------------------------------------------------
-- Page
-- ------------------------------------------------------------------------------------

local function ProfileValues()
    local entries = {}
    for _, name in ipairs(Merge():GetProfileNames()) do
        local active = (name == Merge():GetActiveProfile())
        entries[#entries + 1] = { value = name, text = active and (name .. "  (active)") or name }
    end
    if #entries == 0 then entries[1] = { value = "", text = "(EllesmereUI not loaded)" } end
    return entries
end

function LingkanUI:InitEUIProfileMerge()
    local parent = LingkanUI.MainFrame.Content
    local db = Settings()

    W:CachedPanel(cache, "euiMerge", parent, function(panel)
        local summary, listContent, listScroll, truncated

        W:CreatePageHeader(panel,
            { { "PROFILE ", C.BLUE }, { "MERGE", C.ORANGE } },
            "Pull individual settings from another EllesmereUI profile into yours.")

        local function Recompare()
            local groups, total = Merge():BuildDiff(db.sourceProfile, db.targetProfile,
                db.ignoreTinyNumbers)
            if not groups then
                diffGroups = nil
                return nil, total
            end
            diffGroups, diffTotal = groups, total
            return total
        end

        -- Profile pickers --------------------------------------------------------------
        W:CreateDropdown(panel, {
            label = "Merge from",
            desc = "The profile to take settings from, e.g. a freshly imported upstream profile.",
            db = db, key = "sourceProfile",
            values = ProfileValues,
            x = 14, y = -70, width = 180,
            onChange = function() diffGroups = nil; Refresh() end,
        })

        W:CreateDropdown(panel, {
            label = "Into",
            desc = "Your profile, which the differences are measured against.",
            db = db, key = "targetProfile",
            values = ProfileValues,
            x = 204, y = -70, width = 180,
            onChange = function() diffGroups = nil; Refresh() end,
        })

        local destinationInput = W:CreateComboBox(panel, {
            label = "Write result to",
            desc = "Type a new profile name, or pick an existing one from the arrow.",
            db = db, key = "destinationProfile",
            values = ProfileValues,
            x = 394, y = -70, width = 180,
            disabled = function() return db.mergeInPlace end,
            onChange = function() Refresh() end,
        })

        W:CreateCheckbox(panel, {
            label = "Merge in place",
            desc = "Write straight into the profile being merged into, instead of a separate one.",
            db = db, key = "mergeInPlace",
            x = 396, y = -124,
            onChange = function() Refresh() end,
        })

        local inPlaceWarning = W:CreateLabel(panel, "", { x = 14, y = -140, width = 370 })

        W:CreateButton(panel, {
            label = "Compare",
            desc = "Build the list of differences between the two profiles.",
            point = "LEFT", relativeTo = destinationInput.editBox, relativePoint = "RIGHT",
            x = 12, y = 0, width = 90, height = 22,
            func = function()
                local total, err = Recompare()
                if not total then
                    LingkanUI:Print("Compare failed: " .. tostring(err))
                else
                    wipe(expanded)
                end
                Refresh()
            end,
        })

        -- Summary and filtering ----------------------------------------------------------
        summary = W:CreateLabel(panel, "", { x = 14, y = -166 })

        local filterInput = W:CreateTextInput(panel, {
            label = "Filter",
            desc = "Show only settings whose name or group contains this text.",
            get = function() return filterText end,
            set = function(value) filterText = strtrim(value or "") end,
            onChange = function() Refresh() end,
            x = 14, y = -186, width = 200,
        })

        local function ForEachFiltered(fn)
            if not diffGroups then return end
            for _, group in ipairs(diffGroups) do
                for _, entry in ipairs(group.entries) do
                    if EntryMatchesFilter(group, entry) then fn(entry) end
                end
            end
        end

        local selectAllButton = W:CreateButton(panel, {
            label = "Select All",
            desc = "Select every unlocked difference currently listed.",
            point = "LEFT", relativeTo = filterInput.editBox, relativePoint = "RIGHT",
            x = 10, y = 0, width = 88, height = 22,
            func = function()
                ForEachFiltered(function(e) SetSelected(Merge().PathKey(e.path), true) end)
                Refresh()
            end,
        })

        local selectNoneButton = W:CreateButton(panel, {
            label = "Select None",
            point = "LEFT", relativeTo = selectAllButton, relativePoint = "RIGHT",
            x = 6, y = 0, width = 88, height = 22,
            func = function()
                ForEachFiltered(function(e) SetSelected(Merge().PathKey(e.path), false) end)
                Refresh()
            end,
        })

        local expandAllButton = W:CreateButton(panel, {
            label = "Expand All",
            point = "LEFT", relativeTo = selectNoneButton, relativePoint = "RIGHT",
            x = 6, y = 0, width = 88, height = 22,
            func = function()
                if diffGroups then
                    for _, group in ipairs(diffGroups) do expanded[group.key] = true end
                end
                Refresh()
            end,
        })

        local collapseAllButton = W:CreateButton(panel, {
            label = "Collapse All",
            point = "LEFT", relativeTo = expandAllButton, relativePoint = "RIGHT",
            x = 6, y = 0, width = 88, height = 22,
            func = function() wipe(expanded); Refresh() end,
        })

        W:CreateButton(panel, {
            label = "Clear Locks",
            desc = "Unlock every setting.",
            point = "LEFT", relativeTo = collapseAllButton, relativePoint = "RIGHT",
            x = 6, y = 0, width = 88, height = 22,
            danger = true,
            disabled = function() return next(db.locked) == nil end,
            func = function() wipe(db.locked); Refresh() end,
        })

        W:CreateCheckbox(panel, {
            label = "Ignore sub-pixel numeric differences",
            desc = "Frame positions drift by fractions of a pixel between profiles. " ..
                "With this on, numbers within 0.1% of each other are treated as equal.",
            db = db, key = "ignoreTinyNumbers",
            x = 14, y = -236,
            onChange = function()
                if diffGroups then Recompare() end
                Refresh()
            end,
        })

        truncated = W:CreateLabel(panel, "", { x = 300, y = -236, color = C.ORANGE })

        -- Diff list --------------------------------------------------------------------
        local listFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
        listFrame:SetPoint("TOPLEFT", 10, -262)
        listFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 56)
        W.ApplyBackdrop(listFrame,
            { r = 0, g = 0, b = 0, a = 0.25 },
            { r = C.DARK_BLUE.r, g = C.DARK_BLUE.g, b = C.DARK_BLUE.b, a = 0.4 })

        listScroll, listContent = W:CreateScrollFrame(listFrame, 1)

        -- Footer -----------------------------------------------------------------------
        W:CreateButton(panel, {
            label = "Merge Selected",
            desc = "Write the selected values into the destination profile. Locked settings are skipped.",
            point = "BOTTOMLEFT", x = 14, y = 16,
            width = 150, height = 26,
            disabled = function() return (select(1, Tally())) == 0 end,
            func = function()
                local chosen = {}
                for _, group in ipairs(diffGroups or {}) do
                    for _, entry in ipairs(group.entries) do
                        local pathKey = Merge().PathKey(entry.path)
                        if IsSelected(pathKey) and not IsLocked(pathKey) then
                            chosen[#chosen + 1] = entry
                        end
                    end
                end

                local count, err = Merge():Apply(db.sourceProfile, db.targetProfile,
                    Destination(), chosen)
                if not count then
                    LingkanUI:Print("Merge failed: " .. tostring(err))
                    return
                end

                LingkanUI:Print(("Merged %d setting%s from '%s' into '%s'."):format(
                    count, count == 1 and "" or "s", db.sourceProfile, Destination()))

                Recompare()
                Refresh()
            end,
        })

        W:CreateButton(panel, {
            label = "Switch To Result",
            desc = "Switch EllesmereUI to the destination profile.",
            point = "BOTTOMLEFT", x = 174, y = 16,
            width = 140, height = 26,
            disabled = function() return not Merge():ProfileExists(Destination()) end,
            func = function()
                if Merge():SwitchTo(Destination()) then
                    LingkanUI:Print("Switched to '" .. tostring(Destination()) .. "'.")
                else
                    LingkanUI:Print("Could not switch; use EllesmereUI's profile list.")
                end
            end,
        })

        local hint = W:CreateLabel(panel, "", { x = 0, y = 0, color = C.DIM })
        hint:ClearAllPoints()
        hint:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 324, 24)
        hint:SetPoint("RIGHT", panel, "RIGHT", -10, 0)
        hint:SetText("Left-click to select, right-click to lock as yours. Left value is " ..
            "yours, right is theirs. Sections that are not compared keep the 'Into' values.")

        -- Refresh ----------------------------------------------------------------------
        Refresh = function()
            if not diffGroups then
                summary:SetText("|cff" .. C.DIM_HEX .. "Press Compare to list the differences.|r")
                if Destination() == db.targetProfile then
                    inPlaceWarning:SetText("|cff" .. C.ORANGE_HEX .. "Merging in place: '" ..
                        tostring(db.targetProfile) .. "' is modified directly.|r")
                else
                    inPlaceWarning:SetText("")
                end
                truncated:SetText("")
                for _, row in ipairs(rowPool) do row:Hide() end
                listContent:SetHeight(1)
                if listScroll.UpdateScrollRange then listScroll.UpdateScrollRange() end
                W:RefreshAll()
                return
            end

            local destination = Destination()
            if destination == db.targetProfile then
                inPlaceWarning:SetText("|cff" .. C.ORANGE_HEX .. "Merging in place: '" ..
                    tostring(destination) .. "' is modified directly.|r")
            elseif Merge():ProfileExists(destination) then
                inPlaceWarning:SetText("|cff" .. C.ORANGE_HEX .. "Overwrites the existing profile '" ..
                    tostring(destination) .. "'.|r")
            else
                inPlaceWarning:SetText("|cff" .. C.DIM_HEX .. "Creates a new profile '" ..
                    tostring(destination) .. "', leaving yours untouched.|r")
            end

            local selectedCount, lockedCount = Tally()
            summary:SetText(string.format(
                "|cff%s%d|r difference%s in |cff%s%d|r group%s   |cff%s%d selected|r   |cff%s%d locked|r",
                C.BLUE_HEX, diffTotal, diffTotal == 1 and "" or "s",
                C.BLUE_HEX, #diffGroups, #diffGroups == 1 and "" or "s",
                selectedCount > 0 and C.GREEN_HEX or C.DIM_HEX, selectedCount,
                lockedCount > 0 and C.RED_HEX or C.DIM_HEX, lockedCount))

            BuildVisibleRows()
            local shown = RenderRows(listContent)

            if #visibleRows > shown then
                truncated:SetText(string.format("Showing %d of %d rows - narrow it with the filter.",
                    shown, #visibleRows))
            else
                truncated:SetText("")
            end

            if listScroll.UpdateScrollRange then listScroll.UpdateScrollRange() end
            W:RefreshAll()
        end

        panel:HookScript("OnShow", function()
            -- Profiles may have changed since the page was last open
            diffGroups = nil
            Refresh()
        end)

        Refresh()
    end)
end
