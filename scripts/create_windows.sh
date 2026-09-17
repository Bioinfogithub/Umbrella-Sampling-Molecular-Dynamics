#!/usr/bin/env bash
set -euo pipefail

# Create umbrella-window directories from selected configurations.
# The selected_windows.dat file should contain:
# frame_name    center_distance_nm

SELECTED="../windows/selected_windows.dat"
TEMPLATE="../mdp/umbrella_template.mdp"
FRAME_DIR="../windows/frames"
WINDOW_DIR="../windows"

while read -r frame center; do
    [ -z "${frame:-}" ] && continue

    number=$(printf "%03d" "$(( $(find "$WINDOW_DIR" -maxdepth 1 -type d -name 'window-*' | wc -l) + 1 ))")
    dir="$WINDOW_DIR/window-$number"

    mkdir -p "$dir"

    cp "$FRAME_DIR/${frame}.gro" "$dir/conf.gro"
    cp "../input/topol.top" "$dir/topol.top"

    if [ -f "../input/index.ndx" ]; then
        cp "../input/index.ndx" "$dir/index.ndx"
    fi

    sed "s/WINDOW_CENTER/${center}/" "$TEMPLATE" > "$dir/umbrella.mdp"

    echo "Created $dir at ${center} nm"
done < "$SELECTED"
