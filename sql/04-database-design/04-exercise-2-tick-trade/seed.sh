#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + an empty "ticktrade" database: the
# whole design is yours.
set -euo pipefail
SB="$HOME/sandbox"; DB=ticktrade
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"

# The Academy opens psql connected to this database: it reads this exact line.
grep -qx "export PGDATABASE=$DB" ~/.bashrc 2>/dev/null || echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "seed: could not set PGDATABASE in ~/.bashrc" >&2; exit 1; }
echo "Sandbox ready: psql opens connected to the empty '$DB' database."
