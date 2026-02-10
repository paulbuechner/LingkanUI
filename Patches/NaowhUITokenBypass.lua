---@diagnostic disable: undefined-global

local function PatchNaowhUI()
    if type(NaowhUI) ~= "table" then
        return
    end

    local ok, NUI = pcall(unpack, NaowhUI)
    if not ok or type(NUI) ~= "table" then
        return
    end

    -- Bypass NaowhUI token validation + prevent unlocker popup.
    function NUI:IsTokenValid()
        return true
    end
end

-- NaowhUI is optional; keep this event hook so the patch applies
-- when/if NaowhUI is loaded.
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "NaowhUI" then
        PatchNaowhUI()
    end
end)

PatchNaowhUI()
