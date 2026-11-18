# Solutions - Views & Materialized Views

## Tier 1

**1.1**
```sql
CREATE VIEW sold_laptops AS
SELECT * FROM transaction WHERE product = 'Laptop';
```

**1.2**
```sql
SELECT customer_name, price FROM sold_laptops;
```
then `\w 1.2.sql`

**1.3**
```sql
SELECT pg_get_viewdef('sold_laptops', true);
```
then `\w 1.3.sql`

**1.4** `\dv`, `\d+ sold_laptops`, `SELECT schemaname, viewname FROM pg_catalog.pg_views;`

## Tier 2

**2.1**
```sql
CREATE VIEW customer_spend AS
SELECT customer_name,
       SUM(quantity * price) AS total_spent,
       COUNT(*)              AS orders
FROM transaction
GROUP BY customer_name;
```

**2.2**
```sql
DELETE FROM sold_laptops
WHERE customer_name = 'Fatima' AND sale_date = '2024-01-15';

SELECT * FROM transaction WHERE customer_name = 'Fatima';   -- gone from the table too
```

**2.3**
```sql
CREATE MATERIALIZED VIEW sold_phones AS
SELECT * FROM transaction WHERE product = 'Phone';
```

**2.4**
```sql
INSERT INTO transaction (sale_date, customer_name, product, quantity, price)
VALUES ('2024-01-20', 'Fatima', 'Phone', 1, 1800.00);

SELECT * FROM sold_phones;                 -- not there yet: the data is stored
REFRESH MATERIALIZED VIEW sold_phones;
SELECT * FROM sold_phones;                 -- now it is
```

## Tier 3

**3.1**
```sql
CREATE VIEW big_spenders AS
SELECT customer_name, total_spent
FROM customer_spend
WHERE total_spent > 1500;
```

**3.2**
```sql
CREATE MATERIALIZED VIEW product_sales AS
SELECT product,
       SUM(quantity)         AS units_sold,
       SUM(quantity * price) AS revenue
FROM transaction
GROUP BY product;

CREATE UNIQUE INDEX product_sales_product_idx ON product_sales (product);

-- later, without blocking readers:
REFRESH MATERIALIZED VIEW CONCURRENTLY product_sales;
```
