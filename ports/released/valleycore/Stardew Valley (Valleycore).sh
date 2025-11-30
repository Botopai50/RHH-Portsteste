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

# Check for latest ValleyCore release
check_valleycore_update() {
	repo="a9ix/ValleyCore"
	version_file="$GAMEDIR/.install"

	# Fetch latest release metadata
	release_json=$(curl -s -H "Accept: application/vnd.github.v3+json" \
		"https://api.github.com/repos/${repo}/releases/latest")
	if [ -z "$release_json" ]; then
		echo "Failed to fetch release info"
		return 1
	fi

	# Extract tag name
	latest_tag=$(echo "$release_json" | grep -Po '"tag_name":\s*"\K[^"]+')
	if [ -z "$latest_tag" ]; then
		echo "Could not find tag_name in JSON"
		return 1
	fi

	# Read current version if any
	current_tag=""
	[ -f "$version_file" ] && current_tag=$(<"$version_file")

	if [ "$latest_tag" = "$current_tag" ]; then
		echo "ValleyCore is already up-to-date: $latest_tag"
		return 0
	fi

	# Find download URL for ValleyCore.tar.gz
	download_url=$(echo "$release_json" \
		| grep -iPo '"browser_download_url":\s*"\K[^"]*ValleyCore\.tar\.gz(?=")')
	if [ -z "$download_url" ]; then
		echo "No ValleyCore.tar.gz asset found in latest release"
		return 1
	fi

	echo "New ValleyCore release detected: $latest_tag"
	# Call download function
	download_valleycore "$latest_tag" "$download_url"
	return $?
}

# Download ValleyCore release
download_valleycore() {
  latest_tag="$1"
  download_url="$2"
  archive_file="$GAMEDIR/ValleyCore.tar.gz"
  tmpfile="$GAMEDIR/ValleyCore.tar.gz.tmp"
  version_file="$GAMEDIR/.install"

  echo "Downloading ValleyCore $latest_tag from $download_url"

  if ! curl -L -o "$tmpfile" "$download_url"; then
	echo "Download failed, removing partial file"
	rm -f "$tmpfile"
	return 1
  fi

  mv "$tmpfile" "$archive_file"
  echo "$latest_tag" > "$version_file"
  echo "Downloaded version $latest_tag"
  return 0
}

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

# Check for updates
check_valleycore_update

# Check for any matching archive
archive="$(ls "$GAMEDIR"/ValleyCore*.tar.gz 2>/dev/null | head -n 1)"
[ -n "$archive" ] && extract_valleycore "$archive"

# Check if we need to patch the game
if [ -f "$GAMEDIR/gamedata/patch.sh" ]; then
	if [ -f "$controlfolder/utils/patcher.txt" ]; then
		export PATCHER_FILE="$GAMEDIR/gamedata/patch.sh"
		export PATCHER_GAME="$(basename "${0%.*}")"
		export PATCHER_TIME="2 to 5 minutes"
		source "$controlfolder/utils/patcher.txt"
		touch .install && rm -rf "$GAMEDIR/gamedata/patch.sh"
		$ESUDO kill -9 $(pidof gptokeyb)
	else
		echo "This port requires the latest version of PortMaster."
	fi
fi

# Display loading splash
if [ -f .install ]; then
	[ "$CFW_NAME" == "muOS" ] && $ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 1
	$ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 8000 & 
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