#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "youtube" database as section 2
# left it: user_profile, youtube_account, youtube_channel, channel_subscriber and the
# course's sample data. You add the video tables.
set -euo pipefail
SB="$HOME/sandbox"; DB=youtube
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS user_profile (
    id BIGSERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    gender TEXT CHECK (gender IN ('MALE', 'FEMALE')) NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
CREATE TABLE IF NOT EXISTS youtube_account (
    id BIGINT PRIMARY KEY REFERENCES user_profile (id),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
CREATE TABLE IF NOT EXISTS youtube_channel (
    id BIGSERIAL PRIMARY KEY,
    youtube_account_id BIGINT NOT NULL REFERENCES youtube_account (id),
    channel_name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
CREATE TABLE IF NOT EXISTS channel_subscriber (
    youtube_account_id BIGINT REFERENCES youtube_account (id),
    youtube_channel_id BIGINT REFERENCES youtube_channel (id),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (youtube_account_id, youtube_channel_id)
);

INSERT INTO user_profile (id, first_name, last_name, email, gender, created_at) VALUES
  (1, 'Mariam', 'Ali',   'm.ali@gmail.com',    'FEMALE', '2020-11-24 23:42:47'),
  (2, 'Joe',    'James', 'j.james@gmail.com',  'MALE',   '2020-11-24 23:42:47'),
  (3, 'Jamila', 'Ahmed', 'jamila@gmail.com',   'FEMALE', '2020-11-24 23:42:47'),
  (4, 'Alex',   'Smith', 'alex2000@gmail.com', 'MALE',   '2020-11-24 23:42:47'),
  (5, 'Bob',    'Bill',  'bobbill@gmail.com',  'MALE',   '2020-11-24 23:42:47');
INSERT INTO youtube_account (id, created_at) VALUES
  (1, '2020-11-24 23:44:36'), (2, '2020-11-24 23:00:36'), (4, '2020-11-24 10:44:36');
INSERT INTO youtube_channel (id, youtube_account_id, channel_name, created_at) VALUES
  (1, 1, 'MariamBeauty',          '2020-11-24 23:47:05'),
  (4, 1, 'MariamBeautyTutorials', '2020-11-24 23:47:05'),
  (2, 2, 'JoeTech',               '2020-11-24 23:47:50'),
  (3, 4, 'AlexTutorials',         '2020-11-24 23:47:50');
INSERT INTO channel_subscriber (youtube_account_id, youtube_channel_id, created_at) VALUES
  (1, 2, '2020-11-25 22:19:41'), (1, 3, '2020-11-25 22:19:58'),
  (4, 1, '2020-11-25 22:19:58'), (2, 1, '2020-11-25 22:19:58');
-- ids were set by hand: move the sequences past them
SELECT setval('user_profile_id_seq', 5);
SELECT setval('youtube_channel_id_seq', 4);
SQL

# The Academy opens psql connected to this database: it reads this exact line.
grep -qx "export PGDATABASE=$DB" ~/.bashrc 2>/dev/null || echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "seed: could not set PGDATABASE in ~/.bashrc" >&2; exit 1; }
echo "Sandbox ready: psql opens connected to the '$DB' database."
