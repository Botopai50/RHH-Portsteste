## Installation
Buy the game and copy all data to `grappledog/assets`.

## Patching on a PC (optional, faster)
Patching on a weak device can take up to an hour. You can instead do the heavy work on a PC (5-10 minutes), copy the result over, and the launcher finishes in seconds.

**Windows:**

1. Make an empty working folder. Inside it, create an `assets` subfolder and copy your whole Grapple Dog install into it (from Steam, e.g. `Z:\SteamLibrary\steamapps\common\Grapple Dog`), so you have `assets/data.win`.
2. Download the tool and this port's config into the working folder, next to `assets`:
   ```bash
   curl -L -o gmtoolkit.exe https://github.com/JeodC/gmtoolkit/releases/latest/download/gmtoolkit.exe
   curl -L -o grappledog.json https://github.com/JeodC/RHH-Ports/raw/main/ports/released/gamemakerengine/grappledog/grappledog/tools/grappledog.json
   ```
3. Run gmtoolkit, picking the texture preset for your screen size:
   ```bash
   gmtoolkit.exe --config grappledog.json --block 5x5 --quality fast assets/data.win
   ```
   | Screen | preset |
   |--|--|
   | up to 640x480 | `--block 6x6 --quality fastest` |
   | up to ~720p (1024x768, 1280x720) | `--block 5x5 --quality fast` |
   | larger | omit both flags (defaults to `4x4` / `medium`) |

   Bigger blocks use less RAM at runtime; smaller blocks look sharper.
4. gmtoolkit patches `assets/data.win` in place and writes the textures to a new `saves/textures` folder beside `assets` — the same layout the device uses, so nothing needs rearranging.
5. Copy both folders into the port directory on the device, keeping that layout: the contents of `assets` → `grappledog/assets/`, and the `saves/textures` folder → `grappledog/saves/`.
6. Launch the port. It detects the PC-patched `data.win`, keeps your textures, and skips the slow on-device transcode.

**Linux / macOS:** build `gmtoolkit` from source ([build instructions](https://github.com/JeodC/gmtoolkit/blob/main/BUILDING.md)), then run the same `--config grappledog.json … assets/data.win` command.

## Notes
Grapple Dog is a heavy game with both cpu and memory. Patching aims to remove the memory bottlenecks, and the launchscript `Grapple Dog.sh` has a tweakable cpu cap. This port was tested on the following devices:

- AYN Thor (full speed)
- RG353V (some slowdowns)
- TrimUI Smart Pro (some slowdowns)

In all cases the first few levels were completable.

## Thanks
Medallion Games -- The amazing game.  
JohnnyOnFlame -- GMLoader-Next, FMOD compatibility, and [UTMT-CLI fork](https://github.com/JohnnyonFlame/UTMT-PortMaster).  
Jeod -- GMLoader-Next improvements and Game Port.  
UnderminersTeam -- For the original [UTMT-CLI utility](https://github.com/UnderminersTeam/UndertaleModTool).  
