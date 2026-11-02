# 01 · SQL Essentials

> Maps to **SQL and Databases Fundamentals → Section 8: Important Stuff**
> (SQL commands, semicolons, upper vs lowercase, naming conventions, the query buffer, running SQL from a file)

Before you write real queries, you need the habits every SQL developer has: knowing
that nothing runs until the `;`, writing keywords in a consistent style, naming
tables so the next person understands them, and not fighting the terminal when a
statement gets long. These are the small things that stop "why isn't my query
working?" moments for the rest of the course.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **SQL and Databases Fundamentals → SQL Essentials** and press
`enter`. You land in `psql`, connected to the `my_db` database. Run each query, then
save it with `\w 1.1.sql` (use the question's number). `:questions` shows the
questions again, `:check` grades your work, and `exit` takes you back with your
progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - Semicolons and case *(hint: nothing runs until you type `;`)*

**1.1 (drill)** At the `my_db=#` prompt, type `\h`: that's every **SQL command** Postgres
knows - `CREATE`, `ALTER`, `DROP` define structure (DDL), `INSERT`, `UPDATE`,
`DELETE` change data, `SELECT` reads it. Then type `\?`: those are the **psql
commands**. They start with a backslash, belong to psql (not SQL) and never need a
semicolon. Find the **Query Buffer** section - you'll use it in Tier 2.

**1.2 (graded)** Someone left a table called `foo_bar` in `my_db` (see it with `\dt`).
Type `DROP TABLE foo_bar` and press `enter` **without** a semicolon. The prompt
changes from `my_db=#` to `my_db-#`: psql is waiting, nothing has run yet. Now type
`;` and press `enter` to finish the statement. `foo_bar` must be gone.

**1.3 (drill)** SQL keywords are not case-sensitive. Run `select 'hello' as greeting;`
and then `SELECT 'hello' AS greeting;` - same result. Even `sElEcT` works, but the
convention (and the one used in this course) is **UPPERCASE for SQL keywords**,
lowercase for your own names: `DROP TABLE foo_bar;`.

## Tier 2 - Naming conventions and the query buffer *(hint: `\e` edits the buffer, `\p` prints it, `\r` resets it, `\w FILE` writes it)*

**2.1 (graded)** A teammate sketched this table:

```sql
CREATE TABLE PersonAddresses (Id INTEGER, StreetName TEXT, PostCode TEXT, DateMovedIn DATE);
```

Create it in `my_db` following the naming conventions instead: **lowercase**, words
separated by **underscores** (snake_case) and a **singular** table name. You should
end up with a table `person_address` whose columns are `id`, `street_name`,
`post_code` and `date_moved_in` (same types as the sketch).

**2.2 (graded)** You need a table for customer orders with the columns `id INTEGER`,
`date DATE` and `description TEXT`. Start typing it over several lines as
`CREATE TABLE order (` ... and run it: you get a **syntax error at or near "order"**,
because `ORDER` is a reserved keyword (think `ORDER BY`). Instead of retyping it,
press `\e` to open the statement in the editor (vim by default - or run
`\setenv PSQL_EDITOR nano` first), rename the table to `customer_order`, save and
quit. psql runs the fixed statement as soon as the editor closes.

**2.3 (graded)** This is how you'll hand in every query in this course. Run
`SELECT * FROM customer_order;` and then save it with `\w 2.3.sql` - `\w` writes the
query buffer (or, when it's empty, your last query) to a file in your sandbox folder.
Run the file back with `\i 2.3.sql` to see it really holds your query.

**2.4 (drill)** Type `SELECT * FROM customer_order` without a semicolon, then `\p` to
print what's in the buffer and `\r` to throw it away. Run `\p` again: the buffer is
empty now, so psql shows your last executed query instead.

## Tier 3 - Run SQL from a file *(goal only)*

**3.1 (graded)** The file `query.sql` in your sandbox folder holds the
`CREATE TABLE person` statement from the previous course. From inside psql, without
copy-pasting, run the file so `my_db` gets the `person` table with its seven columns.
(Tip: `\set ECHO all` first makes psql print every line of the file as it runs it.)

**3.2 (graded)** Write your own script file without leaving psql. Type a
`CREATE TABLE passport` statement with the columns `id INTEGER`,
`passport_number VARCHAR(20)` and `expiry_date DATE`, but **leave off the final `;`**
so it stays in the query buffer instead of running. Save the buffer with
`\w passport.sql` and clear it with `\r`. Now run the file with `\i`, sending what
psql prints to a log file: `\o passport.log` before the `\i`, and a plain `\o`
afterwards to send output back to the screen. You need the `passport` table,
`passport.sql` and a `passport.log` that holds psql's `CREATE TABLE` reply.

**3.3 (drill)** *Optional - uses the Linux shell.* The same file also runs from the
command line, outside an open session, with psql's `-d` (database), `-a` (echo
everything) and `-f` (file) options. You can try it from psql with `\!`, which hands
one command to the shell: `\! psql -d my_db -a -f passport.sql`. It prints the
statement and then `ERROR: relation "passport" already exists`, because 3.2 already
created it.

## Self-check questions

1. You typed a `SELECT` and pressed `enter`, and nothing happened. What's missing, and
   why don't `\dt` or `\l` need it?
2. Why is `CREATE TABLE order (...)` an error, and what's a better name?
3. Name three naming conventions from this section and the reason behind singular
   table names.
4. When would you use `\e` instead of typing at the prompt, and what do `\p`, `\r` and
   `\w` do?
5. What's the difference between running a file with `\i query.sql` inside psql and with
   psql's `-f` option (drill 3.3)?
