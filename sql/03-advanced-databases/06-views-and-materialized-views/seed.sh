#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "sales" database for this section.
set -euo pipefail
SB="$HOME/sandbox"; DB=sales
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

dropdb --if-exists "$DB"; createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
CREATE TABLE transaction (
    id            SERIAL PRIMARY KEY,
    sale_date     DATE NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    product       VARCHAR(100) NOT NULL,
    quantity      INT NOT NULL CHECK (quantity > 0),
    price         DECIMAL(10, 2) NOT NULL CHECK (price > 0)
);

INSERT INTO transaction (sale_date, customer_name, product, quantity, price) VALUES
('2024-01-01', 'John', 'Laptop', 1, 1200.00),
('2024-01-02', 'John', 'Mouse', 2, 25.00),
('2024-01-05', 'John', 'Keyboard', 1, 100.00),
('2024-01-07', 'John', 'Laptop', 1, 1200.00),
('2024-01-09', 'John', 'Monitor', 1, 300.00),
('2024-01-02', 'Fatima', 'Phone', 2, 700.00),
('2024-01-03', 'Fatima', 'Tablet', 1, 500.00),
('2024-01-08', 'Fatima', 'Headphones', 1, 150.00),
('2024-01-11', 'Fatima', 'Phone', 1, 700.00),
('2024-01-15', 'Fatima', 'Laptop', 1, 1200.00),
('2024-01-04', 'Ravi', 'Monitor', 1, 300.00),
('2024-01-10', 'Ravi', 'Keyboard', 1, 100.00),
('2024-01-12', 'Ravi', 'Laptop', 1, 1200.00),
('2024-01-01', 'David', 'Tablet', 1, 500.00),
('2024-01-06', 'David', 'Mouse', 3, 25.00),
('2024-01-13', 'David', 'Phone', 1, 700.00),
('2024-01-05', 'Aisha', 'Laptop', 1, 1200.00),
('2024-01-14', 'Aisha', 'Headphones', 1, 150.00),
('2024-01-09', 'Mohammed', 'Phone', 1, 700.00),
('2024-01-18', 'Mohammed', 'Laptop', 1, 1200.00);
SQL

# The Academy opens psql connected to this database (it reads this line).
sed -i '/^export PGDATABASE=/d' ~/.bashrc
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database."
