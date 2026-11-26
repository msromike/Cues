-- Cues' own sounds (Cues\media\). Registered into LibSharedMedia as
-- "Cues: <name>" by Media.lua, so they show in every LSM sound picker.
-- Sources: Prat-3.0 3.9.109 sounds folder, GPL-3.0 (license text beside the
-- files); NovaWorldBuffs 3.25 Media folder; one of unrecorded origin. Each
-- file's source is in media\SOUNDS.md. Adding a file here means dropping
-- it in media\ and adding a row; the client must be fully restarted to see
-- new files.
local _, ns = ...
ns.OWN_SOUNDS = {
    { name = "Bell",       file = "Bell.ogg" },
    { name = "Bell Chime", file = "BellChime.ogg" },
    { name = "Chime",      file = "Chime.ogg" },
    { name = "Dink",       file = "Dink.ogg" },
    { name = "Dink 2",     file = "Dink2.ogg" },
    { name = "Electronic", file = "Electronic.ogg" },
    { name = "Heart",      file = "Heart.ogg" },
    { name = "IM",         file = "IM.ogg" },
    { name = "Info",       file = "Info.ogg" },
    { name = "Kachink",    file = "Kachink.ogg" },
    { name = "Link",       file = "Link.ogg" },
    { name = "MGS",        file = "MGS.ogg" },
    { name = "Pop",        file = "Pop.ogg" },
    { name = "Pop 2",      file = "Pop2.ogg" },
    { name = "Text 1",     file = "Text1.ogg" },
    { name = "Text 2",     file = "Text2.ogg" },
    { name = "WT",         file = "WT.ogg" },
    { name = "Xylo",       file = "Xylo.ogg" },
}
