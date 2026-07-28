local ADDON_NAME, LingkanUI = ...

LingkanUI.Customizing = LingkanUI.Customizing or {}

-- ------------------------------------------------------------------------------------
-- NaowhUI_EUI forces the EllesmereUI damage meter background to fully transparent.
--
-- Its dark-mode pass (NaowhUI_EUI/NaowhUI_Frames.lua) applies a fixed table containing
-- bgAlpha = 0.0 and then calls _G._EDM_Apply() to rebuild every meter window. That pass
-- re-runs from its ReassertFrames() hook on login and on profile switches, so a value
-- set by hand in EllesmereUI never survives a reload. Its override helper only snapshots
-- the previous value the first time, and in this install the stored snapshot already
-- holds bgAlpha = 0, so turning dark mode off restores 0 as well.
--
-- Two things matter for how this is patched:
--
-- 1. _EDM_Apply() must never be called from a hook on itself. The damage meter builds
--    its windows in a staggered C_Timer chain at login, and _EDM_Apply rebuilds them
--    synchronously. The two overlap, and because the windows are globally named
--    (EllesmereUIDMFrame1..5), a second CreateFrame with the same name returns a fresh
--    frame and rebinds the global while the previous one stays parented and visible.
--    The leftovers stack and their backgrounds add up. At 0% alpha that is invisible,
--    which is why it only became noticeable once the background had a real value.
--
-- 2. So instead of rebuilding, restyle the existing windows in place -- the same thing
--    the damage meter's own (private) ns.ApplyBackground does -- and hide any leaked
--    duplicates left behind by that race.
-- ------------------------------------------------------------------------------------

local MODULE_NAME = "naowhUI"
local MAX_DM_WINDOWS = 5 -- matches the damage meter's own MAX_WINDOWS

local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

-- The meter keeps its database in a file-local, so GetAddon(folder).db does not reach
-- it. _G._EDM_DB is exported by the addon itself; the others are fallbacks.
local function GetDamageMeterConfig()
    local db = _G._EDM_DB
    if db and type(db.profile) == "table" and type(db.profile.dm) == "table" then
        return db.profile.dm
    end

    local naowh = _G.NaowhUIEUI
    if naowh and naowh.GetProfile then
        local profile = naowh.GetProfile("EllesmereUIDamageMeters")
        if profile and type(profile.dm) == "table" then
            return profile.dm
        end
    end

    local lite = _G.EllesmereUI and _G.EllesmereUI.Lite
    local registry = lite and lite._dbRegistry
    if type(registry) == "table" then
        for index = 1, #registry do
            local entry = registry[index]
            if entry and entry.folder == "EllesmereUIDamageMeters"
                and type(entry.profile) == "table"
                and type(entry.profile.dm) == "table" then
                return entry.profile.dm
            end
        end
    end

    return nil
end

-- Repaints the window backgrounds that already exist. No teardown, so no rebuild race
-- and no flash.
--
-- Only frame._bg is touched, deliberately. Plenty of other elements carry a _bg of their
-- own -- every damage bar row does (its own barBgAlpha setting), as do the summary cards
-- and some buttons -- and they are drawn on top of the window background. Painting those
-- with the window colour stacks a second layer and makes the result look roughly twice
-- as opaque as configured.
--
-- The per-source detail pane also has a _bg, but it is an unnamed child that cannot be
-- told apart from the bar rows safely. It does not need repainting here: because the
-- wanted alpha is written into the profile, anything built afterwards already reads the
-- correct value.
local function ApplyBackgroundInPlace(dm)
    local r, g, b = dm.bgR or 0, dm.bgG or 0, dm.bgB or 0
    local alpha = dm.bgAlpha or 0.75

    for index = 1, MAX_DM_WINDOWS do
        local frame = _G["EllesmereUIDMFrame" .. index]
        if frame and frame._bg then
            frame._bg:SetColorTexture(r, g, b, alpha)
        end
    end
end

-- Hides leaked duplicate windows.
--
-- The meter builds its windows in a staggered C_Timer chain at login while NaowhUI's
-- _EDM_Apply() rebuilds them synchronously. The two overlap, and because the windows are
-- globally named, a second CreateFrame with the same name returns a fresh frame and
-- rebinds the global while the previous one stays parented and visible. Those leftovers
-- keep painting their own background, so the result looks about twice as opaque as
-- configured -- invisible at 0% alpha, obvious at any real value.
--
-- The global name is authoritative: any frame carrying a window name that is not the
-- frame that name currently resolves to has been abandoned. GetName() is called through
-- pcall because on 12.0 some UIParent children cannot be queried that way and throw
-- "calling '?' on bad self".
local function HideOrphanedWindows()
    local live = {}
    for index = 1, MAX_DM_WINDOWS do
        local frame = _G["EllesmereUIDMFrame" .. index]
        if frame then live[frame] = true end
    end

    local hidden = 0
    for _, child in ipairs({ UIParent:GetChildren() }) do
        local ok, name = pcall(function() return child:GetName() end)
        if ok and type(name) == "string"
            and name:match("^EllesmereUIDMFrame%d+$")
            and not live[child] then
            local shown = select(2, pcall(function() return child:IsShown() end))
            if shown then
                pcall(function() child:Hide() end)
                hidden = hidden + 1
            end
        end
    end

    if hidden > 0 then
        DebugPrint(("Hid %d leftover damage meter window(s)"):format(hidden))
    end
    return hidden
