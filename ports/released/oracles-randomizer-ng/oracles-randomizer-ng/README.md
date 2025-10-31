# LOZ: Oracles Randomizer NG

This is a linux aarch64 build of Stewmath's [Oracles Randomizer NG](https://github.com/Stewmath/oracles-randomizer-ng). It will run on-device, no external ROM generation is necessary.

## Sourcing ROMs

To use the randomizer, you need clean ROM files—these are untrimmed, unmodified ROMs, roughly `2,048 KB` in size. If you can't source your own, you can build them from the [Oracles Disassembly](https://github.com/Stewmath/oracles-disasm).

If you already have clean ROM files stored in your `roms/gbc` folder, you’re ready to go.

The randomizer looks for `ages.gbc` and `seasons.gbc` in the `oracles-randomizer-ng/randomizer` folder. If it doesn’t find them there, it will automatically search your `roms/gbc` folder and copy the ROMs into the randomizer folder for you.

## Using the randomizer

If ROMs are present, a Love2D frontend will launch where you can select your randomizer options. You can toggle the following options:

- Which game to randomize (Ages/Seasons)
- Cross-Items (Ages items appear in Seasons and vice versa)
- Keysanity (Dungeon keys, compasses, maps, slates etc are shuffled)
- Dungeon Shuffle (Shuffles dungeon entrances)
- Portal Shuffle (Shuffles Subrosian portals, Seasons only)
- Hard Logic (see [documentation](https://github.com/Stewmath/oracles-randomizer-ng/tree/ng-1.0.1/doc))
- Music Shuffle (off, on, all)

Once you confirm your options, the frontend will generate an `options.ini` file. This is then parsed by the launchscript to construct arguments for the randomizer.

## Output

The default output is `roms/gbc/randomized-<game>.gbc`. You can modify the filename and output location by editing the environment variable in the launchscript.

For example, you could modify the output to be `roms/gbch/Legend of Zelda, The - Oracle of <game>.gbc`.

Output will overwrite existing files! Be careful!