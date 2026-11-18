#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + an empty "youtube" database: you build
# the tables yourself, then load the course's sample data from sample-data.sql.
set -euo pipefail
SB="$HOME/sandbox"; DB=youtube
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"

cat > "$SB/sample-data.sql" <<'SQL'
-- The course's sample data for user_profile, youtube_account, youtube_channel and
-- channel_subscriber. Load it from psql with:  \i sample-data.sql
-- It empties the four tables first, so you can load it again after fixing a table.
TRUNCATE user_profile, youtube_account, youtube_channel, channel_subscriber;

-- users
INSERT INTO user_profile (id, first_name, last_name, email, gender, created_at) VALUES
  (1, 'Mariam', 'Ali',   'm.ali@gmail.com',    'FEMALE', '2020-11-24 23:42:47'),
  (2, 'Joe',    'James', 'j.james@gmail.com',  'MALE',   '2020-11-24 23:42:47'),
  (3, 'Jamila', 'Ahmed', 'jamila@gmail.com',   'FEMALE', '2020-11-24 23:42:47'),
  (4, 'Alex',   'Smith', 'alex2000@gmail.com', 'MALE',   '2020-11-24 23:42:47'),
  (5, 'Bob',    'Bill',  'bobbill@gmail.com',  'MALE',   '2020-11-24 23:42:47');

-- accounts (one-to-one: the account id IS the profile id; Jamila and Bob have none)
INSERT INTO youtube_account (id, created_at) VALUES
  (1, '2020-11-24 23:44:36'),
  (2, '2020-11-24 23:00:36'),
  (4, '2020-11-24 10:44:36');

-- channels (one-to-many: Mariam's account owns two)
INSERT INTO youtube_channel (id, youtube_account_id, channel_name, created_at) VALUES
  (1, 1, 'MariamBeauty',          '2020-11-24 23:47:05'),
  (4, 1, 'MariamBeautyTutorials', '2020-11-24 23:47:05'),
  (2, 2, 'JoeTech',               '2020-11-24 23:47:50'),
  (3, 4, 'AlexTutorials',         '2020-11-24 23:47:50');

-- subscriptions (many-to-many)
INSERT INTO channel_subscriber (youtube_account_id, youtube_channel_id, created_at) VALUES
  (1, 2, '2020-11-25 22:19:41'),
  (1, 3, '2020-11-25 22:19:58'),
  (4, 1, '2020-11-25 22:19:58'),
  (2, 1, '2020-11-25 22:19:58');

-- The rows above set their ids by hand, so move the BIGSERIAL sequences past them:
-- the next profile or channel you insert gets id 6 / 5 instead of clashing with 1.
SELECT setval(pg_get_serial_sequence('user_profile', 'id'), (SELECT max(id) FROM user_profile));
SELECT setval(pg_get_serial_sequence('youtube_channel', 'id'), (SELECT max(id) FROM youtube_channel));
SQL

# The Academy opens psql connected to this database: it reads this exact line.
grep -qx "export PGDATABASE=$DB" ~/.bashrc 2>/dev/null || echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "seed: could not set PGDATABASE in ~/.bashrc" >&2; exit 1; }
echo "Sandbox ready: psql opens connected to the empty '$DB' database."
