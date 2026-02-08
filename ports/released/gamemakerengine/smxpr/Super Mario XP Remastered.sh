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
GAMEDIR="/$directory/ports/smxpr"

# CD and set logging
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Setup permissions
$ESUDO chmod +xwr "$GAMEDIR/gmloadernext.aarch64"
$ESUDO chmod +xr "$GAMEDIR/tools/splash"

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Assign gptokeyb and load the game
$GPTOKEYB "gmloadernext.aarch64" -c "mario.gptk" &
pm_platform_helper "$GAMEDIR/gmloadernext.aarch64" >/dev/null
./gmloadernext.aarch64 -c gmloader.json

# Cleanup
pm_finish
