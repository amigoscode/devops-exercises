# SQL and Databases Fundamentals - Hands-On Exercises

Practice exercises for the **SQL and Databases Fundamentals** course. This is where you
stop creating empty tables and start working with data: inserting it, querying it,
filtering, grouping and summarising it, changing it safely, and joining tables
together - all in **PostgreSQL 16** with **psql**, the same tools you'd use on a real
server.

You work with the course's own sample data: the `person` table (100 people) and the
`car` table (100 cars), in a database called `my_db`, just like the videos.

## Quick start

From the repo root:

```bash
./academy.sh        # macOS, Linux, WSL, Git Bash, Codespaces
academy.cmd         # Windows
```

Pick **SQL and Databases Fundamentals**, choose a section and press `enter`. You land
in `psql`, connected to the `my_db` database, with the section's data already loaded.
Run each query, then save it with `\w 1.1.sql` (use the question's number).
`:questions` shows the questions again, `:check` grades your work, and `exit` takes you
back with your progress saved. Press `r` in the Academy for a fresh start. You never
need the Linux shell: everything happens at the psql prompt.

**Docker is the only thing you need installed.** (Codespaces works too - zero install.)

## Sections

| # | Section | Course § | Skills |
|---|---------|----------|--------|
| 01 | [SQL Essentials](01-sql-essentials/) | 8 | semicolons, keyword case, naming conventions, `\e` `\p` `\r` `\w`, `\i`, `\o` |
| 02 | [Insert and Select](02-insert-and-select/) | 9 | `INSERT INTO`, `SELECT`, `AS` aliases, sample data, `ORDER BY`, `DISTINCT` |
| 03 | [Filtering Data](03-filtering-data/) | 10 | `WHERE`, comparison operators, `AND`/`OR`, `IN`, `BETWEEN`, `LIKE`/`ILIKE`, `IS NULL`, `LIMIT`/`OFFSET` |
| 04 | [Aggregates and Math](04-aggregates-and-math/) | 11-12 | `GROUP BY`, `COUNT`, `SUM`, `MIN`/`MAX`/`AVG`, `HAVING`, arithmetic, `ROUND` |
| 05 | [Modifying Data](05-modifying-data/) | 13 | `DELETE`, `UPDATE`, multi-column updates, CRUD |
| 06 | [Relationships and Joins](06-relationships-and-joins/) | 14-16 | primary/foreign keys, `INNER`/`LEFT`/`RIGHT`/`FULL JOIN`, `USING`, order of SQL execution |

Each section: `README.md` (3-tier tasks) · `seed.sh` (creates `my_db` with the
section's data) · `verify.sh` (grades your queries and your database) · `solutions.md`.

## How grading works

There are two kinds of tasks:

- **Queries.** You save each query in a file named after its task - in psql, run it
  and then `\w 2.1.sql` writes your last query to `2.1.sql` in your sandbox folder. The grader runs your file
  inside a transaction that is rolled back, against an **untouched copy** of the
  section's data, and compares the rows with the expected answer (and their order when
  the task asks for one). So experimenting in `my_db` never breaks a query you've
  already saved, and upper/lowercase SQL, extra spaces and a missing final `;` are all
  fine.
- **Changes.** `INSERT`, `UPDATE`, `DELETE`, `CREATE`/`ALTER TABLE` and keys are graded
  on your live `my_db`: the right rows changed, nothing else did, and constraints really
  reject bad data.

Deleted too much? Press `r` in the Academy for a brand-new sandbox. Stuck? Each
section's `solutions.md` has every statement.
