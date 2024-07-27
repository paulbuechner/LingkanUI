local _, LingkanUI = ...

LingkanUI.Customizing = {}

-- Bartender4 action bars to show/hide
local actionbars = {
    "BT4Bar1",
    "BT4Bar3",
    "BT4Bar5",
    "BT4Bar6",
    "BT4BarPetBar",
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

-- !WA:2!TJ1YVTX1vFRq7MMPPP2YjUooVMWKOqLir9WwYpQDCjPinPnLeZqkj7e7inpUKZepCMj3zgjtNMKw12udKnTQfifztke6YuGc9pqaYIUORoXiODtb((qA7Ig8beKS8dOq9CVZWhdjLFaNuG2eUy4m3NNZ53VZ5Eo3bwCqxLPsoXujp8G1huBqTR9uodQAB5rTnnjAz0nm1OeRNzJIKQEILn0iBkzutp41pwXMQrOPLvVSg12XzVPnnU6vLPAIvSTn9mCuwtUMDHz2W)86liLB8lREDzFpDB68oEg2wUc0gZxTQlXR4WBjBPIDuY2WYtjt25QKvARGvpJTPn9SdmWaXM0NA68q6EEoUNySXylDsd7XAT2JnbvwLVUtl56jt9esByz4jOuf)ZvxyDpQrTAeQ7HgIg(6BUPgrXVA1knCi08zlwk3cft7HFij7tLNCDxhIPzbnxHp21xHSkXYRmoAJRS1YzsvUYYLRKsQsRUkrjyxsLlLTyX0(4oR4yk3GqL49QKNiB6PlzjxN4kSHVvOii85OgtOwYMlIIgk9V9gYwg1LzkY0W(YbhmTLTf5diYUKYEiuuZt)UVUgkESrSmtyPUeeX0CxNngMQapD66Ygw4CHNgsC3WWWZapl(6(7Uf6Qb7zSnrLqIuJdkPnTL1YP4jBII9bKQ7JiPqA0uOEaycbjvtzxx2BPDnUkH9Y1vcjabqvSyXkfB8KtP4A7tvjkg1DSPEsUQ4cwA3JN8OtPeGS6Bg8FwTAeN9v(v8LPeXC(MMIlPB4r2KYfiMcjvJA77eo8Y42UNpi49a6Z9O4sQJQI0ejhp54B6zRgQxhCGF3VpUHMZ9FgAdhDu5eLT0exQb2TLRIdUFwERxchRnA)3QkfXg0gl7jh7Zd4J5ynXKaLYzKYMDUnCjMv5Ku4Ed5NfSqja5MgABvlvPuYPMwxBHJrVsGOnGccnvnQjSjdImcO9Bzyv1MgGXcsYMo6YXgu9pETNcURxyJqrvSOZdMXUUISNyZwY2GiEgt71WUE8DSlX5i(OkyUEGwIJ9GHJnSH2df2d8nG7g(MWmqgqya4Bb3l8T5EAW9bFhyVi9tagua2VaC)hAi4bEt4aW3fzqpiCib4HGhgEe4rHhdeHhhIdpHa8KcWt92WqbS2OmVrU5Cry0yqsbySCW4msfmj)5H5ppc)5uTOwW0WrHJfdoUoCc47bNeof8C7bo99aFFifKoe1HyWSV3Jc5IbNbYdfqLBob4SXG7rao3w5sN64RnvUPYtUkmVausaE(yx7Pzwdjvolo)P)K35DE)T3(t79LynnwDyLgAdn7Lv9D9SRVIsW)x5EVKrvrlBpXLpZlgpngqIyH8LJe)sIE6elbr8NdfPsjIpNTy7(f1iEevpIwsXzmCLvmnSQjoRTVlXgbWrZwTk2ROHLy)i1IlLkzYKXhMV6uINp1saxwbHrhvCElZgImNkxmGdtgeRkRre1XPBInyBPse6qIBU8PS0cx8LiYxofg5PagCZqgJ1t06uzUDM0PW920Liqyp6wwnTXyfIC3rCGnxa3KNH4feKkbl88YeRvtAOn8jWMlXDLte5DruLRr84kA8(zRIhSfTTnSZ9mS8jIOvGBE4sGHR4QOCRXSn8wWnv81p1oTMTmhDQr85DIYeVumN9eJZfo(HuIRz4PloUipkaxu6GjeCEMOIm1v0Zw0v3ETX0XdEdTqbDZ79uIVkFtJNUYrWfyI4J05Nho6Ntf9ZPJ(zjIh(mABL9W4HKGMFTwaKVvG8vNrol4o)QSCbOjqbkG)fmSIPsJIxrdLYE(kjIJVKIpT0(EE2wJIXSdPRrNtz2zV5mBy77XMEQ0mSTJg5HMtemtezMTTmWeGKmFf843G(TPIj6C9yawhFFIcULrtRfYz6UNo5t3G(ImUtDkgIXhENsvhtD42IvxAkBsrBQlHRRo7w(25UVveXOZE4HBtMBtOf9O(bUSmMDlClSZqV6o8IBssctQmhgYzEFV2KeKXNrNOEzgikB1q0oW3RtQplVaDgGs06GJWcEXuIMHsy9GhRkU8iSzzXDDTenCKnOUjA7QmSOMDlvQl)iCTWGyHZ(sTgfkzDrXBnJUmrCzOLC1Ys18NcfJL1QLM2Vi2r0CWmrJwWAS5z8bmBinmVslIwNMKVev2UgUkE8qnCZ70khAtATsjzQSgNn1u57XQ0AWTJc2E(b5iLKhdC4(pTW94uIwgMrgrBbShZnAlZZpCdpvuuhPprXPOXKNO9gZouc1VeStc7sac8YyDSJAkURsnpKLN6VlhPiYQ6DaHrMsBcnQgTTuOhBkpSobfFpsI4SUJh16WoNY2YVUc67Y6UpSXMmsCHRByLOU8v4JCeXXhEeXjghpjAm2F9mN(Gx8DiYajDYiUDqA2sHry4aolm44DTUHEe7mlOhS(lkAqhssNsbAPBUdmcqBbkNnnf6JEd47bJir8fC0K9i8Dj(W9niq)cBIRW8wbtnh2wcwbiJGgEzhxKnYNkRPKHTG6FKpF2MdT55Kr695c(mkOOH92iQc1vSB2KARbDT9JhvDAhK6ghGANcoDPiHgVvDS6m6uuvbxKjsERSoH5f3op5egwQM(Ae3Gu2IKGrp8(YQudhmZ(Myx8r6gjhoQD62l5zghNxx2lDlvxgoO)eoGhZzq8uSLLXkZP87JywBnYkSPCDSyuvDcptJ5T2KLOzkZ1KB4cp(MzAv4kBHxNTcSB3yf2U9ecFC7vmy1Wn(dyTHwlEDNRWLUNuylnd3xMZQxLmjEqVZ(K5Vxj4Eqyt(921DsbKBIqJSh7Iri6o7d3nvmNeYYuBpEH2dWlW8qhao41D9vyxzb7sfS0u0jSl06Zu4devGXQsRgGLdP4I1Ezswh9FnyjadtmenS(6vG6ReuP6wmTnCg69w26N7rUckvKLOYomL05(Zum1SLQmF6IPYCUuZmtHkfwmlRIwL6guQnv3zVDC5d8hBM1C1fkSmltE4K0WfCdftK5WwsP0fZo3mGVZJ4BmQUV2OTOIJwlGsnQjPQhm7aSIFJuJSew3ByjYR32sDUTEbJZo7X0wB4jMAoygSs65eKwZqZt)ZG5p0qsQSe2MgEG9S(QYudSevsAgLrcRtYNeJgeP09qdbVbwh9F7J(O)NT3(t69LyR7qTDiuVgW5zvGJLOhucoC(Zoq(t)HF4h()URDT)yy52f6PCB4cRaVa8ICFG7dP3)bg9gUiNmdYRGu)L5UaihL5nOScSYkmFHaUi0bvBr4GkouIlXJtRq(06kU6yD5xMtSgzronRvxRzRGQlVR9Z6A9wDb)yERv1HAT5AGoyCb4LzSk4YdbMqDyId0I6a29HWaoWRWVGdQo46S)wL)EIw3meCsWhwDsK7Gy(jlWU)qK)rUyknT5TCVyRzCXzjAgYxSsaFX9IzmOQMKLlx322tFYKE1KHzxQhkrz45zxYYX40ITkNTy2mvYjLA2SqdgZ4OzYF(k5ppT4fMiKzaV6fcVdLorWy5p9N(UV77V92)98N(VU)9)yBV9)F(t)p(Z3xTT3(F(LoI2lS0foc)K7qi06wgcHFAaEbVj(8N1plELoT4W1cSZy0YzUYr8kzpU(n0oF7ErvDANV9o9OjyCj4L4ObBGReEmadHytsPz4Eqf0G7Wi69bi(SoacP8SlGLbgVvlWyLBgy4fcgRHUopCpHlxJFSBy0YhEx9Gul0oCzak1yYZ)8x4QtL7mMMTqjEms4hWIpcVg86WBed(H30yHWpQ3GGOl0VzV7vCx7k)aiuM6)GDzERBpuYzW2r9AEp2rDIUupqZI9ZjYAY5vDvtV6HBC0(6ef5g3L25BCxYrCh7IFJ7TVWDPD8c3L(V9lCF3WS)2D6c3BCSdF8fo(c5F5fR21fU)v6yySdtgIDyYTEkbrcH9O7ygFuwwT9lLVFE3XWWeiwmTA1PlCE2j67(l2yy)BnrUV8p2)olZnPObX(l3vpGZVOFrXoA1QVI90lD4JzxQfa91PCDJCr(13ud9g9ZqN5OhPC2ZLQsP5x6gAO)kC8Q36oiFRhzNY3kmwvFs46x2DWk1PKUWKfVqn)kf(Ipy1xNWv7eU6kw1)xVUq)Q(5cjvOC9IhDjZJp)K9ZfAWv39R9V(d

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
        "BT4BarPetBar",
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
