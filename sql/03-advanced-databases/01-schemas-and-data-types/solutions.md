# Solutions - Schemas & Data Types

Run these in `psql` (you land in `my_db`). For query tasks, run the query, then save
it with `\w <task>.sql` (it lands in your sandbox folder).

## Tier 1 - Schemas and the search path

**1.1**
```sql
CREATE SCHEMA engineering;
CREATE SCHEMA data_science;
\dn
```

**1.2**
```sql
CREATE TABLE engineering.deployment (
  id   BIGSERIAL PRIMARY KEY,
  name VARCHAR(100)
);
INSERT INTO engineering.deployment (name) VALUES ('backend'), ('frontend');
SELECT * FROM engineering.deployment;
```

**1.3** `SHOW search_path;` prints `"$user", public`: Postgres first looks for a schema
named after the current role (`SELECT current_role;`), then `public`.
`SELECT current_schema();` is the first schema in the path that exists.

**1.4**
```
SET search_path TO engineering, public \; SELECT name FROM deployment;
\w 1.4.sql
\i 1.4.sql
RESET search_path;
```
`\;` puts a literal `;` into the query without sending it, so psql sends both statements
together and `\w` saves both. With `public, engineering` you'd get `legacy-cron`:
the first schema in the path that has the table wins, which is why being explicit
(`engineering.deployment`) is the safe habit. `RESET search_path;` puts you back on
`"$user", public` (reconnecting with `\c` does too).

## Tier 2 - Advanced data types

**2.1**
```sql
CREATE SEQUENCE ticket_seq START WITH 100 INCREMENT BY 10 MINVALUE 100;
SELECT nextval('ticket_seq');  -- 100
SELECT nextval('ticket_seq');  -- 110
SELECT nextval('ticket_seq');  -- 120
SELECT nextval('ticket_seq');  -- 130
SELECT currval('ticket_seq');  -- 130
```
(or `SELECT setval('ticket_seq', 130);`)

**2.2**
```sql
UPDATE customer SET emails = array_append(emails, 'jamila@gmail.com') WHERE name = 'Jamila';
UPDATE customer SET emails = array_remove(emails, 'j@hotmail.com')    WHERE name = 'John';
```
Without the `WHERE`, every customer gets the new email.

**2.3**
```sql
SELECT name, emails[1] FROM customer;
\w 2.3.sql
```

**2.4**
```sql
SELECT name, attributes ->> 'ram' AS ram
FROM product
WHERE attributes @> '{"water_resistant": true}';
\w 2.4.sql
```
`->` returns JSON (`"8GB"`), `->>` returns text (`8GB`).

**2.5**
```sql
CREATE TYPE priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');
CREATE TABLE todo (
  id       SERIAL,
  task     TEXT,
  priority priority
);
ALTER TYPE priority ADD VALUE IF NOT EXISTS 'SUPER_URGENT' AFTER 'URGENT';
SELECT enum_range(NULL::priority);
```
You can add enum values but not remove them: that needs a new type.

**2.6**
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE transaction (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  description TEXT
);
INSERT INTO transaction (description) VALUES ('Smash burger'), ('Birthday cake');
SELECT * FROM transaction;
```

**2.7** `pg_available_extensions` lists what can be enabled; `installed_version` is
filled in for the ones that are. `CREATE EXTENSION IF NOT EXISTS hstore;` adds the
key/value `hstore` type. `::type` and `CAST(x AS type)` are the same conversion.

## Tier 3 - Working with dates

**3.1**
```sql
SELECT customer, (started_at + duration)::date AS ends_on
FROM subscription
WHERE EXTRACT(YEAR FROM started_at + duration) = 2025;
\w 3.1.sql
```
Adding an interval to a timestamp gives a timestamp;
`::date` keeps only the date.

**3.2**
```sql
SELECT first_name, EXTRACT(YEAR FROM age(dob)) AS age
FROM person
WHERE dob < '1990-01-01'
ORDER BY dob;
\w 3.2.sql
```
Oldest first = earliest date of birth first.
`(current_date - dob) / 365` drifts by leap days, `age` doesn't.

**3.3**
```sql
ALTER TABLE signup
  ALTER COLUMN signed_up_on TYPE DATE
  USING to_date(signed_up_on, 'DD/MM/YYYY');
SELECT * FROM signup;
```
`USING signed_up_on::date` either fails (`31/01/2024` isn't a valid month-first date)
or silently swaps day and month (`05/03/2024` becomes the 3rd of May).
