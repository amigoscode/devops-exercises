# 01 · Schemas & Data Types

> Maps to **Advanced Databases → Sections 2-4: Schemas, Advanced Data Types, Working with Dates**
> (`CREATE SCHEMA`, `search_path`, sequences, `SERIAL`/`BIGSERIAL`, arrays, `JSONB`, `ENUM`, `UUID`, extensions, `interval`, `age`, `extract`, `to_date`)

Real databases outgrow `public` and `TEXT` fast. Teams get their own schemas, ids
come from sequences or UUIDs, products carry JSON attributes and dates arrive as
strings that someone has to turn into real dates. Knowing which type to reach for
(and how to move data into it) is what keeps a schema clean for years.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Schemas & Data Types** and press `enter`.
You land in `psql`, connected to the `my_db` database. Run each query, then save it
with `\w 1.1.sql` (use the question's number). `:questions` shows the questions again,
`:check` grades your work, and `exit` takes you back with your progress saved. Press
`r` in the Academy for a fresh start.

---

## Tier 1 - Schemas and the search path *(hint: `CREATE SCHEMA name;`, then `schema.table`)*

`my_db` already has a few tables in `public`, including an old `deployment` table
with one row (`legacy-cron`). Leave that one alone.

**1.1 (graded)** Create two schemas, one per team: `engineering` and `data_science`.
Check them with `\dn`.

**1.2 (graded)** Create the table `engineering.deployment` with an `id BIGSERIAL PRIMARY KEY`
and a `name VARCHAR(100)`, then insert two deployments: `backend` and `frontend`
(insert only the names; the ids number themselves).

**1.3 (drill)** Explore where Postgres looks for tables: `SHOW search_path;`,
`SELECT current_schema();`, `\d public.*` and `\d engineering.*`. What does
`"$user"` in the search path mean?

**1.4 (graded)** Save a two-statement script as `1.4.sql`: it first sets the
`search_path` so `engineering` is searched before `public`, then selects `name` from
`deployment` **without** writing a schema name. psql runs a query as soon as it sees
`;`, so to keep both statements in one query, type them on one line joined by `\;`
instead of `;` (`first statement \; second statement;`), then `\w 1.4.sql`. Run it
again with `\i 1.4.sql`: you should see `backend` and `frontend`, not `legacy-cron`.
Then run `RESET search_path;` so the tables you create next land in `public` again.

## Tier 2 - Advanced data types *(hint: `\d table`, `\dT`, `\ds` show what you built)*

**2.1 (graded)** Create a sequence `ticket_seq` that starts at `100` and goes up by
`10` (`MINVALUE 100`). Then hand out tickets with `nextval` (or reset it with `setval`)
so the **last value handed out is 130**. `currval` and `lastval` show where you are.

**2.2 (graded)** The `customer` table stores every email in a `VARCHAR(50)[]` array.
Add `jamila@gmail.com` to the end of **Jamila's** emails (`array_append`) and remove
`j@hotmail.com` from **John's** (`array_remove`). Nobody else changes.

**2.3 (graded)** List each customer's `name` and their **first** email (arrays in
Postgres start at 1). Save it as `2.3.sql`.

**2.4 (graded)** `product.attributes` is `JSONB`. List the `name` and the `ram`
attribute **as plain text** (`8GB`, not `"8GB"`) of every product that is water
resistant (`"water_resistant": true`; the `@>` containment operator does it).
Save it as `2.4.sql`.

**2.5 (graded)** Create an enum type `priority` with the values `LOW`, `MEDIUM`,
`HIGH`, `URGENT`, and a table `todo` with `id SERIAL`, `task TEXT` and a `priority`
column of that type. Then add `SUPER_URGENT` **after** `URGENT` with `ALTER TYPE`.
(`SELECT enum_range(NULL::priority);` shows the order.)

**2.6 (graded)** Enable the `uuid-ossp` extension and create a table `transaction`
whose `id` is a `UUID PRIMARY KEY` with `DEFAULT uuid_generate_v4()`, plus a
`description TEXT`. Insert two transactions, `Smash burger` and `Birthday cake`,
giving only the description.

**2.7 (drill)** Browse `SELECT name, installed_version FROM pg_available_extensions;`,
then `CREATE EXTENSION IF NOT EXISTS hstore;` and try a cast or two:
`SELECT '123'::INTEGER, CAST('2024-08-18' AS DATE), pg_typeof(now());`.

## Tier 3 - Working with dates *(goal only)*

**3.1 (graded)** Every `subscription` has a `started_at` timestamp and a `duration`
interval. List the `customer` and the **date** (a `DATE`, not a timestamp) each
subscription ends, only for subscriptions that end in **2025**. Save it as `3.1.sql`.

**3.2 (graded)** List the `first_name` and the age **in whole years** (a number like
`41`, from `age` + `extract`) of every `person` born **before 1990**, oldest first.
Save it as `3.2.sql`.

**3.3 (graded)** A legacy import left `signup.signed_up_on` as `TEXT` in UK format
(`31/01/2024` is the 31st of January). Convert the column **in place** to a real
`DATE` so every row keeps its correct date: `ALTER TABLE ... ALTER COLUMN ... TYPE DATE USING ...`
with `to_date`. A plain cast guesses the format and gets it wrong.

## Self-check questions

1. Why would you put tables in an `engineering` schema instead of `public`, and what
   can go wrong when two schemas in your `search_path` both have a `deployment` table?
2. What is the difference between `SERIAL` and `BIGSERIAL`, and what object does each
   one create behind the scenes?
3. When is `JSONB` a better fit than extra columns, and when would a separate table be
   better than an array column?
4. What does `now() - interval '10 days'` return, and what type do you get from
   subtracting one `DATE` from another?
