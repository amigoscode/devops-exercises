#!/usr/bin/env bash
# Runs INSIDE the Ubuntu container. Builds a fresh ~/sandbox for the exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"
mkdir -p "$SB"

# Tier 1 - an empty dir (rmdir works) and a non-empty one (rmdir refuses)
mkdir -p "$SB/old-empty"
mkdir -p "$SB/has-stuff"; echo 'keep me' > "$SB/has-stuff/file.txt"

# Tier 2 - a build dir to nuke, and a cache dir to empty-but-keep
mkdir -p "$SB/temp-build/obj"; echo 'object' > "$SB/temp-build/obj/a.o"
mkdir -p "$SB/cache"; echo 'c1' > "$SB/cache/c1"; echo 'c2' > "$SB/cache/c2"

# Tier 3 - a badly-named folder a colleague left behind (note the space)
mkdir -p "$SB/old releases"; echo 'v1' > "$SB/old releases/v1.txt"

# Clean any prior outputs so re-runs start fresh
rm -f  "$SB/release-v2.zip" "$SB/danger.txt"
rm -rf "$SB/release" "$SB/archived-releases" "$SB/builds" "$SB/app"

echo "Sandbox ready at ~/sandbox"
echo "Remember: in here rm -rf is SAFE to practise - that's the point of a throwaway container."
