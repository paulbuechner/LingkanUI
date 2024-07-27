local _, LingkanUI = ...

LingkanUI.Customizing = {}

-- Bartender4 action bars to show/hide
local actionbars = {
    "BT4Bar1",
    "BT4Bar3",
    "BT4Bar5",
    "BT4Bar6",
    "BT4BarStanceBar",
}

--------------------------------------------------------------------------------------------------------

local function mouseIsOverBar(bar)
    local LAB = LibStub("LibActionButton-1.0")

    local LABSpellFlyout = LAB:GetSpellFlyoutFrame()
    if MouseIsOver(bar.overlay)
        or (SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() and SpellFlyout:GetParent():GetParent() == bar and MouseIsOver(SpellFlyout))
        or (LABSpellFlyout and LABSpellFlyout:IsShown() and LABSpellFlyout:GetParent() and LABSpellFlyout:GetParent():GetParent() == bar and MouseIsOver(LABSpellFlyout)) then
        return true
    end

    return false
end

local function controlFadeOut(bar)
    -- Check if any of the action bars are hovered
    local fadebar = false
    for _, barname in ipairs(actionbars) do
        local actionbar = _G[barname]
        if mouseIsOverBar(actionbar) then
            fadebar = true
            break
        end
    end

    -- Fade-In/Out all defined action bars
    for _, barname in ipairs(actionbars) do
        local actionbar = _G[barname]

        local changed = false
        if actionbar.faded and fadebar then
            actionbar:SetAlpha(actionbar.config.alpha)
            actionbar.faded = nil
            changed = true
        elseif (not actionbar.faded) and not fadebar then
            -- Register events for each action bar
            local fade = actionbar:GetAttribute("fade")
            if tonumber(fade) then
                fade = min(max(fade, 0), 100) / 100
                actionbar:SetAlpha(fade)
            else
                actionbar:SetAlpha(actionbar.config.fadeoutalpha or 0)
            end
            actionbar.faded = true
            changed = true
        end
        if changed and actionbar.ForAll then
            actionbar:ForAll("UpdateAlpha")
        end
    end
end

