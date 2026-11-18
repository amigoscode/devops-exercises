# 03 · Indexes & Query Analysis

> Maps to **Advanced Databases → Sections 8-9: Indexes, Analyse Queries**
> (`CREATE INDEX`, `DROP INDEX`, `\di`, index size, partial / multi-column / unique indexes, B-tree vs GIN, `CONCURRENTLY`, `EXPLAIN`, `EXPLAIN ANALYZE`, reading query plans)

"The app is slow" usually means "a query is reading the whole table". Indexes fix
that, but each one costs disk space and slows down every write, so you add the right
one and prove it with `EXPLAIN ANALYZE`. This is the skill interviewers probe when
they ask how you'd speed up a query.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Indexes & Query Analysis** and press
`enter`. You land in `psql`, connected to the `my_db` database. It has an `employee`
table with 200,000 rows. Run each query, then save it with `\w 1.1.sql` (use the
question's number); query plans go to files with `\o` (see 2.3). The grader asks the
planner itself whether your indexes get used. `:questions` shows the questions again,
`:check` grades your work, and `exit` takes you back with your progress saved. Press
`r` in the Academy for a fresh start.

---

## Tier 1 - Indexes in action *(hint: `CREATE INDEX name ON table (column);`, `\di`, `\d employee`)*

**1.1 (drill)** Turn on `\timing` and `\x auto`. Compare
`SELECT * FROM employee WHERE id = 150000;` with
`SELECT * FROM employee WHERE email = 'employee150000@amigoscode.com';`. Why is
one so much faster? Look at the *Indexes:* part of `\d employee`.

**1.2 (graded)** Searching by `name` reads the whole table. Create a (B-tree) index
on `employee(name)`, then check that `SELECT * FROM employee WHERE name = 'c4ca4238a0b923820dcc509a6f75849b';`
got faster.

**1.3 (graded)** `idx_employee_is_manager` was added "just in case" and nothing uses
it, but every insert and update still pays for it. Drop it (and nothing else).

**1.4 (graded)** Write a query that lists every index on `employee` with its size,
pretty-printed (`pg_size_pretty(pg_relation_size(indexrelid))` from
`pg_stat_user_indexes`, `relname = 'employee'`): two columns, the index name and its
size. Save it as `1.4.sql`.

## Tier 2 - Partial and multi-column indexes, reading plans *(hint: `CREATE INDEX ... WHERE ...`, `EXPLAIN SELECT ...`)*

**2.1 (graded)** HR runs `SELECT count(*) FROM employee WHERE termination_date IS NOT NULL;`
all day to contact leavers. Only 10% of rows have a termination date, so create a
**partial** index on `termination_date` covering only those rows. `EXPLAIN` the
query before and after.

**2.2 (graded)** Reports filter on both columns:
`SELECT count(*) FROM employee WHERE department = 'SALES' AND hire_date > '2020-01-01';`
and plenty of others filter on `department` alone. Create **one** multi-column
index that serves both, so choose the column order deliberately.

**2.3 (graded)** Run `EXPLAIN ANALYZE SELECT * FROM employee WHERE id = 4242;` and
find the node type, the estimated cost and rows, the actual time and the *Execution
Time* in the plan. Then save the plan to a file: `\o plan-by-id.txt` sends the output
of everything you run next to `plan-by-id.txt` instead of the screen, so run the
same `EXPLAIN ANALYZE` again and finish with `\o` on its own to get your screen back:
```
\o plan-by-id.txt
EXPLAIN ANALYZE SELECT * FROM employee WHERE id = 4242;
\o
```

**2.4 (drill)** Compare `EXPLAIN` with `EXPLAIN ANALYZE` on the same `SELECT`: which
one runs the query? Why must you never `EXPLAIN ANALYZE` a `DELETE` you don't want
to happen? Try `\di+` to see each index's type (all B-tree here; GIN is for `JSONB`,
arrays and full-text search).

## Tier 3 - Make the login query fast *(goal only)*

> **Scenario:** the login endpoint runs `SELECT id, name FROM employee WHERE email = '...'`
> thousands of times a minute and it's doing a full table scan. Emails are meant to be
> unique, but a botched import created a second row for 50 employees (same email,
> higher `id`).

**3.1 (graded)** Before changing anything, capture the evidence: save the
`EXPLAIN ANALYZE` of `SELECT id, name FROM employee WHERE email = 'employee4242@amigoscode.com';`
to `before.txt` (use `\o` as in 2.3).

**3.2 (graded)** Fix it properly: delete the duplicate rows (keep the **lowest** `id`
for each email, nothing else goes), then create a **unique** index on `email`, so the
login lookup uses it and the database refuses a second account with the same email.

**3.3 (graded)** Prove it: save the `EXPLAIN ANALYZE` of the same login query, now
using your index, to `after.txt`. Run it once more on screen and compare its
*Execution Time* with the one in 3.1.

**3.4 (drill)** On a busy production table you'd build that index with
`CREATE UNIQUE INDEX CONCURRENTLY`, so inserts, updates and deletes aren't blocked
while it builds. Drop your index and recreate it that way. Why does it refuse to run
inside `BEGIN ... COMMIT`?

## Self-check questions

1. Postgres creates some indexes for you. Which constraints come with an index?
2. What are the costs of an index, and why is "index every column" a bad idea?
3. For an index on `(department, hire_date)`, which of these can use it:
   `WHERE department = ...`, `WHERE hire_date > ...`, both together? Why?
4. In `cost=0.42..8.44 rows=1 width=82`, what do the two cost numbers, `rows` and
   `width` mean, and what does `EXPLAIN ANALYZE` add on top?
