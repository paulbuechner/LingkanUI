-------------------------------------------------------------------------------
--  LingkanUI -- WIM skin: Customizing/WIM/Shell.lua
--  Originally the standalone addon EllesmereSkin_WIM v1.2.0 by Laurent.
--
--  Everything in WIM that is NOT the message window.
--
--  Skin.lua can only reach the message window and the tab strip, because those
--  are the only two things WIM's skin engine exposes (RegisterSkin + the
--  ApplySkinToWindow / ApplySkinToTabs hooks). The rest of WIM -- the options
--  window, the History Viewer, the filter editor, the popup menus, the chat
--  user list and the toolkit's own dropdown -- is built by hand, outside the
--  engine, and has to be skinned from the outside.
--
--  Three seams make that possible without touching WIM's source:
--
--   1. Every one of those shells is a BackdropTemplate frame. So one helper
--      (Panel) strips Blizzard's 9-slice and replaces it with a flat EUI fill
--      plus a real 1px border, and all six shells are the same one-liner.
--
--   2. The constructors are all file-local, but the PUBLIC entry points are
--      WIM namespace members (every relevant file runs setfenv(1, WIM)), and
--      creation is lazy-on-first-show. So a post-hook on ShowOptions /
--      ShowHistoryViewer / ShowFilterFrame always finds the frame already
--      built. No polling, no reaching into locals.
--
--   3. The options widgets have a single chokepoint. Every options page gets
--      its constructors stamped on by options.InherritOptionFrameProperties,
--      which is public -- so wrapping that one function lets us skin every
--      checkbox, slider, dropdown and button on every page, without walking
--      the frame tree and guessing what each child is.
--
--  Menus and the chat user list are the exception: they DO go through the skin
--  engine, via a `menu` section in the skin table and their own ApplySkin
--  methods. We declare that section in Skin.lua (flat white, zero insets) and
--  then post-pass here, because a backdrop edgeFile cannot produce a 1px edge.
--
--  Known limitation: switching AWAY from this skin does not un-skin the
--  options window. WIM re-skins its own message windows on a skin change, but
--  nothing re-skins these surfaces, and reconstructing Blizzard's stripped
--  textures is not worth the code. A /reload restores them.
-------------------------------------------------------------------------------
local _, LingkanUI = ...

LingkanUI.WIMSkin = LingkanUI.WIMSkin or {}
local ns = LingkanUI.WIMSkin

-- Guards repeated per chunk; see Locale.lua for why.
if not (LingkanUI.Version and LingkanUI.Version.isRetail) then return end
if not _G.WIM then return end

local L     = ns.L
local Theme = ns.Theme
local Pixel = ns.Pixel

local WIM = _G.WIM
if not WIM then return end

local Shell = {}
ns.Shell = Shell

local WHITE = "Interface\\Buttons\\WHITE8X8"

-------------------------------------------------------------------------------
--  Guard. Re-checked on every entry point, never cached: WIM calls the skin
--  paths for whichever skin is selected, so a cached "yes" would keep us
--  restyling after the user picks another skin.
-------------------------------------------------------------------------------
local function IsOurSkin()
    local sel = WIM.GetSelectedSkin and WIM.GetSelectedSkin()
    if not sel then return false end
    local t = sel.title
    return t == L["SKIN_TITLE"] or t == L["SKIN_TITLE_LIGHT"]
end

-------------------------------------------------------------------------------
--  Primitives
-------------------------------------------------------------------------------

-- Idempotence rule, same as Skin.lua's SkinInset: the guard prevents duplicate
-- texture CREATION, never the recolour. Bailing out early on an already-skinned
-- frame would freeze it at whatever colour it was first given, so a theme or
-- accent change would never land on frames built before it.
local function Fill(frame, key, r, g, b, a, layer, sub)
    if not frame or not frame.CreateTexture then return nil end
    local tex = frame[key]
    if not tex then
        tex = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sub or -8)
        tex:SetTexture(WHITE)
        frame[key] = tex
    end
    tex:SetVertexColor(r, g, b, a)
    tex:ClearAllPoints()
    tex:SetAllPoints(frame)
    Pixel.DisablePixelSnap(tex)
    return tex
end

-- Hide every Texture region the frame owns. Used to clear Blizzard template art
-- (UIPanelButtonTemplate's 3-slice, InputBoxTemplate's 9-slice) before we draw
-- our own. FontStrings are left alone -- they are the label, not the chrome --
-- and so are textures we created, which are tracked on the frame by key.
local OURS = { _eskShellBG = true, _eskFill = true, _eskTrack = true }
local function StripTextures(frame, keep)
    if not frame or not frame.GetRegions then return end
    local mine = {}
    for key in pairs(OURS) do
        if frame[key] then mine[frame[key]] = true end
    end
    if keep then
        for _, region in ipairs(keep) do
            if region then mine[region] = true end
        end
    end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region.IsObjectType and region:IsObjectType("Texture")
            and not mine[region] then
            region:SetTexture(nil)
            region:Hide()
        end
    end
