-------------------------------------------------------------------------------
--  Cues/Locales/enUS.lua
--  English strings. Every user-facing string lives here; files read L["..."].
--  Sound names ("Cues: Bell", "EllesmereUI: Sonar") are not here: they are
--  LibSharedMedia keys saved in profiles, so they never change with the locale.
-------------------------------------------------------------------------------
local L = LibStub("AceLocale-3.0"):NewLocale("Cues", "enUS", true)
if not L then return end

L["Cues"] = true

-- Sound channels (the dropdown's names; the keys are the game's channel names)
L["Master"] = true
L["Sound"] = true
L["Music"] = true
L["Ambience"] = true
L["Dialog"] = true

-- Minimap icon tooltip
L["Range cue"] = true
L["On"] = true
L["Off"] = true
L["Attack range"] = true
L["%d yd"] = true
L["Left-click"] = true
L["Right-click"] = true
L["%s to open settings"] = true
L["%s to toggle the Range cue"] = true

-- General options
L["General"] = true
L["Sound channel"] = true
L["Which volume slider the cues follow."] = true
L["Show minimap icon"] = true
L["%d sounds available from LibSharedMedia."] = true

-- Chat
L["No LibSharedMedia sound named: "] = true
L["Range cue disabled: EllesmereUI's range engine is not loaded."] = true
L["No buff reminders: Forever Enhanced Cooldown Manager's buff list was not found."] = true
L["No buff reminders: Forever Enhanced Cooldown Manager has no buffs listed for this character."] = true

-- A sound row
L["Enabled"] = true
L["Play the selected sound."] = true

-- Range
L["Range check sound"] = true
L["Enable range check sound"] = true
L["Play a cue when your target enters or leaves your attack range. Range is read from EllesmereUI's range engine (caster Druid: Wrath/Moonfire range; Bear/Cat: melee)."] = true
L["In combat only"] = true
L["Stay silent unless you are in combat."] = true
L["Melee range too"] = true
L["Also cue at melee (5 yd) range: melee classes, Bear and Cat Form. Off by default because targets shuffle in and out of melee constantly."] = true
L["Cooldown (seconds)"] = true
L["Minimum time between cues, so standing on the range line does not spam."] = true
L["In range"] = true
L["Out of range"] = true

-- Combat
L["Combat sound"] = true
L["Enable combat sound"] = true
L["Play a cue when you enter combat, and optionally another when combat ends."] = true
L["Entering combat"] = true
L["Leaving combat"] = true

-- Buffs
L["Buff reminders"] = true
L["Enable buff reminders"] = true
L["Play a cue while a buff on your Forever Enhanced Cooldown Manager buff list is missing. Silent while you are dead, on a flight path, mounted, resting, away or in a fight."] = true
L["Forever Enhanced Cooldown Manager's buff list was not found."] = true
L["Forever Enhanced Cooldown Manager has no buffs listed for this character."] = true
L["Repeat"] = true
L["Play the sound once, or again this often until the buff is back."] = true
L["Once"] = true
L["30 seconds"] = true
L["1 minute"] = true
L["2 minutes"] = true
L["5 minutes"] = true
