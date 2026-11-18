#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "platform" database for this section:
# a bank-style account table (procedures) and a small course platform (triggers).
set -euo pipefail
SB="$HOME/sandbox"; DB=platform
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
-- Money -------------------------------------------------------------------
CREATE TABLE account (
    id      SERIAL PRIMARY KEY,
    owner   VARCHAR(50) NOT NULL,
    balance DECIMAL(10, 2) NOT NULL
);
INSERT INTO account (owner, balance) VALUES ('Ana', 100.00), ('Ben', 100.00), ('Carla', 250.00);

CREATE TABLE account_audit (
    id          SERIAL PRIMARY KEY,
    account_id  INT NOT NULL,
    old_balance DECIMAL(10, 2),
    new_balance DECIMAL(10, 2),
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- The course platform ----------------------------------------------------
CREATE TYPE app_role AS ENUM ('student', 'instructor', 'admin');

CREATE TABLE app_user (
    id          SERIAL PRIMARY KEY,
    email       TEXT NOT NULL UNIQUE,
    full_name   TEXT NOT NULL,
    signup_role app_role            -- what they picked at sign-up (NULL = didn't pick)
);
CREATE TABLE user_role (
    user_id INT PRIMARY KEY REFERENCES app_user (id),
    role    app_role NOT NULL
);
CREATE TABLE course (
    id    SERIAL PRIMARY KEY,
    title TEXT NOT NULL
);
CREATE TABLE course_enrollment (
    id         SERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES app_user (id),
    course_id  INT NOT NULL REFERENCES course (id),
    progress   INT NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    UNIQUE (student_id, course_id)
);
CREATE TABLE certificate (
    id         SERIAL PRIMARY KEY,
    course_id  INT NOT NULL REFERENCES course (id),
    student_id INT NOT NULL REFERENCES app_user (id),
    issued_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO app_user (email, full_name, signup_role) VALUES
    ('ana@example.com',   'Ana Lopez',   'student'),
    ('ben@example.com',   'Ben Okafor',  NULL),
    ('carla@example.com', 'Carla Rossi', 'instructor'),
    ('dev@example.com',   'Dev Patel',   'admin');
INSERT INTO user_role (user_id, role) VALUES (1, 'student'), (2, 'student'), (3, 'instructor'), (4, 'admin');
INSERT INTO course (title) VALUES ('Advanced Databases'), ('Docker'), ('Git & GitHub');
INSERT INTO course_enrollment (student_id, course_id, progress) VALUES
    (1, 1, 100), (1, 2, 60), (2, 1, 30), (2, 3, 100), (1, 3, 0);
INSERT INTO certificate (course_id, student_id) VALUES (1, 1), (3, 2);
SQL

# The Academy opens psql connected to this database (it reads this line).
sed -i '/^export PGDATABASE=/d' ~/.bashrc
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database."