local function barOnUpdateFunc(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed > self.config.fadeoutdelay then
        controlFadeOut(self)
        self.elapsed = 0
    end
end

--------------------------------------------------------------------------------------------------------

local function ShowActionBar()
    -- LingkanUI:Print("ShowActionBar...")

    -- Show action bars when entering one of them
    for _, bar in ipairs(actionbars) do
        local actionbar = _G[bar]
        -- Register events for each action bar
        if actionbar and actionbar:GetFadeOut() then
            -- LingkanUI:Print("ShowActionBar Showing Bartender4 action bar: " .. bar)

            actionbar:SetFadeOut(false)
        end
    end
end

local function HideActionBar()
    -- LingkanUI:Print("HideActionBar...")

    -- Hide other action bars when leaving one of them
    for _, bar in ipairs(actionbars) do
        local actionbar = _G[bar]
        -- Register events for each action bar
        if actionbar and not actionbar:GetFadeOut() then
            -- LingkanUI:Print("HideActionBar Hiding Bartender4 action bar: " .. bar)

            actionbar:SetFadeOut(true)
        end
    end
end

--------------------------------------------------------------------------------------------------------

function LingkanUI.Customizing:LoadBartender4()
    if _G["Bartender4"] then
        LingkanUI:Print("Bartender4 detected. Load custom visibility configuration...")
    else
        LingkanUI:Print("No Bartender4 detected. Won't load custom visibility configuration...")
        return
    end

    for _, bar in ipairs(actionbars) do
        -- LingkanUI:Print("Checking Bartender4 action bar: " .. bar)

        local actionbar = _G[bar]
        -- Register events for each action bar
        if actionbar then
            -- LingkanUI:Print("Registering events for Bartender4 action bar: " .. bar)

            -- 1. Register events for each action bar handle the fade (includes with overlay)
            actionbar:SetScript("OnUpdate", barOnUpdateFunc)

            -- 2. (Alternative apporach) Register events for each action bar button (without overlay)
            -- for _, button in ipairs(actionbar.buttons) do
            --     button:HookScript('OnEnter', ShowActionBar)
            --     button:HookScript('OnLeave', HideActionBar)
            -- end

            -- DevTools_Dump(actionbar.hidedriver)
            -- DevTools_Dump(actionbar.config)

            -- Hide action bars 1...4 on load
            if not actionbar:GetFadeOut() then actionbar:SetFadeOut(true) end
        end
    end
end

-- /run DevTools_Dump(_G["BT4Bar1"].config)
-- /run DevTools_Dump(_G["BT4Bar1"].hidedriver)


--------------------------------------------------------------------------------------------------------

-- !WA:2!TJ12ZTXvz84QekDPTK40gAs6LTcIRCBS8Le7CH6gKuKIuJCK7kz7K2KAVxos72SA3TNDx7OuAlyGsz6lGHzktFPmE4XYmm(FGotFGh4PVMPd8cZatbEGomtN2hzggZ35SR0Qvwox6fyaQEy1UNRFx(99789Dgy(bDvMm94tM(id2CqTb1E1d5mOQTLh120KOLt3WuJsSE01ktQ7jw1qJSUKrd9GxFFfBQgHMvw9YAuBhNDN104QxvMQjwZ220ZWrzf5g2Lo9A(NxFoPcJDzvfhzC18wDwc112s2K2Qs96UeVYdVHSLQUnDwBdlpLC5pxT8sBeS85SnTPp5admqIj8PMohu3ZZX9KJokBTtBypANfF0XPYQEg2wUtj56jt9euQByz4QlKf)ZtyvpQrJg4oFGHOHV(kRRru8RxVwlhcTy(YZwyUYz9WpKK9PYtSQRdX0SKMRW776Rqwgf9Q4OnUYglMlt1AlwTwgPAD6Awkb7sQ6S5lxoRpUJkoMYTiujEVkfjYME6swYnjUcR5BfkccFmQXekAmMhfnu6F91KTmAkZuKPGbl8oezxsvp0S1Wt)2H9N1Y2ICnnu8yJyrMWsDjOltZDv2qzQcmC2MYgwfGu4eGHHhfEm4W4)7T3wOlhSNjwhvcjsdMXtiRPTSwHSUgxLSpPM(OJuilAiu3hmHGKQPSRl7nfpztuTyVEnLqeqGRkrIeZMyS0tQ4A7tvjkgnDSPEsUQ4eMDNJL(ytQe4z1xp4)8Anio7P6Z7JGdXc(MMIlOB4rwNYfiMcj1GA77eo8QOGTR3j49a4ZDO4sAIQI04Phl9yR7zRgQx33a)QFDsdnN75m0wo6OYjkBPjUqlSBlxjzthD5eBuNIUe0cl7jN4JdGHfynX2yLQ5KYN)Cxt23dBUIdhEjeImlzH7nIkn02OrMzZiNzkDT5oo9kbc1akOtPUrdH1zohJWzAyv3Mg4DfwZLywNJ4H7Aq1F7REi42E61cLuXYo7pNDtfzpX2TKVfr8mM2RGD9WBBxINJ4JQI5Qbkjo27lCSHnenuyxWxcUD4ldZ8wpi8vgaUt4UG7MhObFvy3WEq0NaSxb4EeG79adb77vGVgCFi65aWbfG7hEa4bHhceHhgscFD4Biahsag61HhHbA7f4nYngkcPtaJkaJvagNHPGJWFEu(Zj5pNQdYcogCC4ejGtQdFt4XHPHNao1UGV1DazGSqUqNoKaYNakKaodueUd40W5eGNmbusao7gfYM5eRmzHjlsUkuraMvaEk4UE1hHznKu5G4IN6dEJ34T3CZpCRVKOTXkUvAO10Sxu131ZU5skb)FL7SKrDrlBpXfpZZKmlsjrSqCZrtEjrpDILGi(ZHI()ujpNTyu)IAepIQhrlT4PnCLvmnSAioJTVlXg9HJKVEDSxrdlX(bRfxit60PtomF1PepFQLaUSccJmIyflZwISWkxKYHjdI1L1iI640nXgSTujcDjXTx(mwAHl(ce5lNb5EkH0BgYiDprRBL5wzstJ7TPlrGWE0RSAAJSfI8itCGTxa30NH4fqtLIrqViXA50gAdFsS5z5NSKk27IOk3G4Xv0K9ZwLmylISnSJ(mS8jIOvGBE4sGHR4YOCRXSn8wWnv8LME7wZoMJU1i(8ozvIxggRtQX4ch)ykXvm80fhtKthXfLUqcbNOjQitDf9SfD1TxzuD8S3qluq38ENw8f4BAYS1okUaJN8WD)5rI)5KX)CQ4Fw1dPbj4lyZVyhNHVvGS0Kbel5wzz2r)0u4MhG1cgw5mzrrPSHsvpFLujXxYWNwwFppBRrqg6qOz85uLDsBbZw2(ESPNjlZp2vJCg5ubZe9cZejdmbinlUapSnOFBQyQUxpMZPRVpzj3QOz0cXh92t3yNRtFXg30tZ8o8H3Tu11uhosS6rtztkEt9iC90zVY3239nJigF2dpCeWnc8k6r9dcpzO4o(TWodJG7kITnijmhYci9sfFViqcIUZPtuVmZjkB1s0oioRByollaDMdLO1fgHruXuI20gSEWJsfx8WSzzXdtTenCKnOUPIclgwuZUJk1tmdUwiHv4SVuNrHswpq8oZOhtexg6ixDSuT)PqrERoT02(fZoIMdMjAKswJwHHhWCF0WSiTiADBs(Cuz7z4Q4rbnWnVBRCOnPZkLMPYAC0uBLFlwLodoIXlA(b5fLMZ3nC)Nw4EmTOLHzSrejGBXCJ2YI8dYWtaf1r4tC)uC(3XJ2y2bqO(LIDQxpcqqugRJTvtXDvQ9bQ8e9D5EkISQExUWytjcqJQrKLcJyZ4HvfO47rsLK1DY4wh2zs2w(nvWyxw39bn2grIlCtdRunLVcFKhwCSHpS44JHN6mk7VTmN(4V47qSbs6grCR4PzlfYWWD4mAWX6zDdJi2EuWw81Fwbd6ss6wkqlD7DGbaIeOc20mym61bVhmIujNZrt2JW3LKd3xsG(rBIRqfRGPwaBlfRcHdJgEzhxenYNkRP0HTG6FSpFS2dT95KX69jc(mUtrd7TvCfQhUB2KI0GE2(XIRorKuxFcQTJC6sXOgVzdS6MDkUQGlY4PVzwNWCGJYjoLHLQPVgXni9SyjySfCFvvQHdMfFBFxYd3RNC442PBTeLzyC4EF2BQAWWb97Wbi(o4jylI6aV4VLyJ99zTiJvLtvMXwJSeKC9CDQmLnz26CqHvzdJD9flDnSovvDcpHKkwRZY9mJ5kYTCz7QZGrlh7QncwsM0DiHn0mCFooKEzYe4P8o7rM)ETGR8Gn03AhFAkwCD0Vi7XUdeIUZEWDtftiHSi12Jxz9a8IjpW(G9FnxFf2TtWU)alnfDc7YR(if(arXDS6b1wsRh4ohsXfl1YKSkgcBWYbgMyiAyf1lbnxAdMohow9yLOYlA9J9ixbLkYcuzhMs6Cp5kNzMzRvjB5m5oBMtF6s1knFEw1RknnOuBQUZU76ch4pwpV5YZvArwk7W00WfCnfte2WwsPSLZFUtd(opGVXi6(AJ0bhosJa80iMK6ES6zzL6gRGyjw1W5tiTIHMN(hXQh(SB80gp5mhxBLHhFYZHfjNy1itiRS5khyijvw6Atb7BxRUSm1algLKLHeKWkI8jjOb8KUhyi4LXIM)lV379h3CZpyRVKyvhQTdH61copRE7zgiOCB48p5afp17(UV7FAh7yVjWsRl1VsRHlSe80WZa37DJW7FddEdkCmnCjegdplpm4GbiyeiV4sWfBJfHUGAZd7xXHsCjECyfIPy4PvvC1XIWVmmY8CmwSUwXwb1yyVSUwnwxW3dQRdnIWAGoyCb45IqvWLhcmHMWe7dHoGDFamGd888lZGQdUo7TtDUNSZTabtd(WYtGyh0N)4LyxviI)ixmJMwfl3l2zgxCgIMH8fRfGxCVyodQQjzXQnTT90NiTxd5(cjQYHeSlv54qRleajowUINVwXZtlFHXzqc4fqSWgvZxoFUAfKYmt(WBmzMf64btu8uF4B(MV9MB(xlEQ)8E37dT5M)JIN6V97V7gBU5)8ZDp6wDl9XpcF)p1UqRBcxi8dc8xWRGp)H91IxRpwCKT80x5OEZApMEhlo8J2QD(tWLs1XoFRD6bZA3LZOZHdmhXsGmFIkDCiQGg8PKrVpoIpAlocPIS7DL5mEn0zS0nYz4f6mwbdDU)TqxUc)m3TNTCUa2sOvitzRjo)tDHRozHZyAg5K4uKW3MrpcVi8sWlNa(o3qQq47gYbE)7O7qOFXU3T4o2rXbqxzM)RpK51Uz9sodgX61(oRVHbrZ3NGiRjQO6QMD5J06y9ji6sXVDDPT)21LCe32U43UE0LRlTTxUUu0LR)l)FYlxFNB)LR364h5eZDI5k(CZxV3lx)l4W4hMme7WKBMucIrH9GBBgFuwwT9nq5h3djgMaX8zvRpvPZZoBFNFwqI9FOe5(31X(FsZCt6gsI9t6xUx1R)82tTWroU9Sr(NoKy)HB7ls5AlHi)8BOHET(yOZDSJwn)zZuB2klC9n0)FpF1R9jkFRhy7Y3A75Q(P9WvPoP0fMO8fA4xR0NvCvFrcx9nHRBmx1pRpHqsLQ2S8XwW8evMOpHq)9BBWL35l(V(

local function GryphonsAndWyvernsWeakAura()
    if not _G["Bartender4"] then
        print("No Bartender4 detected. Disabling Mouseover-Effect in Gryphons and Wyverns WA...")
        return
    end

    -- Only register the fade handler once
    if not _G["GryphonsAndWyvernsWeakAuraInitialized"] then
        _G["GryphonsAndWyvernsWeakAuraInitialized"] = false
    else
        return
    end

    local frame = WeakAuras.GetRegion(aura_env.id):GetParent():GetParent() -- get the "Gryphons and Wyverns" frame

    -- Only continue if the frame is valid
    if frame.id ~= "Gryphons and Wyverns" then
        return
    end

    frame:SetAlpha(0) -- start with 0 alpha

    -- Bartender4 action bars to show/hide
    local actionbars = {
        "BT4Bar1",
        "BT4Bar3",
        "BT4Bar5",
        "BT4Bar6",
        "BT4BarStanceBar",
    }

    local function mouseIsOverBar(bar)
        local LAB = LibStub("LibActionButton-1.0")

        local LABSpellFlyout = LAB:GetSpellFlyoutFrame()
        if MouseIsOver(bar.overlay)
            or (SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() and SpellFlyout:GetParent():GetParent() == bar and MouseIsOver(SpellFlyout))
            or (LABSpellFlyout and LABSpellFlyout:IsShown() and LABSpellFlyout:GetParent() and LABSpellFlyout:GetParent():GetParent() == bar and MouseIsOver(LABSpellFlyout)) then
            return true
        end

        return false
    end

    local function controlFadeOut(bar)
        -- Check if any of the action bars are hovered
        local fadebar = false
        for _, barname in ipairs(actionbars) do
            local actionbar = _G[barname]
            if mouseIsOverBar(actionbar) then
                fadebar = true
                break
            end
        end

        -- Fade-In/Out all defined action bars
        for _, barname in ipairs(actionbars) do
            local actionbar = _G[barname]

            local changed = false
            if actionbar.faded and fadebar then
                actionbar:SetAlpha(actionbar.config.alpha)
                actionbar.faded = nil
                changed = true
                -- Handle WA here
                frame:SetAlpha(1)
            elseif (not actionbar.faded) and not fadebar then
                -- Register events for each action bar
                local fade = actionbar:GetAttribute("fade")
                if tonumber(fade) then
                    fade = min(max(fade, 0), 100) / 100
                    actionbar:SetAlpha(fade)
                else
                    actionbar:SetAlpha(actionbar.config.fadeoutalpha or 0)
                end
                actionbar.faded = true
                changed = true
                -- Handle WA here
                frame:SetAlpha(0)
            end
            if changed and actionbar.ForAll then
                actionbar:ForAll("UpdateAlpha")
            end
        end
    end

    local function barOnUpdateFunc(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed > self.config.fadeoutdelay then
            controlFadeOut(self)
            self.elapsed = 0
        end
    end

    for _, bar in ipairs(actionbars) do
        local actionbar = _G[bar]

        -- Register events for each action bar
        if actionbar then
            -- 1. Register events for each action bar handle the fade (includes with overlay)
            actionbar:SetScript("OnUpdate", barOnUpdateFunc)
        end
    end

    _G["GryphonsAndWyvernsWeakAuraInitialized"] = true


    -- (Alternative apporach) Register events for each action bar button (without overlay)
    -- Gryphons and Wyvern Alpha
    -- local function ShowAura()
    --     frame:SetAlpha(1)
    -- end

    -- local function HideAura()
    --     frame:SetAlpha(0)
    -- end

    -- Set scripts for the WeakAura frame itself
    -- frame:SetScript('OnEnter', ShowAura)
    -- frame:SetScript('OnLeave', HideAura)

    -- Set scripts for each action bar button, excluding ElvUI_Bar4 and ElvUI_Bar13
    -- for button, _ in pairs(LAB.buttonRegistry) do
    --     if button then
    --         local buttonName = button:GetName()
    --         -- define action buttons where to exclude this effect
    --         local exclude =
    --         -- Bartender Bar 5
    --             buttonName:match("^BT4Button37") or
    --             buttonName:match("^BT4Button38") or
    --             buttonName:match("^BT4Button39") or
    --             buttonName:match("^BT4Button40") or
    --             buttonName:match("^BT4Button41") or
    --             buttonName:match("^BT4Button42") or
    --             buttonName:match("^BT4Button43") or
    --             buttonName:match("^BT4Button44") or
    --             buttonName:match("^BT4Button45") or
    --             -- Bartender Bar 6
    --             buttonName:match("^BT4Button145") or
    --             buttonName:match("^BT4Button146") or
    --             buttonName:match("^BT4Button147") or
    --             buttonName:match("^BT4Button148") or
    --             buttonName:match("^BT4Button149") or
    --             buttonName:match("^BT4Button150") or
    --             buttonName:match("^BT4Button151")

    --         if buttonName and not exclude then
    --             button:HookScript('OnEnter', ShowAura)
    --             button:HookScript('OnLeave', HideAura)
    --         end
    --     end
    -- end
end
