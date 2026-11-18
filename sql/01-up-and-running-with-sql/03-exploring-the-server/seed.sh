#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox; the server is the one the image starts.
set -euo pipefail
SB="$HOME/sandbox"; DB=student
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

# The Academy opens psql connected to this database.
grep -qx "export PGDATABASE=$DB" ~/.bashrc 2>/dev/null || echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: you're in psql, connected to your '$DB' database."
