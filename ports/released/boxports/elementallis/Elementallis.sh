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
GAMEDIR="/$directory/ports/elementallis"
GAME="$GAMEDIR/data/Elementallis.x86_64"
BOX64="$GAMEDIR/box64/box64"

# CD and set log
cd $GAMEDIR/data
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Pre-flight checks for X11 and OpenGL
if [ -z "$DISPLAY" ]; then
    echo "Error: Display manager not found. This game requires OpenGL and X11 to run."
    exit 1
fi

if ! command -v glxinfo >/dev/null 2>&1; then
    echo "Error: OpenGL not found. This game requires OpenGL and X11 to run."
    exit 1
fi

# Display loading splash
[ "$CFW_NAME" == "muOS" ] && $ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 1 
$ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 30000 &

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export LD_LIBRARY_PATH="$GAMEDIR/box64/x64:$GAMEDIR/libs.aarch64:$GAMEDIR/data:$LD_LIBRARY_PATH"
export BOX64_LD_LIBRARY_PATH="$GAMEDIR/box64/x64:$GAMEDIR/data:$LD_LIBRARY_PATH"
export XDG_CONFIG_HOME="$GAMEDIR/config" && mkdir -p "$GAMEDIR/config"
export SDL_VIDEODRIVER=x11

# Box64 settings
export BOX64_NOBANNER=1
export BOX64_DYNAREC=1
export BOX64_DYNAREC_SAFEFLAGS=0
export BOX64_DYNAREC_FASTROUND=1
export BOX64_DYNAREC_BIGBLOCK=1
export BOX64_DYNAREC_CALLRET=1
export BOX64_DYNAREC_DIRTY=1
export BOX64_DYNAREC_FORWARD=128
export BOX64_RDTSC_1GHZ=1
export BOX64_VSYNC=0

export BOX64_DYNAREC_STRONGMEM=0
export BOX64_DYNAREC_WAIT=1
export BOX64_DYNAREC_X87DOUBLE=0
export BOX64_DYNAREC_FASTNAN=1
export BOX64_PREFER_WRAPPED=1
export BOX64_PREFER_EMULATED=0
export BOX64_NOSIGSEGV=1

export UNITY_DISABLE_PARTICLES=0
export __GL_THREADED_OPTIMIZATIONS=1

# Run it
$GPTOKEYB "$GAME" xbox360 & 
pm_platform_helper $GAME > /dev/null
$BOX64 "$GAME"

#Clean up after ourselves
pm_finish