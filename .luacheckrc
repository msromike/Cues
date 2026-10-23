-- luacheck configuration for Cues (WoW Forever runs Lua 5.1).
-- Run from the addon root: luacheck .   (the GitHub workflow does this on every push)
-- Every name in read_globals is a real WoW API or FrameXML global that Cues calls,
-- harvested from a run with no whitelist on 2026-10-23. Add a name only when the game has it.

std = "lua51"
max_line_length = false
self = false -- a method written with ':' may leave self unused
codes = true

exclude_files = { "Libs/**", ".github/**" }

read_globals = {
    -- libraries and the addon Cues reads range and sounds from
    "LibStub", "EllesmereUI",
    -- functions
    "UnitClass", "UnitExists", "UnitCanAttack", "UnitIsDead",
    "InCombatLockdown", "GetTime", "PlaySoundFile",
}
