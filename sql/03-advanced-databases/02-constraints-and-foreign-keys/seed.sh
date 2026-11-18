#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "my_db" database for this section.
set -euo pipefail
SB="$HOME/sandbox"; DB=my_db
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
-- person and car as they were before constraints: anything goes.
CREATE TABLE person (
  id                INTEGER,
  first_name        VARCHAR(50),
  last_name         VARCHAR(50),
  gender            CHAR(1),
  dob               DATE,
  phone_number      VARCHAR(15),
  country_of_origin VARCHAR(50),
  CONSTRAINT check_country_of_origin CHECK (country_of_origin IN ('UK', 'USA'))
);
INSERT INTO person VALUES
  (1, 'Jamila', 'Bob',    'F', '2000-09-30', '+447700900001', 'UK'),
  (2, 'John',   'Doe',    'M', '1985-02-15', '+12025550101',  'USA'),
  (3, 'Jane',   'Smith',  'F', '1990-06-24', NULL,            'USA'),
  (4, 'Ahmed',  'Hassan', 'M', '1975-01-20', '+447700900002', 'UK'),
  (5, 'Fatima', 'Ali',    'F', '1988-04-12', NULL,            'UK'),
  (6, 'James',  'Brown',  'M', '1991-04-22', '+447700900003', 'UK');

CREATE TABLE car (
  id          INTEGER,
  brand       VARCHAR(50),
  model       VARCHAR(50),
  price       NUMERIC(10,2),
  mileage     INTEGER,
  is_electric BOOLEAN,
  owner_id    INTEGER
);
INSERT INTO car VALUES
  (1, 'Tesla',  'Model S',    79999.99, 12000, TRUE,  2),
  (2, 'Toyota', 'Corolla',    19999.99, 30000, FALSE, 3),
  (3, 'BMW',    'i8',        140000.00, 15000, TRUE,  4),
  (4, 'Ford',   'F-150',      35000.00, 50000, FALSE, 2),
  (5, 'Tesla',  'Cybertruck', 99990.00,     0, TRUE,  NULL),
  (6, 'Honda',  'Civic',      22000.00, 35000, FALSE, NULL);

-- Legacy import: duplicate passport numbers and people who don't exist.
CREATE TABLE passport (
  id              SERIAL PRIMARY KEY,
  person_id       INTEGER NOT NULL,
  passport_number VARCHAR(20) NOT NULL,
  country         VARCHAR(50) NOT NULL
);
INSERT INTO passport (person_id, passport_number, country) VALUES
  (1,  'UK1234567', 'UK'),
  (2,  'US7654321', 'USA'),
  (3,  'US1111111', 'USA'),
  (4,  'UK2222222', 'UK'),
  (5,  'UK3333333', 'UK'),
  (2,  'US7654321', 'USA'),
  (99, 'UK9999999', 'UK'),
  (3,  'US1111111', 'USA'),
  (6,  'UK4444444', 'UK'),
  (42, 'US5555555', 'USA');

CREATE TABLE dealership (
  id   SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);
INSERT INTO dealership (name) VALUES ('North Motors'), ('City Cars'), ('Empty Lot');

CREATE TABLE car_listing (
  id            SERIAL PRIMARY KEY,
  dealership_id INTEGER NOT NULL,
  title         TEXT NOT NULL,
  price         NUMERIC(10,2) NOT NULL,
  CONSTRAINT fk_car_listing_dealership_id
    FOREIGN KEY (dealership_id) REFERENCES dealership(id) ON DELETE CASCADE
);
INSERT INTO car_listing (dealership_id, title, price) VALUES
  (1, 'Audi A4 2019',         18500.00),
  (1, 'Nissan Leaf 2021',     16900.00),
  (1, 'VW Golf 2018',         11250.00),
  (2, 'Kia Niro 2022',        24990.00),
  (2, 'Mercedes C-Class 2020', 27500.00);
SQL

# The Academy opens psql in this database: it reads this exact line from ~/.bashrc.
touch ~/.bashrc
sed -i '/^export PGDATABASE=/d' ~/.bashrc
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database."
