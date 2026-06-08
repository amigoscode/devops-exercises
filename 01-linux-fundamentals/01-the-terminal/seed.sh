#!/usr/bin/env bash
# Runs INSIDE the Ubuntu container. Builds a fresh ~/sandbox for the exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"
mkdir -p "$SB"

# Tier 1 - a deliberately long, single-child path so TAB completion shines.
mkdir -p "$SB/srv/var/log/nginx-application-server"

# Tier 3 - a logs folder with some ERROR lines to grep during the on-call task.
mkdir -p "$SB/logs"
printf 'INFO  boot ok\nERROR disk almost full\nINFO  serving\n' > "$SB/logs/app.log"
printf 'INFO  connected\nERROR query timeout\n'                 > "$SB/logs/db.log"

# Pre-load the shell history. These commands are NOT executed - they just sit in
# your history so you can practise recalling them (Ctrl+R / history).
# Two of them are "planted" for the exercises; the rest is realistic clutter.
cat > "$HOME/.bash_history" <<'EOF'
pwd
ls -l
echo "found-via-ctrl-r" > ~/sandbox/recall.txt
clear
cd ~/sandbox
grep -r "ERROR" ~/sandbox/logs > ~/sandbox/errors-found.txt
ls -la
EOF

echo "Sandbox ready at ~/sandbox"
echo "(Your command history has been pre-loaded - try the Up arrow and Ctrl+R.)"
