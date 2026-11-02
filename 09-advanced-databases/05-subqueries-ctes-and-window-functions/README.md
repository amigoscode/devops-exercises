# 05 · Subqueries, CTEs & Window Functions

> Maps to **Advanced Databases → Sections 12-14: Sub Queries, Common Table Expressions, Window Functions**
> (subqueries in `WHERE`/`SELECT`, `EXISTS`/`NOT EXISTS`, `ANY`/`ALL`, `WITH ... AS (...)`, multiple CTEs, `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `NTILE`, `SUM/AVG/MAX/MIN/COUNT OVER`, `LAG`, `LEAD`, `FIRST_VALUE`, `LAST_VALUE`, `NTH_VALUE`)

This is where SQL stops being "select some rows" and starts answering business
questions: who spends more than average, which department is over-staffed, what each
customer's running total is, what they bought last. Window functions in particular
replace pages of application code, and they come up in almost every data-heavy
interview.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Subqueries, CTEs & Window Functions** and
press `enter`. You land in `psql`, connected to the `my_db` database. Run each query,
then save it with `\w 1.1.sql` (use the question's number). Columns are compared in
the order the task lists them; row order doesn't matter. `:questions` shows the
questions again, `:check` grades your work, and `exit` takes you back with your
progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - Subqueries *(hint: `WHERE id IN (SELECT owner_id FROM car WHERE ...)`)*

Tables: `person` and `car` (`car.owner_id` references `person.id`).

**1.1 (graded)** List the `first_name` and `last_name` of everyone who owns a car that
is more expensive than the **average** price of all cars, each person once. Save it as `1.1.sql`.

**1.2 (graded)** List the `first_name` and `last_name` of everyone who owns **no** car,
using `NOT EXISTS`. Save it as `1.2.sql`.

**1.3 (graded)** List the `first_name` and `last_name` of everyone who owns a car that
is cheaper than **every** Tesla (`ALL`, not `ANY`), each person once. Save it as `1.3.sql`.

**1.4 (graded)** List the `first_name` and `last_name` of everyone who owns **more
than one** car (a subquery with `GROUP BY ... HAVING`). Save it as `1.4.sql`.

## Tier 2 - Common table expressions *(hint: `WITH name AS (SELECT ...) SELECT ... FROM name;`)*

Tables: `department` and `employee` (`employee.department_id` references `department.id`).

**2.1 (graded)** With a CTE called `it_employee` holding the IT department's
employees, list each IT employee's `name` and their department's name (join the CTE
to `department`). Save it as `2.1.sql`.

**2.2 (graded)** With **two** CTEs, `marketing` and `it`, combine both teams into one
list (`UNION`) of two columns: the department name (`Marketing` or `IT`) and the
employee's name. Save it as `2.2.sql`.

**2.3 (graded)** List each department's name and headcount, but only the departments
with **more** employees than the average department (one CTE for the headcounts,
another for the average, or a subquery). Save it as `2.3.sql`.

## Tier 3 - Window functions on sales *(goal only)*

Table: `transaction` (`sale_date`, `customer_name`, `product`, `quantity`, `price`).

**3.1 (graded)** Number each customer's purchases in date order: `customer_name`,
`sale_date`, `product` and the purchase number (1 for their first purchase, 2 for the
next, ...). Save it as `3.1.sql`.

**3.2 (graded)** Each customer's running total of spend (`price * quantity`) in date
order: `customer_name`, `sale_date`, `product` and the running total so far. Save it as `3.2.sql`.

**3.3 (graded)** Each customer's most expensive purchase (highest `price`): columns
`customer_name`, `product`, `price`. When a customer has a tie for the top price,
show **every** tied purchase (`RANK` or `DENSE_RANK`, not `ROW_NUMBER`). Save it as `3.3.sql`.

**3.4 (graded)** Next to every purchase, the price of the same customer's
**previous** purchase (by date; empty for their first one): `customer_name`,
`sale_date`, `price`, previous price. Save it as `3.4.sql`.

**3.5 (graded)** Next to every purchase, the **last** product that customer bought
(by date): `customer_name`, `sale_date`, `product`, last product. Watch the window
frame: by default `LAST_VALUE` only sees rows up to the current one. Save it as `3.5.sql`.

**3.6 (drill)** Play with the rest: `LEAD`, `FIRST_VALUE`, `NTH_VALUE(price, 3)`, and
`NTILE(4) OVER (ORDER BY price DESC)` to split the sales into price buckets. Swap
`RANK` and `DENSE_RANK` in 3.3 with `ORDER BY product` and spot the gap.

## Self-check questions

1. A subquery inside `SELECT` (a scalar subquery) must return how many rows and columns?
2. Why can `EXISTS` be faster than `IN` on large tables, and why is `SELECT 1` common
   inside it?
3. What does a CTE give you over a nested subquery? When does it pay off?
4. How is `SUM(price) OVER (PARTITION BY customer_name)` different from
   `SUM(price) ... GROUP BY customer_name`?
5. What does `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` change?
