#!/usr/bin/env bash
# Runs INSIDE the container when the Academy wakes it after a restart (Docker or the
# machine rebooted). A reboot kills the runaway process; if you haven't recorded its
# PID yet, start a new one so Tier 2 can still be done.
SB="$HOME/sandbox"
[ -s "$SB/runaway-pid.txt" ] && exit 0
pgrep -x sleep >/dev/null && exit 0
nohup sleep 99999 >/dev/null 2>&1 & disown
echo $! > /tmp/.academy-runaway-pid
