-------------------------------------------------------------------------------
--  Cues/FECMList.lua
--  The buff list Cues watches, read from Forever Enhanced Cooldown Manager's
--  saved settings (the global ForeverEnhancedCooldownManagerDB). None of
--  FECM's code is called or hooked: only that table is read, and never
--  written. The table is FECM's live one, so a buff added or removed in FECM
--  shows here on the next read.
--
--  What is read: chars[<player GUID>] names this character's profile, and
--  profiles[<that name>].buff (with .buff2 / .buff3, its extra Buffs bars) is
--  an ordered list of buff names. Lists that swap with a form are not read.
-------------------------------------------------------------------------------
local _, ns = ...

local BARS = { "buff", "buff2", "buff3" }

-- This character's FECM buff names in FECM's order, each once (an empty list
-- when FECM has none for it). Or nil and why: "missing" when FECM's settings
-- aren't loaded, "unreadable" when they don't hold a list for this character.
function ns.FECMBuffs()
    local db = _G.ForeverEnhancedCooldownManagerDB
    if type(db) ~= "table" then return nil, "missing" end
    local chars, profiles = db.chars, db.profiles
    if type(chars) ~= "table" or type(profiles) ~= "table" then return nil, "unreadable" end
    local key = chars[UnitGUID("player") or ""]
    local profile = key ~= nil and profiles[key] or nil
    if type(profile) ~= "table" then return nil, "unreadable" end

    local names, seen = {}, {}
    for _, bar in ipairs(BARS) do
        local list = profile[bar]
        if type(list) == "table" then
            for _, name in ipairs(list) do
                if type(name) == "string" and name ~= "" and not seen[name] then
                    seen[name] = true
                    names[#names + 1] = name
                end
            end
        end
    end
    return names
end
