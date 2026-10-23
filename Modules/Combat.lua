-------------------------------------------------------------------------------
--  Cues/Modules/Combat.lua
--  "Combat sound": plays a cue when the player enters combat
--  (PLAYER_REGEN_DISABLED) and, optionally, when combat ends
--  (PLAYER_REGEN_ENABLED). No cooldown needed: each event fires once per
--  combat transition.
-------------------------------------------------------------------------------
local ADDON, ns = ...
local Cues = ns.addon
local Combat = Cues:NewModule("Combat", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON)

local MODULE = "Combat"
Cues:RegisterModuleDefaults(MODULE, {
    enabled      = true,
    enterEnabled = true,
    enterSound   = ns.EUI_PREFIX .. "Warning Siren",
    leaveEnabled = false,
    leaveSound   = ns.EUI_PREFIX .. "Kaching",
})

local function db() return Cues:ModuleDB(MODULE) end

function Combat:OnInitialize()
    self:SetEnabledState(db().enabled)
end

function Combat:OnEnable()
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEnterCombat")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnLeaveCombat")
end

function Combat:OnDisable()
    self:UnregisterAllEvents()
end

function Combat:OnProfileRefresh()
    if db().enabled then
        if self:IsEnabled() then self:Disable() end
        self:Enable()
    else
        self:Disable()
    end
end

function Combat:OnEnterCombat()
    local d = db()
    if d.enterEnabled then Cues:Play(d.enterSound) end
end

function Combat:OnLeaveCombat()
    local d = db()
    if d.leaveEnabled then Cues:Play(d.leaveSound) end
end

function Combat:GetOptions()
    local args = {
        enabled = {
            type = "toggle", name = L["Enable combat sound"], order = 1, width = "full",
            desc = L["Play a cue when you enter combat, and optionally another when combat ends."],
            get = function() return db().enabled end,
            set = function(_, v)
                db().enabled = v
                if v then self:Enable() else self:Disable() end
            end,
        },
    }
    for k, v in pairs(Cues:SoundRow(db, "enter", L["Entering combat"], 10)) do args[k] = v end
    for k, v in pairs(Cues:SoundRow(db, "leave", L["Leaving combat"], 20)) do args[k] = v end
    return {
        type = "group",
        name = L["Combat sound"],
        args = args,
    }
end
