# Solutions - SQL Essentials

The Academy opens `psql` connected to `my_db`; everything below is typed at that prompt.

## Tier 1
**1.1** `\h` lists SQL commands, `\h CREATE TABLE` shows one command's syntax, `\?`
lists psql's own backslash commands (look for *Query Buffer*).

**1.2**
```
my_db=# DROP TABLE foo_bar
my_db-# ;
DROP TABLE
```

**1.3** `select 'hello' as greeting;` and `SELECT 'hello' AS greeting;` return the same
thing. Use uppercase keywords for readability.

## Tier 2
**2.1**
```sql
CREATE TABLE person_address (
    id INTEGER,
    street_name TEXT,
    post_code TEXT,
    date_moved_in DATE
);
```

**2.2**
```sql
CREATE TABLE order (
    id INTEGER,
    date DATE,
    description TEXT
);
-- ERROR:  syntax error at or near "order"
```
Then `\e`, change the first line to `CREATE TABLE customer_order (`, save and quit
(vim: `Esc` then `:wq`; nano: `Ctrl+O`, `Enter`, `Ctrl+X`). The fixed statement runs:
```sql
CREATE TABLE customer_order (
    id INTEGER,
    date DATE,
    description TEXT
);
```

**2.3**
```
SELECT * FROM customer_order;
\w 2.3.sql
\i 2.3.sql
```

**2.4** `SELECT * FROM customer_order` (no `;`), `\p`, `\r`, `\p`.

## Tier 3
**3.1**
```
\set ECHO all
\i query.sql
\set ECHO none
\d person
```

**3.2** Type the statement with no final `;` (the prompt stays at `my_db(#`/`my_db-#`
and nothing runs), then:
```
CREATE TABLE passport (
    id INTEGER,
    passport_number VARCHAR(20),
    expiry_date DATE
)
\w passport.sql
\r
\o passport.log
\i passport.sql
\o
\d passport
```
`\w` writes the buffer to `passport.sql`, `\r` clears it so it doesn't run, and `\i`
runs the file (psql runs a last statement without `;` when the file ends). With
`\o passport.log` on, psql's reply `CREATE TABLE` goes into the log instead of the
screen. (Ran it with a `;` by mistake? `DROP TABLE passport;` and start again.)

**3.3** (optional - uses the Linux shell)
```
\! psql -d my_db -a -f passport.sql
```
`-a` echoes every line of the file, so you see the statement followed by
`ERROR:  relation "passport" already exists` (3.2 already created it).
