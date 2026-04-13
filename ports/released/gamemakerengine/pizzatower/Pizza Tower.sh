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
source $controlfolder/tasksetter
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

export ESUDO=$ESUDO
export GAMEDIR="/$directory/ports/pizzatower"
cd "$GAMEDIR"

# Log execution
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Mount gmloadernext runtime
GMLOADER="$HOME/gmloadernext"
GMLOADER_RUNTIME="$controlfolder/libs/gmloadernext.squashfs"
if [ -f "$GMLOADER_RUNTIME" ]; then
    $ESUDO mkdir -p "$GMLOADER"
    $ESUDO umount "$GMLOADER" 2>/dev/null || true
    $ESUDO mount "$GMLOADER_RUNTIME" "$GMLOADER"
else
    pm_message "This port requires the gmloadernext runtime. Please download it."
    pm_finish
    exit 1
fi

export GMLOADER_LIB_PATH="$GMLOADER/lib"

# Setup other misc environment variables
export LD_LIBRARY_PATH="$GMLOADER/lib/arm64-v8a:$GAMEDIR/libs:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export controlfolder
export DEVICE_ARCH

$ESUDO chmod +x "$GAMEDIR/tools/patchscript"

# Check if we need to patch
if [ ! -f patchlog.txt ] || [ -f "$GAMEDIR/assets/data.win" ]; then
    if [ -f "$controlfolder/utils/patcher.txt" ]; then            
        # Setup and execute the Portmaster Patcher utility with our patch file
        export PATCHER_FILE="$GAMEDIR/tools/patchscript"
        export PATCHER_GAME="$(basename "${0%.*}")"
        export PATCHER_TIME="a while"
        export controlfolder
        source "$controlfolder/utils/patcher.txt"
        $ESUDO kill -9 $(pidof gptokeyb)
    else
        pm_message "This port requires the latest version of PortMaster."
        pm_finish
        exit 1
    fi
fi


swapabxy() {
    # Update SDL_GAMECONTROLLERCONFIG to swap a/b and x/y button
    PYTHON=$(command -v python3)
    if [ "$CFW_NAME" == "knulli" ] && [ -f "$SDL_GAMECONTROLLERCONFIG_FILE" ];then
        cat "$SDL_GAMECONTROLLERCONFIG_FILE" | $PYTHON $GAMEDIR/tools/swapabxy.py > "$GAMEDIR/gamecontrollerdb_swapped.txt"
        export SDL_GAMECONTROLLERCONFIG_FILE="$GAMEDIR/gamecontrollerdb_swapped.txt"
    else
        export SDL_GAMECONTROLLERCONFIG="`echo "$SDL_GAMECONTROLLERCONFIG" | $PYTHON $GAMEDIR/tools/swapabxy.py`"
    fi
}

# Swap a/b and x/y button if needed
if [ -f "$GAMEDIR/swapabxy.txt" ]; then
    swapabxy
fi

$GPTOKEYB "gmloadernext.aarch64" -c "pizza.gptk" & 
pm_platform_helper "$GMLOADER/gmloadernext.aarch64" > /dev/null
$TASKSET "$GMLOADER/gmloadernext.aarch64" -c gmloader.json

# Unmount gmloadernext runtime
$ESUDO umount "$GMLOADER" 2>/dev/null || true

pm_finish