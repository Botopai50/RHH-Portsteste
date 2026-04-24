## Installation

This port accepts data from either **Sonic Origins** (recommended) or the
**mobile Sonic CD** Android APK. Drop the appropriate files into
`ports/sonic.cd/` and launch — the port patcher handles the rest on first run.

### Origins data (recommended)

Copy these files from your Sonic Origins install (`image/x64/raw/` path
shown for the Steam version):

| File | Source |
|--|--|
| `SonicCDu.rsdk` | `image/x64/raw/retro/SonicCDu.rsdk` |
| `SCD_music.acb` | `image/x64/raw/sound/SCD_music.acb` |
| `SCD_music.awb` | `image/x64/raw/sound/SCD_music.awb` |
| `SCD_sfx.acb` | `image/x64/raw/sound/SCD_sfx.acb` |
| `HITE_sfx.acb` | `image/x64/raw/sound/HITE_sfx.acb` |

On first launch the patcher will extract the RSDK container, transcode the Origins CRIWARE audio to `.wav` / `.ogg`, place the dual JP/US music tracks under `Data/Music/JP/` and `Data/Music/US/`, flip settings.ini into Origins mode, and delete the source files.

### Filling the Amy audio gaps (Ultrafix)

Vanilla Origins declares cue names for three Plus-mode Amy SFX (`OuttaHere`, `Giggle`, `AmyCaptured`) but ships no audio data for them — Amy's voice clips are silent in stock Origins. The [Sonic Origins Ultrafix](https://www.sonichacking.org/entries/contest2024/981) mod's replacement `SCD_sfx.acb` fills these in.

To use it: install Ultrafix on PC, then instead of copying `SCD_sfx.acb` from the Origins install path, copy it from `<Ultrafix install>/raw/sound/SCD_sfx.acb` into
`ports/sonic.cd/`. Our patcher handles it the same way — just with the three extra cues now producing audio.

Ultrafix also provides alternate music packs (Hardware-style Genesis emulation, or remastered) at:
- `<Ultrafix>/ModConfig/SCDOST/Mobile/raw/sound/SCD_music.awb`
- `<Ultrafix>/ModConfig/SCDOST/Remastered/raw/sound/SCD_music.awb`

Drop-in compatible. Pick whichever you prefer for your `SCD_music.awb` input.

### Mobile Data.rsdk (legacy)

Drop a mobile-format `Data.rsdk` (from the Android APK) into `ports/sonic.cd/` and launch. The engine loads it directly — no patching runs.

Guidance for extracting `Data.rsdk` from a legal source is [here](https://github.com/RSDKModding/RSDKv3-Decompilation).

## Default Controls
| Button | Action |
|--|--|
| START | Pause / Accept |
| SELECT | Dev menu |
| D-PAD | Move |
| LEFT ANALOG | Move |
| ABXY | Jump |
| DOWN + ABXY | Spindash |

## Using mods

Open the dev menu by pressing SELECT to toggle mods or access stage select. Drop additional mods into the `mods/` folder.

Recommendations:
- [MegAmi's Additions](https://gamebanana.com/mods/50093)
- [Sonic CD Miracle Edition](https://gamebanana.com/mods/467930) & [SCD Origins Fix](https://gamebanana.com/mods/download/467930#FileInfo_1220798)

## Rebuilding

See [BUILDING.md](BUILDING.md) if you want to rebuild RSDKv3 with
Plus-mode characters unlocked (Amy and Knuckles).

## Thanks

- christianhaitan — the original port
- [Rubberduckycooly](https://github.com/Rubberduckycooly/RSDKv3-Decompilation) for the decompilation work that makes this possible
- Team Ultrafix — restoration mod that fills the Amy audio gap
- Testers and Devs from the PortMaster Discord
