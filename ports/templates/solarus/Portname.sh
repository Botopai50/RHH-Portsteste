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

# Set variables
GAMEDIR="/$directory/ports/portfolder"
runtime="solarus-1.6.5"
solarus_dir="$HOME/portmaster-solarus"
solarus_file="$controlfolder/libs/${runtime}.squashfs"

# Exports
export LD_LIBRARY_PATH="/usr/lib:$GAMEDIR/libs:$solarus_dir"

cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Optional: enable libGL via gl4es for games that need desktop GL
# (uncomment if the game won't render under GLES)
# if [ -f "${controlfolder}/libgl_${CFW_NAME}.txt" ]; then
#   source "${controlfolder}/libgl_${CFW_NAME}.txt"
# else
#   source "${controlfolder}/libgl_default.txt"
# fi

# Check for runtime, ask harbourmaster to fetch if missing
if [ ! -f "$solarus_file" ]; then
  if [ ! -f "$controlfolder/harbourmaster" ]; then
    pm_message "This port requires the latest version of PortMaster."
    sleep 5
    pm_finish
    exit 1
  fi
  $ESUDO $controlfolder/harbourmaster --quiet --no-check runtime_check "${runtime}.squashfs"
fi

# Mount Solarus runtime
$ESUDO mkdir -p "$solarus_dir"
$ESUDO umount "$solarus_file" 2>/dev/null || true
$ESUDO mount "$solarus_file" "$solarus_dir"
PATH="$solarus_dir:$PATH"

# Run the game (the .solarus quest file ships alongside in $GAMEDIR)
$GPTOKEYB "$runtime" -c "game.gptk" &
pm_platform_helper "$runtime" > /dev/null
"$runtime" $GAMEDIR/*.solarus

# Cleanup
pm_finish
