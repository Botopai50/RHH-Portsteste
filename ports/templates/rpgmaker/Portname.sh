#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
GAMEDIR="/$directory/ports/portfolder"
MKXPZ_RUNTIME="$controlfolder/libs/mkxp-z.squashfs"
MKXPZ="$HOME/mkxp-z"

# CD and set logging
cd "$GAMEDIR" || exit 1
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Mount the mkxp-z runtime
if [ -f "$MKXPZ_RUNTIME" ]; then
    $ESUDO mkdir -p "$MKXPZ"
    $ESUDO umount "$MKXPZ" 2>/dev/null || true
    $ESUDO mount "$MKXPZ_RUNTIME" "$MKXPZ"
else
    pm_message "mkxp-z runtime missing. Install it via PortMaster."
    sleep 5
    pm_finish
    exit 1
fi

# Make config dir for saves
mkdir -p "$GAMEDIR/config"

# stdlib lives inside the runtime. Drop any pre-runtime extracted copy
# first so the bind mount lands cleanly, then bind into $GAMEDIR.
[ -e "$GAMEDIR/stdlib" ] && [ ! -L "$GAMEDIR/stdlib" ] && rm -rf "$GAMEDIR/stdlib"
bind_directories "$GAMEDIR/stdlib" "$MKXPZ/stdlib"

# Exports — LD_LIBRARY_PATH deferred until just before mkxp-z runs.
# Backgrounded gptokeyb inherits its env at fork time, and runtime libs
# in its LD path confuse gptokeyb's dependency chain.
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export XDG_DATA_HOME="$GAMEDIR/config"
export LC_ALL=C
export LANG=C

# Optional: sanity-check that game data was copied in (adjust file to game's marker)
# if [ ! -f "$GAMEDIR/Game.rgssad" ] && [ ! -f "$GAMEDIR/Game.ini" ]; then
#     pm_message "Game data missing. Copy your install into $GAMEDIR."
#     sleep 5
#     $ESUDO umount "$GAMEDIR/stdlib" 2>/dev/null || true
#     $ESUDO umount "$MKXPZ" 2>/dev/null || true
#     pm_finish
#     exit 1
# fi

# Optional: strip Windows-only artifacts copied from a Steam install
# rm -f "$GAMEDIR"/*.exe "$GAMEDIR"/*.dll "$GAMEDIR/mkxp.conf"

# Optional: restore handheld-tuned mkxp.json (ship one as $GAMEDIR/mkxp/mkxp.json)
# if [ -d "$GAMEDIR/mkxp" ]; then
#     rm -f "$GAMEDIR/mkxp.json"
#     mv "$GAMEDIR/mkxp/mkxp.json" "$GAMEDIR/mkxp.json"
#     rmdir "$GAMEDIR/mkxp" 2>/dev/null || true
# fi

# Optional: force onscreen keyboard via sed patch on RPG Maker XP script files
# TE_FILE="$GAMEDIR/path/to/TextEntry.rb"
# [ -f "$TE_FILE" ] && sed -i 's/^\(\s*USEKEYBOARD\s*=\s*\).*/\1false/' "$TE_FILE"

# Gptk — launched with stock LD path so its hotkey/kill logic isn't
# broken by our runtime libs
$GPTOKEYB "mkxp-z.aarch64" -c "$GAMEDIR/game.gptk" &

# Now wire the runtime libs in for mkxp-z and run it
export LD_LIBRARY_PATH="$MKXPZ/libs:$LD_LIBRARY_PATH"
export SRCDIR="$GAMEDIR"
pm_platform_helper "$MKXPZ/mkxp-z.aarch64" >/dev/null
"$MKXPZ/mkxp-z.aarch64"

# Cleanup — unmount bind first, then the runtime
$ESUDO umount "$GAMEDIR/stdlib" 2>/dev/null || true
$ESUDO umount "$MKXPZ" 2>/dev/null || true
pm_finish
