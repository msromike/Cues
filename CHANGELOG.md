# Changelog

## 1.0.0 (2026-10-23)

First public version. WoW Forever only; requires EllesmereUI.

- Range check sound: a cue when your target enters or leaves your attack range, read from
  EllesmereUI's range engine. Separate sounds for in range and out of range, an in combat
  only switch, an optional melee range cue, and a cooldown so standing on the line does
  not spam.
- Combat sound: a cue when you enter combat, and optionally another when it ends.
- Every LibSharedMedia sound to pick from, plus EllesmereUI's alert sounds and ten of
  Cues' own. Each sound has a Play button to hear it first. The cues follow the sound
  channel you pick.
- Settings in `/cue` and in Settings > AddOns, one profile per class by default.
- A minimap button: left-click opens the settings, right-click turns the Range cue on or
  off. Its tooltip shows whether the Range cue is on and your current attack range.
