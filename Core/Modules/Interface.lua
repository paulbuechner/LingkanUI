local ADDON_NAME, LingkanUI = ...

-- Create the Interface module
LingkanUI.Interface = {}

-- Module name for debug output
local MODULE_NAME = "interface"

-- Module-specific debug function
local function DebugPrint(message)
    LingkanUI:DebugPrint(message, MODULE_NAME)
end

--------------------------------------- Interface Settings Handler ---------------------------------------

function LingkanUI.Interface:Load()
    -- Apply settings immediately
    self:ApplyInterfaceSettings()
end

function LingkanUI.Interface:Unload()
end

function LingkanUI:InterfaceHandler()
    LingkanUI.Interface:ApplyInterfaceSettings()
end

function LingkanUI.Interface:ApplyInterfaceSettings()
    DebugPrint("Applying interface settings...")

    -- Apply UI Errors setting
    if LingkanUI.db.profile.general.interface.hideUIErrors then
        DebugPrint("Hiding UI errors")
        UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    else
        DebugPrint("Showing UI errors")
        UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
    end
end
