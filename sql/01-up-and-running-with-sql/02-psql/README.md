# 02 · psql

> Maps to **Up and Running with SQL and Databases → Section 4: PSQL**
> (`psql`, `help`, `\?`, `\h`, `\q`, `\du`, `\l`, `\dn`, `\dt`, `\d`, `\o`, `\x`, `\i`, `\timing`, Tab completion)

`psql` is the terminal front end to PostgreSQL: you type queries, it sends them to the
server and shows you the results. It is the same program on macOS, Windows and Linux,
so every command you learn here works everywhere. Commands that start with a backslash
(`\l`, `\dt`...) are psql's own **meta-commands**; everything else is SQL and must end
with a semicolon.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Up and Running with SQL and Databases → psql** and press
`enter`. You land in `psql`, connected to the `student` database. The tasks here save
what a psql command **prints**: `\o roles.txt` sends output to that file (in your
sandbox folder), you run the command, then `\o` on its own sends output back to the
screen. (To save a query itself, it's `\w 1.1.sql` - you'll use that in the other
sections.) `:questions` shows the questions again, `:check` grades your work, and `exit`
takes you back with your progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - Getting around psql *(hint: `help`, `\?`, `\h`, `\q`)*

**1.1 (drill)** You're already in `psql`. Type `help`. Then `\?` lists psql's own
commands (press `space` to scroll, `q` to leave the list) and `\h` lists the SQL
commands. `\h CREATE TABLE` and `\h CREATE DATABASE` show the syntax of one SQL
command. `\q` quits psql - in the Academy that takes you back to the menu (and grades
your work), so keep it for the end.

**1.2 (drill)** The Ubuntu video connects as the `postgres` superuser, the role every
fresh installation comes with. *Optional - uses the Linux shell:*
`\! sudo -u postgres psql -c '\du'` runs psql as the `postgres` Linux user and lists
the roles. (You also have your own `student` role, which is why you're connected
without typing anything.)

**1.3 (graded)** List the **roles** on the server with `\du` and save that list in
`roles.txt`:
```
\o roles.txt
\du
\o
```

## Tier 2 - Meta-commands that list things *(hint: `\l`, `\dn`, `\dt`, `\o FILE`)*

**2.1 (graded)** Save the list of **databases** on the server in `databases.txt`.

**2.2 (graded)** Save the list of **schemas** in the `student` database in
`schemas.txt`.

**2.3 (graded)** Follow the auto-complete video: create a table called `foo` with no
columns (`CREATE TABLE foo ();`), then type `SELECT * FROM f` and press `Tab` - psql
completes the table name for you. Keep `foo` (don't drop it this time) and save the list
of **tables** in `tables.txt`.

## Tier 3 - Run a script *(goal only)*

**3.1 (graded)** A teammate left a script called `report.sql` in your sandbox folder.
Run that file from inside psql (don't retype it) with **expanded display** turned on, so
each column is printed on its own line, and send the result to `report.txt`.

**3.2 (drill)** Turn on `\timing`, run the script again and read how long the query
took. Use `Tab` twice after `\d` to see every command that starts with `\d`.

## Self-check questions

1. What's the difference between `\?` and `\h`?
2. Why does `\l` work without a semicolon, while `SELECT version()` does nothing until
   you type one?
3. What do `\du`, `\l`, `\dt` and `\d person` each show?
4. You ran `\o report.txt` and now your queries print nothing. Why, and how do you fix it?
