#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

# Detect PortMaster control folder
if [ -d "/opt/system/Tools/PortMaster/" ]; then
    controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
    controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
    controlfolder="$XDG_DATA_HOME/PortMaster"
else
    controlfolder="/roms/ports/PortMaster"
fi

source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Paths and constants
GAMEDIR="/$directory/ports/smb1r"
CONFDIR="$GAMEDIR/config"
TARGET_ROM="$CONFDIR/baserom.nes"

# Logging and permissions
cd "$GAMEDIR"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +rwx "$GAMEDIR/godot-45.aarch64"

# Environment exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export GODOT_SILENCE_ROOT_WARNING=1

# --- ROM detection & validation ---
find_and_copy_rom() {
    NES_DIR="/$directory/nes"
    VALID_MD5="f94bb9bb55f325d9af8a0fff80b9376d"
    mkdir -p "$(dirname "$TARGET_ROM")"
    local search_dirs=("$GAMEDIR" "$NES_DIR")
    local found=false

    for dir in "${search_dirs[@]}"; do
        echo "Searching in $dir..."

        # 1. Check .nes files
        for rom in "$dir"/*.nes; do
            [ -e "$rom" ] || continue
            md5=$(md5sum "$rom" | awk '{print $1}')
            if [[ "$md5" == "$VALID_MD5" ]]; then
                echo "Valid ROM found: $rom"
                cp "$rom" "$TARGET_ROM"
                found=true
                break 2
            fi
        done

        # 2. Check .nes files inside zip archives
        for zip in "$dir"/*.zip; do
            [ -e "$zip" ] || continue
            while IFS= read -r nes_file; do
                tmpfile=$(mktemp)
                unzip -p "$zip" "$nes_file" > "$tmpfile" 2>/dev/null
                md5=$(md5sum "$tmpfile" | awk '{print $1}')
                if [[ "$md5" == "$VALID_MD5" ]]; then
                    echo "Valid ROM found inside zip: $zip -> $nes_file"
                    cp "$tmpfile" "$TARGET_ROM"
                    found=true
                    rm -f "$tmpfile"
                    break 3
                fi
                rm -f "$tmpfile"
            done < <(unzip -Z1 "$zip" | grep -i '\.nes$')
        done
    done

    if ! $found; then
        echo "No valid baserom.nes found in $GAMEDIR or $NES_DIR!"
        exit 1
    fi
}

# Run ROM search
[ ! -f "$TARGET_ROM" ] && find_and_copy_rom

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

# --- Launch the game ---
$GPTOKEYB "godot-45.aarch64" -c "mario.gptk" &

# Start Westonpack and Godot
$ESUDO env $weston_dir/westonwrap.sh headless noop kiosk crusty_x11egl \
./godot-45.aarch64 \
--resolution ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} -f \
--rendering-driver opengl3_es \
--main-pack SMB1R.pck

#Clean up after ourselves
$ESUDO $weston_dir/westonwrap.sh cleanup
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "${weston_dir}"
    $ESUDO umount "${godot_dir}"
fi
pm_finish
