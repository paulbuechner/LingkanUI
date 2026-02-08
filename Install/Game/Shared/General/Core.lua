local LUI = unpack(LUI)

local tonumber, ipairs, unpack = tonumber, ipairs, unpack
local format = format

LUI.title = format("|cff0091edLingkan|r|cffffa300UI|r")
LUI.version = tonumber(C_AddOns.GetAddOnMetadata("LingkanUI", "Version"))
LUI.myname = UnitName("player")

function LUI:Initialize()
end
