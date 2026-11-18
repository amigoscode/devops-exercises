#!/usr/bin/env bash
# Runs INSIDE the container when the Academy wakes it after a restart (Docker or the
# machine rebooted). Brings the local service on port 8000 back up.
SB="$HOME/sandbox"
pgrep -f 'http.server 8000' >/dev/null && exit 0
cd "$SB" || exit 0
nohup python3 -m http.server 8000 >/dev/null 2>&1 & disown
sleep 1
