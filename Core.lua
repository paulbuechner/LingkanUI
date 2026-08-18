local ADDON_NAME, LingkanUI = ...

-- Addon version, shown in the sidebar header. The number comes from the TOC.
LingkanUI.versionStage = "RELEASE"
LingkanUI.versionNumber = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "0.0.0"

-- ------------------------------------------------------------------------------------
-- Database defaults
--
-- Carried over unchanged from the former Core/Options/Options.lua so that existing
-- LingkanUIDB saved variables keep working across the UI rewrite. Do not reshape these
-- keys without a migration.
-- ------------------------------------------------------------------------------------

LingkanUI.defaults = {
    profile = {
        general = {
            developerMode = false,
            interface = {
                debug = false,
                hideUIErrors = false,
            },
        },
        sheath = {
            enabled = false,
            mode = "KEEP_UNSHEATED", -- "KEEP_SHEATED" or "KEEP_UNSHEATED"
            meleeOnly = false,
            rangedOnly = false,
            debug = false,
        },
        lean = {
            enabled = false,
            debug = false,
        },
        tabTargetArenaFix = {
            enabled = false,
            showMessages = true,
            debug = false,
        },
        roleIcons = {
            enabled = false,
            raid = true,
            tooltip = false,
            chat = true,
            system = true,
            classbuttons = true,
            rolebuttons = false,
            serverinfo = true,
            trimserver = true,
            autorole = true,
            target = true,
            focus = true,
            popup = true,
            map = true,
            debug = false,
        },
        betterCharacterPanel = {
            enabled = false,
            debug = false,
            showItemLevel = true,
            showEnchants = true,
            showDurability = true,
            showSockets = true,
            scale = 1,
        },
        interface = {
            healthPercent = {
                enabled = false,
                font = "Fonts\\FRIZQT__.TTF",
                fontsize = 12,
                outline = "OUTLINE",
                anchorFrom = "TOPLEFT",
                anchorTo = "TOPLEFT",
                offsetX = 0,
                offsetY = 0,
                debug = false,
            },
            healthAbsolute = {
                enabled = false,
                font = "Fonts\\FRIZQT__.TTF",
                fontsize = 12,
                outline = "OUTLINE",
                anchorFrom = "RIGHT",
                anchorTo = "RIGHT",
                offsetX = 0,
                offsetY = 0,
                debug = false,
            },
            targetPercent = {
                enabled = false,
                font = "Fonts\\FRIZQT__.TTF",
                fontsize = 12,
                outline = "OUTLINE",
                anchorFrom = "RIGHT",
                anchorTo = "RIGHT",
                offsetX = 0,
                offsetY = 0,
                debug = false,
            },
            targetAbsolute = {
                enabled = false,
                font = "Fonts\\FRIZQT__.TTF",
                fontsize = 12,
                outline = "OUTLINE",
                anchorFrom = "LEFT",
                anchorTo = "LEFT",
                offsetX = 0,
                offsetY = 0,
                debug = false,
            },
        },
        zoneText = {
            enabled = false,
            zoneSize = 32,
            subZoneSize = 25,
            debug = false,
        },
        chatBubbles = {
            enabled = false,
            fontSize = 12,
            senderFontSize = 12,
            debug = false,
        },
        euiMerge = {
            -- Interactive merge between two EllesmereUI profiles.
            -- See Modules/EUIProfileMerge.lua
            sourceProfile = "Naowh",
            targetProfile = "LUI",
            destinationProfile = "LUI Merged",
            -- Write straight into targetProfile instead of a separate one
            mergeInPlace = false,
            -- Remembered per-setting choices, keyed by path, so a re-run of the same
            -- merge does not have to be reviewed from scratch
            selected = {},
            -- Settings pinned as "keep mine": never selectable, never merged
            locked = {},
            -- Frame positions drift by fractions of a pixel between profiles; without
            -- this the diff is mostly noise
            ignoreTinyNumbers = true,
            debug = false,
        },
        minimap = {
            hide = false,
            minimapPos = 220,
        },
        config = {
            lastTab = nil,
        },
    }
}

-- ------------------------------------------------------------------------------------
-- Output helpers (replaces AceConsole-3.0)
-- ------------------------------------------------------------------------------------

