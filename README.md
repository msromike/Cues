# Cues

[![lint](https://github.com/msromike/Cues/actions/workflows/lint.yml/badge.svg)](https://github.com/msromike/Cues/actions/workflows/lint.yml)

Sound cues for game events: hear when your target walks into or out of your attack range, and when you enter or leave combat.

**[Download Cues](https://github.com/msromike/Cues/releases/latest/download/Cues.zip)** (latest release, ready to unzip into `Interface\AddOns`)

## Requires

- **WoW Forever.** Tested on Forever only. It may well work wherever EllesmereUI runs, but that's untested, so other clients list Cues as out of date.
- **EllesmereUI.** Tested on EllesmereUI 9.6.6. The range cue uses EllesmereUI's range engine, so the EllesmereUI crosshair doesn't need to be on.

## Install

1. **[Download Cues.zip](https://github.com/msromike/Cues/releases/latest/download/Cues.zip)**, the latest release. Older versions are on the [Releases](https://github.com/msromike/Cues/releases) page.
2. Unzip it into your Forever install's `Interface\AddOns` folder, so you end up with `AddOns\Cues\Cues.toc`.

Don't use the green **Code > Download ZIP** button: it names the folder `Cues-main`, and WoW won't load an addon under that name.

## The cues

- **Range check sound.** A sound when your target comes into your attack range, and another when it leaves. Options: in combat only, a cue at melee range too (off by default, because targets shuffle in and out of melee all the time), and a cooldown between cues.
- **Combat sound.** A sound when you enter combat, and optionally another when combat ends.

Each sound is picked from a list with a Play button beside it. The list has every LibSharedMedia sound your addons provide, EllesmereUI's alert sounds, and ten of Cues' own. The General tab picks which volume slider the cues follow: Master, Sound, Music, Ambience or Dialog.

## Using it

- **Settings.** `/cue` opens them, or Escape > Options > AddOns > Cues. Settings are saved per class by default; the Profiles tab copies or switches them.
- **The minimap button.** Left-click opens the settings, right-click turns the range cue on or off. The icon greys out while the range cue is off. Also available to broker display addons as "Cues".

## Commands

| Command | What it does |
|---|---|
| `/cue` | Opens the settings (`/cues` does as well) |
| `/cue play NAME` | Plays the sound called NAME |
| `/cue list` | Lists every sound name |

## What can break it

The range cue reads range from EllesmereUI's range engine instead of keeping its own spell and range lists. If an EllesmereUI update renames that engine, the range cue turns itself off and says "Range cue disabled: EllesmereUI's range engine is not loaded." until Cues is updated. The combat cue keeps working either way.

If it stops working after an EllesmereUI update, [open an issue](https://github.com/msromike/Cues/issues) and say which EllesmereUI version you're on. A PR is welcome too.

## License

MIT, see [LICENSE](LICENSE).

The ten sounds in `media/` come from Prat-3.0 and are GPL-3.0, see [media/SOUNDS.md](media/SOUNDS.md).

Bundles Ace3 (BSD-style), LibSharedMedia, LibDBIcon, LibDataBroker and LibStub. Each keeps its own license.
