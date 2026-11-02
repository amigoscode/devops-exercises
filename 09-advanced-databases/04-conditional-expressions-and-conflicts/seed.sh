#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "my_db" database for this section.
set -euo pipefail
SB="$HOME/sandbox"; DB=my_db
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
CREATE TYPE gender AS ENUM ('MALE', 'FEMALE', 'M', 'F');

CREATE TABLE person (
  id                BIGSERIAL PRIMARY KEY,
  first_name        VARCHAR(50) NOT NULL,
  last_name         VARCHAR(50) NOT NULL,
  gender            gender NOT NULL,
  dob               DATE NOT NULL,
  phone_number      VARCHAR(50) UNIQUE,
  country_of_origin VARCHAR(50) NOT NULL
);
INSERT INTO person (id, first_name, last_name, gender, dob, phone_number, country_of_origin) VALUES
  (1,  'Annette', 'Torres',    'MALE',   '1964-01-05', NULL,                   'Paraguay'),
  (2,  'Renee',   'Hensley',   'M',      '1998-01-03', NULL,                   'Senegal'),
  (3,  'Mark',    'Barajas',   'FEMALE', '1985-10-17', '001-308-674-9013x649', 'Rwanda'),
  (4,  'Barbara', 'Evans',     'MALE',   '1945-11-02', '(490)911-1576',        'Iran'),
  (5,  'Eric',    'Chavez',    'MALE',   '1995-08-22', NULL,                   'Western Sahara'),
  (6,  'Monique', 'Mills',     'F',      '1970-06-25', '1-510-583-7735x008',   'United Kingdom'),
  (7,  'Roy',     'Nguyen',    'FEMALE', '1983-03-13', '353-972-6717',         'Mauritania'),
  (8,  'Leonard', 'Cain',      'M',      '1979-04-15', NULL,                   'San Marino'),
  (9,  'Tonya',   'Anderson',  'FEMALE', '1992-10-05', '914-342-4165x780',     'Ecuador'),
  (10, 'Harold',  'Rodriguez', 'M',      '1969-08-31', '001-456-931-9891',     'Kyrgyzstan');
SELECT setval('person_id_seq', 10);

CREATE TABLE campaign (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  clicks      INTEGER NOT NULL,
  impressions INTEGER NOT NULL
);
INSERT INTO campaign (name, clicks, impressions) VALUES
  ('Spring sale',  120,  4000),
  ('Black Friday', 950, 10000),
  ('Newsletter',     0,     0),
  ('Retargeting',   45,   900),
  ('Brand video',   30,     0),
  ('Podcast',        7,  1000);

-- Which lectures each enrollment has completed. It was created without a unique key,
-- so retries and double clicks left duplicate (enrollment_id, lecture_id) rows.
CREATE TABLE lecture_progress (
  id            BIGSERIAL PRIMARY KEY,
  enrollment_id INTEGER NOT NULL,
  lecture_id    INTEGER NOT NULL,
  completed     BOOLEAN NOT NULL,
  updated_at    TIMESTAMPTZ NOT NULL
);
INSERT INTO lecture_progress (enrollment_id, lecture_id, completed, updated_at) VALUES
  (1, 1, TRUE,  '2024-05-01 10:00+00'),
  (1, 2, FALSE, '2024-05-01 10:05+00'),
  (1, 3, FALSE, '2024-05-01 10:10+00'),
  (2, 1, TRUE,  '2024-05-02 09:00+00'),
  (2, 3, TRUE,  '2024-05-02 09:30+00'),
  (1, 2, TRUE,  '2024-05-03 08:00+00'),
  (2, 1, FALSE, '2024-05-01 07:00+00'),
  (3, 1, FALSE, '2024-05-04 12:00+00');

-- Tonight's batch of progress events from the video player.
CREATE TABLE incoming_progress (
  enrollment_id INTEGER NOT NULL,
  lecture_id    INTEGER NOT NULL,
  completed     BOOLEAN NOT NULL,
  event_at      TIMESTAMPTZ NOT NULL
);
INSERT INTO incoming_progress VALUES
  (1, 3, TRUE,  '2024-06-01 10:00+00'),
  (1, 4, TRUE,  '2024-06-01 10:05+00'),
  (3, 2, TRUE,  '2024-06-02 11:00+00'),
  (3, 2, FALSE, '2024-06-02 11:30+00'),
  (2, 3, FALSE, '2024-04-01 09:00+00'),
  (2, 2, TRUE,  '2024-06-03 08:00+00');
SQL

# An untouched copy the grader runs your saved queries against, so whatever you do
# to the data while experimenting can't change what a query is expected to return.
dropdb --if-exists "${DB}_ref"; createdb -T "$DB" "${DB}_ref"

# The Academy opens psql in this database: it reads this exact line from ~/.bashrc.
touch ~/.bashrc
sed -i '/^export PGDATABASE=/d' ~/.bashrc
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database."