end

-- ------------------------------------------------------------------------------------
-- Diagnostics: /lui dmdebug
--
-- Reports every layer actually drawn behind a damage meter window, so a doubled-looking
-- background can be traced to the object producing it instead of guessed at.
-- ------------------------------------------------------------------------------------

local function Report(message)
    print("|cff0091edLingkanUI|r|cffffa300 DM|r: " .. message)
end

function LingkanUI.Customizing:DebugDamageMeter()
    local dm = GetDamageMeterConfig()
    if not dm then
        Report("could not reach the damage meter profile")
        return
    end

    local settings = LingkanUI.db.profile.naowhUI.damageMeterBg
    Report(string.format("patch enabled=%s wanted=%.2f | profile bgAlpha=%s rgb=%s/%s/%s windows=%s",
        tostring(settings.enabled), settings.alpha,
        tostring(dm.bgAlpha), tostring(dm.bgR), tostring(dm.bgG), tostring(dm.bgB),
        tostring(dm.windowCount)))

    -- Screen rectangle of every visible window: two windows sharing a rectangle stack
    -- their backgrounds, which looks exactly like one background at twice the opacity.
    local visible = {}
    for index = 1, MAX_DM_WINDOWS do
        local frame = _G["EllesmereUIDMFrame" .. index]
        if frame then
            local left = frame:GetLeft() and math.floor(frame:GetLeft() + 0.5) or -1
            local top = frame:GetTop() and math.floor(frame:GetTop() + 0.5) or -1

            Report(string.format("window %d: shown=%s pos=%d,%d size=%dx%d",
                index, tostring(frame:IsShown()), left, top,
                math.floor((frame:GetWidth() or 0) + 0.5),
                math.floor((frame:GetHeight() or 0) + 0.5)))

            if frame:IsShown() then
                visible[#visible + 1] = { index = index, left = left, top = top }
            end
        end
    end

    -- Report any pair of visible windows sitting in the same place
    for i = 1, #visible do
        for j = i + 1, #visible do
            local a, b = visible[i], visible[j]
            if math.abs(a.left - b.left) <= 4 and math.abs(a.top - b.top) <= 4 then
                Report(string.format("OVERLAP: windows %d and %d are at the same position",
                    a.index, b.index))
            end
        end
    end

    -- Leftover frames from an interrupted rebuild. The name lookup is wrapped per child
    -- because on 12.0 some UIParent children cannot be queried this way.
    local live, orphans = {}, 0
    for index = 1, MAX_DM_WINDOWS do
        local frame = _G["EllesmereUIDMFrame" .. index]
        if frame then live[frame] = true end
    end

    for _, child in ipairs({ UIParent:GetChildren() }) do
        local ok, name = pcall(function() return child:GetName() end)
        if ok and type(name) == "string" and name:match("^EllesmereUIDMFrame%d+$") and not live[child] then
            orphans = orphans + 1
            local shown = select(2, pcall(function() return child:IsShown() end))
            Report(string.format("LEFTOVER: %s (unreachable duplicate) shown=%s", name, tostring(shown)))
        end
    end
    Report("leftover duplicates found: " .. orphans)
end

function LingkanUI.Customizing:EnforceDamageMeterBackground()
    local settings = LingkanUI.db and LingkanUI.db.profile.naowhUI
    if not (settings and settings.damageMeterBg.enabled) then return end

    local dm = GetDamageMeterConfig()
    if not dm then return end

    local wanted = settings.damageMeterBg.alpha

    -- Keep the profile correct so any later rebuild starts from the right value
    if dm.bgAlpha ~= wanted then
        DebugPrint(("Restoring bgAlpha %s -> %s"):format(tostring(dm.bgAlpha), tostring(wanted)))
        dm.bgAlpha = wanted
    end

    HideOrphanedWindows()
    ApplyBackgroundInPlace(dm)
end

-- ------------------------------------------------------------------------------------
-- Hook installation
--
-- _G._EDM_Apply is assigned exactly once, during the damage meter's own initialisation,
-- which can land after PLAYER_ENTERING_WORLD -- hence the bounded retries. The delayed
-- passes also catch duplicates created by the staggered login build finishing after
-- NaowhUI's rebuild.
-- ------------------------------------------------------------------------------------

local hooked = false
local PASS_DELAYS = { 0, 1, 3, 6, 10 }

-- This patch depends on another addon's internals, so a failure should degrade quietly
-- rather than throw on every rebuild.
local function SafeEnforce()
    local ok, err = pcall(LingkanUI.Customizing.EnforceDamageMeterBackground, LingkanUI.Customizing)
    if not ok then
        DebugPrint("Enforce failed: " .. tostring(err))
    end
end

local function TryInstallHook()
    if hooked or not _G._EDM_Apply then return false end

    hooked = true
    hooksecurefunc("_EDM_Apply", function()
        SafeEnforce()
        -- The staggered build can still be queued; sweep again once it has settled
        C_Timer.After(0.5, SafeEnforce)
    end)
    DebugPrint("Hooked _EDM_Apply")
    return true
end

function LingkanUI.Customizing.LoadNaowhUI()
    if LingkanUI.Customizing._naowhLoaded then return end
    LingkanUI.Customizing._naowhLoaded = true

    for _, delay in ipairs(PASS_DELAYS) do
        C_Timer.After(delay, function()
            TryInstallHook()
            SafeEnforce()
        end)
    end
end
