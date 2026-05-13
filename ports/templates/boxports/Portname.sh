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
GAME="$GAMEDIR/data/GameBinary.x86_64"   # the user-provided Linux Steam binary
BOX64="$GAMEDIR/box64/box64"

# CD and set log
cd "$GAMEDIR/data"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Permissions
chmod +x "$BOX64"
chmod +x "$GAME"
chmod +x "$GAMEDIR/tools/splash"

# Pre-flight checks for X11 and OpenGL
if [ -z "$DISPLAY" ]; then
    echo "Error: Display manager not found. This game requires OpenGL and X11 to run."
    exit 1
fi

if ! command -v glxinfo >/dev/null 2>&1; then
    echo "Error: OpenGL not found. This game requires OpenGL and X11 to run."
    exit 1
fi

# Optional: spoof GL version on devices with old Mesa (< 3.3).
# Needed for Unity games that probe minimum GL version at startup.
# Uncomment if the game refuses to launch on lowres/older devices.
# version=$(glxinfo | grep -oP 'OpenGL version string: \K[0-9]+\.[0-9]+' | head -n 1)
# major=${version%%.*}
# minor=${version#*.}
# if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 3 ]; }; then
#     export MESA_GL_VERSION_OVERRIDE=3.3
#     export MESA_GLSL_VERSION_OVERRIDE=330
#     export MESA_NO_ASYNC_COMPILE=1
#     echo "[WARNING] Overriding GL version to run the game; may cause perf or visual issues."
# fi

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/box64/x64:$GAMEDIR/libs.aarch64:$GAMEDIR/data:$LD_LIBRARY_PATH"
export BOX64_LD_LIBRARY_PATH="$GAMEDIR/box64/x64:$GAMEDIR/data:$LD_LIBRARY_PATH"
export XDG_CONFIG_HOME="$GAMEDIR/config" && mkdir -p "$GAMEDIR/config"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export SDL_VIDEODRIVER="x11"

# Box64 dynarec tuning — see https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md
# Defaults below favor compatibility over raw speed. For Unity games, the
# Hollow Knight tuning (FASTROUND=0, CALLRET=2, BIGBLOCK=3, FORWARD=1024) is
# usually a safer starting point.
export BOX64_NOBANNER=1                # Hide Box64 startup banner (cleaner logs)
export BOX64_DYNAREC=1                 # Enable the JIT dynarec for x86_64 to ARM
export BOX64_DYNAREC_SAFEFLAGS=0       # Skip extra flag-preservation checks for speed
export BOX64_DYNAREC_FASTROUND=1       # Fast (non-IEEE) FP rounding — set to 0 if game misbehaves
export BOX64_DYNAREC_BIGBLOCK=1        # Merge more instructions per block
export BOX64_DYNAREC_CALLRET=1         # CALL/RET optimization — set to 2 for more compatibility
export BOX64_DYNAREC_DIRTY=1
export BOX64_DYNAREC_FORWARD=128       # Scan N bytes ahead to extend blocks; weaker CPUs may want lower
export BOX64_RDTSC_1GHZ=1              # Emulate RDTSC at 1 GHz for predictable timing
export BOX64_VSYNC=0                   # Let the engine control vsync

# Optional: OpenGL/Mesa error suppression (minor perf gain)
# export LIBGL_NOERROR=1
# export MESA_NO_ERROR=1

# Optional: Unity-specific tweaks (uncomment for Unity games)
# export UNITY_DISABLE_PARTICLES=0
# export __GL_THREADED_OPTIMIZATIONS=1

# Optional: extra compat knobs some games need (rare, comment in only if required)
# export BOX64_DYNAREC_STRONGMEM=0
# export BOX64_DYNAREC_WAIT=1
# export BOX64_DYNAREC_X87DOUBLE=0
# export BOX64_DYNAREC_FASTNAN=1
# export BOX64_PREFER_WRAPPED=1
# export BOX64_PREFER_EMULATED=0
# export BOX64_NOSIGSEGV=1

# Optional: display loading splash (most boxports have one — long load times)
# [ "$CFW_NAME" == "muOS" ] && $ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 1
# $ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 30000 &

# Optional: use a port-bundled gptokeyb if the system one has d-pad issues
# (common for Unity games — uncomment to use)
# chmod +x "$GAMEDIR/tools/gptokeyb"
# export GPTOKEYB="$GAMEDIR/tools/gptokeyb $ESUDOKILL"

# Run it
$GPTOKEYB "$GAME" -c "$GAMEDIR/game.gptk" &
pm_platform_helper "$GAME" > /dev/null
$BOX64 "$GAME"

# Cleanup
pm_finish