function LingkanUI:Print(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring((select(i, ...)))
    end
    DEFAULT_CHAT_FRAME:AddMessage(LingkanUI.TITLE .. ": " .. table.concat(parts, " "))
end

-- Debug print gated per module by its own `debug` flag (or the General debug flag)
function LingkanUI:DebugPrint(message, module)
    if not (module and self.db and self.db.profile) then
        return
    end

    local debugEnabled = (self.db.profile[module] and self.db.profile[module].debug) or -- Module specific
        (self.db.profile.general[module] and self.db.profile.general[module].debug)     -- General Settings

    if debugEnabled then
        local moduleTag = module and (" [" .. string.upper(module) .. "]") or ""
        self:Print("[DEBUG]" .. moduleTag .. " " .. tostring(message))
    end
end

function LingkanUI:AddToInspector(data, strName)
    if DevTool and self.debug then
        DevTool:AddData(data, strName)
    end
end

-- ------------------------------------------------------------------------------------
-- Named module registry (replaces AceAddon-3.0 NewModule/GetModule)
--
-- The installer under Install/ is built on the AceAddon module pattern
-- (LUI:NewModule("Data"), LUI:GetModule("Setup")). It only ever needs plain named
-- tables -- no OnEnable/OnDisable lifecycle, and the "AceHook-3.0" mixin it asks for is
-- never actually used -- so this shim keeps that subsystem working untouched.
-- ------------------------------------------------------------------------------------

local namedModules = {}

function LingkanUI:NewModule(name)
    if namedModules[name] then return namedModules[name] end

    local module = {
        moduleName = name,
        Print = LingkanUI.Print,
    }
    namedModules[name] = module
    return module
end

function LingkanUI:GetModule(name, silent)
    local module = namedModules[name]
    if not module and not silent then
        error("LingkanUI: module '" .. tostring(name) .. "' does not exist", 2)
    end
    return module
end

-- ------------------------------------------------------------------------------------
-- Event dispatch (replaces AceEvent-3.0)
--
-- Every consumer gets its own frame and handler table. The previous AceEvent setup keyed
-- registrations by (object, event) on a single shared addon object, so Sheathing and
-- TabTargetArenaFix both claiming PLAYER_ENTERING_WORLD silently replaced the core
-- handler -- and their Unload() removed it outright. Isolated frames make that
-- impossible.
-- ------------------------------------------------------------------------------------

local function DispatchEvent(owner, handler, event, ...)
    if type(handler) == "function" then
        handler(event, ...)
    elseif type(handler) == "string" then
        local method = owner[handler]
        if method then
            method(owner, event, ...)
        end
    end
end

-- Adds RegisterEvent/UnregisterEvent/UnregisterAllEvents to `target`, backed by a
-- private frame. Handler may be a function, a method name, or nil (defaults to a method
-- named after the event) -- matching the AceEvent signatures the modules already use.
function LingkanUI:EmbedEvents(target)
    local handlers = {}
    local frame = CreateFrame("Frame")

    frame:SetScript("OnEvent", function(_, event, ...)
        local handler = handlers[event]
        if handler then
            DispatchEvent(target, handler, event, ...)
        end
    end)

    function target:RegisterEvent(event, handler)
        handlers[event] = handler or event
        frame:RegisterEvent(event)
    end

    function target:UnregisterEvent(event)
        handlers[event] = nil
        frame:UnregisterEvent(event)
    end

    function target:UnregisterAllEvents()
        wipe(handlers)
        frame:UnregisterAllEvents()
    end

    return target
end

LingkanUI:EmbedEvents(LingkanUI)

-- ------------------------------------------------------------------------------------
-- Slash commands (replaces AceConsole-3.0 command registration)
-- ------------------------------------------------------------------------------------

function LingkanUI:SlashCommand(input)
    input = strtrim(input or "")
    local cmd = input:match("^(%S+)")
    cmd = cmd and cmd:lower() or ""

    if cmd == "" then
        if LingkanUI.ToggleConfig then
            LingkanUI:ToggleConfig()
        end
        return
    end

    if cmd == "install" then
        if LingkanUI.Installer and LingkanUI.Installer.Show then
            LingkanUI.Installer:Show()
        else
            LingkanUI:Print("Installer not loaded")
        end
        return
    end

    if cmd == "config" or cmd == "options" then
        if LingkanUI.ToggleConfig then
            LingkanUI:ToggleConfig()
        end
        return
    end

    LingkanUI:Print("Usage:")
    LingkanUI:Print("  /lui - Opens the configuration window")
    LingkanUI:Print("  /lui install - Opens the installer")
end

SLASH_LINGKANUI1 = "/lui"
SLASH_LINGKANUI2 = "/lingkanui"
SlashCmdList["LINGKANUI"] = function(input) LingkanUI:SlashCommand(input) end

-- Opened from the AddOn Compartment on the minimap
function LingkanUI_OnAddonCompartmentClick()
    if LingkanUI.ToggleConfig then
        LingkanUI:ToggleConfig()
    end
end

-- ------------------------------------------------------------------------------------
-- Bootstrap (replaces AceAddon-3.0 lifecycle)
-- ------------------------------------------------------------------------------------

LingkanUI:RegisterEvent("ADDON_LOADED", function(_, loadedAddon)
    if loadedAddon ~= ADDON_NAME then return end
    LingkanUI:UnregisterEvent("ADDON_LOADED")

    LingkanUI.db = LibStub("AceDB-3.0"):New("LingkanUIDB", LingkanUI.defaults, true)

    if LingkanUI.OnInitialize then
        LingkanUI:OnInitialize()
    end
end)
