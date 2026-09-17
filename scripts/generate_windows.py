#!/usr/bin/env python3
"""Select approximately equally spaced configurations from a distance table.

Input format:
    frame0001    0.500
    frame0002    0.700
    ...

Usage:
    python generate_windows.py ../windows/summary_distances.dat 0.2
"""

from pathlib import Path
import sys

def read_table(path):
    rows = []
    for line in Path(path).read_text().splitlines():
        if not line.strip() or line.lstrip().startswith(("#", "@")):
            continue
        cols = line.split()
        if len(cols) >= 2:
            rows.append((cols[0], float(cols[1])))
    return rows

def choose_windows(rows, spacing):
    rows = sorted(rows, key=lambda x: x[1])
    selected = []
    last = None
    for frame, distance in rows:
        if last is None or abs(distance - last) >= spacing:
            selected.append((frame, distance))
            last = distance
    return selected

if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: python generate_windows.py DISTANCE_TABLE SPACING_NM")

    table = Path(sys.argv[1])
    spacing = float(sys.argv[2])

    selected = choose_windows(read_table(table), spacing)

    out = table.with_name("selected_windows.dat")
    out.write_text("
".join(f"{frame}	{distance:.3f}" for frame, distance in selected) + "
")

    print(f"Selected {len(selected)} windows")
    print(f"Written to: {out}")
