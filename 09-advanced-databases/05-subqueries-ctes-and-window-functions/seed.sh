#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "my_db" database for this section:
# person/car (subqueries), department/employee (CTEs), transaction (window functions).
set -euo pipefail
SB="$HOME/sandbox"; DB=my_db
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
CREATE TYPE gender AS ENUM ('MALE', 'FEMALE', 'M', 'F');

CREATE TABLE person (
  id                BIGSERIAL,
  first_name        VARCHAR(50) NOT NULL,
  last_name         VARCHAR(50) NOT NULL,
  gender            gender NOT NULL,
  dob               DATE NOT NULL,
  phone_number      VARCHAR(15),
  country_of_origin VARCHAR(50) NOT NULL,
  CONSTRAINT pk_person_id PRIMARY KEY (id),
  CONSTRAINT unique_phone_number UNIQUE (phone_number)
);
CREATE TABLE car (
  id          BIGSERIAL,
  brand       VARCHAR(50) NOT NULL,
  model       VARCHAR(50) NOT NULL,
  price       NUMERIC(10,2) DEFAULT 0.0,
  mileage     NUMERIC(10,2) DEFAULT 0.0,
  is_electric BOOLEAN DEFAULT FALSE,
  owner_id    BIGINT,
  CONSTRAINT pk_car_id PRIMARY KEY (id),
  CONSTRAINT fk_car_owner_id FOREIGN KEY (owner_id) REFERENCES person(id)
);
INSERT INTO person (first_name, last_name, gender, dob, phone_number, country_of_origin) VALUES
  ('John',     'Doe',       'MALE',   '1985-02-15', '1234567890', 'USA'),
  ('Jane',     'Smith',     'FEMALE', '1990-06-24', '0987654321', 'Canada'),
  ('Ahmed',    'Hassan',    'MALE',   '1975-01-20', '5551112222', 'Egypt'),
  ('Fatima',   'Ali',       'FEMALE', '1988-04-12', '5553334444', 'Pakistan'),
  ('Ravi',     'Sharma',    'MALE',   '1980-05-16', '5555556666', 'India'),
  ('Lakshmi',  'Rao',       'FEMALE', '1992-09-21', '5557778888', 'India'),
  ('David',    'Goldstein', 'MALE',   '1987-03-10', '5559990000', 'Israel'),
  ('Sarah',    'Levy',      'FEMALE', '1991-07-19', '5551113333', 'Israel'),
  ('Carlos',   'Martinez',  'MALE',   '1984-11-04', '5552224444', 'Mexico'),
  ('Maria',    'Gomez',     'FEMALE', '1993-02-23', '5556667777', 'Mexico'),
  ('Cheng',    'Wei',       'MALE',   '1982-06-18', '5558889999', 'China'),
  ('Mei',      'Lin',       'FEMALE', '1989-08-25', '5557770000', 'China'),
  ('Samuel',   'Olu',       'MALE',   '1985-10-14', '5551115555', 'Nigeria'),
  ('Adamu',    'Yakubu',    'MALE',   '1994-11-30', '5553336666', 'Nigeria'),
  ('Aisha',    'Mohammed',  'FEMALE', '1990-03-12', '5554447777', 'Saudi Arabia'),
  ('James',    'Brown',     'MALE',   '1991-04-22', '5556660000', 'UK'),
  ('Yuki',     'Tanaka',    'FEMALE', '1990-12-15', '5551239999', 'Japan'),
  ('Santiago', 'Perez',     'MALE',   '1983-07-09', '5551234444', 'Argentina'),
  ('Isaac',    'Cohen',     'MALE',   '1979-11-22', '5559991111', 'USA'),
  ('Mia',      'Johnson',   'FEMALE', '1995-01-02', '5558886666', 'USA');
