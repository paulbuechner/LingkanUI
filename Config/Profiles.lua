local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

local newProfileName = ""

local function ProfileList()
    local entries = {}
    if not LingkanUI.db then return entries end

    for _, name in ipairs(LingkanUI.db:GetProfiles()) do
        entries[#entries + 1] = { value = name, text = name }
    end
    table.sort(entries, function(a, b) return a.text < b.text end)
    return entries
end

-- Profiles that are not the active one (valid copy/delete targets)
local function OtherProfileList()
    local entries = {}
    local current = LingkanUI.db and LingkanUI.db:GetCurrentProfile()

    for _, entry in ipairs(ProfileList()) do
        if entry.value ~= current then entries[#entries + 1] = entry end
    end
    return entries
end

function LingkanUI:InitProfiles()
    local parent = LingkanUI.MainFrame.Content
    local SettingsIO = LingkanUI.SettingsIO

    W:CachedPanel(cache, "profiles", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 700)

        W:CreatePageHeader(content,
            { { "PROFILES", C.BLUE } },
            "Switch, copy and share your LingkanUI settings.")

        -- Active profile --------------------------------------------------------------
        W:CreateSectionHeader(content, "Active Profile", 10, -80)

        W:CreateDropdown(content, {
            label = "Current Profile",
            desc = "Switching profiles applies immediately; a reload is needed for module toggles.",
            get = function() return LingkanUI.db:GetCurrentProfile() end,
            set = function(value)
                LingkanUI.db:SetProfile(value)
                LingkanUI:RequestReload()
            end,
            values = ProfileList,
            x = 14, y = -104,
            width = 240,
        })

        W:CreateTextInput(content, {
            label = "New Profile Name",
            get = function() return newProfileName end,
            set = function(value) newProfileName = value end,
            x = 274, y = -104,
            width = 200,
        })

        W:CreateButton(content, {
            label = "Create",
            desc = "Creates and switches to a new profile using default settings.",
            x = 484, y = -126,
            width = 90,
            disabled = function() return strtrim(newProfileName or "") == "" end,
            func = function()
                local name = strtrim(newProfileName or "")
                if name == "" then return end
                LingkanUI.db:SetProfile(name)
                newProfileName = ""
                LingkanUI:Print("Created and switched to profile: " .. name)
                LingkanUI:RequestReload()
            end,
        })

        W:CreateSeparator(content, 10, -166)

        -- Manage ----------------------------------------------------------------------
        W:CreateSectionHeader(content, "Manage", 10, -182)

        local copySource = nil

        W:CreateDropdown(content, {
            label = "Copy From",
            desc = "Copies another profile's settings into the active profile.",
            get = function() return copySource end,
            set = function(value) copySource = value end,
            values = OtherProfileList,
            x = 14, y = -206,
            width = 240,
        })

        W:CreateButton(content, {
            label = "Copy",
            x = 264, y = -228,
            width = 90,
            disabled = function() return copySource == nil end,
            func = function()
                if not copySource then return end
                LingkanUI.db:CopyProfile(copySource)
                LingkanUI:Print("Copied settings from: " .. copySource)
                LingkanUI:RequestReload()
            end,
        })

        W:CreateButton(content, {
            label = "Reset Profile",
            desc = "Restores every setting in the active profile to its default.",
            x = 374, y = -228,
            width = 120,
            danger = true,
            func = function()
                LingkanUI.db:ResetProfile()
                LingkanUI:Print("Active profile reset to defaults.")
                LingkanUI:RequestReload()
            end,
        })

        W:CreateSeparator(content, 10, -268)

        -- Import / Export -------------------------------------------------------------
        W:CreateSectionHeader(content, "Import / Export", 10, -284)

        local ioBox = W:CreateMultiLineInput(content, {
            label = "Profile String",
            x = 14, y = -308,
            width = 460,
            height = 150,
        })

        local status = W:CreateLabel(content, "", { x = 14, y = -488 })

        W:CreateButton(content, {
            label = "Export",
            desc = "Writes the active profile into the box above, ready to copy.",
            x = 14, y = -510,
            width = 110,
            func = function()
                local text, err = SettingsIO:ExportProfile()
                if not text then
                    status:SetText("|cff" .. C.RED_HEX .. "Export failed: " .. tostring(err) .. "|r")
                    return
                end
                ioBox:SetText(text)
                ioBox.SelectAll()
                status:SetText("|cff" .. C.GREEN_HEX ..
                    "Exported. Press Ctrl+C to copy.|r")
            end,
        })

        W:CreateButton(content, {
            label = "Import",
            desc = "Applies a profile string pasted into the box above.",
            x = 134, y = -510,
            width = 110,
            func = function()
                local ok, err = SettingsIO:ImportProfile(ioBox:GetText())
                if ok then
                    status:SetText("|cff" .. C.GREEN_HEX ..
                        "Imported. Reload to apply everything.|r")
                    LingkanUI:RequestReload()
                    W:RefreshAll()
                else
                    status:SetText("|cff" .. C.RED_HEX .. "Import failed: " .. tostring(err) .. "|r")
                end
            end,
        })

        W:CreateButton(content, {
            label = "Clear",
            x = 254, y = -510,
            width = 90,
            func = function()
                ioBox:SetText("")
                status:SetText("")
            end,
        })

        W:CreateLabel(content,
            "Importing merges the string into the active profile; settings it does not " ..
            "mention keep their current value.",
            { x = 14, y = -542, color = C.DIM })
    end)
end