end

-- Drop a BackdropTemplate frame's 9-slice entirely.
--
-- SetBackdrop(nil) rather than recolouring it: WIM's backdrops are 64px-inset
-- rounded art that STRETCHES with the frame, which is the same reason Skin.lua
-- flattens the message window atlas. No texture can give a 1px edge here.
local function StripBackdrop(frame)
    if frame and frame.SetBackdrop then pcall(frame.SetBackdrop, frame, nil) end
end

--- Turn any frame into an EllesmereUI panel: flat fill + 1px border.
-- Returns the frame so calls can chain at the call site.
function Shell.Panel(frame, r, g, b, a)
    if not frame then return end
    if r == nil then r, g, b, a = Theme.Background() end

    StripBackdrop(frame)
    Fill(frame, "_eskShellBG", r, g, b, a)

    local br, bg, bb, ba = Theme.Border()
    if frame._eskBorderFrame then
        Pixel.SetBorderColor(frame, br, bg, bb, ba)
    else
        -- Keep the container: BorderFollowsHeight needs something to toggle,
        -- and Pixel has no "get the border for this frame" accessor in the
        -- standalone path.
        frame._eskBorderFrame =
            Pixel.CreateBorder(frame, br, bg, bb, ba, 1, "OVERLAY", 7)
        Pixel.Attach(frame)
    end
    return frame
end

--- A recessed surface (list wells, edit boxes): darker fill, same 1px edge.
function Shell.Inset(frame, r, g, b, a)
    if r == nil then r, g, b, a = Theme.Inset() end
    return Shell.Panel(frame, r, g, b, a)
end

-- Border visibility follows height. WIM collapses empty menu groups to height 0
-- and a 1px border on a zero-height frame renders as a stray line across the
-- menu. Driven off OnSizeChanged so it tracks the group being refilled.
local function BorderFollowsHeight(frame, minHeight)
    if not frame or frame._eskHeightWatch then return end
    frame._eskHeightWatch = true
    local function Sync(self)
        local container = self._eskBorderFrame
        if not container then return end
        if (self:GetHeight() or 0) < (minHeight or 4) then
            container:Hide()
        else
            container:Show()
        end
    end
    frame:HookScript("OnSizeChanged", Sync)
    Sync(frame)
end

-------------------------------------------------------------------------------
--  Popup menus (WIM3Menu groups) and the chat user list.
--
--  Both read the skin table's `menu` section and re-apply it on every skin
--  load, so this runs from the LoadSkin post-hook rather than once at startup.
--  Each group is bordered separately because that is how WIM lays them out --
--  two stacked panels, Whispers over Chat -- and bordering the parent instead
--  would not work: WIM3Menu's height is the sum of the group heights and
--  ignores the 25px overlap it anchors them with, so the parent rect is taller
--  than what is actually drawn.
-------------------------------------------------------------------------------
local function SkinMenuButton(button)
    if not button then return end

    -- The row highlight is the only interactive feedback in the menu, so it is
    -- the accent -- consistent with the tab flash being the one accent in the
    -- message window.
    local ar, ag, ab = Theme.Accent()
    if button.SetHighlightTexture then
        button:SetHighlightTexture(WHITE, "ADD")
        local hl = button:GetHighlightTexture()
        if hl then
            hl:SetVertexColor(ar, ag, ab, 0.25)
            Pixel.DisablePixelSnap(hl)
        end
    end
    if button.text then
        Theme.ApplyFont(button.text, 12)
    end
end

local function SkinMenuGroup(group)
    if not group then return end

    Shell.Panel(group)
    BorderFollowsHeight(group, 8)

    local title = group.title
    if title then
        -- The group heading reads as a label on the panel, not a bar across it:
        -- a hairline under the text instead of a filled strip.
        if title.bg then
            local br, bg, bb, ba = Theme.Border()
            title.bg:SetTexture(WHITE)
            title.bg:SetVertexColor(br, bg, bb, ba)
            title.bg:ClearAllPoints()
            title.bg:SetPoint("BOTTOMLEFT", title, "BOTTOMLEFT", 0, -2)
            title.bg:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", 0, -2)
            title.bg:SetHeight(1)
            Pixel.DisablePixelSnap(title.bg)
        end
        if title.text then
            local tr, tg, tb = Theme.TextMuted()
            Theme.ApplyFont(title.text, 11, tr, tg, tb)
        end
    end

    if group.buttons then
        for i = 1, #group.buttons do
            SkinMenuButton(group.buttons[i])
        end
    end
