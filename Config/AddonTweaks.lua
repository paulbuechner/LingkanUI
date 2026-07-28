local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

function LingkanUI:InitAddonTweaks()
    local parent = LingkanUI.MainFrame.Content
    local db = LingkanUI.db.profile.naowhUI.damageMeterBg

    local function Apply() LingkanUI.Customizing:EnforceDamageMeterBackground() end

    W:CachedPanel(cache, "addonTweaks", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 520)

        W:CreatePageHeader(content,
            { { "ADDON ", C.BLUE }, { "TWEAKS", C.ORANGE } },
            "Fixes for third-party addons that overwrite settings you want to keep.")

        W:CreateSectionHeader(content, "Damage Meter Background (EllesmereUI / NaowhUI)", 10, -80)

        W:CreateLabel(content,
            "NaowhUI's dark mode forces the damage meter background to 0% opacity and " ..
            "re-applies it on every login, so a value set in EllesmereUI does not survive " ..
            "a reload. Enabling this re-asserts your opacity after each rebuild.",
            { x = 14, y = -102 })

        W:CreateCheckbox(content, {
            label = "Keep Damage Meter Background Opacity",
            desc = "Re-apply the opacity below whenever the meter windows are rebuilt.",
            db = db, key = "enabled",
            x = 14, y = -158,
            isMaster = true,
            onChange = Apply,
        })

        W:CreateSlider(content, {
            label = "Background Opacity",
            desc = "Opacity of the damage meter window background.",
            db = db, key = "alpha",
            min = 0, max = 1, step = 0.01,
            isPercent = true,
            x = 14, y = -194,
            width = 260,
            disabled = function() return not db.enabled end,
            onChange = Apply,
        })

        W:CreateButton(content, {
            label = "Apply Now",
            desc = "Force the opacity onto the meter windows immediately.",
            x = 14, y = -250,
            width = 120, height = 26,
            disabled = function() return not db.enabled end,
            func = Apply,
        })

        W:CreateSeparator(content, 10, -292)

        local status = W:CreateLabel(content, "", { x = 14, y = -308 })

        local function UpdateStatus()
            if not _G.NaowhUIEUI then
                status:SetText("|cff" .. C.DIM_HEX ..
                    "NaowhUI_EUI is not loaded, so nothing is overwriting the background.|r")
            elseif db.enabled then
                status:SetText("|cff" .. C.GREEN_HEX .. "Active|r |cff" .. C.DIM_HEX ..
                    "- your opacity is re-applied after NaowhUI's dark mode pass.|r")
            else
                status:SetText("|cff" .. C.ORANGE_HEX .. "Inactive|r |cff" .. C.DIM_HEX ..
                    "- NaowhUI will keep resetting the background to 0%.|r")
            end
        end

        panel:HookScript("OnShow", UpdateStatus)
        UpdateStatus()

        W:CreateLabel(content,
            "Turning this off leaves the current opacity as-is rather than guessing a " ..
            "previous value. Note that while this is enabled, LingkanUI owns this one " ..
            "setting: changing it in EllesmereUI's own options will be reverted.",
            { x = 14, y = -336, color = C.DIM })
    end)
end
