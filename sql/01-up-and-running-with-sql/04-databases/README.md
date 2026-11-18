# 04 · Databases

> Maps to **Up and Running with SQL and Databases → Section 6: Databases**
> (what a database holds, `\l`, `\c`, `pg_database`, `CREATE DATABASE`, `ALTER DATABASE ... RENAME TO`, `DROP DATABASE`)

A database is a named collection of SQL objects - tables, indexes, views, sequences,
functions - organised in **schemas** (you get `public` by default). Every object belongs
to one and only one database, and one server holds many databases. Creating, connecting
to, renaming and dropping databases is day-one work, and `DROP DATABASE` is one of the
most dangerous commands you'll ever type: everything inside is gone.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Up and Running with SQL and Databases → Databases** and press
`enter`. You land in `psql`, connected to your `student` database; a few other databases
are already there. SQL commands end with `;`, psql's backslash commands don't. Run each
query, then save it with `\w 1.4.sql` (use the question's number). `:questions` shows
the questions again, `:check` grades your work, and `exit` takes you back with your
progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - Create and connect *(hint: `CREATE DATABASE name;` then `\c name`)*

**1.1 (drill)** Run `\l`: for now look at the **Name** and **Owner** columns. `\d`
lists the relations in the database you're connected to (your `student` database is
empty). `\h CREATE DATABASE` shows the syntax.

**1.2 (graded)** Create a database called `my_db`. Then run the same command again and
read the error: a database name can only be used once.

**1.3 (graded)** Connect to `my_db` with `\c my_db` and notice the prompt changes to
`my_db=#`. Prove where you are: send the result of
`SELECT current_database(), current_user;` to `1.3.txt` (`\o 1.3.txt`, run the query,
then `\o`). `\c student` takes you back.

**1.4 (graded)** In the video, `\c template0` is refused. Try it: psql prints
`database "template0" is not currently accepting connections` and keeps you where you
were. Every database has an `allow connections` flag, and the server keeps the list of
databases in the `pg_database` catalog. Write a query that returns the `datname` and
`datallowconn` columns of the `template0` row only, and save it as `1.4.sql`.

## Tier 2 - Rename and drop *(hint: `ALTER DATABASE old RENAME TO new;`, `DROP DATABASE name;`)*

**2.1 (graded)** Someone created `tset_db` with a typo. Rename it to `test_db` - keep
the database (and the `notes` table inside it), don't drop and recreate it.

**2.2 (graded)** The `old_app` database belongs to an application that was shut down.
Drop it - and nothing else.

## Tier 3 - Rename the database you're in *(goal only)*

**3.1 (graded)** Connect to the `staging` database (`\c staging`). The team wants the
current one kept as `staging_old`, with all its data, and a brand-new, empty `staging`
database next to it. Try renaming `staging` while you're connected to it and read why
PostgreSQL refuses - then get it done.

## Self-check questions

1. Can one table belong to two databases at the same time?
2. Why does `CREATE DATABASE my_db` do nothing until you type `;`, while `\c my_db`
   doesn't need one?
3. Why can't you rename (or drop) the database you're connected to?
4. Why is renaming a database in production almost as dangerous as dropping it?
