local ADDON_NAME, LingkanUI = ...

local C = LingkanUI.COLORS
local W = LingkanUI.Widgets
local cache = {}

function LingkanUI:InitRoleIcons()
    local parent = LingkanUI.MainFrame.Content
    local db = LingkanUI.db.profile.roleIcons

    local function IsOff() return not db.enabled end
    local function IsRaidOff() return not db.enabled or not db.raid end

    W:CachedPanel(cache, "roleIcons", parent, function(panel)
        local _, content = W:CreateScrollFrame(panel, 620)

        W:CreatePageHeader(content,
            { { "ROLE ", C.BLUE }, { "ICONS", C.ORANGE } },
            "Show role icons across the raid tab, chat, tooltips and unit frames.")

        if not LingkanUI.Version.isRetail then
            W:CreateLabel(content,
                "|cff" .. C.ORANGE_HEX .. "Role Icons are only available on retail clients.|r",
                { x = 14, y = -84 })
            return
        end

        W:CreateCheckbox(content, {
            label = "Enable Role Icons",
            desc = "Enable the role icon display module.",
            db = db, key = "enabled",
            x = 14, y = -84,
            isMaster = true,
            onChange = function(value)
                if value then
                    LingkanUI.RoleIcons:Load()
                else
                    LingkanUI.RoleIcons:Unload()
                end
            end,
        })

        -- Display Options -------------------------------------------------------------
        local displayWrapper, displayContent = W:CreateCollapsibleSection(content, {
            text = "Display Options",
            x = 14, y = -120,
            startOpen = true,
        })

        local displayToggles = {
            { key = "raid",    label = "Raid Frame",       desc = "Show role icons on the Raid tab." },
            { key = "tooltip", label = "Tooltips",         desc = "Show role icons in player tooltips." },
            { key = "chat",    label = "Chat",             desc = "Show role icons in chat windows." },
            { key = "system",  label = "System Messages",  desc = "Show role icons in system messages." },
            { key = "target",  label = "Target Frame",     desc = "Show role icons on the target frame." },
            { key = "focus",   label = "Focus Frame",      desc = "Show role icons on the focus frame." },
            { key = "popup",   label = "Unit Popup Menus", desc = "Show role icons in unit popup menus." },
            { key = "map",     label = "Map Tooltips",     desc = "Show role icons in map tooltips." },
        }

        for index, toggle in ipairs(displayToggles) do
            W:CreateCheckbox(displayContent, {
                label = toggle.label,
                desc = toggle.desc,
                db = db, key = toggle.key,
                x = 10, y = -6 - ((index - 1) * 24),
                disabled = IsOff,
            })
        end
        displayContent:SetHeight(#displayToggles * 24 + 10)
        displayWrapper:RecalcHeight()

        -- Raid Frame Options ----------------------------------------------------------
        local raidWrapper, raidContent = W:CreateCollapsibleSection(content, {
            text = "Raid Frame Options",
            x = 14, y = 0,
            startOpen = false,
        })
        raidWrapper:ClearAllPoints()
        raidWrapper:SetPoint("TOPLEFT", displayWrapper, "BOTTOMLEFT", 0, -6)
        raidWrapper:SetPoint("RIGHT", content, "RIGHT", -10, 0)

        local raidToggles = {
            { key = "classbuttons", label = "Class Summary Buttons", desc = "Add class summary buttons to the Raid tab." },
            { key = "rolebuttons",  label = "Role Summary Buttons",  desc = "Add role summary buttons to the Raid tab." },
            { key = "serverinfo",   label = "Server Info Frame",     desc = "Add a server info frame to the Raid tab." },
        }

        for index, toggle in ipairs(raidToggles) do
            W:CreateCheckbox(raidContent, {
                label = toggle.label,
                desc = toggle.desc,
                db = db, key = toggle.key,
                x = 10, y = -6 - ((index - 1) * 24),
                disabled = IsRaidOff,
            })
        end
        raidContent:SetHeight(#raidToggles * 24 + 10)
        raidWrapper:RecalcHeight()

        -- Miscellaneous ---------------------------------------------------------------
        local miscWrapper, miscContent = W:CreateCollapsibleSection(content, {
            text = "Miscellaneous",
            x = 14, y = 0,
            startOpen = false,
        })
        miscWrapper:ClearAllPoints()
        miscWrapper:SetPoint("TOPLEFT", raidWrapper, "BOTTOMLEFT", 0, -6)
        miscWrapper:SetPoint("RIGHT", content, "RIGHT", -10, 0)

        local miscToggles = {
            { key = "trimserver", label = "Trim Server Names",    desc = "Trim realm names in tooltips." },
            { key = "autorole",   label = "Auto Role Assignment", desc = "Automatically set your role and answer role checks based on your spec." },
        }

        for index, toggle in ipairs(miscToggles) do
            W:CreateCheckbox(miscContent, {
                label = toggle.label,
                desc = toggle.desc,
                db = db, key = toggle.key,
                x = 10, y = -6 - ((index - 1) * 24),
                disabled = IsOff,
            })
        end
        miscContent:SetHeight(#miscToggles * 24 + 10)
        miscWrapper:RecalcHeight()
    end)
end
