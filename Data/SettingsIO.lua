local ADDON_NAME, LingkanUI = ...

-- ------------------------------------------------------------------------------------
-- Profile serialisation.
--
-- Profiles are emitted as a plain Lua table literal and then Base64 encoded so the
-- result is a single safe-to-paste line. No compression library is bundled, so strings
-- are longer than e.g. an ElvUI export -- acceptable for a config this size.
-- ------------------------------------------------------------------------------------

local SettingsIO = {}
LingkanUI.SettingsIO = SettingsIO

local PREFIX = "LUI1:"

-- ------------------------------------------------------------------------------------
-- Base64
-- ------------------------------------------------------------------------------------

local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local B64_LOOKUP = {}
for index = 1, #B64_CHARS do
    B64_LOOKUP[B64_CHARS:sub(index, index)] = index - 1
end

function SettingsIO.Encode(text)
    local out, length = {}, #text

    for position = 1, length, 3 do
        local byte1 = text:byte(position) or 0
        local byte2 = text:byte(position + 1)
        local byte3 = text:byte(position + 2)

        local triple = byte1 * 65536 + (byte2 or 0) * 256 + (byte3 or 0)

        local char1 = math.floor(triple / 262144) % 64
        local char2 = math.floor(triple / 4096) % 64
        local char3 = math.floor(triple / 64) % 64
        local char4 = triple % 64

        out[#out + 1] = B64_CHARS:sub(char1 + 1, char1 + 1)
        out[#out + 1] = B64_CHARS:sub(char2 + 1, char2 + 1)
        out[#out + 1] = byte2 and B64_CHARS:sub(char3 + 1, char3 + 1) or "="
        out[#out + 1] = byte3 and B64_CHARS:sub(char4 + 1, char4 + 1) or "="
    end

    return table.concat(out)
end

function SettingsIO.Decode(text)
    text = text:gsub("[^A-Za-z0-9%+/=]", "")

    local out = {}
    for position = 1, #text, 4 do
        local c1 = B64_LOOKUP[text:sub(position, position)]
        local c2 = B64_LOOKUP[text:sub(position + 1, position + 1)]
        local c3Char = text:sub(position + 2, position + 2)
        local c4Char = text:sub(position + 3, position + 3)

        if not c1 or not c2 then return nil end

        local c3 = B64_LOOKUP[c3Char]
        local c4 = B64_LOOKUP[c4Char]

        local triple = c1 * 262144 + c2 * 4096 + (c3 or 0) * 64 + (c4 or 0)

        out[#out + 1] = string.char(math.floor(triple / 65536) % 256)
        if c3Char ~= "=" and c3 then
            out[#out + 1] = string.char(math.floor(triple / 256) % 256)
        end
        if c4Char ~= "=" and c4 then
            out[#out + 1] = string.char(triple % 256)
        end
    end

    return table.concat(out)
end

-- ------------------------------------------------------------------------------------
-- Serialisation
-- ------------------------------------------------------------------------------------

local function SerializeValue(value, out)
    local valueType = type(value)

    if valueType == "table" then
        out[#out + 1] = "{"
        for key, entry in pairs(value) do
            local keyType = type(key)
            local entryType = type(entry)

            -- Only plain data survives a round trip; anything else is dropped
            local keyOk = (keyType == "string" or keyType == "number")
            local entryOk = (entryType == "string" or entryType == "number"
                or entryType == "boolean" or entryType == "table")

            if keyOk and entryOk then
                if keyType == "string" then
                    out[#out + 1] = "[" .. string.format("%q", key) .. "]="
                else
                    out[#out + 1] = "[" .. string.format("%.14g", key) .. "]="
                end
                SerializeValue(entry, out)
                out[#out + 1] = ","
            end
        end
        out[#out + 1] = "}"
    elseif valueType == "string" then
        out[#out + 1] = string.format("%q", value)
    elseif valueType == "number" then
        out[#out + 1] = string.format("%.14g", value)
    elseif valueType == "boolean" then
        out[#out + 1] = tostring(value)
    else
        out[#out + 1] = "nil"
    end
end

function SettingsIO.Serialize(tbl)
    local out = {}
    SerializeValue(tbl, out)
    return table.concat(out)
end

-- Runs the literal in an empty environment: a data-only chunk cannot call anything,
-- so a malformed or hostile string fails harmlessly instead of executing.
function SettingsIO.Deserialize(text)
    local chunk, err = loadstring("return " .. text)
    if not chunk then return nil, err end

    setfenv(chunk, {})

    local ok, result = pcall(chunk)
    if not ok then return nil, result end
    if type(result) ~= "table" then return nil, "decoded value is not a table" end

    return result
end

-- ------------------------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------------------------

function SettingsIO:ExportProfile()
    local profile = LingkanUI.db and LingkanUI.db.profile
    if not profile then return nil, "no active profile" end

    return PREFIX .. SettingsIO.Encode(SettingsIO.Serialize(profile))
end

function SettingsIO:ImportProfile(text)
    if type(text) ~= "string" then return false, "nothing to import" end

    text = strtrim(text)
    if text == "" then return false, "nothing to import" end

    if text:sub(1, #PREFIX) ~= PREFIX then
        return false, "string is not a LingkanUI profile"
    end

    local decoded = SettingsIO.Decode(text:sub(#PREFIX + 1))
    if not decoded then return false, "string is corrupted" end

    local imported, err = SettingsIO.Deserialize(decoded)
    if not imported then return false, err or "string is corrupted" end

    -- Merge into the live profile so AceDB defaults fill any missing keys
    local profile = LingkanUI.db.profile
    local function Merge(target, source)
        for key, value in pairs(source) do
            if type(value) == "table" then
                if type(target[key]) ~= "table" then target[key] = {} end
                Merge(target[key], value)
            else
                target[key] = value
            end
        end
    end
    Merge(profile, imported)

    return true
end
