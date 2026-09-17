#!/usr/bin/env bash
set -euo pipefail

# Extract individual configurations from the pulling trajectory.
# Edit PULL_TPR and PULL_XTC before running.

PULL_TPR="../input/pull.tpr"
PULL_XTC="../input/pull.xtc"
OUTDIR="../windows/frames"

mkdir -p "$OUTDIR"

gmx trjconv \
    -s "$PULL_TPR" \
    -f "$PULL_XTC" \
    -o "$OUTDIR/frame.gro" \
    -sep

echo "Frames written to $OUTDIR"