INSERT INTO car (brand, model, price, mileage, is_electric, owner_id) VALUES
  ('Tesla',      'Model S',   79999.99, 12000, TRUE,  1),
  ('Toyota',     'Corolla',   19999.99, 30000, FALSE, 2),
  ('BMW',        'i8',       140000.00, 15000, TRUE,  3),
  ('Ford',       'F-150',     35000.00, 50000, FALSE, 4),
  ('Honda',      'Civic',     22000.00, 35000, FALSE, 5),
  ('Chevrolet',  'Bolt',      37000.00,  8000, TRUE,  6),
  ('Audi',       'A4',        45000.00, 25000, FALSE, 7),
  ('Nissan',     'Altima',    23000.00, 27000, FALSE, 8),
  ('Volkswagen', 'Jetta',     28000.00, 20000, FALSE, 9),
  ('Hyundai',    'Elantra',   19000.00, 40000, FALSE, 10),
  ('Tesla',      'Model 3',   39999.99,  5000, TRUE,  11),
  ('Toyota',     'Prius',     24000.00, 22000, FALSE, 12),
  ('BMW',        'X5',        60000.00, 18000, FALSE, 13),
  ('Mercedes',   'C-Class',   55000.00, 16000, FALSE, 14),
  ('Honda',      'Accord',    27000.00, 35000, FALSE, 15),
  ('Tesla',      'Model Y',   52000.00,  3000, TRUE,  1),
  ('Fiat',       '500',       12000.00, 60000, FALSE, 3);

CREATE TABLE department (
  id   SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL
);
CREATE TABLE employee (
  id            SERIAL PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  department_id INT NOT NULL REFERENCES department(id)
);
INSERT INTO department (name) VALUES ('Sales'), ('Marketing'), ('IT'), ('HR'), ('Finance');
INSERT INTO employee (name, department_id) VALUES
  ('John Doe', 1), ('Jane Smith', 2), ('Sam Johnson', 1), ('Sara Davis', 3),
  ('David Brown', 4), ('Emily White', 5), ('Michael Green', 1), ('Anna Black', 2),
  ('Tom Harris', 3), ('Karen Lee', 4), ('Jason Martin', 5), ('Nancy Wright', 1),
  ('Ethan Clark', 2), ('Olivia Turner', 3), ('Mason Walker', 4), ('Sophia Young', 5),
  ('Logan Hill', 1), ('Chloe Adams', 2), ('Liam Baker', 3), ('Ava Carter', 5);

CREATE TABLE transaction (
  id            SERIAL PRIMARY KEY,
  sale_date     DATE NOT NULL,
  customer_name VARCHAR(100) NOT NULL,
  product       VARCHAR(100) NOT NULL,
  quantity      INT NOT NULL CHECK (quantity > 0),
  price         DECIMAL(10, 2) NOT NULL CHECK (price > 0)
);
INSERT INTO transaction (sale_date, customer_name, product, quantity, price) VALUES
  ('2024-01-01', 'John',     'Laptop',     1, 1200.00),
  ('2024-01-02', 'John',     'Mouse',      2,   25.00),
  ('2024-01-05', 'John',     'Keyboard',   1,  100.00),
  ('2024-01-07', 'John',     'Laptop',     1, 1200.00),
  ('2024-01-09', 'John',     'Monitor',    1,  300.00),
  ('2024-01-02', 'Fatima',   'Phone',      2,  700.00),
  ('2024-01-03', 'Fatima',   'Tablet',     1,  500.00),
  ('2024-01-08', 'Fatima',   'Headphones', 1,  150.00),
  ('2024-01-11', 'Fatima',   'Phone',      1,  700.00),
  ('2024-01-15', 'Fatima',   'Laptop',     1, 1200.00),
  ('2024-01-04', 'Ravi',     'Monitor',    1,  300.00),
  ('2024-01-10', 'Ravi',     'Keyboard',   1,  100.00),
  ('2024-01-12', 'Ravi',     'Laptop',     1, 1200.00),
  ('2024-01-01', 'David',    'Tablet',     1,  500.00),
  ('2024-01-06', 'David',    'Mouse',      3,   25.00),
  ('2024-01-13', 'David',    'Phone',      1,  700.00),
  ('2024-01-05', 'Aisha',    'Laptop',     1, 1200.00),
  ('2024-01-14', 'Aisha',    'Headphones', 1,  150.00),
  ('2024-01-09', 'Mohammed', 'Phone',      1,  700.00),
  ('2024-01-18', 'Mohammed', 'Laptop',     1, 1200.00);
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
