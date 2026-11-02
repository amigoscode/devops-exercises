#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "my_db" database for this section.
set -euo pipefail
SB="$HOME/sandbox"; DB=my_db
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
-- An old table that lives in public and shares its name with the one you'll build.
CREATE TABLE deployment (
  id   SERIAL PRIMARY KEY,
  name VARCHAR(100)
);
INSERT INTO deployment (name) VALUES ('legacy-cron');

CREATE TABLE customer (
  id     SERIAL PRIMARY KEY,
  name   TEXT NOT NULL,
  emails VARCHAR(50)[]
);
INSERT INTO customer (name, emails) VALUES
  ('John',   ARRAY['john@gmail.com', 'j@hotmail.com']),
  ('Kai',    ARRAY['kai@cool.com']),
  ('Jamila', ARRAY['jamila@amigoscode.com']),
  ('Ola',    ARRAY['ola@amigoscode.com', 'ola@yahoo.com', 'ola.n@gmail.com']);

CREATE TABLE product (
  id         SERIAL PRIMARY KEY,
  name       VARCHAR(50) NOT NULL,
  attributes JSONB
);
INSERT INTO product (name, attributes) VALUES
  ('iPhone',  '{"price": 900, "water_resistant": true,  "ram": "4GB"}'),
  ('Samsung', '{"price": 700, "water_resistant": true,  "ram": "8GB"}'),
  ('Pixel',   '{"price": 650, "water_resistant": false, "ram": "8GB"}'),
  ('Nokia',   '{"price": 120, "water_resistant": false, "ram": "2GB"}'),
  ('OnePlus', '{"price": 550, "water_resistant": true,  "ram": "12GB"}');

CREATE TABLE person (
  id                BIGSERIAL PRIMARY KEY,
  first_name        VARCHAR(50) NOT NULL,
  last_name         VARCHAR(50) NOT NULL,
  dob               DATE NOT NULL,
  country_of_origin VARCHAR(50) NOT NULL
);
INSERT INTO person (first_name, last_name, dob, country_of_origin) VALUES
  ('Annette', 'Torres',    '1964-01-05', 'Paraguay'),
  ('Renee',   'Hensley',   '1998-01-03', 'Senegal'),
  ('Mark',    'Barajas',   '1985-10-17', 'Rwanda'),
  ('Barbara', 'Evans',     '1945-11-02', 'Iran'),
  ('Eric',    'Chavez',    '1995-08-22', 'Western Sahara'),
  ('Monique', 'Mills',     '1970-06-25', 'United Kingdom'),
  ('Roy',     'Nguyen',    '1983-03-13', 'Mauritania'),
  ('Leonard', 'Cain',      '1979-04-15', 'San Marino'),
  ('Tonya',   'Anderson',  '1992-10-05', 'Ecuador'),
  ('Harold',  'Rodriguez', '1969-08-31', 'Kyrgyzstan');

CREATE TABLE subscription (
  id         SERIAL PRIMARY KEY,
  customer   TEXT NOT NULL,
  plan       TEXT NOT NULL,
  started_at TIMESTAMP NOT NULL,
  duration   INTERVAL NOT NULL
);
INSERT INTO subscription (customer, plan, started_at, duration) VALUES
  ('Alice', 'monthly',   '2024-12-15 09:30:00', '1 month'),
  ('Bob',   'yearly',    '2024-03-01 12:00:00', '1 year'),
  ('Chen',  'trial',     '2024-12-20 18:45:00', '14 days'),
  ('Dara',  'monthly',   '2024-11-02 08:00:00', '1 month'),
  ('Eve',   'quarterly', '2025-10-10 10:10:00', '3 months'),
  ('Femi',  'yearly',    '2023-06-30 23:00:00', '2 years'),
  ('Gus',   'trial',     '2024-12-25 22:00:00', '7 days'),
  ('Hana',  'daily',     '2024-12-31 23:30:00', '1 day 1 hour');

-- Imported from a spreadsheet: dates as UK-format text.
CREATE TABLE signup (
  id           SERIAL PRIMARY KEY,
  email        TEXT NOT NULL,
  signed_up_on TEXT NOT NULL
);
INSERT INTO signup (email, signed_up_on) VALUES
  ('ana@example.com', '31/01/2024'),
  ('ben@example.com', '05/03/2024'),
  ('cy@example.com',  '12/11/2023'),
  ('di@example.com',  '29/02/2024'),
  ('ed@example.com',  '01/12/2024');
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
