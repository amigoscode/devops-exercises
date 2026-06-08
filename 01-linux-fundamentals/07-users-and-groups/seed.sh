#!/usr/bin/env bash
# Runs INSIDE the Ubuntu container. Resets user/group state for a fresh start.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"; mkdir -p "$SB"

# Remove anything left from a previous attempt (ignore errors on first run).
for u in alice bob carol; do sudo userdel -r "$u" 2>/dev/null || true; done
for g in developers ops legacy; do sudo groupdel "$g" 2>/dev/null || true; done
sudo rm -rf /opt/acme

# A leftover, unused group for the cleanup task in Tier 3.
sudo groupadd legacy

echo "Sandbox ready. You have passwordless sudo - you're effectively the sysadmin here."
echo "(This whole section only works because we're in a container with real root.)"
