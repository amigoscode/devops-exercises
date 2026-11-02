#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + a "customers" table in your own
# "student" database, the one the Academy connects you to.
set -euo pipefail
SB="$HOME/sandbox"; DB=student
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
  id         INTEGER,
  first_name VARCHAR(50),
  last_name  VARCHAR(50),
  email      VARCHAR(100),
  country    VARCHAR(50)
);
INSERT INTO customers (id, first_name, last_name, email, country) VALUES
  (1, 'John',   'Smith',   'john.smith@example.com',   'United Kingdom'),
  (2, 'Jamila', 'Ahmed',   'jamila.ahmed@example.com', 'Egypt'),
  (3, 'Maria',  'Garcia',  'maria.garcia@example.com', 'Spain'),
  (4, 'Ahmed',  'Hassan',  'ahmed.hassan@example.com', 'Morocco'),
  (5, 'Chen',   'Wei',     'chen.wei@example.com',     'China'),
  (6, 'Ana',    'Silva',   'ana.silva@example.com',    'Portugal');
SQL

# An untouched copy the grader runs your saved queries against.
dropdb --if-exists "${DB}_ref"; createdb -T "$DB" "${DB}_ref"

# The Academy opens psql connected to this database.
grep -qx "export PGDATABASE=$DB" ~/.bashrc 2>/dev/null || echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: you're in psql, connected to your '$DB' database."
