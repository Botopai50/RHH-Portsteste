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
GAMEDIR="/$directory/ports/ratcheteerdx"
GAME="$GAMEDIR/data/RatcheteerDX-Demo"
BOX64="$GAMEDIR/box64/box64"

# CD and set log
cd $GAMEDIR/data
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/box64/x64:$GAMEDIR/libs.aarch64:$GAMEDIR/data:$LD_LIBRARY_PATH"
export BOX64_LD_LIBRARY_PATH="$GAMEDIR/box64/x64:$GAMEDIR/data:$LD_LIBRARY_PATH"
export XDG_CONFIG_HOME="$GAMEDIR/config" && mkdir -p "$GAMEDIR/config"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

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

if [ ! -f "$GAME" ]; then
  GAME="$GAMEDIR/data/RatcheteerDX"
  if [ ! -f "$GAME" ]; then
    echo "Missing game data!"
  fi
fi

# Mount Weston runtime
weston_dir=/tmp/weston
$ESUDO mkdir -p "${weston_dir}"
weston_runtime="weston_pkg_0.2"
if [ ! -f "$controlfolder/libs/${weston_runtime}.squashfs" ]; then
  if [ ! -f "$controlfolder/harbourmaster" ]; then
    pm_message "This port requires the latest PortMaster to run, please go to https://portmaster.games/ for more info."
    sleep 5
    exit 1
  fi
  $ESUDO $controlfolder/harbourmaster --quiet --no-check runtime_check "${weston_runtime}.squashfs"
fi
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "${weston_dir}"
fi
$ESUDO mount "$controlfolder/libs/${weston_runtime}.squashfs" "${weston_dir}"

# rocknix mode on rocknix panfrost; libmali not supported
if [[ "$CFW_NAME" = "ROCKNIX" ]]; then
  export rocknix_mode=1
fi

# Display loading splash
[ "$CFW_NAME" == "muOS" ] && $ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 1 
$ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 30000 &

# Run it
$GPTOKEYB "$GAME" xbox360 & 
pm_platform_helper $GAME > /dev/null
$BOX64 "$GAME"

# Start Westonpack
$ESUDO env \
BOX64_LD_LIBRARY_PATH="$GAMEDIR/box64/x64:$GAMEDIR/data:$LD_LIBRARY_PATH" \
$weston_dir/westonwrap.sh headless noop kiosk crusty_glx_gl4es \
XDG_CONFIG_HOME=$CONFDIR \
XDG_DATA_HOME=$LOCALDIR \
$BOX64 ./$GAME

# Clean up after ourselves
$ESUDO $weston_dir/westonwrap.sh cleanup
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "${weston_dir}"
fi

pm_finish