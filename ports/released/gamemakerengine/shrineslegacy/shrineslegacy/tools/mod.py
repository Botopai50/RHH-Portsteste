#!/usr/bin/env python3
import os
import sys

def modify_get_default_path(gml_dir):
    filename = "gml_GlobalScript_game_save_migrate.gml"
    file_path = os.path.join(gml_dir, filename)

    if not os.path.isfile(file_path):
        print(f"Warning: {filename} not found, skipping.")
        return

    new_function = [
        "function get_default_path()",
        "{",
        '    var _path = working_directory + "Shrines_Legacy/";',
        "",
        "    if (!directory_exists(_path))",
        "        directory_create(_path);",
        "",
        '    Debug("DEFAULT PATH: " + string(_path));',
        "    return _path;",
        "}"
    ]

    with open(file_path, "r") as f:
        lines = f.readlines()

    new_lines = []
    in_function = False
    brace_count = 0
    replaced = False

    for line in lines:
        stripped = line.strip()

        if stripped.startswith("function get_default_path"):
            in_function = True
            brace_count = 0
            replaced = True
            new_lines.extend(line + "\n" for line in new_function)
            continue

        if in_function:
            brace_count += line.count("{") - line.count("}")
            if brace_count <= 0:
                in_function = False
            continue

        new_lines.append(line)

    with open(file_path, "w") as f:
        f.writelines(new_lines)

    if replaced:
        print(f"Updated get_default_path() in {filename}")
    else:
        print(f"Function get_default_path() not found in {filename}, no changes made.")


def main(gml_dir):
    modify_get_default_path(gml_dir)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: mod_shrines.py <gml_directory>")
        sys.exit(1)
    main(sys.argv[1])