end

function Shell.SkinMenu()
    local menu = WIM.Menu
    if not menu or not menu.groups then return end
    for i = 1, #menu.groups do
        SkinMenuGroup(menu.groups[i])
    end
end

function Shell.SkinUserList()
    local win = WIM.ChatUserList
    if not win then return end

    Shell.Panel(win)

    if win.title then
        if win.title.bg then
            local br, bg, bb, ba = Theme.Border()
            win.title.bg:SetTexture(WHITE)
            win.title.bg:SetVertexColor(br, bg, bb, ba)
            win.title.bg:ClearAllPoints()
            win.title.bg:SetPoint("BOTTOMLEFT", win.title, "BOTTOMLEFT", 0, -2)
            win.title.bg:SetPoint("BOTTOMRIGHT", win.title, "BOTTOMRIGHT", 0, -2)
            win.title.bg:SetHeight(1)
            Pixel.DisablePixelSnap(win.title.bg)
        end
        if win.title.text then
            local tr, tg, tb = Theme.TextMuted()
            Theme.ApplyFont(win.title.text, 11, tr, tg, tb)
        end
    end

    if win.buttons then
        for i = 1, #win.buttons do
            SkinMenuButton(win.buttons[i])
        end
    end
end

-------------------------------------------------------------------------------
--  Options toolkit widgets
-------------------------------------------------------------------------------

-- UICheckButtonTemplate. The template's normal/pushed art is a chunky raised
-- box; we replace it with a flat 1px-bordered square and make the CHECK itself
-- the accent -- so a ticked option is the only coloured thing in a page of
-- grey, which is how EllesmereUI marks state.
-- Structure once, colour always -- see the Fill() note. A widget built under an
-- old accent must still pick up a new one when LoadSkin re-runs, so only the
-- CreateFrame and the texture-stripping sit behind the guard.
local function SkinCheckButton(cb)
    if not cb then return end

    if not cb._eskDone then
        cb._eskDone = true
        StripTextures(cb)

        local box = CreateFrame("Frame", nil, cb)
        box:SetPoint("TOPLEFT", cb, "TOPLEFT", 6, -6)
        box:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", -6, 6)
        box:SetFrameLevel(cb:GetFrameLevel())
        cb._eskBox = box
    end

    local box = cb._eskBox
    Shell.Inset(box)

    local ar, ag, ab = Theme.Accent()

    if cb.SetCheckedTexture then
        cb:SetCheckedTexture(WHITE)
        local checked = cb:GetCheckedTexture()
        if checked then
            checked:ClearAllPoints()
            checked:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
            checked:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
            checked:SetVertexColor(ar, ag, ab, 1)
            Pixel.DisablePixelSnap(checked)
        end
    end
    if cb.SetHighlightTexture then
        cb:SetHighlightTexture(WHITE, "ADD")
        local hl = cb:GetHighlightTexture()
        if hl then
            hl:ClearAllPoints()
            hl:SetAllPoints(box)
            hl:SetVertexColor(ar, ag, ab, 0.18)
            Pixel.DisablePixelSnap(hl)
        end
    end

    if cb.text then
        local tr, tg, tb = Theme.Text()
        Theme.ApplyFont(cb.text, 12, tr, tg, tb)
    end

    -- A checkbutton hands the RAW constructor to its own children
    -- (cb.CreateCheckButton = CreateCheckButton inside the toolkit), which
    -- bypasses our wrapper on InherritOptionFrameProperties. Re-wrap it here or
    -- every nested/child option stays unskinned.
    if cb.CreateCheckButton and not cb._eskWrapped then
        cb._eskWrapped = true
        local original = cb.CreateCheckButton
        cb.CreateCheckButton = function(...)
            local child = original(...)
            if IsOurSkin() then SkinCheckButton(child) end
            return child
        end
    end
end

-- UIPanelButtonTemplate.
local function SkinButton(btn)
    if not btn then return end

    if not btn._eskDone then
        btn._eskDone = true
        StripTextures(btn)
    end
    Shell.Panel(btn, Theme.Raised())

    local ar, ag, ab = Theme.Accent()
    if btn.SetHighlightTexture then
        btn:SetHighlightTexture(WHITE, "ADD")
        local hl = btn:GetHighlightTexture()
        if hl then
            hl:SetAllPoints(btn)
            hl:SetVertexColor(ar, ag, ab, 0.20)
            Pixel.DisablePixelSnap(hl)
        end
    end

    local label = btn.text or (btn.GetName and btn:GetName() and _G[btn:GetName() .. "Text"])
    if label then
        local tr, tg, tb = Theme.Text()
        Theme.ApplyFont(label, 12, tr, tg, tb)
    end
