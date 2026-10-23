-------------------------------------------------------------------------------
--  Cues/Modules/Range.lua
--  "Range check sound": plays a cue when the current target crosses the
--  player's attack range. Range comes from EllesmereUI's shared range engine
--  (EllesmereUI_Range.lua), so nothing here duplicates spell/item range logic
--  and the QoL crosshair can be off.
-------------------------------------------------------------------------------
local ADDON, ns = ...
local Cues = ns.addon
local Range = Cues:NewModule("Range", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON)

local MODULE = "Range"
Cues:RegisterModuleDefaults(MODULE, {
    enabled    = true,
    inEnabled  = true,
    inSound    = ns.EUI_PREFIX .. "Sonar",
    outEnabled = true,
    outSound   = ns.EUI_PREFIX .. "Robot Blip",
    combatOnly = false,
    meleeToo   = false,
    interval   = 0.2,
    cooldown   = 0.5,
})

local function db() return Cues:ModuleDB(MODULE) end

-- nil = unknown / no valid target (first reading after this is silent)
local state = nil
local lastPlay = 0

local function EngineAvailable()
    local E = _G.EllesmereUI
    return E and E.Range_SetActive and E.Range_GetAttackCutoff and E.Range_IsBeyondAttackRange
end

function Range:OnInitialize()
    self:SetEnabledState(db().enabled)
end

function Range:OnEnable()
    if not EngineAvailable() then
        Cues:Print(L["Range cue disabled: EllesmereUI's range engine is not loaded."])
        self:Disable()
        return
    end
    EllesmereUI.Range_SetActive("Cues", true)
    state = nil
    self.timer = self:ScheduleRepeatingTimer("Tick", db().interval or 0.2)
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "ResetState")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "ResetState")
    if Cues.UpdateMinimapIcon then Cues:UpdateMinimapIcon() end
end

function Range:OnDisable()
    if self.timer then self:CancelTimer(self.timer); self.timer = nil end
    self:UnregisterAllEvents()
    if _G.EllesmereUI and EllesmereUI.Range_SetActive then
        EllesmereUI.Range_SetActive("Cues", false)
    end
    state = nil
    if Cues.UpdateMinimapIcon then Cues:UpdateMinimapIcon() end
end

function Range:OnProfileRefresh()
    if db().enabled then
        if self:IsEnabled() then self:Disable() end
        self:Enable()
    else
        self:Disable()
    end
end

function Range:ResetState()
    state = nil
end

function Range:Tick()
    if not (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")) then
        state = nil
        return
    end
    local cutoff = EllesmereUI.Range_GetAttackCutoff()
    local d = db()
    if cutoff <= 5 and not d.meleeToo then
        state = nil
        return
    end
    local beyond = EllesmereUI.Range_IsBeyondAttackRange("target", cutoff)
    if beyond == nil then return end -- no probe answered; keep last state

    if state == nil then
        state = beyond -- first reading after target change / zoning: silent
        return
    end
    if beyond == state then return end
    state = beyond

    if d.combatOnly and not InCombatLockdown() then return end
    local now = GetTime()
    if now - lastPlay < (d.cooldown or 0) then return end

    if beyond then
        if d.outEnabled then Cues:Play(d.outSound); lastPlay = now end
    else
        if d.inEnabled then Cues:Play(d.inSound); lastPlay = now end
    end
end

function Range:GetOptions()
    local args = {
        enabled = {
            type = "toggle", name = L["Enable range check sound"], order = 1, width = "full",
            desc = L["Play a cue when your target enters or leaves your attack range. Range is read from EllesmereUI's range engine (caster Druid: Wrath/Moonfire range; Bear/Cat: melee)."],
            get = function() return db().enabled end,
            set = function(_, v)
                db().enabled = v
                if v then self:Enable() else self:Disable() end
            end,
        },
        combatOnly = {
            type = "toggle", name = L["In combat only"], order = 2,
            desc = L["Stay silent unless you are in combat."],
            get = function() return db().combatOnly end,
            set = function(_, v) db().combatOnly = v end,
        },
        meleeToo = {
            type = "toggle", name = L["Melee range too"], order = 3,
            desc = L["Also cue at melee (5 yd) range: melee classes, Bear and Cat Form. Off by default because targets shuffle in and out of melee constantly."],
            get = function() return db().meleeToo end,
            set = function(_, v) db().meleeToo = v end,
        },
        cooldown = {
            type = "range", name = L["Cooldown (seconds)"], order = 4, width = "double",
            desc = L["Minimum time between cues, so standing on the range line does not spam."],
            min = 0, max = 5, step = 0.1,
            get = function() return db().cooldown end,
            set = function(_, v) db().cooldown = v end,
        },
    }
    for k, v in pairs(Cues:SoundRow(db, "in", L["In range"], 10)) do args[k] = v end
    for k, v in pairs(Cues:SoundRow(db, "out", L["Out of range"], 20)) do args[k] = v end
    return {
        type = "group",
        name = L["Range check sound"],
        args = args,
    }
end
