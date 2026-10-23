-------------------------------------------------------------------------------
--  Cues/Core.lua
--  AceAddon core: AceDB profiles (one per class by default), the /cue config
--  dialog, and Cues:Play(name) for any module (or other addon) to call.
--  Modules add their own options group via GetOptions(); nothing here needs
--  to change when a new cue module is added.
-------------------------------------------------------------------------------
local ADDON, ns = ...
local Cues = LibStub("AceAddon-3.0"):NewAddon("Cues", "AceConsole-3.0", "AceEvent-3.0")
_G.Cues = Cues
ns.addon = Cues

local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions    = LibStub("AceDBOptions-3.0")
local LSM             = ns.LSM
local L               = LibStub("AceLocale-3.0"):GetLocale(ADDON)

Cues.CHANNELS = { Master = L["Master"], SFX = L["Sound"], Music = L["Music"], Ambience = L["Ambience"], Dialog = L["Dialog"] }

local defaults = {
    profile = {
        channel = "Master",
        minimap = { hide = false }, -- LibDBIcon position/visibility
        modules = {}, -- per-module settings live under modules[<name>]
    },
}

Cues.ICON = "Interface\\Icons\\INV_Misc_Bell_01"

-- Modules register their defaults here before OnInitialize runs (file load order).
function Cues:RegisterModuleDefaults(name, tbl)
    defaults.profile.modules[name] = tbl
end

function Cues:OnInitialize()
    -- Default profile = class token (DRUID, WARRIOR, ...): every class gets its
    -- own settings automatically; the Profiles tab still allows copy/switch.
    local _, classToken = UnitClass("player")
    self.db = LibStub("AceDB-3.0"):New("CuesDB", defaults, classToken or true)
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileRefresh")
    self.db.RegisterCallback(self, "OnProfileCopied",  "OnProfileRefresh")
    self.db.RegisterCallback(self, "OnProfileReset",   "OnProfileRefresh")

    ns.RegisterOwnSounds()
    ns.RegisterEllesmereSounds()

    AceConfig:RegisterOptionsTable("Cues", function() return self:BuildOptions() end)
    AceConfigDialog:SetDefaultSize("Cues", 620, 520)
    AceConfigDialog:AddToBlizOptions("Cues", L["Cues"]) -- Settings > AddOns
    self:RegisterChatCommand("cue", "ChatCommand")
    self:RegisterChatCommand("cues", "ChatCommand")

    self:SetupMinimapIcon()
end

function Cues:OnProfileRefresh()
    for _, mod in self:IterateModules() do
        if mod.OnProfileRefresh then mod:OnProfileRefresh() end
    end
    local DBIcon = LibStub("LibDBIcon-1.0", true)
    if DBIcon then DBIcon:Refresh("Cues", self.db.profile.minimap) end
    self:UpdateMinimapIcon()
end

-------------------------------------------------------------------------------
--  Minimap icon (LibDataBroker + LibDBIcon)
--  Left-click: open /cue. Right-click: toggle the Range cue on/off.
--  Icon is desaturated while the Range cue is off.
-------------------------------------------------------------------------------
function Cues:SetupMinimapIcon()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local DBIcon = LibStub("LibDBIcon-1.0", true)
    if not (LDB and DBIcon) then return end

    self.ldb = LDB:NewDataObject("Cues", {
        type = "launcher",
        text = L["Cues"],
        icon = self.ICON,
        OnClick = function(_, button)
            if button == "RightButton" then
                local range = self:GetModule("Range", true)
                if range then
                    local d = self:ModuleDB("Range")
                    d.enabled = not d.enabled
                    if d.enabled then range:Enable() else range:Disable() end
                    self:UpdateMinimapIcon()
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Cues")
                end
            else
                if AceConfigDialog.OpenFrames["Cues"] then
                    AceConfigDialog:Close("Cues")
                else
                    AceConfigDialog:Open("Cues")
                end
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine(L["Cues"])
            local range = self:GetModule("Range", true)
            if range then
                local on = range:IsEnabled()
                tt:AddDoubleLine(L["Range cue"], on and "|cff00ff00" .. L["On"] .. "|r" or "|cffff4040" .. L["Off"] .. "|r")
                if on and _G.EllesmereUI and EllesmereUI.Range_GetAttackCutoff then
                    tt:AddDoubleLine(L["Attack range"], L["%d yd"]:format(EllesmereUI.Range_GetAttackCutoff()))
                end
            end
            tt:AddLine(" ")
            tt:AddLine(L["%s to open settings"]:format("|cffeda55f" .. L["Left-click"] .. "|r"), 0.8, 0.8, 0.8)
            tt:AddLine(L["%s to toggle the Range cue"]:format("|cffeda55f" .. L["Right-click"] .. "|r"), 0.8, 0.8, 0.8)
        end,
    })
    DBIcon:Register("Cues", self.ldb, self.db.profile.minimap)
    self:UpdateMinimapIcon()
