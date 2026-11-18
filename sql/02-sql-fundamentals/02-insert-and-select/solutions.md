# Solutions - Insert and Select

Run these in `psql` (connected to `my_db`). Save each query with `\w` right after it runs.

## Tier 1
**1.1**
```sql
INSERT INTO person (id, first_name, last_name, gender, dob, phone_number, country_of_origin)
VALUES (1, 'Jamila', 'Bah', 'F', '1997-01-20', '123-456-789', 'Guinea-Bissau');
```
then `\w 1.1.sql`

**1.2**
```sql
INSERT INTO person (id, first_name, last_name, gender, dob, phone_number, country_of_origin)
VALUES (2, 'Alex', 'Yu', 'M', '1980-09-04', '000-000-000', 'Italy');
```
then `\w 1.2.sql`

**1.3** `SELECT first_name, last_name, dob FROM person;` then `\w 1.3.sql`

**1.4** `SELECT * FROM person;`, `\pset pager off`, `\pset pager on`

## Tier 2
**2.1**
```
DELETE FROM person;
\i sample-data.sql
```
(`INSERT 0 100` - 100 rows affected.)

**2.2** `SELECT first_name AS name, last_name AS surname, dob AS date_of_birth FROM person;` then `\w 2.2.sql`
(`AS` is optional: `first_name name` works too.)

**2.3** `SELECT id, first_name, last_name FROM person ORDER BY id DESC;` then `\w 2.3.sql`

**2.4** `SELECT first_name, last_name, country_of_origin FROM person ORDER BY first_name, last_name DESC;` then `\w 2.4.sql`
(`ORDER BY first_name ASC, last_name DESC` is the same.)

## Tier 3
**3.1** `SELECT DISTINCT country_of_origin FROM person ORDER BY country_of_origin;` then `\w 3.1.sql`

**3.2** `SELECT DISTINCT country_of_origin, gender FROM person ORDER BY country_of_origin, gender;` then `\w 3.2.sql`
