-------------------------------------------------------------------------------
--  Cues/Modules/Buffs.lua
--  "Buff reminders": plays a cue while a buff on this character's Forever
--  Enhanced Cooldown Manager (FECM) buff list is missing. FECM is the anchor:
--  its list says what is watched (FECMList.lua) and its rule for a buff's
--  group version says when one counts as up (GROUP, below). Cues adds only
--  the sounds; each row's settings live in the class profile, by buff name.
--
--  The rules:
--    * Missing is the trigger: a ticked buff that is not on you.
--    * Never a sound while dead, a ghost, on a flight path, mounted, resting,
--      away or in a fight (Quiet). In a fight the game keeps your buffs from
--      addons, so nothing is read then either.
--    * One ding at a time. With several missing, the one with the shortest
--      repeat dings, with its own sound (Once counts as the longest; a tie
--      goes to FECM's order).
--    * A ding comes when a ticked buff goes missing, each time a no-sound
--      state ends with one still missing, and when the dinging buff's repeat
--      comes up. Every ding restarts the one clock. Putting a buff back is
--      never a ding and leaves the clock alone.
-------------------------------------------------------------------------------
local ADDON, ns = ...
local Cues = ns.addon
local Buffs = Cues:NewModule("Buffs", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON)

local MODULE = "Buffs"
Cues:RegisterModuleDefaults(MODULE, {
    enabled = true,
    -- One per buff name, made as a buff first shows on FECM's list.
    -- repeatSec: 0 is Once.
    rows = { ["*"] = { dropEnabled = false, dropSound = ns.OWN_PREFIX .. "Bell", repeatSec = 0 } },
})

local function db() return Cues:ModuleDB(MODULE) end

-- A buff's group version counts as the same buff. Copied from FECM's
-- Spells.lua (its GROUP, a local there that Cues can't reach), so the two
-- addons agree on when a buff is up. A pair FECM adds later is added here.
local GROUP = {
    ["Mark of the Wild"] = "Gift of the Wild",
    ["Power Word: Fortitude"] = "Prayer of Fortitude",
    ["Arcane Intellect"] = "Arcane Brilliance",
    ["Divine Spirit"] = "Prayer of Spirit",
    ["Shadow Protection"] = "Prayer of Shadow Protection",
    ["Blessing of Might"] = "Greater Blessing of Might",
    ["Blessing of Wisdom"] = "Greater Blessing of Wisdom",
    ["Blessing of Kings"] = "Greater Blessing of Kings",
}

local REPEATS = { 0, 30, 60, 120, 300 }
local REPEAT_NAMES = {
    [0] = L["Once"], [30] = L["30 seconds"], [60] = L["1 minute"], [120] = L["2 minutes"], [300] = L["5 minutes"],
}
local REPEAT_TEXTS = {}
for _, sec in ipairs(REPEATS) do REPEAT_TEXTS[#REPEAT_TEXTS + 1] = REPEAT_NAMES[sec] end

-- Seconds after a loading screen before buffs are read: the game needs a
-- moment to hand them over, and FECM to note which profile is this
-- character's.
local SETTLE = 3
local EVENTS = { "PLAYER_REGEN_ENABLED", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_MOUNT_DISPLAY_CHANGED",
    "PLAYER_CONTROL_GAINED", "PLAYER_UPDATE_RESTING", "PLAYER_FLAGS_CHANGED" }

local enteredAt        -- when the last loading screen ended
local told = false     -- the "no list" chat line, once a login
local up = {}          -- buff name -> true / false as last read; nil until the game answers
local missing = {}     -- buff name -> true while ticked and known to be missing
local wasQuiet         -- whether a no-sound state held at the last check
local lastDing         -- when a sound last played

local function Secret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

-- What the game says of the player: true also when it won't say (a secret
-- answer), which keeps Cues silent.
local function Says(ask, ...)
    if type(ask) ~= "function" then return false end
    local ok, value = pcall(ask, ...)
    if not ok then return false end
    if Secret(value) then return true end
    return value and true or false
end

local function Fighting()
    return InCombatLockdown() or Says(UnitAffectingCombat, "player")
end

-- Whether the game lets an addon see your buffs now.
local function Readable()
    if Fighting() then return false end
    local ask = type(C_Secrets) == "table" and C_Secrets.ShouldAurasBeSecret
    if type(ask) == "function" then
        local ok, secret = pcall(ask)
        if not ok or Secret(secret) or secret ~= false then return false end
    end
    return true
end

-- The no-sound states.
local function Quiet()
    return Fighting() or Says(UnitIsDeadOrGhost, "player") or Says(UnitOnTaxi, "player") or Says(IsMounted)
        or Says(IsResting) or Says(UnitIsAFK, "player")
end

-- Whether a buff by this name is on you: true, false, or nil when the game
-- won't say.
local function Has(name)
    local find = type(C_UnitAuras) == "table" and C_UnitAuras.GetAuraDataBySpellName
    local ok, aura
    if type(find) == "function" then
        ok, aura = pcall(find, "player", name, "HELPFUL")
    elseif type(AuraUtil) == "table" and type(AuraUtil.FindAuraByName) == "function" then
        ok, aura = pcall(AuraUtil.FindAuraByName, name, "player", "HELPFUL")
    else
        return nil
    end
    if not ok or Secret(aura) then return nil end
    return aura ~= nil
end

-- The same for a listed buff, its group version counting as it.
local function OnYou(name)
    local own = Has(name)
    if own then return true end
    local group = GROUP[name]
    local other = group and Has(group)
    if other then return true end
    if own == nil or (group and other == nil) then return nil end
    return false
end

-- The buff that dings: of the ticked ones known missing, the shortest repeat,
-- then FECM's order.
local function Pick(names, rows)
    local best, bestEvery
    for _, name in ipairs(names) do
        if missing[name] then
            local every = rows[name].repeatSec or 0
            if every <= 0 then every = math.huge end
            if not best or every < bestEvery then best, bestEvery = name, every end
        end
    end
    return best
end

local function Forget()
    wipe(up)
    wipe(missing)
    wasQuiet, lastDing = nil, nil
end

function Buffs:OnInitialize()
    self:SetEnabledState(db().enabled)
    -- Heard whether or not the module is on, so one switched on later knows
    -- the world has loaded.
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnterWorld")
end

function Buffs:OnEnable()
    Forget()
    -- Again here: switching the module off drops every event it heard.
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnterWorld")
    self:RegisterEvent("UNIT_AURA", "OnAura")
    for _, event in ipairs(EVENTS) do
        pcall(self.RegisterEvent, self, event, "Soon") -- one the game lacks is left out
    end
    self.beat = self:ScheduleRepeatingTimer("Check", 1)
end

function Buffs:OnDisable()
    self:CancelAllTimers()
    self.beat, self.soon = nil, nil
    self:UnregisterEvent("UNIT_AURA")
    for _, event in ipairs(EVENTS) do pcall(self.UnregisterEvent, self, event) end
    Forget()
end

function Buffs:OnProfileRefresh()
    if db().enabled then
        if self:IsEnabled() then self:Disable() end
        self:Enable()
    else
        self:Disable()
    end
end

function Buffs:OnEnterWorld()
    enteredAt = GetTime()
end

function Buffs:OnAura(_, unit)
    if unit == "player" then self:Soon() end
end

-- One check a moment from now, however many events ask.
function Buffs:Soon()
    if not self:IsEnabled() or self.soon then return end
    self.soon = self:ScheduleTimer("Now", 0.05)
end

function Buffs:Now()
    self.soon = nil
    self:Check()
end

-- Reads the listed buffs where the game allows, then plays at most one sound.
-- Runs once a second and right after anything that may have changed the
-- answer (Soon).
function Buffs:Check()
    if not enteredAt or GetTime() - enteredAt < SETTLE then return end

    local names, why = ns.FECMBuffs()
    if names and #names == 0 then names, why = nil, "empty" end
    if not names then
        if not told then
            told = true
            Cues:Print(why == "empty"
                and L["No buff reminders: Forever Enhanced Cooldown Manager has no buffs listed for this character."]
                or L["No buff reminders: Forever Enhanced Cooldown Manager's buff list was not found."])
        end
        Forget()
        return
    end

    local rows = db().rows
    local readable = Readable()
    if readable then
        for _, name in ipairs(names) do
            local now = OnYou(name)
            if now ~= nil then up[name] = now end
        end
    end

    -- The ticked buffs known missing, and whether one has just become so (a
    -- drop, the first answer after a login, a row just ticked).
    local listed, fresh = {}, false
    for _, name in ipairs(names) do
        listed[name] = true
        local gone = rows[name].dropEnabled and up[name] == false
        if gone and not missing[name] then fresh = true end
        missing[name] = gone or nil
    end
    for name in pairs(up) do
        if not listed[name] then up[name], missing[name] = nil, nil end
    end

    -- Buffs the game won't show yet count as a no-sound state too, so the
    -- ding as a fight ends waits for a real answer.
    local quiet = Quiet() or not readable
    local ended = wasQuiet and not quiet
    wasQuiet = quiet
    if quiet then return end

    local pick = Pick(names, rows)
    if not pick then return end
    local row, now = rows[pick], GetTime()
    local every = row.repeatSec or 0
    if fresh or ended or (every > 0 and (not lastDing or now - lastDing >= every)) then
        Cues:Play(row.dropSound)
        lastDing = now
    end
end

-------------------------------------------------------------------------------
--  Options: the switch, then a row for each buff on FECM's list.
-------------------------------------------------------------------------------
function Buffs:GetOptions()
    self.args = {}
    self:RefreshOptions()
    return {
        type = "group",
        name = L["Buff reminders"],
        args = self.args,
    }
end

-- Refills the rows when FECM's list has changed (Core calls this each time
-- the settings are fetched).
function Buffs:RefreshOptions()
    local args = self.args
    if not args then return end
    local names, why = ns.FECMBuffs()
    if names and #names == 0 then names, why = nil, "empty" end
    local shape = names and table.concat(names, "\n") or ("\n" .. why)
    if shape == self.shape then return end
    self.shape = shape

    wipe(args)
    args.enabled = {
        type = "toggle", name = L["Enable buff reminders"], order = 1, width = "full",
        desc = L["Play a cue while a buff on your Forever Enhanced Cooldown Manager buff list is missing. Silent while you are dead, on a flight path, mounted, resting, away or in a fight."],
        get = function() return db().enabled end,
        set = function(_, v)
            db().enabled = v
            if v then self:Enable() else self:Disable() end
        end,
    }
    if not names then
        args.none = {
            type = "description", order = 2, fontSize = "medium",
            name = "\n" .. (why == "empty"
                and L["Forever Enhanced Cooldown Manager has no buffs listed for this character."]
                or L["Forever Enhanced Cooldown Manager's buff list was not found."]),
        }
        return
    end
    for i, name in ipairs(names) do
        local function row() return db().rows[name] end
        local id, order = "buff" .. i, i * 10
        for k, v in pairs(Cues:SoundRow(row, "drop", name, order, id)) do args[k] = v end
        args[id .. "Repeat"] = Cues:FitDropdown({
            type = "select", name = L["Repeat"], order = order + 4,
            desc = L["Play the sound once, or again this often until the buff is back."],
            values = REPEAT_NAMES,
            sorting = REPEATS,
            disabled = function() return not row().dropEnabled end,
            get = function() return row().repeatSec end,
            set = function(_, v) row().repeatSec = v end,
        }, function() return REPEAT_TEXTS end)
    end
end
