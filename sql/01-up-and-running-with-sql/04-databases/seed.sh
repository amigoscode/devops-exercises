#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + a few databases to rename and drop.
set -euo pipefail
SB="$HOME/sandbox"
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

for db in my_db test_db tset_db old_app staging staging_old; do dropdb --if-exists "$db"; done
createdb tset_db; createdb old_app; createdb staging

psql -X -q -v ON_ERROR_STOP=1 -d tset_db <<'SQL'
CREATE TABLE notes (id INTEGER, note VARCHAR(100));
INSERT INTO notes VALUES (1, 'first test'), (2, 'second test'), (3, 'third test');
SQL
psql -X -q -v ON_ERROR_STOP=1 -d old_app <<'SQL'
CREATE TABLE users (id INTEGER, username VARCHAR(50));
INSERT INTO users VALUES (1, 'legacy_admin'), (2, 'legacy_user');
SQL
psql -X -q -v ON_ERROR_STOP=1 -d staging <<'SQL'
CREATE TABLE orders (id INTEGER, customer VARCHAR(50), total INTEGER);
INSERT INTO orders VALUES (1, 'John', 120), (2, 'Jamila', 75), (3, 'Maria', 310), (4, 'Ahmed', 42);
SQL

# The Academy opens psql connected to your own database.
grep -qx "export PGDATABASE=student" ~/.bashrc 2>/dev/null || echo "export PGDATABASE=student" >> ~/.bashrc
grep -qx "export PGDATABASE=student" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: you're in psql, connected to 'student'. Type \\l to see the databases."
