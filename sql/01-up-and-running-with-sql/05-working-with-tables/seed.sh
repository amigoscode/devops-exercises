#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "my_db" database from the videos,
# with two tables someone else left behind.
set -euo pipefail
SB="$HOME/sandbox"; DB=my_db
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
CREATE TABLE custmer (
  id        INTEGER,
  full_name VARCHAR(100),
  emial     VARCHAR(100)
);
INSERT INTO custmer VALUES
  (1, 'John Smith',   'john.smith@example.com'),
  (2, 'Jamila Ahmed', 'jamila.ahmed@example.com'),
  (3, 'Maria Garcia', 'maria.garcia@example.com');

CREATE TABLE temp_import (line TEXT);
INSERT INTO temp_import VALUES ('id,name'), ('1,John Smith');
SQL

# The Academy opens psql connected to this section's database.
grep -qx "export PGDATABASE=$DB" ~/.bashrc 2>/dev/null || echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: you're in psql, connected to the '$DB' database."
