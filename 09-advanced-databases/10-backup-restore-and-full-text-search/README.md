# 10 · Backup, Restore & Full-Text Search

> Maps to **Advanced Databases → Section 19: Backup and Restore** and
> **Section 20: Full Text Search**
> (`pg_dump` plain and tar, `pg_dumpall`, `pg_restore`, `\i`, `COPY` / `\copy ... CSV
> HEADER`, `tsvector`, `tsquery`, `@@`, `&` `|` `!`, prefix `:*`, `phraseto_tsquery`,
> `ts_rank`, GIN index)

A backup you've never restored is only a hope, so in this set you restore every backup
you take. In the second half you'll build search the way PostgreSQL does it: words
become lexemes, queries become `tsquery`s, a GIN index keeps it fast and `ts_rank` puts
the best match first. Plenty of products ship that instead of running a separate search
engine.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Backup, Restore & Full-Text Search** and
press `enter`. You land in `psql`, connected to the `my_db` database. Run each query,
then save it with `\w 2.3.sql` (use the question's number). `:questions` shows the
questions again, `:check` grades your work, and `exit` takes you back with your progress
saved. Press `r` in the Academy for a fresh start.

---

The `my_db` database has three tables:
- `car (id, brand, model, year, price)`: 15 cars.
- `article (id, title, body, search_vector)`: the full-text search exercise table, with 30
  articles about databases, programming, AI, tech companies and phones.
  `search_vector` is a `TSVECTOR` column that is still empty.
- `comment (id, article_id, author, body, created_at)`: **empty**. Last night's backup,
  `backups/nightly.tar`, still has all the comments. This morning someone ran
  `TRUNCATE comment;` on the live database.

**PostgreSQL's backup tools.** `pg_dump`, `pg_dumpall` and `pg_restore` are programs
that ship with PostgreSQL, not SQL statements. psql runs one for you when you put `\!`
in front of it (`\!` hands that one command to the system). Each task that needs one
says so and gives the exact command: type it as shown. Backups go in the `backups`
folder, next to the queries you save with `\w`.

**How backups are graded:** the grader restores each file into a brand-new scratch
database and counts the rows, the same way you'd test a backup for real.

## Tier 1 - Back up and restore *(hint: `pg_dump -f file`, `pg_dump -F t`, `pg_restore -d db file`)*

**1.1 (graded)** This one runs a PostgreSQL tool through `\!`. Back up `my_db` as a
**plain SQL** file, `backups/backup.sql`:
`\! pg_dump -d my_db -f backups/backup.sql`
The file is a script of `CREATE TABLE` and `COPY` statements that rebuilds the database.

**1.2 (graded)** This one runs a PostgreSQL tool through `\!`. Back up `my_db` again,
this time in **tar** format (`-F t`), as `backups/backup.tar`:
`\! pg_dump -F t -d my_db -f backups/backup.tar`

**1.3 (graded)** Restore the tar backup into a new database. Create the database
`my_db_from_dump` with SQL. Then (this step runs a PostgreSQL tool through `\!`)
restore into it: `\! pg_restore -d my_db_from_dump backups/backup.tar`. Connect with
`\c my_db_from_dump`, check the tables are there with `\dt`, and go back with
`\c my_db`. (A plain `.sql` backup is restored from psql instead: connect to the empty
database and run the file with `\i backups/backup.sql`.)

**1.4 (graded)** This one runs a PostgreSQL tool through `\!`. Back up **every database
on the server, and the roles**, into one file, `backups/all-dbs.sql`:
`\! pg_dumpall -f backups/all-dbs.sql`
It holds a `CREATE ROLE` for every role and a `CREATE DATABASE` for every database.

## Tier 2 - COPY and full-text search *(hint: `\copy ... TO 'file' CSV HEADER`, `to_tsvector('english', text) @@ to_tsquery('english', 'a & b')`)*

**2.1 (graded)** Export the whole `car` table to `backups/car.csv` (comma-separated,
**with a header row**). The video uses `COPY car TO '/full/path/car.csv' DELIMITER ','
CSV HEADER;`, which the database **server** writes, on its own machine. psql's `\copy`
takes the same options but writes the file into your folder, so use it here:
`\copy car TO 'backups/car.csv' DELIMITER ',' CSV HEADER`
(`\copy` is a psql command, so it ends at the end of the line: no `;` needed.)

**2.2 (graded)** Export only the `id` and `brand` of every car, from a query, to
`backups/car2.csv`, with a header. (`\copy` takes a query in brackets where the table
name goes.)

**2.3 (graded)** Find the articles about **PostgreSQL and indexes**: search the title
and body together, `to_tsvector('english', title || ' ' || body)`, for both words.
Return `id` and `title`. Save it as `2.3.sql`.

**2.4 (graded)** Find the articles containing the exact phrase **"full text search"**
(the three words together, in that order; an article that just mentions "full", "text"
and "search" somewhere doesn't count). Return `id`, `title`, and save it as
`2.4.sql`.

**2.5 (graded)** Find the articles with a word **starting with `data`** (data,
database, datasets...) that do **not** mention MySQL. Return `id`, `title`, and save it
as `2.5.sql`.

**2.6 (drill)** Look at what PostgreSQL does to text:
`SELECT to_tsvector('english', 'I love databases and PostgreSQL is the best');`. Which
words were dropped, what are the numbers, and why is it `databas`? Try
`SELECT to_tsquery('english', 'football & !car');` and
`SELECT to_tsvector('I love cats and football is awesome') @@ to_tsquery('foot:*');`.

## Tier 3 - Ship search, survive an accident *(goal only)*

> **Scenario:** The blog is getting a search box, and the comments need to come back
> before anyone notices.

**3.1 (graded)** Fill `article.search_vector` for every row with
`to_tsvector('english', title || ' ' || body)`, and add a **GIN index** on it so searches
don't scan the whole table. (With 30 rows the planner prefers a scan anyway. To see your
index used, run `SET enable_seqscan = off;` before `EXPLAIN`.)

**3.2 (graded)** New and edited articles must be searchable straight away. Keep
`search_vector` in sync on every `INSERT` and `UPDATE` (the exercise uses a trigger).

**3.3 (graded)** The search results page: articles matching **`postgresql &
performance`**, **most relevant first** with `ts_rank` on `search_vector`. Return `id`
and `title`, and save it as `3.3.sql`.

**3.4 (graded)** This one runs a PostgreSQL tool through `\!`. Bring the comments back:
restore **only the `comment` table's data** from `backups/nightly.tar` into `my_db`.
Don't drop or overwrite anything else: your search work in 3.1 and 3.2 must survive, so
a full restore is out. First list what's inside the backup:
`\! pg_restore -l backups/nightly.tar`
Then restore one table (`-t comment`), data only (`--data-only`), into `my_db`:
`\! pg_restore --data-only -t comment -d my_db backups/nightly.tar`
Check with `SELECT count(*) FROM comment;`.

## Self-check questions

1. `pg_dump` runs while people keep using the database. Why is the backup still
   consistent?
2. Plain SQL or tar: how do you restore each one, and when would you pick tar?
3. Server-side `COPY ... TO '/path'` writes the file as the server's OS user. When is
   psql's `\copy` the better choice?
4. Why does `to_tsvector` store `databas` and `postgresql`, and drop words like `is` and
   `the`?
5. What does a GIN index store that makes `@@` fast, and what does it cost you on
   writes?
