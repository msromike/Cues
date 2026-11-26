-------------------------------------------------------------------------------
--  Cues/Media.lua
--  Sound discovery. LibSharedMedia-3.0 is the catalog: every addon shares one
--  library instance, so whatever MSBT, BugSack or any other addon registers is
--  already in LSM:HashTable("sound"). The one exception is EllesmereUI, which
--  keeps its sounds in its own catalog -- we publish those into LSM here so
--  they show up in our dropdown (and in every other LSM consumer).
-------------------------------------------------------------------------------
local ADDON, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")

ns.LSM = LSM
ns.EUI_PREFIX = "EllesmereUI: "

-- Register EllesmereUI's alert sounds as "EllesmereUI: <Name>". Read live from
-- EllesmereUI's catalog so sounds it adds later appear without touching Cues.
-- Safe to call more than once (LSM ignores duplicate names).
function ns.RegisterEllesmereSounds()
    local EUI = _G.EllesmereUI
    if not (EUI and EUI.BuildAlertSoundTables) then return 0 end
    local paths, names, order = EUI.BuildAlertSoundTables()
    local n = 0
    for _, key in ipairs(order) do
        local path, name = paths[key], names[key]
        -- LSM only takes .ogg/.mp3 and reports anything else as an error.
        local ext = path and path:lower():match("%.(%a+)$")
        if name and (ext == "ogg" or ext == "mp3") then
            if LSM:Register("sound", ns.EUI_PREFIX .. name, path) then
                n = n + 1
            end
        end
    end
    return n
end

-- Register Cues' own files (Cues\media\, listed in the generated Sounds.lua)
-- as "Cues: <Name>".
ns.OWN_PREFIX = "Cues: "
function ns.RegisterOwnSounds()
    local list = ns.OWN_SOUNDS
    if not list then return 0 end
    local dir = "Interface\\AddOns\\" .. ADDON .. "\\media\\"
    local n = 0
    for _, s in ipairs(list) do
        if LSM:Register("sound", ns.OWN_PREFIX .. s.name, dir .. s.file) then
            n = n + 1
        end
    end
    return n
end

-- Every sound name LSM knows about right now: Cues' own ("Cues: ...") first,
-- then all the others, each part in alphabetical order regardless of case.
function ns.SoundList()
    local own, other = {}, {}
    for _, name in ipairs(LSM:List("sound")) do
        if name:sub(1, #ns.OWN_PREFIX) == ns.OWN_PREFIX then
            own[#own + 1] = name
        else
            other[#other + 1] = name
        end
    end
    local function byName(a, b)
        local la, lb = a:lower(), b:lower()
        if la ~= lb then return la < lb end
        return a < b
    end
    table.sort(own, byName)
    table.sort(other, byName)
    for _, name in ipairs(other) do own[#own + 1] = name end
    return own
end

-- name -> name table for AceConfig `values`, rebuilt on each call so sounds
-- registered after the dialog was first built are still listed.
function ns.SoundValues()
    local t = {}
    for _, name in ipairs(LSM:List("sound")) do
        t[name] = name
    end
    return t
end
