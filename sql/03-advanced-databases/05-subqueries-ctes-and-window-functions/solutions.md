# Solutions - Subqueries, CTEs & Window Functions

Run each query in `psql` (you land in `my_db`), then save it with
`\w <task>.sql`.

## Tier 1 - Subqueries

**1.1**
```sql
SELECT first_name, last_name
FROM person
WHERE id IN (
  SELECT owner_id FROM car
  WHERE price > (SELECT AVG(price) FROM car)
);
\w 1.1.sql
```
The inner `SELECT AVG(price)` is a scalar subquery (one value); the middle one returns
a list for `IN`. A `JOIN` instead would list John twice (both his Teslas qualify).

**1.2**
```sql
SELECT first_name, last_name
FROM person
WHERE NOT EXISTS (
  SELECT 1 FROM car WHERE car.owner_id = person.id
);
\w 1.2.sql
```

**1.3**
```sql
SELECT first_name, last_name
FROM person
WHERE id IN (
  SELECT owner_id FROM car
  WHERE price < ALL (SELECT price FROM car WHERE brand = 'Tesla')
);
\w 1.3.sql
```
`< ANY` would mean "cheaper than at least one Tesla", i.e. cheaper than the cheapest
is not required: far more people match.

**1.4**
```sql
SELECT first_name, last_name
FROM person
WHERE id IN (
  SELECT owner_id FROM car
  GROUP BY owner_id
  HAVING count(*) > 1
);
\w 1.4.sql
```

## Tier 2 - Common table expressions

**2.1**
```sql
WITH it_employee AS (
  SELECT * FROM employee WHERE department_id = 3
)
SELECT it.name, department.name AS department
FROM it_employee AS it
JOIN department ON it.department_id = department.id;
\w 2.1.sql
```

**2.2**
```sql
WITH marketing AS (
  SELECT * FROM employee WHERE department_id = 2
),
it AS (
  SELECT * FROM employee WHERE department_id = 3
)
SELECT 'Marketing' AS department, marketing.name FROM marketing
UNION
SELECT 'IT' AS department, it.name FROM it;
\w 2.2.sql
```
Only the first CTE gets `WITH`; the rest are separated by commas, and there's no comma
before the main query.

**2.3**
```sql
WITH headcount AS (
  SELECT d.name, count(*) AS employees
  FROM department d
  JOIN employee e ON e.department_id = d.id
  GROUP BY d.name
),
average AS (
  SELECT AVG(employees) AS avg_employees FROM headcount
)
SELECT name, employees
FROM headcount, average
WHERE employees > avg_employees;
\w 2.3.sql
```
Only Sales (5) beats the average of 4.

## Tier 3 - Window functions on sales

**3.1**
```sql
SELECT customer_name, sale_date, product,
       ROW_NUMBER() OVER (PARTITION BY customer_name ORDER BY sale_date) AS purchase_number
FROM transaction;
\w 3.1.sql
```

**3.2**
```sql
SELECT customer_name, sale_date, product,
       SUM(price * quantity) OVER (PARTITION BY customer_name ORDER BY sale_date) AS running_total
FROM transaction;
\w 3.2.sql
```
With an `ORDER BY` in the window, `SUM` adds up the rows from the start of the
partition to the current one, instead of collapsing them like `GROUP BY`.

**3.3**
```sql
WITH ranked AS (
  SELECT customer_name, product, price,
         RANK() OVER (PARTITION BY customer_name ORDER BY price DESC) AS price_rank
  FROM transaction
)
SELECT customer_name, product, price
FROM ranked
WHERE price_rank = 1;
\w 3.3.sql
```
John bought two laptops at 1200: `RANK` gives both a 1, `ROW_NUMBER` would pick one.
(A window function can't go in `WHERE` directly, hence the CTE.)

**3.4**
```sql
SELECT customer_name, sale_date, price,
       LAG(price) OVER (PARTITION BY customer_name ORDER BY sale_date) AS previous_price
FROM transaction;
\w 3.4.sql
```

**3.5**
```sql
SELECT customer_name, sale_date, product,
       LAST_VALUE(product) OVER (
         PARTITION BY customer_name ORDER BY sale_date
         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS last_product
FROM transaction;
\w 3.5.sql
```
The default frame ends at the current row, so without the `ROWS BETWEEN ...` clause
`LAST_VALUE` just returns the current row's product.

**3.6** `LEAD` is the next row's value, `FIRST_VALUE` the first in the partition,
`NTH_VALUE(price, 3)` the third (needs the full frame too), and `NTILE(4)` splits the
ordered rows into 4 buckets of (nearly) equal size. With ties, `RANK` skips numbers
(1, 2, 2, 4) and `DENSE_RANK` doesn't (1, 2, 2, 3).
