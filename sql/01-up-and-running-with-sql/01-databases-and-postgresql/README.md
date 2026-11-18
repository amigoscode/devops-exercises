# 01 · Databases & PostgreSQL

> Maps to **Up and Running with SQL and Databases → Section 2: Getting Started with Databases** and **Section 3: PostgreSQL Installation**
> (databases, RDBMS, SQL and its sub-languages, PostgreSQL, checking an installation, your first query)

Every backend application starts with data, and that data lives in a database. Before
you write real SQL you need to know what a relational database is, what PostgreSQL is,
and how to tell that a PostgreSQL installation actually works: the `psql` client is
there, the server is accepting connections, and it answers a query.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Up and Running with SQL and Databases → Databases & PostgreSQL**
and press `enter`. You land in `psql`, connected to the `student` database. Run each
query, then save it with `\w 1.2.sql` (use the question's number). `:questions` shows
the questions again, `:check` grades your work, and `exit` takes you back with your
progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - PostgreSQL is installed *(hint: `SELECT version();`, then `\w 1.2.sql`)*

**1.1 (drill)** In the videos you install PostgreSQL yourself: Postgres.app on macOS,
the installer on Windows, `sudo apt install -y postgresql-16` on Ubuntu. Installing
can't be done in here, because this sandbox **is** that Ubuntu machine with
PostgreSQL 16 already installed. *Optional - uses the Linux shell:* `\!` runs one
shell command from psql, so `\! pg_lsclusters` shows the PostgreSQL server the
installation gave you (version `16`, port `5432`, its data directory, status `online`).

**1.2 (graded)** The first thing to check after any installation is which PostgreSQL
you've got. You're already connected with `psql`, so ask the server with your first SQL
statement: `SELECT version();`. Then save it with `\w 1.2.sql` - psql writes the query
you just ran to that file. You'll save your work this way in every SQL course.

**1.3 (drill)** The videos also check the `psql` client: `psql -V` prints its version,
and on macOS you had to add Postgres.app's `bin` folder to your `PATH` before typing
`psql` worked. *Optional - uses the Linux shell:* `\! psql --version` and
`\! which psql` show the same here.

## Tier 2 - Talk to the server *(hint: `SHOW setting_name;`)*

**2.1 (graded)** PostgreSQL is a server: clients like `psql` connect to it on a
**port**. Ask the server which port it listens on (`SHOW port;`) and save the query as
`2.1.sql`.

**2.2 (graded)** A server that answers your queries is up and accepting connections.
Ask it **since when** it has been running - the function is
`pg_postmaster_start_time()` - and save the query as `2.2.sql`.

**2.3 (graded)** SQL is **declarative**: you say *what* you want, not how to get it. The
`student` database has a `customers` table. Run the example from the SQL video - select
**all the columns** of every customer - and save the query as `2.3.sql`.

## Tier 3 - Inside your installation *(goal only)*

**3.1 (graded)** The macOS video opened the server settings: the **data directory**
(where all the data is stored), the configuration file, the HBA file and the log file.
Ask the server itself, with SQL, where its data directory is, and save that query as
`3.1.sql`.

**3.2 (graded)** The server reads its settings from a file called `postgresql.conf`.
Ask the server where **its configuration file** is and save that query as `3.2.sql`.

**3.3 (drill)** In the video that file is opened in a text editor: it holds the port
(`5432`), the maximum number of connections, SSL, memory... *Optional - uses the Linux
shell:* `\! grep -n '^port' /etc/postgresql/16/main/postgresql.conf` shows the line
that sets the port - the same `5432` that `SHOW port;` told you.

## Self-check questions

1. What is a database, and how does a relational database organise its data?
2. What does RDBMS stand for, and name three of them besides PostgreSQL.
3. SQL has sub-languages: which one do `CREATE`/`DROP`, `INSERT`/`UPDATE`/`DELETE`,
   `GRANT`/`REVOKE`, `COMMIT`/`ROLLBACK` and `SELECT` belong to?
4. Give one advantage of relational databases over NoSQL ones, and one disadvantage.
5. Why does this course use the terminal (`psql`) rather than a GUI client?
