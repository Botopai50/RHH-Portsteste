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
GAMEDIR="/$directory/ports/valleycore"

# CD and set logging
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Setup permissions
$ESUDO chmod +xwr "$GAMEDIR/gamedata/Stardew Valley"
$ESUDO chmod +xwr "$GAMEDIR/gamedata/StardewModdingAPI"
$ESUDO chmod +xwr "$GAMEDIR/gamedata/patch.sh"
$ESUDO chmod +xr "$GAMEDIR/tools/splash"

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Display loading splash
if [ -f .install ]; then
    [ "$CFW_NAME" == "muOS" ] && $ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 1
    $ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 8000 & 
fi

# Unzip Valleycore if exists
extract_valleycore() {
    SEVENZIP="$controlfolder/7zzs.${DEVICE_ARCH}"

    [ -x "$SEVENZIP" ] || { pm_message "7zss not found. Please use the beta branch of the PortMaster app."; return 1; }

    archive="$1"
    [ -f "$archive" ] || return 1

    mkdir -p "$GAMEDIR/gamedata"
    echo "Extracting $archive..."

    if "$SEVENZIP" x -y "$archive" -o"$GAMEDIR/gamedata"; then
        # Handle nested .tar
        inner_tar="$(ls "$GAMEDIR"/gamedata/*.tar 2>/dev/null | head -n 1)"
        if [ -f "$inner_tar" ]; then
            echo "Extracting inner tar: $inner_tar"
            if "$SEVENZIP" x -y "$inner_tar" -o"$GAMEDIR/gamedata"; then
                rm -f "$inner_tar"
            else
                echo "Failed to extract inner tar"
                return 1
            fi
        fi
        rm -f "$archive"
    else
        echo "Extraction failed for $archive"
        return 1
    fi
}

# Check for any matching archive
if ls "$GAMEDIR"/*ValleyCore*.tar.gz "$GAMEDIR"/*ValleyCore*.tar.gz >/dev/null 2>&1; then
    archive="$(ls "$GAMEDIR"/*ValleyCore*.tar.gz "$GAMEDIR"/*ValleyCore*.tar.gz 2>/dev/null | head -n 1)"
    extract_valleycore "$archive"
fi

# Check if we need to patch the game
if [ ! -f .install ] && [ -f "$GAMEDIR/gamedata/patch.sh" ]; then
    if [ -f "$controlfolder/utils/patcher.txt" ]; then
        export PATCHER_FILE="$GAMEDIR/gamedata/patch.sh"
        export PATCHER_GAME="$(basename "${0%.*}")"
        export PATCHER_TIME="2 to 5 minutes"
        source "$controlfolder/utils/patcher.txt"
        touch .install
        $ESUDO kill -9 $(pidof gptokeyb)
    else
        echo "This port requires the latest version of PortMaster."
    fi
elif [ ! -f .install ] && [ ! -f "$GAMEDIR/gamedata/patch.sh" ]; then
    pm_message "Missing patch.sh! Please follow the readme and add ValleyCore-SMAPI.tar.gz to the game directory."
    exit
fi

# Determine exec to use
if [ -f "$GAMEDIR/gamedata/StardewModdingAPI" ]; then
    EXEC="StardewModdingAPI"
else
    EXEC="Stardew Valley"
fi

# Set XDG_DATA_HOME to our GAMEDIR
export XDG_CONFIG_HOME="$GAMEDIR"

# Assign gptokeyb and load the game
$GPTOKEYB "$EXEC" -c "valleycore.gptk" &
pm_platform_helper "$GAMEDIR/gamedata/$EXEC" >/dev/null
./gamedata/$EXEC

# Cleanup
pm_finish
