local _, LingkanUI = ...

LingkanUI.Install = LingkanUI.Install or {}
local Install = LingkanUI.Install

Install.Addons = Install.Addons or {}
local Addons = Install.Addons

local function NormalizeProfileData(data)
  if type(data) == "table" and type(data[1]) == "string" and data[1] ~= "" and next(data, 1) == nil then
    return data[1]
  end
  return data
end

function Addons:ApplyBigWigsProfile(profileName, profileData)
  local encoded = NormalizeProfileData(profileData)

  if type(encoded) == "string" and encoded ~= "" then
    BigWigsAPI.RegisterProfile("LingkanUI", encoded, profileName, function()
      -- async callback; installer will prompt for reload anyway
    end)
    return true
  end

  return self:ApplyAceDBProfile("BigWigs3DB", profileName, profileData)
end
