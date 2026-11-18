#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "bank" database for this section.
set -euo pipefail
SB="$HOME/sandbox"; DB=bank
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
CREATE TABLE account (
    id      SERIAL PRIMARY KEY,
    owner   VARCHAR(50) NOT NULL,
    balance DECIMAL(10, 2) NOT NULL CHECK (balance >= 0)   -- no overdrafts
);
INSERT INTO account (owner, balance) VALUES
    ('Ana',   100.00),
    ('Ben',   100.00),
    ('Carla', 250.00),
    ('Dev',    40.00),
    ('Eve',     0.00);
-- dblink opens a second connection from SQL: the drills use it as "another session"
CREATE EXTENSION dblink;
SQL

# An untouched copy: the grader runs each script you save on a fresh copy of it, so
# what you try out in the live database can't change what a script is expected to do.
dropdb --if-exists "${DB}_ref"; createdb -T "$DB" "${DB}_ref"

# The Academy opens psql connected to this database (it reads this line).
sed -i '/^export PGDATABASE=/d' ~/.bashrc
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database."
