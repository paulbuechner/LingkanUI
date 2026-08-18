local ADDON_NAME, LingkanUI = ...

-- ------------------------------------------------------------------------------------
-- EllesmereUI profile merger
--
-- Compares two EllesmereUI profiles and lets individual differences be pulled from one
-- into the other. The case it exists for: a customised profile derived from a published
-- one, where the published profile gets updated and the useful parts of that update need
-- to come across without flattening the customisations.
--
-- All EllesmereUI profile data lives in one table:
--   EllesmereUIDB.profiles[name].addons[folder] = { ... }
-- plus sibling sections for layout, fonts and colours. Action bar spells are the one
-- thing kept outside it, in EllesmereUIDB.spellAssignments.profiles[name].
-- ------------------------------------------------------------------------------------

LingkanUI.EUIProfileMerge = {}
local Merge = LingkanUI.EUIProfileMerge

local MODULE_NAME = "euiMerge"

local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

-- Sections compared key by key. Spec and condition overrides are handled separately as
-- one atomic block, see OVERRIDE_SECTIONS below.
--
-- Bookkeeping the addon owns (_migrations, _importEstablishPending) is deliberately
-- absent from both lists and must never be copied: _migrations records which schema
-- upgrades have run against this profile, and taking another profile's copy would make
-- EllesmereUI skip upgrades it still needs.
--
-- Anything not listed anywhere keeps the value already in the destination, which is a
-- full copy of the profile being merged into.
local SECTIONS = {
    { key = "addons",           label = "Addon settings", perFolder = true },
    { key = "unlockLayout",     label = "Frame positions" },
    { key = "unlockLayoutMeta", label = "Layout metadata" },
    { key = "fonts",            label = "Fonts" },
    { key = "customColors",     label = "Custom colours" },
    { key = "darkMode",         label = "Dark mode" },
    { key = "euiAccent",        label = "Accent colour" },
    { key = "tooltipFixedPos",  label = "Tooltip position" },
    { key = "uiScale",          label = "UI scale" },
}
Merge.SECTIONS = SECTIONS

local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[k] = DeepCopy(v) end
    return copy
end
Merge.DeepCopy = DeepCopy

local function ProfilesDB()
    local EUI = _G.EllesmereUI
    if EUI and EUI.GetProfilesDB then
        local ok, db = pcall(EUI.GetProfilesDB)
        if ok then return db end
    end
    return _G.EllesmereUIDB
end
Merge.ProfilesDB = ProfilesDB

function Merge:GetProfileNames()
    local db = ProfilesDB()
    local names = {}
    if not (db and type(db.profiles) == "table") then return names end

    for name in pairs(db.profiles) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function Merge:GetActiveProfile()
    local db = ProfilesDB()
    return db and db.activeProfile
end

function Merge:ProfileExists(name)
    local db = ProfilesDB()
    return name and db and type(db.profiles) == "table" and type(db.profiles[name]) == "table"
end

local function FormatNumber(value, precision)
    if value == math.floor(value) then return tostring(value) end
    return string.format("%." .. precision .. "g", value)
end

-- Short readable form of a value for the diff rows
function Merge.Describe(value)
    local valueType = type(value)
    if value == nil then return "|cff666666(not set)|r" end
    if valueType == "boolean" then return value and "true" or "false" end
    if valueType == "number" then return FormatNumber(value, 4) end
    if valueType == "string" then
        if #value > 34 then return '"' .. value:sub(1, 31) .. '..."' end
        return '"' .. value .. '"'
    end
    if valueType == "table" then
        local count = 0
        for _ in pairs(value) do count = count + 1 end
        return string.format("|cff666666{%d keys}|r", count)
    end
    return tostring(value)
end

-- Formats a pair for display, raising precision until the two actually read differently.
-- Without this, two positions a few thousandths apart both render as "-243.2" and the row
-- looks like a difference between identical values.
function Merge.DescribePair(target, source)
    if type(target) == "number" and type(source) == "number" then
        for precision = 4, 14 do
            local left, right = FormatNumber(target, precision), FormatNumber(source, precision)
            if left ~= right then return left, right end
        end
    end
    return Merge.Describe(target), Merge.Describe(source)
end

