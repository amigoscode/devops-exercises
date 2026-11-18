#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "normalization" database: the
# course's examples, each one breaking a normal form, ready for you to split.
set -euo pipefail
SB="$HOME/sandbox"; DB=normalization
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
-- 1NF + 2NF examples: a list in phone_numbers, an address with its postcode
CREATE TABLE user_profile (
    id            BIGSERIAL PRIMARY KEY,
    first_name    TEXT NOT NULL,
    last_name     TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    gender        TEXT NOT NULL CHECK (gender IN ('MALE', 'FEMALE')),
    phone_numbers TEXT,
    address       TEXT NOT NULL,
    postcode      TEXT NOT NULL,
    created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
INSERT INTO user_profile (first_name, last_name, email, gender, phone_numbers, address, postcode, created_at) VALUES
  ('James',  'Bond',  'jamesbond@gmail.com', 'MALE',   '007,0071,0072',                       'London',     'NW1 1PK', '2020-11-20 09:00:00'),
  ('Mariam', 'Ali',   'm.ali@gmail.com',     'FEMALE', '07700900123,07700900124',             'Manchester', 'M1 2AB',  '2020-11-24 23:42:47'),
  ('Joe',    'James', 'j.james@gmail.com',   'MALE',   '07700900200',                         'London',     'E1 6AN',  '2020-11-24 23:43:10'),
  ('Jamila', 'Ahmed', 'jamila@gmail.com',    'FEMALE', '07700900310,07700900311,07700900312', 'Birmingham', 'B1 1AA',  '2020-11-25 08:15:00'),
  ('Alex',   'Smith', 'alex2000@gmail.com',  'MALE',   '07700900400',                         'Leeds',      'LS1 4DY', '2020-11-25 10:30:00'),
  ('Bob',    'Bill',  'bobbill@gmail.com',   'MALE',   NULL,                                  'Bristol',    'BS1 5TR', '2020-11-26 18:05:00');

CREATE TABLE youtube_account (
    id         BIGINT PRIMARY KEY REFERENCES user_profile (id),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
INSERT INTO youtube_account (id, created_at) VALUES
  (1, '2020-11-20 09:05:00'), (2, '2020-11-24 23:44:36'), (3, '2020-11-24 23:50:00'), (5, '2020-11-25 10:44:36');

CREATE TABLE youtube_channel (
    id                 BIGSERIAL PRIMARY KEY,
    youtube_account_id BIGINT NOT NULL REFERENCES youtube_account (id),
    channel_name       TEXT NOT NULL UNIQUE,
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
INSERT INTO youtube_channel (youtube_account_id, channel_name, created_at) VALUES
  (2, 'MariamBeauty',          '2020-11-24 23:47:05'),
  (3, 'JoeTech',               '2020-11-24 23:47:50'),
  (5, 'AlexTutorials',         '2020-11-25 10:47:50'),
  (2, 'MariamBeautyTutorials', '2020-11-26 12:00:00'),
  (1, 'BondGadgets',           '2020-11-27 07:00:00');

-- 2NF example: the category depends on the channel only, not on the whole key
CREATE TABLE channel_subscriber (
    youtube_account_id       BIGINT REFERENCES youtube_account (id),
    youtube_channel_id       BIGINT REFERENCES youtube_channel (id),
    youtube_channel_category TEXT NOT NULL,
    created_at               TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (youtube_account_id, youtube_channel_id)
);
INSERT INTO channel_subscriber VALUES
  (3, 1, 'Beauty',    '2020-11-25 22:19:41'), (5, 1, 'Beauty',    '2020-11-25 22:19:58'),
  (1, 1, 'Beauty',    '2020-11-26 09:00:00'), (2, 2, 'Tech',      '2020-11-25 22:20:10'),
  (5, 2, 'Tech',      '2020-11-26 11:11:11'), (2, 3, 'Education', '2020-11-25 22:21:00'),
  (3, 3, 'Education', '2020-11-26 14:30:00'), (1, 3, 'Education', '2020-11-27 08:00:00'),
  (3, 4, 'Beauty',    '2020-11-27 12:00:00'), (2, 5, 'Tech',      '2020-11-27 13:00:00'),
  (5, 5, 'Tech',      '2020-11-28 16:45:00');

-- 3NF example (Wikipedia): winner_date_of_birth depends on the key only through winner
CREATE TABLE tournament_winner (
    tournament           TEXT,
    year                 INT,
    winner               TEXT NOT NULL,
    winner_date_of_birth DATE NOT NULL,
    PRIMARY KEY (tournament, year)
);
INSERT INTO tournament_winner VALUES
  ('Indiana Invitational', 1998, 'Al Fredrickson', '1975-07-21'),
  ('Cleveland Open',       1999, 'Bob Albertson',  '1968-09-28'),
  ('Des Moines Masters',   1999, 'Al Fredrickson', '1975-07-21'),
  ('Indiana Invitational', 1999, 'Chip Masterson', '1977-03-14'),
  ('Cleveland Open',       2000, 'Al Fredrickson', '1975-07-21'),
  ('Des Moines Masters',   2000, 'Chip Masterson', '1977-03-14'),
  ('Indiana Invitational', 2000, 'Bob Albertson',  '1968-09-28'),
  ('Cleveland Open',       2001, 'Dana Whitfield', '1980-11-02');
SQL

# An untouched copy: the grader runs your saved queries against it, and compares
# the data in your split tables with the original rows kept here.
dropdb --if-exists "${DB}_ref"; createdb -T "$DB" "${DB}_ref"

# The Academy opens psql connected to this database: it reads this exact line.
grep -qx "export PGDATABASE=$DB" ~/.bashrc 2>/dev/null || echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "seed: could not set PGDATABASE in ~/.bashrc" >&2; exit 1; }
echo "Sandbox ready: psql opens connected to the '$DB' database."
