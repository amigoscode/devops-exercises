# Solutions - Indexes & Query Analysis

Run these in `psql` (you land in `my_db`). `\timing` shows how long each query takes.

## Tier 1 - Indexes in action

**1.1** `id` has the primary key's index (`employee_pkey`, a B-tree), so Postgres
jumps straight to the row. `email` has no index, so it reads all 200,000 rows.

**1.2**
```sql
CREATE INDEX idx_employee_name ON employee (name);
EXPLAIN SELECT * FROM employee WHERE name = 'c4ca4238a0b923820dcc509a6f75849b';
-- Index Scan using idx_employee_name on employee ...
```

**1.3**
```sql
DROP INDEX idx_employee_is_manager;
```

**1.4**
```sql
SELECT indexrelname, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE relname = 'employee';
\w 1.4.sql
```

## Tier 2 - Partial and multi-column indexes, reading plans

**2.1**
```sql
EXPLAIN SELECT count(*) FROM employee WHERE termination_date IS NOT NULL;  -- Seq Scan
CREATE INDEX idx_terminated_employee ON employee (termination_date)
WHERE termination_date IS NOT NULL;
EXPLAIN SELECT count(*) FROM employee WHERE termination_date IS NOT NULL;  -- Index Only Scan
```
It indexes only the 10% of rows the query asks about, so it's a fraction of the size
of a full index (check with your 1.4 query).

**2.2**
```sql
CREATE INDEX idx_department_hire_date ON employee (department, hire_date);
EXPLAIN SELECT count(*) FROM employee WHERE department = 'SALES' AND hire_date > '2020-01-01';
```
Column order matters: the index is sorted by `department` first, so it helps queries
on `department` alone or on both, but not on `hire_date` alone. `(hire_date, department)`
would be used for the two-column query too, but not for the department-only ones.

**2.3**
```
\o plan-by-id.txt
EXPLAIN ANALYZE SELECT * FROM employee WHERE id = 4242;
\o
```
`Index Scan using employee_pkey` is the node type; `cost=0.42..8.44` is the startup
and total cost estimate (planner units), `rows` the estimated rows, `width` the
average row size in bytes; `actual time=...` and `Execution Time` are real
milliseconds, because `ANALYZE` actually ran the query.

**2.4** `EXPLAIN` only plans; `EXPLAIN ANALYZE` executes. `EXPLAIN ANALYZE DELETE FROM car;`
really deletes every car. If you must analyse a write, wrap it:
`BEGIN; EXPLAIN ANALYZE DELETE ...; ROLLBACK;`

## Tier 3 - Make the login query fast

**3.1**
```
\o before.txt
EXPLAIN ANALYZE SELECT id, name FROM employee WHERE email = 'employee4242@amigoscode.com';
\o
```
It shows a (Parallel) `Seq Scan on employee` with `Filter: (email = ...)` and
`Rows Removed by Filter` close to 200,000.

**3.2**
```sql
-- see the problem
SELECT email, count(*) FROM employee GROUP BY email HAVING count(*) > 1;

-- keep the lowest id per email
DELETE FROM employee e
USING employee keep
WHERE e.email = keep.email
  AND e.id > keep.id;

CREATE UNIQUE INDEX idx_unique_employee_email ON employee (email);
```
Creating the unique index before the cleanup fails with *could not create unique
index ... Key (email)=(...) is duplicated*. (`ALTER TABLE employee ADD CONSTRAINT
unique_employee_email UNIQUE (email);` works too: it builds the same unique index.)

**3.3**
```
\o after.txt
EXPLAIN ANALYZE SELECT id, name FROM employee WHERE email = 'employee4242@amigoscode.com';
\o
```
`Index Scan using idx_unique_employee_email`, and the execution time drops from tens
of milliseconds to a fraction of one.

**3.4**
```sql
DROP INDEX idx_unique_employee_email;
CREATE UNIQUE INDEX CONCURRENTLY idx_unique_employee_email ON employee (email);
```
A plain `CREATE INDEX` locks the table against writes for the whole build.
`CONCURRENTLY` builds it in several passes while writes carry on, and those passes
need their own transactions, so it can't run inside a transaction block.