end

function Cues:UpdateMinimapIcon()
    local DBIcon = LibStub("LibDBIcon-1.0", true)
    local button = DBIcon and DBIcon:GetMinimapButton("Cues")
    if not (button and button.icon) then return end
    local range = self:GetModule("Range", true)
    button.icon:SetDesaturated(not (range and range:IsEnabled()))
end

-- Per-module settings table for the active profile.
function Cues:ModuleDB(name)
    return self.db.profile.modules[name]
end

-------------------------------------------------------------------------------
--  Sound playback
-------------------------------------------------------------------------------
-- Play a LibSharedMedia sound by name. "None"/nil is silent. Returns true if
-- something was played.
function Cues:Play(name, channel)
    if not name or name == "None" then return false end
    local path = LSM:Fetch("sound", name, true)
    if not path or path == 1 then return false end
    channel = channel or self.db.profile.channel or "Master"
    PlaySoundFile(path, channel)
    return true
end

-------------------------------------------------------------------------------
--  Options
-------------------------------------------------------------------------------
function Cues:BuildOptions()
    if self._options then return self._options end
    local opts = {
        type = "group",
        name = L["Cues"],
        childGroups = "tab",
        args = {
            general = {
                type = "group", name = L["General"], order = 1,
                args = {
                    channel = {
                        type = "select", name = L["Sound channel"], order = 1,
                        desc = L["Which volume slider the cues follow."],
                        values = self.CHANNELS,
                        get = function() return self.db.profile.channel end,
                        set = function(_, v) self.db.profile.channel = v end,
                    },
                    minimap = {
                        type = "toggle", name = L["Show minimap icon"], order = 2,
                        get = function() return not self.db.profile.minimap.hide end,
                        set = function(_, v)
                            self.db.profile.minimap.hide = not v
                            local DBIcon = LibStub("LibDBIcon-1.0", true)
                            if DBIcon then
                                if v then DBIcon:Show("Cues") else DBIcon:Hide("Cues") end
                            end
                        end,
                    },
                    count = {
                        type = "description", order = 3, fontSize = "medium",
                        name = function()
                            return "\n" .. L["%d sounds available from LibSharedMedia."]:format(#ns.SoundList())
                        end,
                    },
                },
            },
        },
    }
    local order = 10
    for name, mod in self:IterateModules() do
        if mod.GetOptions then
            local g = mod:GetOptions()
            g.order = g.order or order
            order = order + 1
            opts.args[name] = g
        end
    end
    opts.args.profiles = AceDBOptions:GetOptionsTable(self.db)
    opts.args.profiles.order = 100
    self._options = opts
    return opts
end

function Cues:ChatCommand(input)
    input = input and input:trim() or ""
    if input == "" then
        AceConfigDialog:Open("Cues")
        return
    end
    local cmd, rest = input:match("^(%S+)%s*(.*)$")
    cmd = cmd:lower()
    if cmd == "play" and rest ~= "" then
        if not self:Play(rest) then self:Print(L["No LibSharedMedia sound named: "] .. rest) end
        return
    end
    if cmd == "list" then
        for _, n in ipairs(ns.SoundList()) do self:Print(n) end
        return
    end
    -- Anything else (e.g. "range enabled on"): let AceConfigCmd handle it.
    LibStub("AceConfigCmd-3.0"):HandleCommand("cue", "Cues", input)
end

-------------------------------------------------------------------------------
--  Shared option builders for modules: a sound row = on/off tick + dropdown
--  of every LibSharedMedia sound + a play button for the selected sound.
-------------------------------------------------------------------------------
-- db: function returning the module's profile table; key: field prefix
-- (e.g. "in" -> inEnabled / inSound); label: row label; order: base order.
function Cues:SoundRow(db, key, label, order)
    local enabledKey, soundKey = key .. "Enabled", key .. "Sound"
    return {
        [key .. "Header"] = {
            type = "header", name = label, order = order,
        },
        [enabledKey] = {
            type = "toggle", name = L["Enabled"], order = order + 1, width = 0.6,
            get = function() return db()[enabledKey] end,
            set = function(_, v) db()[enabledKey] = v end,
        },
        [soundKey] = {
            type = "select", name = L["Sound"], order = order + 2, width = 1.8,
            style = "dropdown",
            values = function() return ns.SoundValues() end,
            sorting = function() return ns.SoundList() end,
            disabled = function() return not db()[enabledKey] end,
            get = function() return db()[soundKey] end,
            set = function(_, v) db()[soundKey] = v end,
        },
        [key .. "Play"] = {
            type = "execute", name = L["Play"], order = order + 3, width = 0.5,
            desc = L["Play the selected sound."],
            disabled = function() return not db()[enabledKey] end,
            func = function() self:Play(db()[soundKey]) end,
        },
    }
end
