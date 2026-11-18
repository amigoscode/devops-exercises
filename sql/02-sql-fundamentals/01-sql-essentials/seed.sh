#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "my_db" database for this section.
set -euo pipefail
SB="$HOME/sandbox"; DB=my_db
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
# A leftover experiment for 1.2 to drop.
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" -c "CREATE TABLE foo_bar (id INTEGER);"

# The person table from "Up and Running with SQL", ready to run with \i (3.1).
cat > "$SB/query.sql" <<'SQL'
CREATE TABLE person (
    id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender CHAR(1),
    dob DATE,
    phone_number VARCHAR(15),
    country_of_origin VARCHAR(50)
);
SQL

# The Academy opens psql connected to the database named here (exactly this line).
sed -i '/^export PGDATABASE=/d' ~/.bashrc 2>/dev/null || true
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "seed: could not write PGDATABASE to ~/.bashrc" >&2; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database."
