# 06 · Views & Materialized Views

> Maps to **Advanced Databases → Section 15: Views & Materialized Views**
> (`CREATE VIEW`, `\dv`, `pg_views`, `pg_get_viewdef`, changing data through a view,
> `CREATE MATERIALIZED VIEW`, `REFRESH MATERIALIZED VIEW`)

A view is a saved query you can treat like a table. It hides a long query behind one
name, lets you hand a team a view instead of the raw table, and always shows the
current data. A materialized view stores the result instead, so it reads fast but goes
stale until you refresh it. Picking the right one is something you do every week on a
reporting or analytics team.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Views & Materialized Views** and press
`enter`. You land in `psql`, connected to the `sales` database. Run each query, then
save it with `\w 1.2.sql` (use the question's number). `:questions` shows the questions
again, `:check` grades your work, and `exit` takes you back with your progress saved.
Press `r` in the Academy for a fresh start.

---

The `sales` database has the `transaction` table from the videos: 20 sales with
`id`, `sale_date`, `customer_name`, `product`, `quantity` and `price`.

```sql
CREATE VIEW view_name AS
SELECT ... ;                                    -- runs the query every time you read it

CREATE MATERIALIZED VIEW mat_view_name AS
SELECT ... ;                                    -- stores the result now
REFRESH MATERIALIZED VIEW mat_view_name;        -- re-runs the query and stores it again
```

## Tier 1 - Views *(hint: `CREATE VIEW name AS SELECT ...;`)*

**1.1 (graded)** The team keeps running `SELECT * FROM transaction WHERE product =
'Laptop'`. Wrap that query in a view called `sold_laptops`, with every column of
`transaction`.

**1.2 (graded)** Using the view (not the table), list the `customer_name` and `price` of
every laptop sale. Save the query as `1.2.sql`.

**1.3 (graded)** A view only stores its query. Write a query that returns the SQL behind
`sold_laptops` with `pg_get_viewdef`. Save it as `1.3.sql`.

**1.4 (drill)** Explore the views you have: `\dv`, `\d+ sold_laptops`, and
`SELECT schemaname, viewname FROM pg_catalog.pg_views;` (look for yours among the
built-in ones). Then add a laptop sale to `transaction`, select from `sold_laptops`
again, and delete the test row.

## Tier 2 - Views that do more, and materialized views

**2.1 (graded)** Create a view `customer_spend` with exactly these columns:
`customer_name`, `total_spent` (the sum of `quantity * price` for that customer) and
`orders` (how many sales they have). One row per customer.

**2.2 (graded)** Fatima cancelled her laptop order from `2024-01-15`. Delete that sale
**through the `sold_laptops` view**, not the table. Delete that one row and nothing
else. Then check that the sale is also gone from `transaction`.

**2.3 (graded)** Create a materialized view `sold_phones` with every column of
`transaction` for each phone sale (`product = 'Phone'`).

**2.4 (graded)** Fatima just bought another phone: `2024-01-20`, quantity `1`, price
`1800.00`. Insert the sale into `transaction` and check: is it in `sold_phones`? Make
`sold_phones` show it.

## Tier 3 - Finance dashboard *(goal only)*

> **Scenario:** Finance wants two things on their dashboard: a list of the customers
> who matter most, and per-product totals that load instantly.

**3.1 (graded)** Create a view `big_spenders` with the columns `customer_name` and
`total_spent`, listing only customers who have spent **more than 1500** in total. Build it
on top of your `customer_spend` view, so the spending logic lives in one place.

**3.2 (graded)** Create a materialized view `product_sales` with the columns `product`,
`units_sold` (total quantity) and `revenue` (total `quantity * price`), one row per
product. It must match today's data. Give it a **unique index on `product`** so the
dashboard can look a product up fast. (A unique index also lets you run
`REFRESH MATERIALIZED VIEW CONCURRENTLY`, which doesn't block readers.)

## Self-check questions

1. A view doesn't store any data. So what happens each time you `SELECT` from one, and
   when does that get slow?
2. You add a row to a table. Which shows it straight away, a view or a materialized
   view? How do you make the other one catch up?
3. Name two reasons to give a team access to a view instead of the underlying table.
4. When you `DELETE` through a simple view, which table loses the rows?
5. When would you accept slightly stale data in exchange for speed?
