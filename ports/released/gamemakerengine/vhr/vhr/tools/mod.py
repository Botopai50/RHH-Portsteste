#!/usr/bin/env python3
import os
import sys

def remove_lines_from_file(gml_dir, filename, lines_to_remove):
    """Remove specific lines from a GML file"""
    file_path = os.path.join(gml_dir, filename)

    if not os.path.isfile(file_path):
        print(f"Warning: {filename} not found, skipping.")
        return

    with open(file_path, "r") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        if any(line.strip().startswith(r) for r in lines_to_remove):
            continue
        new_lines.append(line)

    with open(file_path, "w") as f:
        f.writelines(new_lines)

# --- Game-specific modifications ---

def clean_bookkeeping_update(gml_dir):
    """Remove steam stat line from gml_GlobalScript_bookkeeping_update.gml"""
    remove_lines_from_file(
        gml_dir,
        "gml_GlobalScript_bookkeeping_update.gml",
        [
            "if (_place == 1)",
            "steam_set_stat_int(\"winning_run\""
        ],
    )

def clean_car_bounce(gml_dir):
    """Remove steam stat + achievement from gml_GlobalScript_car_bounce.gml"""
    remove_lines_from_file(
        gml_dir,
        "gml_GlobalScript_car_bounce.gml",
        [
            "steam_set_stat_int(\"backmarker\"",
            "achievement_set(obj_main.achievement_list_backmarker)"
        ],
    )

def clean_player_scripts(gml_dir):
    """Remove steam stat + achievement from gml_GlobalScript_player_scripts.gml"""
    remove_lines_from_file(
        gml_dir,
        "gml_GlobalScript_player_scripts.gml",
        [
            "steam_set_stat_int(\"fall_out\"",
            "achievement_set(obj_main.achievement_list_fall)"
        ],
    )


# --- Main entry point ---

def main(gml_dir):
    clean_bookkeeping_update(gml_dir)
    clean_car_bounce(gml_dir)
    clean_player_scripts(gml_dir)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: mod.py <gml_directory>")
        sys.exit(1)
    main(sys.argv[1])
