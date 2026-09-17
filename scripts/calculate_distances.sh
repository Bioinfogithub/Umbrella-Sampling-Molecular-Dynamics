#!/usr/bin/env bash
set -euo pipefail

# Calculate the reaction-coordinate distance for every extracted frame.
# Replace GROUP1 and GROUP2 with the names of the index groups in your system.

PULL_TPR="../input/pull.tpr"
INDEX="../input/index.ndx"
FRAMEDIR="../windows/frames"
OUT="../windows/summary_distances.dat"

: > "$OUT"

for frame in "$FRAMEDIR"/frame*.gro; do
    [ -e "$frame" ] || continue

    base=$(basename "$frame" .gro)

    gmx distance \
        -s "$PULL_TPR" \
        -f "$frame" \
        -n "$INDEX" \
        -select 'com of group "GROUP1" plus com of group "GROUP2"' \
        -oall "${FRAMEDIR}/${base}_distance.xvg"

    distance=$(awk '!/^[@#]/ {v=$2} END {print v}' "${FRAMEDIR}/${base}_distance.xvg")
    echo -e "${base}\t${distance}" >> "$OUT"
done

echo "Summary written to $OUT"
