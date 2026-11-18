# Up and Running with SQL and Databases - Hands-On Exercises

Your first steps with **PostgreSQL**. You'll check an installation, find your way around
`psql`, explore the server you're connected to, and create databases and tables - all on
a real PostgreSQL 16 server of your own, inside a disposable sandbox, so even
`DROP DATABASE` is safe to try.

This is the beginner course: it takes you from "what is a database?" to a `person`
table you designed yourself, ready for the SQL in the next course.

## Quick start

From the repo root:

```bash
./academy.sh        # macOS, Linux, WSL, Git Bash, Codespaces
academy.cmd         # Windows
```

Pick **Up and Running with SQL and Databases**, choose a section and press `enter`. You
land in `psql`, connected to the section's database, with PostgreSQL already running, the
scenario set up and the questions printed at the top. Run each query, then save it with
`\w 1.1.sql` (use the question's number). `:questions` shows the questions again,
`:check` grades your work, and `exit` takes you back with your progress saved. Press `r`
in the Academy for a fresh start. You never need the Linux shell: everything graded is
SQL or a psql command.

**Docker is the only thing you need installed.** (Codespaces works too - zero install.)
The videos show how to install PostgreSQL on macOS, Windows and Ubuntu; in the Academy
it's already installed for you, so section 01 asks the server about its installation
instead.

## Sections

| # | Section | Course § | Skills |
|---|---------|----------|--------|
| 01 | [Databases & PostgreSQL](01-databases-and-postgresql/) | 2-3 | databases, RDBMS, SQL, `SELECT version();`, `SHOW port`, `SHOW data_directory`, `SHOW config_file`, `\w` |
| 02 | [psql](02-psql/) | 4 | `help`, `\?`, `\h`, `\du`, `\l`, `\dn`, `\dt`, `\o`, `\x`, `\i`, `\timing`, Tab completion |
| 03 | [Exploring the PostgreSQL Server](03-exploring-the-server/) | 5 | host, port, roles, `\conninfo`, `\c db user host port`, `\password`, `pg_settings` |
| 04 | [Databases](04-databases/) | 6 | `CREATE DATABASE`, `\c`, `pg_database`, `ALTER DATABASE ... RENAME TO`, `DROP DATABASE` |
| 05 | [Working with Tables](05-working-with-tables/) | 7 | data types, `CREATE TABLE`, `\d`, `ALTER TABLE ... RENAME`, `DROP TABLE` |

Each section: `README.md` (3-tier tasks) · `seed.sh` (sets up the databases) ·
`verify.sh` (checks your work) · `solutions.md`.

## How grading works

The grader looks at the **real server**. Queries you're asked to save go in your sandbox
folder as `<task>.sql` (in psql, `\w 2.1.sql` writes your last query to that file) and
are run against an untouched copy of the data, so experimenting can't break them.
Databases and tables you create, rename or drop are checked on the live server, and
psql skills are checked by their effect: the output you saved with `\o`, a query result
that proves which database (and host) you were connected to. A few things from the
videos - installing PostgreSQL, stopping the server, a second server on port 5433 - are
optional drills that show the Linux command; nothing graded needs them. Stuck? Each
section's `solutions.md` has every command.
