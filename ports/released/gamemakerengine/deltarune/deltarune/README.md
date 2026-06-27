## Installation
This port works with the following data:

- [LTS DELTARUNE Chapter 1&2 PC Version](https://tobyfox.itch.io/deltarune) on Itch.io/deltarune
- [Deltarune Demo](https://store.steampowered.com/app/1671210/DELTARUNE/) on Steam by switching to the LTS beta branch
- [Deltarune](https://store.steampowered.com/app/1671210/DELTARUNE/) on Steam by purchasing the game

Add all files to `ports/deltarune/assets/install`.

## Console Borders
If you are using a widescreen device you may be interested in the [console borders mod](https://gamejolt.com/games/nxrune/629072) which enables the console borders present in the Switch and PS4/PS5 versions of the game. Apply the xdelta patches as the mod's readme states and then copy your data to the assets folder, or just add the zip file to `deltarune/assets/install` with the rest of your game data.

## Runtimes

This port requires the following:

- [gmloadernext.squashfs](https://github.com/JeodC/RHH-Ports/raw/main/runtimes/gmloadernext.squashfs) placed in the `PortMaster/libs/` folder.
- [gmtoolkit](https://github.com/JeodC/gmtoolkit/releases) placed in the `PortMaster/` folder.

[Pharos](https://github.com/JeodC/RHH-Ports/releases/download/ports-latest/pharos.zip) will fetch these automatically when installing the port. Otherwise download them manually and add them to the correct folders.

## Thanks
TobyFox -- The absolutely amazing game  
JohnnyOnFlame -- GMLoader and TextureRepacker via UTMT  
Cyril aka kotzebuedog -- GMTools audio patcher  
BinaryCounter -- Video playback for gmloadernext  
Testers & Devs from the PortMaster Discord