end

-- InputBoxTemplate. Its 9-slice edge art is what StripTextures clears; the
-- replacement is the same input-well treatment the message box gets, so typing
-- surfaces look identical everywhere in WIM.
local function SkinEditBox(box)
    if not box then return end

    if not box._eskDone then
        box._eskDone = true
        StripTextures(box)
    end
    Shell.Panel(box, Theme.InputInset())

    local tr, tg, tb = Theme.Text()
    Theme.ApplyFont(box, 12, tr, tg, tb)
end

local function SkinSlider(slider)
    if not slider then return end

    -- The track is a thin recessed line, not a full-height trough: at 17px tall
    -- a filled trough dominates the row and reads as a progress bar.
    if not slider._eskDone then
        slider._eskDone = true
        StripBackdrop(slider)
    end
    local track = slider._eskTrack
    if not track then
        track = slider:CreateTexture(nil, "BACKGROUND", nil, -8)
        track:SetTexture(WHITE)
        slider._eskTrack = track
    end
    local ir, ig, ib, ia = Theme.Inset()
    track:SetVertexColor(ir, ig, ib, ia)
    track:ClearAllPoints()
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    track:SetHeight(4)
    Pixel.DisablePixelSnap(track)

    if slider.SetThumbTexture then
        slider:SetThumbTexture(WHITE)
        local thumb = slider:GetThumbTexture()
        if thumb then
            local ar, ag, ab = Theme.Accent()
            thumb:SetVertexColor(ar, ag, ab, 1)
            thumb:SetSize(8, 16)
            Pixel.DisablePixelSnap(thumb)
        end
    end

    local tr, tg, tb = Theme.Text()
    local mr, mg, mb = Theme.TextMuted()
    if slider.title   then Theme.ApplyFont(slider.title, 12, tr, tg, tb) end
    if slider.minText then Theme.ApplyFont(slider.minText, 10, mr, mg, mb) end
    if slider.maxText then Theme.ApplyFont(slider.maxText, 10, mr, mg, mb) end
    if slider.input   then SkinEditBox(slider.input) end
end

-- The colour swatch keeps Blizzard's ChatFrameColorSwatch art: it is the one
-- widget whose texture carries meaning (it is tinted to the chosen colour), so
-- stripping it would destroy the control. It just gets a border and a label.
local function SkinColorPicker(frame)
    if not frame then return end

    local swatch = frame.swatch
    if swatch then
        local br, bg, bb, ba = Theme.Border()
        if swatch._eskBorderFrame then
            Pixel.SetBorderColor(swatch, br, bg, bb, ba)
        else
            swatch._eskBorderFrame =
                Pixel.CreateBorder(swatch, br, bg, bb, ba, 1, "OVERLAY", 7)
        end
        if swatch.title then
            local tr, tg, tb = Theme.Text()
            Theme.ApplyFont(swatch.title, 12, tr, tg, tb)
        end
    end
end

-- CreateFramedPanel draws its outline as four white 0.25-alpha textures rather
-- than a backdrop, so it needs recolouring rather than stripping.
local function SkinFramedPanel(frame)
    if not frame or not frame.backdrop then return end
    local br, bg, bb, ba = Theme.Border()
    for _, key in ipairs({ "top", "bottom", "left", "right" }) do
        local tex = frame.backdrop[key]
        if tex then
            tex:SetColorTexture(br, bg, bb, ba)
            Pixel.DisablePixelSnap(tex)
        end
    end
end

