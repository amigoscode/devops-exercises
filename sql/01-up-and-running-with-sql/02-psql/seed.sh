#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox with a script to run from psql.
set -euo pipefail
SB="$HOME/sandbox"; DB=student
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

# Start with an empty "student" database (no foo table yet).
psql -X -q -d "$DB" -c "DROP TABLE IF EXISTS foo" >/dev/null 2>&1 || true

cat > "$SB/report.sql" <<'SQL'
-- Server report: who am I, where am I connected, which PostgreSQL is this?
SELECT current_user                       AS connected_as,
       current_database()                 AS database_name,
       current_setting('server_version')  AS server_version,
       current_setting('port')            AS port,
       current_setting('server_encoding') AS encoding;
SQL

# The Academy opens psql connected to this database.
grep -qx "export PGDATABASE=$DB" ~/.bashrc 2>/dev/null || echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: you're in psql, connected to your '$DB' database."
