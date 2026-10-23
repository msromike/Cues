-- Cues' own sounds (Cues\media\). Registered into LibSharedMedia as
-- "Cues: <name>" by Media.lua, so they show in every LSM sound picker.
-- Source: Prat-3.0 3.9.109 sounds folder, GPL-3.0 (media\SOUNDS.md, with the
-- license text beside it). Adding a file here means dropping
-- it in media\ and adding a row; the client must be fully restarted to see
-- new files.
local _, ns = ...
ns.OWN_SOUNDS = {
    { name = "Bell",    file = "Bell.ogg" },
    { name = "Chime",   file = "Chime.ogg" },
    { name = "Heart",   file = "Heart.ogg" },
    { name = "IM",      file = "IM.ogg" },
    { name = "Info",    file = "Info.ogg" },
    { name = "Kachink", file = "Kachink.ogg" },
    { name = "Link",    file = "Link.ogg" },
    { name = "Text 1",  file = "Text1.ogg" },
    { name = "Text 2",  file = "Text2.ogg" },
    { name = "Xylo",    file = "Xylo.ogg" },
}
