#!/usr/bin/env bash
set -euo pipefail

mkdir -p ../results

gmx wham \
    -it tpr-files.dat \
    -if pullf-files.dat \
    -o ../results/pmf.xvg \
    -hist ../results/histo.xvg \
    -unit kJ

echo "PMF written to ../results/pmf.xvg"
echo "Histogram written to ../results/histo.xvg"
