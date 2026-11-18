#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "company" database and its roles.
# Roles live in the whole server, not in one database, so they're reset here too.
set -euo pipefail
SB="$HOME/sandbox"; DB=company
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"
for r in jamila alex dev_team data_team old_contractor ci_runner jane dpatel tcohen staff; do
  psql -X -q -d postgres -c "DROP ROLE IF EXISTS $r" >/dev/null 2>&1 || true
done
createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
CREATE TABLE car (
    id    SERIAL PRIMARY KEY,
    make  VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year  INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);
INSERT INTO car (make, model, year, price) VALUES
    ('Toyota', 'Corolla', 2021, 18500.00), ('Ford', 'Focus', 2019, 12900.00),
    ('Tesla', 'Model 3', 2023, 39990.00), ('BMW', '320d', 2020, 24500.00),
    ('Honda', 'Civic', 2022, 21000.00),   ('Kia', 'Niro', 2024, 29950.00);

-- The table from the row-level security videos (your role, student, is the first row)
CREATE TABLE employee (
    id         SERIAL PRIMARY KEY,
    username   VARCHAR(50) NOT NULL,
    name       VARCHAR(50) NOT NULL,
    role       VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL
);
INSERT INTO employee (username, name, role, department) VALUES
    ('student',  'Mama Samba',    'Manager',         'Engineering'),
    ('jane',     'Jane Smith',    'Manager',         'Marketing'),
    ('dpatel',   'Divya Patel',   'Developer',       'Engineering'),
    ('ymizrahi', 'Yael Mizrahi',  'Sales Executive', 'Marketing'),
    ('sgupta',   'Sanjay Gupta',  'HR Specialist',   'HR'),
    ('mkhan',    'Mohammed Khan', 'Analyst',         'Finance'),
    ('rstein',   'Rachel Stein',  'Support Agent',   'Support'),
    ('postgres', 'Postgres',      'Developer',       'Engineering'),
    ('hkim',     'Hye-Jin Kim',   'Developer',       'Engineering'),
    ('dzhao',    'Deng Zhao',     'HR Specialist',   'HR'),
    ('tcohen',   'Tova Cohen',    'Sales Executive', 'Marketing');

-- Roles that already exist on this server
CREATE ROLE old_contractor WITH LOGIN PASSWORD 'password';     -- left the company
GRANT SELECT ON car TO old_contractor;
CREATE ROLE ci_runner WITH LOGIN SUPERUSER PASSWORD 'password'; -- "it needed to create test databases"

-- The HR app's staff: a group role with the table privileges, and three employees in it
CREATE ROLE staff NOLOGIN;
GRANT SELECT, INSERT, UPDATE ON employee TO staff;
GRANT USAGE, SELECT ON SEQUENCE employee_id_seq TO staff;
CREATE ROLE jane   WITH LOGIN PASSWORD 'password' IN ROLE staff;
CREATE ROLE dpatel WITH LOGIN PASSWORD 'password' IN ROLE staff;
CREATE ROLE tcohen WITH LOGIN PASSWORD 'password' IN ROLE staff;
SQL

# The Academy opens psql connected to this database (it reads this line).
sed -i '/^export PGDATABASE=/d' ~/.bashrc
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database."