-- LibDropDownMenu widget (Libs/LibDropDownMenu). The frame rect is NOT the
-- visible control: UIDropDownMenu_SetWidth sets the frame to width + 2*padding,
-- and the Left/Middle/Right art is 64px tall anchored 17px ABOVE the 32px frame.
-- Panelling the frame rect would therefore draw a box far wider and taller than
-- the dropdown the user sees.
--
-- The toggle button is the one deterministic landmark: it is 24x24 anchored
-- TOPRIGHT of the Right cap at (-16, -18), which puts the real control between
-- frame_top-1 and frame_top-25, ending 12px shy of the frame's right edge. So
-- the skin frame is derived from the button rather than from the frame rect.
local function SkinDropDown(dd)
    if not dd then return end

    if not dd._eskDone then
        dd._eskDone = true
        -- Icon is kept: it is content (some dropdowns show a per-entry icon),
        -- not chrome, and it is hidden by default anyway.
        StripTextures(dd, { dd.Icon })

        local skin = CreateFrame("Frame", nil, dd)
        skin:SetFrameLevel(dd:GetFrameLevel())
        skin:SetPoint("TOPLEFT", dd, "TOPLEFT", 12, -1)
        if dd.Button then
            skin:SetPoint("BOTTOMRIGHT", dd.Button, "BOTTOMRIGHT", 4, 0)
        else
            skin:SetPoint("BOTTOMRIGHT", dd, "TOPRIGHT", -12, -25)
        end
        dd._eskSkinFrame = skin
    end

    Shell.Panel(dd._eskSkinFrame, Theme.Raised())

    local ar, ag, ab = Theme.Accent()
    local tr, tg, tb = Theme.Text()

    -- The arrow keeps its shape but loses the Blizzard bevel wash.
    local btn = dd.Button
    if btn then
        local normal = btn.GetNormalTexture and btn:GetNormalTexture()
        if normal then normal:SetVertexColor(0.65, 0.65, 0.65) end
        local hl = btn.GetHighlightTexture and btn:GetHighlightTexture()
        if hl then hl:SetVertexColor(ar, ag, ab) end
    end

    -- menu.Text is the LibDropDownMenu field; `text` is the defensive fallback
    -- for anything else routed through here.
    Theme.ApplyFont(dd.Text or dd.text, 12, tr, tg, tb)
end