-- Frame positions are stored as floats and drift by fractions of a pixel, which produces
-- a wall of differences nobody wants to review. A relative tolerance filters that noise
-- while keeping genuinely different values: 0.1% of the larger magnitude, so -243.238 vs
-- -243.242 is noise, while alpha 0.65 vs 0.70 is not.
local NUMBER_TOLERANCE = 1e-3

local function ValuesEqual(a, b, tolerant)
    if a == b then return true end
    if not (tolerant and type(a) == "number" and type(b) == "number") then return false end

    local difference = math.abs(a - b)
    if difference <= 1e-9 then return true end

    local scale = math.max(math.abs(a), math.abs(b))
    return difference <= scale * NUMBER_TOLERANCE
end

-- ------------------------------------------------------------------------------------
-- Diff
-- ------------------------------------------------------------------------------------

-- Walks `source` against `target`, appending one entry per differing leaf. A table on
-- one side and a scalar (or nothing) on the other is reported as a single entry for the
-- whole subtree, since merging half of it would be meaningless.
local function Walk(source, target, pathParts, prefix, entries, tolerant)
    local keys = {}
    for key in pairs(source) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

    for _, key in ipairs(keys) do
        local sourceValue = source[key]
        local targetValue
        if type(target) == "table" then targetValue = target[key] end

        local label = (prefix == "") and tostring(key) or (prefix .. "." .. tostring(key))
        pathParts[#pathParts + 1] = key

        if type(sourceValue) == "table" and type(targetValue) == "table" then
            Walk(sourceValue, targetValue, pathParts, label, entries, tolerant)
        elseif not ValuesEqual(sourceValue, targetValue, tolerant) then
            entries[#entries + 1] = {
                path = DeepCopy(pathParts),
                label = label,
                source = sourceValue,
                target = targetValue,
                added = (targetValue == nil),
            }
        end

        pathParts[#pathParts] = nil
    end
end

-- The spec and condition override tables, which reference each other: an override names
-- a group id, and nextId hands out the next free one. They are offered as one atomic
-- block rather than key by key, so a set taken from a profile stays internally
-- consistent. Anything not present in a profile is simply skipped.
local OVERRIDE_SECTIONS = {
    "specOverrides", "specOverrideGroups", "specOverrideNextId",
    "specUnlockOverrides", "specBmOverrides",
    "condOverrides", "condOverrideGroups", "condUnlockOverrides", "condBmOverrides",
}
Merge.OVERRIDE_SECTIONS = OVERRIDE_SECTIONS
Merge.OVERRIDE_GROUP_KEY = "__overrides"

local function DeepEqual(a, b, tolerant)
    if ValuesEqual(a, b, tolerant) then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end

    for key, value in pairs(a) do
        if not DeepEqual(value, b[key], tolerant) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

-- Returns an array of groups: { key, label, entries = { ... } }
function Merge:BuildDiff(sourceName, targetName, tolerant)
    local db = ProfilesDB()
    if not (db and type(db.profiles) == "table") then
        return nil, "EllesmereUI profiles are not available"
    end
    if sourceName == targetName then
        return nil, "source and target are the same profile"
    end

    local source = db.profiles[sourceName]
    local target = db.profiles[targetName]
    if type(source) ~= "table" then return nil, "profile '" .. tostring(sourceName) .. "' not found" end
    if type(target) ~= "table" then return nil, "profile '" .. tostring(targetName) .. "' not found" end

    local groups, total = {}, 0

    local function AddGroup(key, label, sourceValue, targetValue, rootPath)
        local entries = {}

        if type(sourceValue) == "table" then
            Walk(sourceValue, targetValue, DeepCopy(rootPath), "", entries, tolerant)
        elseif not ValuesEqual(sourceValue, targetValue, tolerant) then
            entries[1] = {
                path = DeepCopy(rootPath),
                label = key,
                source = sourceValue,
                target = targetValue,
                added = (targetValue == nil),
            }
        end

        if #entries > 0 then
            groups[#groups + 1] = { key = key, label = label, entries = entries }
            total = total + #entries
        end
    end

    for _, section in ipairs(SECTIONS) do
        local sourceSection = source[section.key]
        local targetSection = target[section.key]

        if section.perFolder and type(sourceSection) == "table" then
            -- One group per addon folder, so the list is navigable
            local folders = {}
            for folder in pairs(sourceSection) do folders[#folders + 1] = folder end
            table.sort(folders)

            for _, folder in ipairs(folders) do
                local pretty = folder:gsub("^EllesmereUI", "")
                if pretty == "" then pretty = folder end
                AddGroup(section.key .. "." .. folder, pretty,
                    sourceSection[folder],
                    (type(targetSection) == "table") and targetSection[folder] or nil,
                    { section.key, folder })
            end
        elseif sourceSection ~= nil then
            AddGroup(section.key, section.label, sourceSection, targetSection, { section.key })
        end
    end

    -- Overrides last, as one atomic group: whole sections replaced together
    local overrideEntries = {}
    for _, key in ipairs(OVERRIDE_SECTIONS) do
        local sourceValue, targetValue = source[key], target[key]
        if sourceValue ~= nil and not DeepEqual(sourceValue, targetValue, tolerant) then
            overrideEntries[#overrideEntries + 1] = {
                path = { key },
                label = key,
                source = sourceValue,
                target = targetValue,
                added = (targetValue == nil),
                wholeSection = true,
            }
        end
    end

    if #overrideEntries > 0 then
        groups[#groups + 1] = {
            key = Merge.OVERRIDE_GROUP_KEY,
            label = "Spec overrides (all together)",
            entries = overrideEntries,
            atomic = true,
        }
        total = total + #overrideEntries
    end

    DebugPrint(("Diff %s -> %s: %d differences in %d groups"):format(
        sourceName, targetName, total, #groups))

    return groups, total
end

-- Stable identifier for a diff entry, used to remember selections between sessions.
-- "/" rather than a control character so it round-trips cleanly through SavedVariables.
function Merge.PathKey(path)
    return table.concat(path, "/")
end

-- ------------------------------------------------------------------------------------
-- Apply
-- ------------------------------------------------------------------------------------

local function SetByPath(root, path, value)
    local node = root
    for index = 1, #path - 1 do
        local key = path[index]
        if type(node[key]) ~= "table" then node[key] = {} end
        node = node[key]
    end
    node[path[#path]] = DeepCopy(value)
end

-- Writes the chosen entries from source into the target profile. When `intoName` differs
-- from `targetName` the target is copied first, leaving the original untouched.
function Merge:Apply(sourceName, targetName, intoName, chosen)
    local db = ProfilesDB()
    if not (db and type(db.profiles) == "table") then
        return nil, "EllesmereUI profiles are not available"
    end

    local source = db.profiles[sourceName]
    local target = db.profiles[targetName]
    if type(source) ~= "table" then return nil, "profile '" .. tostring(sourceName) .. "' not found" end
    if type(target) ~= "table" then return nil, "profile '" .. tostring(targetName) .. "' not found" end

    intoName = strtrim(intoName or "")
    if intoName == "" then return nil, "no destination profile name set" end
    if intoName == sourceName then return nil, "the destination would overwrite the source profile" end
    if not chosen or #chosen == 0 then return nil, "nothing selected to merge" end

    local destination
    if intoName == targetName then
        destination = target
    else
        destination = DeepCopy(target)
        db.profiles[intoName] = destination

        -- Action bar spells live outside the profile table; a copy without them renders
        -- the bars empty
        local spells = db.spellAssignments
        if type(spells) == "table" and type(spells.profiles) == "table" then
            local assignments = spells.profiles[targetName]
            if type(assignments) == "table" then
                spells.profiles[intoName] = DeepCopy(assignments)
            end
        end

        if type(db.profileOrder) ~= "table" then db.profileOrder = {} end
        local listed = false
        for _, name in ipairs(db.profileOrder) do
            if name == intoName then listed = true break end
        end
        if not listed then table.insert(db.profileOrder, 1, intoName) end
    end

    for _, entry in ipairs(chosen) do
        SetByPath(destination, entry.path, entry.source)
    end

    DebugPrint(("Merged %d values from '%s' into '%s'"):format(#chosen, sourceName, intoName))
    return #chosen
end

function Merge:SwitchTo(name)
    local EUI = _G.EllesmereUI
    if not (EUI and EUI.SwitchProfile) then return false end
    if not self:ProfileExists(name) then return false end
    return (pcall(EUI.SwitchProfile, name))
end
