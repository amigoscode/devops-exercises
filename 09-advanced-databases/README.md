# Advanced Databases - Hands-On Exercises

The PostgreSQL that separates juniors from seniors. You already write `SELECT`s and
joins; here you'll organise a database into schemas, pick the right data types,
let constraints refuse bad data, make slow queries fast with indexes (and prove it
with `EXPLAIN ANALYZE`), write upserts that are safe to retry, answer business
questions with CTEs and window functions, and then go further: views, transactions,
functions and triggers, roles and row-level security, backups and full-text search.

Every exercise runs against a **real PostgreSQL 16** server in your own sandbox, and
the grader checks what the database actually does, not what your SQL looks like.

## Quick start

From the repo root:

```
./academy.sh        # macOS, Linux, WSL, Git Bash, Codespaces
academy.cmd         # Windows
```

Pick **Advanced Databases**, choose a section and press `enter`. You land in `psql`,
connected to the section's database, already loaded with its data. Run each query,
then save it with `\w 1.1.sql` (use the question's number). `:questions` shows the
questions, `:check` grades your work, and `exit` takes you back with your progress
saved. Press `r` in the Academy for a fresh start. You never need the Linux shell:
everything happens at the `psql` prompt.

**Docker is the only thing you need installed.** (Codespaces works too - zero install.)

## Sections

| # | Section | Course § | Skills |
|---|---------|----------|--------|
| 01 | [Schemas & Data Types](01-schemas-and-data-types/) | 2-4 | `CREATE SCHEMA`, `search_path`, sequences, `SERIAL`, arrays, `JSONB`, `ENUM`, `UUID`, extensions, dates and intervals |
| 02 | [Constraints & Foreign Keys](02-constraints-and-foreign-keys/) | 5-6 | `PRIMARY KEY`, `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`, foreign keys, cleaning data first, `ON DELETE CASCADE` |
| 03 | [Indexes & Query Analysis](03-indexes-and-query-analysis/) | 8-9 | B-tree, partial, multi-column and unique indexes, `CONCURRENTLY`, `EXPLAIN`, `EXPLAIN ANALYZE` |
| 04 | [Conditional Expressions & Conflicts](04-conditional-expressions-and-conflicts/) | 10-11 | `COALESCE`, `NULLIF`, `CASE`, `ON CONFLICT DO NOTHING`, upserts with `DO UPDATE` |
| 05 | [Subqueries, CTEs & Window Functions](05-subqueries-ctes-and-window-functions/) | 12-14 | subqueries, `EXISTS`, `ANY`/`ALL`, `WITH`, `ROW_NUMBER`, `RANK`, running totals, `LAG`, `LAST_VALUE` |
| 06 | [Views & Materialized Views](06-views-and-materialized-views/) | 15 | `CREATE VIEW`, `CREATE MATERIALIZED VIEW`, `REFRESH MATERIALIZED VIEW` |
| 07 | [Transactions](07-transactions/) | 16 | `BEGIN`/`COMMIT`/`ROLLBACK`, ACID, isolation levels, savepoints |
| 08 | [Functions, Procedures & Triggers](08-functions-procedures-and-triggers/) | 17 | `CREATE FUNCTION`, `CREATE PROCEDURE`, `CALL`, triggers |
| 09 | [Roles, Privileges & Row-Level Security](09-roles-privileges-and-row-level-security/) | 18, 21 | roles, groups, `GRANT`/`REVOKE`, `ENABLE ROW LEVEL SECURITY`, policies |
| 10 | [Backup, Restore & Full-Text Search](10-backup-restore-and-full-text-search/) | 19-20 | `pg_dump`, `pg_restore`, `COPY`/CSV, `tsvector`, `tsquery`, ranking |

Each section: `README.md` (3-tier tasks) · `seed.sh` (loads its database) ·
`verify.sh` (the grader) · `solutions.md`.

## How grading works

- **Queries** you're asked for are saved with `\w <task>.sql` right after you run
  them (`\w 2.1.sql` writes your last query to `2.1.sql` in your sandbox folder;
  `\i 2.1.sql` runs it again). The grader runs each one inside a transaction it rolls
  back, against an **untouched copy** of the section's data, and compares the rows
  with the right answer, so experimenting on your own database can't break a query
  you've already saved.
- **Query plans** are saved with `\o`: `\o plan.txt` sends the output of what you run
  next to `plan.txt`, and `\o` on its own sends it back to the screen.
- **Changes** (schemas, constraints, indexes, upserts, roles, ...) are graded on your
  **live database** by behaviour: the grader tries to insert rows that a constraint
  must refuse, asks the planner whether your index gets used, runs your saved upsert
  twice and checks the rows it leaves. All of that happens in transactions that are
  rolled back, so checking never changes your data.

Stuck on the how? Each section's `solutions.md` has the exact SQL and the reasoning.
