local _, LingkanUI = ...

local ltab = {}

function LingkanUI:GetLangTab()
    return ltab
end

local missingTab = {}

function LingkanUI:GT(str)
    local result = LingkanUI:GetLangTab()[str]

    if result ~= nil then
        return result
    elseif not tContains(missingTab, str) then
        tinsert(missingTab, str)
        LingkanUI:DebugPrint("Missing translation for: " .. str)

        return str
    end

    return str
end

function LingkanUI:UpdateLanguage()
    LingkanUI:LangenUS()

    if GetLocale() == "deDE" then
        LingkanUI:LangdeDE()
    end
end

LingkanUI:UpdateLanguage()
