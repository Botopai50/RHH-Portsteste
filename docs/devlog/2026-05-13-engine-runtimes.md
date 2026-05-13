47 GameMaker ports and 6 RPG Maker ports moved off per-port bundled engines this week and onto shared squashfs runtimes — the same mount mechanism Solarus and RLVM ports have been using for ages. Nothing I invented; I'm leveraging what's already in the PortMaster framework.

GMLoader-Next is a 2.7 MB squashfs; MKXP-Z is 11.5 MB. Each one lives in one place now instead of being mirrored into every port zip — a few hundred megabytes of duplicate binaries that users were redownloading every time they grabbed one of mine.

The GameMaker side was mostly mechanical: gmloadernext got packaged as a squashfs runtime ([7a1bc15](https://github.com/JeodC/RHH-Ports/commit/7a1bc15)), 47 launchers got their `LD_LIBRARY_PATH` repointed at the mounted runtime ([0b9aa2e](https://github.com/JeodC/RHH-Ports/commit/0b9aa2e), [aeee599](https://github.com/JeodC/RHH-Ports/commit/aeee599)).

The RPG Maker drop is the more interesting one, because two of those six (**Pokemon Reborn** and **Pokemon Rejuvenation**) already have ports in PortMaster's catalog. Why a second copy? Because I tune mine for a specific case that's harder to satisfy with one-size-fits-all defaults — the very-low-resolution, no-keyboard handheld:

- A handheld-tuned `mkxp.json` (display scaling, savedata path, audio buffering)
- Default screen size flipped from M (1×) to Full (4×)
- `USEKEYBOARD = false` patched into the `.rb` scripts so name entry uses MKXP-Z's on-screen character grid instead of trying to read a keyboard you don't have
- For Tectonic specifically: auto-unzip of the data zip, plus sed patches that work around a couple of upstream crashes (resize-on-screen-size-change, the Controls menu) I hit running MKXP-Z fullscreen

These tweaks happen at first launch rather than being baked into the zip. If you're already happy with the PortMaster version, no reason to switch; if you specifically want the low-res-handheld defaults I've been iterating on, mine are there as an option alongside.

All the per-port sed patches are codified in the [rpgmaker template](https://github.com/JeodC/RHH-Ports/blob/main/ports/templates/rpgmaker/Portname.sh) so future RPG Maker ports inherit them.
