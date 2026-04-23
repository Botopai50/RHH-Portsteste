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
GAMEDIR="/$directory/ports/sonic3air"

cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Create config dir
mkdir -p "config"
bind_directories "$XDG_DATA_HOME/Sonic3AIR" "$GAMEDIR/config"

# Engine data is shipped as data.zip to keep the port repo small and fast to
# update. Presence of data.zip means the zip is newer than whatever's in
# data/ (either first run or port update), so we purge and re-extract.
# Uses PortMaster's bundled 7zzs — not regular unzip — for speed on device.
if [ -f "$GAMEDIR/data.zip" ]; then
  SEVENZIP="$controlfolder/7zzs.${DEVICE_ARCH}"
  if [ ! -x "$SEVENZIP" ]; then
    echo "7zzs binary not found at $SEVENZIP; aborting data extraction."
    pm_finish; exit 1
  fi
  echo "Extracting data.zip..."
  rm -rf "$GAMEDIR/data"
  if "$SEVENZIP" x -y "$GAMEDIR/data.zip" -o"$GAMEDIR" >/dev/null; then
    rm -f "$GAMEDIR/data.zip"
  else
    echo "Unable to extract data.zip."
    pm_finish; exit 1
  fi
fi

# Run the game
$GPTOKEYB "sonic3air_linux" -c "sonic.gptk" &
./sonic3air_linux

# Cleanup
pm_finish
