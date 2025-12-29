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
GAMEDIR="/$directory/ports/theforceengine"

# CD and set logging
cd $GAMEDIR/engine
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Zip check
if [ -f "$GAMEDIR/engine.zip" ]; then
  if ! unzip -oq "$GAMEDIR/engine.zip" -d "$GAMEDIR" 2>/dev/null; then
    echo "ERROR: Failed to extract engine.zip"
    exit 1
  fi
  rm -rf "$GAMEDIR/engine.zip"
fi

# Assets check
ASSET_DIR="$GAMEDIR/darkforces"
REQUIRED_FILES="
dark.gob
sounds.gob
sprites.gob
textures.gob
"

REQUIRED_DIRS="
lfd
"

for asset in $REQUIRED_FILES; do
  if ! find "$ASSET_DIR" -maxdepth 1 -type f -iname "$asset" | grep -q .; then
    echo "ERROR: Missing asset file: $asset in $ASSET_DIR"
    exit 1
  fi
done

for dir in $REQUIRED_DIRS; do
  if ! find "$ASSET_DIR" -maxdepth 1 -type d -iname "$dir" | grep -q .; then
    echo "ERROR: Missing asset directory: $dir in $ASSET_DIR"
    exit 1
  fi
done

# Setup permissions
$ESUDO chmod 755 "$GAMEDIR/engine/tfe"

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs:$LD_LIBRARY_PATH"
export SDL_VIDEODRIVER="x11"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export TFE_DATA_HOME="$GAMEDIR/config"

# --- OpenGL 3.3 check ---
if ! command -v glxinfo >/dev/null 2>&1; then
  echo "ERROR: glxinfo not found; cannot verify OpenGL version."
  exit 1
fi

GL_VERSION_RAW=$(glxinfo -B 2>/dev/null | awk -F': ' '/OpenGL core profile version string/ {print $2}')
[ -z "$GL_VERSION_RAW" ] && GL_VERSION_RAW=$(glxinfo -B 2>/dev/null | awk -F': ' '/OpenGL version string/ {print $2}')

GL_MAJOR=$(echo "$GL_VERSION_RAW" | sed 's/^\([0-9][0-9]*\)\..*/\1/')
GL_MINOR=$(echo "$GL_VERSION_RAW" | sed 's/^[0-9][0-9]*\.\([0-9][0-9]*\).*/\1/')

if [ "$GL_MAJOR" -lt 3 ] || [ "$GL_MAJOR" -eq 3 -a "$GL_MINOR" -lt 3 ]; then
  echo "ERROR: OpenGL 3.3 or higher is required."
  exit 1
fi
# --- end OpenGL check ---

# Assign gptokeyb and load the game
$GPTOKEYB "tfe" -c "$GAMEDIR/tfe.gptk" &
pm_platform_helper "$GAMEDIR/engine/tfe" >/dev/null
./tfe --game DARK --fullscreen

# Cleanup
pm_finish
