# 03 · Exploring the PostgreSQL Server

> Maps to **Up and Running with SQL and Databases → Section 5: Exploring PostgreSQL Server**
> (the server on `localhost:5432`, clients, roles, databases, config files, `\conninfo`, `\c` with database, user, host and port, `pg_settings`, a second server on another port)

Here is the picture so far: a PostgreSQL **server** listens on a host and port
(`localhost` and `5432` by default). **Clients** - `psql` in the terminal, GUI clients
like pgAdmin - connect to it. Inside the server live **roles** (users) and
**databases**, and the server is tuned with **configuration files**. Knowing exactly
what you're connected to, and how to connect to something else, is the skill you'll use
every time you touch a database at work.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Up and Running with SQL and Databases → Exploring the PostgreSQL
Server** and press `enter`. You land in `psql`, connected to the `student` database. Run
each query, then save it with `\w 1.2.sql` (use the question's number). Tasks that ask
you to **prove where you're connected** save the *result* instead: `\o 2.2.txt` sends
output to that file, you run the query, then `\o` on its own sends output back to the
screen. `:questions` shows the questions again, `:check` grades your work, and `exit`
takes you back with your progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - What we have so far *(hint: `\du`, `\l`, `\conninfo`)*

**1.1 (drill)** Draw the picture from the video for this sandbox: run `\du` (roles:
`postgres` and your own `student`) and `\l` (databases: `postgres`, `student`,
`template0`, `template1`). Then find the config files the video showed:
`SHOW config_file;` and `SHOW hba_file;`.

**1.2 (graded)** `\conninfo` tells you what you're connected to. You connected with
the defaults: your user name (`student`) as the role **and** the database name, the
local server, port `5432`. `\conninfo` only prints to the screen, so write the same
thing as SQL: one query that returns the **database**, the **user** and the **port**
you're connected to, in that order (`current_database()`, `current_user` and
`current_setting('port')`). Save it with `\w 1.2.sql` - you'll reuse it below.

## Tier 2 - Connecting to the server *(hint: `\c database user host port`)*

**2.1 (drill)** In the video the server is stopped, `psql` fails to connect, and then it
works again once the server is started. *Optional - uses the Linux shell:*
`\! sudo service postgresql stop`, then `SELECT 1;` - the connection is lost. Bring
it back with `\! sudo service postgresql start` and `\c dbname=student`.
`\! psql --help` lists the connection flags the video uses from the terminal: `-h`
host, `-p` port, `-U` user, `-d` database.

**2.2 (graded)** Inside psql, `\c` connects you somewhere else - it takes the same four
things as those flags, in the order database, user, host, port. Connect to the
`postgres` database with `\c postgres` (the prompt changes to `postgres=#`), then prove
it: send the result of your query from 1.2 to `2.2.txt` (`\o 2.2.txt`, `\i 1.2.sql`,
`\o`). `\c student` takes you back.

**2.3 (graded)** Now the long form from the video, with everything spelled out:
database `postgres`, your user `student`, host `localhost`, port `5432`. Over
`localhost` the server asks for a password, so first give your role one with
`\password` (type it twice). Then connect with `\c postgres student localhost 5432`
and send the result of this query to `2.3.txt` - it shows the server's network address
and port, which are empty when you're not connected over the network:
`SELECT current_database(), current_user, inet_server_addr(), inet_server_port();`

## Tier 3 - A second server *(goal only)*

**3.1 (graded)** A server is identified by its **port**, and it keeps its data and
settings in its own **data directory** and **configuration files** (`config_file`,
`hba_file`). Before adding a second server, write down this one's: a single query on
the `pg_settings` view that returns the `name` and `setting` of exactly those four
settings. Save it as `3.1.sql`.

**3.2 (drill)** In the macOS video a second server is added in Postgres.app on port
`5433`, so two servers run side by side. *Optional - uses the Linux shell:* the Ubuntu
way is `\! sudo pg_createcluster 16 second --port 5433 --start`, and
`\! pg_lsclusters` lists both servers. Then `\c postgres student - 5433` fails with
the error the Ubuntu video hit, `role "student" does not exist`: the new server only
knows the `postgres` role. `\! sudo -u postgres psql -p 5433 -c 'SHOW data_directory'`
asks it as `postgres`: a different data directory from the one in 3.1.

## Self-check questions

1. What are the default host and port of a PostgreSQL server?
2. Which role and database does a plain `psql` connect with, and why did it fail on a
   fresh Ubuntu installation?
3. What's the difference between connecting with `-U postgres` and with `-d postgres`?
   Which of the two does `\c postgres` change?
4. Why must two servers on the same machine use different ports?
5. What is `postgresql.conf` for?
