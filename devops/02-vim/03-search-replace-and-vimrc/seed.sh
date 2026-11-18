#!/usr/bin/env bash
# Runs INSIDE the container. Builds a fresh ~/sandbox for the exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"; mkdir -p "$SB"

# Tier 1 - a config riddled with 'localhost' to replace
printf 'db_host=localhost\ncache_host=localhost\napi_host=localhost\n' > "$SB/config.txt"

# Tier 2 - flip a single setting
printf 'ENV=staging\nDEBUG=true\nLOG_LEVEL=info\n' > "$SB/app.env"

# Tier 3 - start with no ~/.vimrc so creating it is a real task
rm -f "$HOME/.vimrc"

echo "Sandbox ready at ~/sandbox. Search with /, replace with :%s/old/new/g"
