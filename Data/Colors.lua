local ADDON_NAME, LingkanUI = ...

-- Shared palette for the config UI.
-- Blue/orange match the branding already used by the installer
-- (Install/Game/Shared/General/Core.lua) and the LingkanUI logo art.
local COLORS = {
    BLUE      = { r = 0.00, g = 0.569, b = 0.929 }, -- #0091ed
    DARK_BLUE = { r = 0.00, g = 0.490, b = 0.790 },
    ORANGE    = { r = 1.00, g = 0.639, b = 0.000 }, -- #ffa300
    WHITE     = { r = 1.00, g = 1.000, b = 1.000 },
    GRAY      = { r = 0.67, g = 0.670, b = 0.670 },
    DIM       = { r = 0.40, g = 0.400, b = 0.400 },
    GREEN     = { r = 0.30, g = 0.900, b = 0.400 },
    RED       = { r = 0.90, g = 0.250, b = 0.250 },
    BG_DARK   = { r = 0.02, g = 0.020, b = 0.020 },
    BG_PANEL  = { r = 0.04, g = 0.040, b = 0.040 },
}

-- Hex forms for inline text coloring (|cffXXXXXX)
COLORS.BLUE_HEX   = "0091ed"
COLORS.ORANGE_HEX = "ffa300"
COLORS.GRAY_HEX   = "aaaaaa"
COLORS.DIM_HEX    = "666666"
COLORS.WHITE_HEX  = "ffffff"
COLORS.GREEN_HEX  = "4ce566"
COLORS.RED_HEX    = "e64040"

LingkanUI.COLORS = COLORS

-- Branded addon title used in the sidebar header, chat prefix and popups
LingkanUI.TITLE = "|cff" .. COLORS.BLUE_HEX .. "Lingkan|r|cff" .. COLORS.ORANGE_HEX .. "UI|r"

function LingkanUI.Colorize(text, hex)
    return "|cff" .. (hex or COLORS.WHITE_HEX) .. tostring(text) .. "|r"
end
