#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "my_db" database with a 200,000-row
# employee table (the videos use 10 million; this is the same shape, just quicker to load).
set -euo pipefail
SB="$HOME/sandbox"; DB=my_db
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
CREATE TABLE employee (
  id               SERIAL PRIMARY KEY,
  name             TEXT NOT NULL,
  department       TEXT NOT NULL,
  hire_date        DATE NOT NULL,
  email            TEXT NOT NULL,
  termination_date DATE,                           -- NULL while still employed
  is_manager       BOOLEAN NOT NULL DEFAULT FALSE
);

-- Same columns as the course's random script, but deterministic: every sandbox gets
-- exactly the same data.
INSERT INTO employee (name, department, hire_date, email, termination_date, is_manager)
SELECT md5(i::text),
       (ARRAY['SALES', 'ENGINEERING', 'HR', 'MARKETING', 'FINANCE'])[1 + (i * 7) % 5],
       date '2000-01-01' + (i * 7919) % 8766,
       'employee' || i || '@amigoscode.com',
       CASE WHEN i % 10 = 0 THEN date '2000-01-01' + (i * 7919) % 8766 + 1826 END,  -- 10% have left
       i % 10 = 3                                                                  -- 10% are managers
FROM generate_series(1, 200000) AS i;

-- A botched import ran twice for 50 people: same email, new id.
INSERT INTO employee (name, department, hire_date, email, termination_date, is_manager)
SELECT name, department, hire_date, email, termination_date, is_manager
FROM employee
WHERE id % 3989 = 0 AND id <= 50 * 3989
ORDER BY id;

-- An index someone added "just in case". Nothing filters on is_manager alone.
CREATE INDEX idx_employee_is_manager ON employee (is_manager);

VACUUM ANALYZE employee;
SQL

# The Academy opens psql in this database: it reads this exact line from ~/.bashrc.
touch ~/.bashrc
sed -i '/^export PGDATABASE=/d' ~/.bashrc
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database."