-- A bare arrow button (CreateCheckButtonMenu's `.menu`). The arrow is the only
-- thing telling the user this opens a list, so it is kept and tinted rather
-- than stripped; only Blizzard's bevelled mouse-highlight is replaced.
local function SkinArrowButton(btn)
    if not btn then return end

    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
        local tex = btn[getter] and btn[getter](btn)
        if tex then tex:SetVertexColor(0.65, 0.65, 0.65) end
    end

    if btn.SetHighlightTexture then
        local ar, ag, ab = Theme.Accent()
        btn:SetHighlightTexture(WHITE, "ADD")
        local hl = btn:GetHighlightTexture()
        if hl then
            hl:SetVertexColor(ar, ag, ab, 0.22)
            Pixel.DisablePixelSnap(hl)
        end
    end
end

-------------------------------------------------------------------------------
--  The widget chokepoint.
--
--  options.InherritOptionFrameProperties stamps all nine constructors onto
--  every options frame, and CreateSection / CreateFramedPanel build their
--  children through options.CreateOptionsFrame -- which runs this too. So
--  wrapping here reaches every widget on every page, including nested ones,
--  with no frame-tree walking.
-------------------------------------------------------------------------------
local WRAPPERS = {
    CreateCheckButton = SkinCheckButton,
    CreateButton      = SkinButton,
    CreateSlider      = SkinSlider,
    CreateColorPicker = SkinColorPicker,
    CreateFramedPanel = SkinFramedPanel,
    CreateDropDownMenu = SkinDropDown,
}

local function WrapConstructors(obj)
    if not obj or obj._eskCtorsWrapped then return end
    obj._eskCtorsWrapped = true

    for name, skinner in pairs(WRAPPERS) do
        local original = obj[name]
        if type(original) == "function" then
            obj[name] = function(...)
                local widget = original(...)
                -- Guard at CALL time, not wrap time: pages are built lazily and
                -- the user may have switched skins since we wrapped.
                if widget and IsOurSkin() then
                    pcall(skinner, widget)
                end
                return widget
            end
        end
    end

    -- CreateCheckButtonMenu returns a checkbutton carrying a `.menu` arrow
    -- button, which in turn owns `.dropdown`, the popup list.
    --
    -- cbm.menu is NOT a LibDropDownMenu widget -- it is a bare 26x26 Button
    -- wearing the ScrollDown arrow -- so SkinDropDown is the wrong tool for it
    -- (it would strip the arrow, which is the whole affordance, and anchor its
    -- panel off a .Button field that does not exist here).
    local originalCBM = obj.CreateCheckButtonMenu
    if type(originalCBM) == "function" then
        obj.CreateCheckButtonMenu = function(...)
            local cbm = originalCBM(...)
            if cbm and IsOurSkin() then
                pcall(SkinCheckButton, cbm)
                if cbm.menu then
                    pcall(SkinArrowButton, cbm.menu)
                    -- The real reference; the global only names the first of
                    -- these. See Shell.SkinDropDownFrame.
                    if cbm.menu.dropdown then
                        pcall(Shell.SkinDropDownFrame, cbm.menu.dropdown)
                    end
                end
            end
            return cbm
        end
    end

    -- CreateSection returns a frame whose title needs the heading treatment.
    local originalSection = obj.CreateSection
    if type(originalSection) == "function" then
        obj.CreateSection = function(...)
            local section = originalSection(...)
            if section and IsOurSkin() then
                if section.title then
                    local ar, ag, ab = Theme.Accent()
                    Theme.ApplyFont(section.title, 15, ar, ag, ab)
                end
                if section.description then
                    local mr, mg, mb = Theme.TextMuted()
                    Theme.ApplyFont(section.description, 11, mr, mg, mb)
                end
            end
            return section
        end
    end

    local originalText = obj.CreateText
    if type(originalText) == "function" then
        obj.CreateText = function(...)
            local fs = originalText(...)
            if fs and IsOurSkin() then
                local tr, tg, tb = Theme.Text()
                local _, size = fs:GetFont()
                Theme.ApplyFont(fs, size or 12, tr, tg, tb)
            end
            return fs
        end
    end
end

-------------------------------------------------------------------------------
--  The three hand-built windows: options, History Viewer, filter editor.
--  Identical 64px backdrop, identical treatment.
-------------------------------------------------------------------------------
local function SkinWindowShell(win, titleSize)
    if not win then return end

    Shell.Panel(win)

    if win.title then
        local tr, tg, tb = Theme.Text()
        Theme.ApplyFont(win.title, titleSize or 15, tr, tg, tb)
    end

    -- Close button. WIM ships a red blip here, which is Blizzard-era art that
    -- does not read as "close" at all.
    --
    -- It gets the SAME three textures the message window's close already uses
    -- (see the `close` widget in Skin.lua), so every close control in WIM is
    -- one control. Deliberately not a hand-drawn glyph: a tinted WHITE8X8 has
    -- no shape, and a flat square is less legible than the blip it replaced.
    --
    -- Assignment only, no frame creation, so this runs on every pass. Each
    -- SetNormalTexture(path) builds a fresh texture that fills the button, so
    -- there is nothing to un-anchor from a previous pass.
    local close = win.close
    if close and close.SetNormalTexture then
        close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        close:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    end

    -- The options nav divider is a white 0.25 strip; make it the border colour
    -- so the sidebar reads as a panel edge rather than a highlight.
    if win.nav and win.nav.bg then
        local br, bg, bb, ba = Theme.Border()
        win.nav.bg:SetColorTexture(br, bg, bb, ba)
        Pixel.DisablePixelSnap(win.nav.bg)
    end
end

-------------------------------------------------------------------------------
--  Options sidebar.
--
--  The category buttons are the collapsed-category header at the top and the
--  other categories parked along the bottom -- one widget type, two positions.
--  They are OptionsListButtonTemplate buttons whose `bg` texture carries a
--  VERTICAL gradient: 658daa when closed, 111111 when open.
--
--  UpdateCategories re-applies those gradients on EVERY refresh, so painting
--  them once is not enough -- this has to ride the same call. And there is no
--  ClearGradient in the API, so the only way to flatten one is to set both
--  stops to the same colour.
-------------------------------------------------------------------------------
local function SkinNavCategory(cat)
    if not cat then return end

    -- UpdateCategories disables the OPEN category and enables the rest, so
    -- "not enabled" is how we read which one is selected.
    local selected = cat.IsEnabled and not cat:IsEnabled()

    local r, g, b, a
    if selected then
        -- Recedes, reading as continuous with the page beside it.
        r, g, b, a = Theme.Background()
    else
        -- Comes forward: these are the clickable ones.
        r, g, b, a = Theme.Raised()
    end

    if cat.bg then
        cat.bg:SetTexture(WHITE)
        local c = { r = r, g = g, b = b, a = a }
        pcall(cat.bg.SetGradient, cat.bg, "VERTICAL", c, c)
        Pixel.DisablePixelSnap(cat.bg)
    end

    -- The label is written as "|cffffffff<title>|r", so an embedded escape wins
    -- over SetTextColor and the text cannot be recoloured without rewriting
    -- WIM's content. An accent bar on the open category marks the selection
    -- instead, which is the EllesmereUI idiom anyway.
    if not cat._eskMark then
        local mark = cat:CreateTexture(nil, "ARTWORK")
        mark:SetTexture(WHITE)
        mark:SetPoint("TOPLEFT", cat, "TOPLEFT", 0, 0)
        mark:SetPoint("BOTTOMLEFT", cat, "BOTTOMLEFT", 0, 0)
        mark:SetWidth(2)
        Pixel.DisablePixelSnap(mark)
        cat._eskMark = mark
    end
    local ar, ag, ab = Theme.Accent()
    cat._eskMark:SetVertexColor(ar, ag, ab, 1)
    cat._eskMark:SetShown(selected and true or false)

    Theme.ApplyFont(cat.text, 13)
end

-- Sub-categories mark the current page with LockHighlight(), so the template's
-- highlight texture IS the selection -- Blizzard blue until it is tinted.
local function SkinNavSubCategory(button)
    if not button then return end

    local ar, ag, ab = Theme.Accent()
    if button.SetHighlightTexture then
        button:SetHighlightTexture(WHITE, "ADD")
        local hl = button:GetHighlightTexture()
        if hl then
            hl:SetVertexColor(ar, ag, ab, 0.22)
            Pixel.DisablePixelSnap(hl)
        end
    end
    Theme.ApplyFont(button.text, 13)
end

function Shell.SkinNav()
    local frame = WIM.options and WIM.options.frame
    local nav = frame and frame.nav
    if not nav then return end

    if nav.category then
        for i = 1, #nav.category do
            SkinNavCategory(nav.category[i])
        end
    end
    if nav.sub and nav.sub.buttons then
        for i = 1, #nav.sub.buttons do
            SkinNavSubCategory(nav.sub.buttons[i])
        end
    end
end

function Shell.SkinOptions()
    local win = _G.WIM3_Options
    if not win then return end
    SkinWindowShell(win, 16)
    Shell.SkinNav()
end

function Shell.SkinHistory()
    SkinWindowShell(_G.WIM3_HistoryFrame, 15)
end

function Shell.SkinFilters()
    SkinWindowShell(_G.WIM3_FilterFrame, 15)
end

-- The toolkit's own dropdown list. It hard-codes TOOLTIP_DEFAULT_COLOR and
-- TOOLTIP_DEFAULT_BACKGROUND_COLOR at creation, so unlike the other shells this
-- one needs its colours overwritten rather than merely bordered.
--
-- Takes the frame explicitly, and that matters: options.createDropDownFrame()
-- runs once per CreateCheckButtonMenu (25 of them in CoreOptions alone) and
-- names every one of them "WIM_DropDownFrame". CreateFrame does NOT rebind an
-- existing global, so _G.WIM_DropDownFrame is only ever the FIRST one and the
-- other 24 are unreachable by name. Callers that hold the real reference --
-- cbm.menu.dropdown -- must pass it in; the global is only a fallback for
-- re-asserting colour on that first frame.
function Shell.SkinDropDownFrame(frame)
    local f = frame or _G.WIM_DropDownFrame
    if not f then return end
    Shell.Panel(f, Theme.Inset())
end

-------------------------------------------------------------------------------
--  LibDropDownMenu popup lists.
--
--  This is what actually opens when you click a dropdown, and it is NOT
--  WIM_DropDownFrame -- that one belongs to CreateCheckButtonMenu. These are
--  the library's own shared frames, LibDropDownMenu_List1..N, pre-created at
--  lib load and reused by every dropdown in the addon.
--
--  Each list carries TWO backdrop children, <name>Backdrop (DialogBox art) and
--  <name>MenuBackdrop (Tooltip art), both SetAllPoints to the list, and the
--  library shows whichever suits the menu type. Rather than skin both and risk
--  two fills stacking when they are shown together, their backdrops are emptied
--  and the panel goes on the list frame itself -- so it does not matter which
--  one the library decides to show.
-------------------------------------------------------------------------------
local function SkinDropDownListButton(button)
    if not button then return end

    local ar, ag, ab = Theme.Accent()

    local hl = button.Highlight or (button.GetHighlightTexture and button:GetHighlightTexture())
    if hl then
        hl:SetTexture(WHITE)
        hl:SetVertexColor(ar, ag, ab, 0.25)
        Pixel.DisablePixelSnap(hl)
    end
    -- The radio/check glyph keeps its shape (it distinguishes radio from check)
    -- and just takes the accent.
    if button.Check then button.Check:SetVertexColor(ar, ag, ab) end

    local name = button.GetName and button:GetName()
    if name then
        local tr, tg, tb = Theme.Text()
        Theme.ApplyFont(_G[name .. "NormalText"], 12, tr, tg, tb)
    end
end

function Shell.SkinDropDownLists()
    local i = 1
    while true do
        local name = "LibDropDownMenu_List" .. i
        local list = _G[name]
        if not list then break end

        for _, suffix in ipairs({ "Backdrop", "MenuBackdrop" }) do
            local bd = _G[name .. suffix]
            if bd and bd.SetBackdrop then pcall(bd.SetBackdrop, bd, nil) end
        end
        Shell.Panel(list, Theme.Inset())

        -- Button count grows on demand (the library appends past
        -- UIDROPDOWNMENU_MAXBUTTONS), so walk until the name runs out rather
        -- than trusting the global.
        local j = 1
        while true do
            local button = _G[name .. "Button" .. j]
            if not button then break end
            SkinDropDownListButton(button)
            j = j + 1
        end

        -- Lists are reused and can gain buttons between openings, so re-run on
        -- show instead of only once here.
        if not list._eskShowHooked then
            list._eskShowHooked = true
            list:HookScript("OnShow", function()
                if IsOurSkin() then pcall(Shell.SkinDropDownLists) end
            end)
        end

        i = i + 1
    end
end

-------------------------------------------------------------------------------
--  Wiring
-------------------------------------------------------------------------------

-- LoadSkin is the one place that touches everything: it re-applies the skin to
-- every message window and then fires OnSkinLoaded at the modules, which is
-- what re-backdrops the menus and the user list. Post-hooking it means our
-- flattening always runs last, on every skin switch and every theme refresh.
if WIM.LoadSkin then
    hooksecurefunc(WIM, "LoadSkin", function()
        if not IsOurSkin() then return end
        Shell.SkinMenu()
        Shell.SkinUserList()
        -- Re-assert the hand-built windows too: they are not rebuilt by a skin
        -- change, but their colours must follow a live accent/theme switch.
        Shell.SkinOptions()
        Shell.SkinHistory()
        Shell.SkinFilters()
        Shell.SkinDropDownFrame()
        -- Also the first run for the popup lists, which installs their OnShow
        -- hooks. They exist from LibDropDownMenu's load, but the skin is not
        -- selected yet at our file scope, so this is the earliest safe point.
        Shell.SkinDropDownLists()
    end)
end

-- Creation is lazy, so these post-hooks are also the "first build" trigger.
local function HookShow(name, skinner)
    if type(WIM[name]) ~= "function" then return end
    hooksecurefunc(WIM, name, function()
        if not IsOurSkin() then return end
        pcall(skinner)
    end)
end

-- History and Filters are reached through closures -- RegisterSlashCommand
-- ("history", function() ShowHistoryViewer() end) and the minimap menu's
-- info.func -- so the name resolves through WIM's table at CALL time and these
-- hooks fire.
HookShow("ShowHistoryViewer", Shell.SkinHistory)
HookShow("ShowFilterFrame",   Shell.SkinFilters)

-- ShowOptions is the exception, and hooking it does NOT work. Both of its
-- callers captured the function VALUE at load:
--
--   Options.lua:331    RegisterSlashCommand("options", ShowOptions, ...)
--   MinimapIcon.lua    info.func = ShowOptions
--
-- hooksecurefunc only replaces WIM.ShowOptions, the table field, so both of
-- those still call the original and the post-hook never runs. (Symptom: every
-- widget in the options window skinned correctly, because they go through the
-- constructor chokepoint no matter how the window opened, while the window
-- shell itself stayed Blizzard blue.)
--
-- options.OnShow has no such problem: the frame's OnShow script calls it as
-- options.OnShow(self), a table lookup resolved at call time.
if WIM.options and type(WIM.options.OnShow) == "function" then
    hooksecurefunc(WIM.options, "OnShow", function()
        if IsOurSkin() then pcall(Shell.SkinOptions) end
    end)
end

-- The sidebar rebuilds and re-gradients itself on every category change, so a
-- one-time paint would survive only until the first click. Both of these are
-- table fields called at runtime (from the nav's OnShow and the buttons'
-- OnClick), so hooking them is safe from the value-capture problem above.
if WIM.options then
    for _, name in ipairs({ "UpdateCategories", "UpdateSubCategories" }) do
        if type(WIM.options[name]) == "function" then
            hooksecurefunc(WIM.options, name, function()
                if IsOurSkin() then pcall(Shell.SkinNav) end
            end)
        end
    end
end

-- PopContextMenu builds the menu on first use; the LoadSkin pass may have run
-- before it existed.
if WIM.PopContextMenu then
    hooksecurefunc(WIM, "PopContextMenu", function()
        if IsOurSkin() then pcall(Shell.SkinMenu) end
    end)
end

-- Same lazy-creation gap for the chat user list: ChatOptions:OnEnableWIM builds
-- it, and that can land after the login LoadSkin has already run and found
-- WIM.ChatUserList still nil. Hooking the creation point is exact; the
-- alternative would be polling for the global to appear.
local chatOptions = WIM.modules and WIM.modules.ChatOptions
if chatOptions and type(chatOptions.OnEnableWIM) == "function" then
    hooksecurefunc(chatOptions, "OnEnableWIM", function()
        if IsOurSkin() then pcall(Shell.SkinUserList) end
    end)
end

if WIM.options and WIM.options.InherritOptionFrameProperties then
    hooksecurefunc(WIM.options, "InherritOptionFrameProperties", function(obj)
        WrapConstructors(obj)
    end)
end
