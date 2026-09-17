#!/usr/bin/env bash
set -euo pipefail

# Run all umbrella windows.
# Before running, generate a window directory containing:
#   conf.gro, umbrella.mdp, topol.top, index.ndx (if required)

for dir in ../windows/window-*; do
    [ -d "$dir" ] || continue

    (
        cd "$dir"

        gmx grompp \
            -f umbrella.mdp \
            -c conf.gro \
            -p topol.top \
            -n index.ndx \
            -o umbrella.tpr

        gmx mdrun \
            -deffnm umbrella \
            -pf umbrella_pullf.xvg \
            -px umbrella_pullx.xvg
    )
done
