# Solutions - Filtering Data

Run each query in `psql`, then save it with `\w <task>.sql`.

## Tier 1
**1.1** `SELECT * FROM person WHERE country_of_origin = 'USA';` then `\w 1.1.sql` (14 rows)

**1.2** `SELECT first_name, last_name FROM person WHERE gender = 'F';` then `\w 1.2.sql`

**1.3** `SELECT first_name, last_name, country_of_origin FROM person WHERE country_of_origin <> 'UK';` then `\w 1.3.sql`
(`!= 'UK'` is the same.)

**1.4** `SELECT first_name, last_name, dob FROM person WHERE dob >= '2000-01-01';` then `\w 1.4.sql`

## Tier 2
**2.1** `t`, `f`, `t`, `t`.

**2.2**
```
SELECT first_name, last_name, dob FROM person
WHERE gender = 'M' AND country_of_origin = 'UK' AND dob < '2000-01-01';
\w 2.2.sql
```

**2.3**
```
SELECT first_name, last_name, country_of_origin FROM person
WHERE gender = 'F' AND (country_of_origin = 'Iraq' OR country_of_origin = 'Pakistan');
\w 2.3.sql
```
(`gender = 'F' AND country_of_origin IN ('Iraq', 'Pakistan')` works too.)

**2.4**
```
SELECT id, first_name, last_name, country_of_origin FROM person
WHERE country_of_origin IN ('Egypt', 'USA', 'Jordan', 'UK');
\w 2.4.sql
```

**2.5**
```
SELECT id, first_name, last_name, country_of_origin FROM person
WHERE country_of_origin NOT IN ('Egypt', 'USA', 'Jordan', 'UK');
\w 2.5.sql
```

**2.6**
```
SELECT id, first_name, last_name, dob FROM person
WHERE dob BETWEEN '2000-08-15' AND '2010-04-25';
\w 2.6.sql
```
(Same as `dob >= '2000-08-15' AND dob <= '2010-04-25'`.)

## Tier 3
**3.1** `SELECT first_name, last_name FROM person WHERE first_name LIKE 'M%';` then `\w 3.1.sql`

**3.2** `SELECT id, first_name, last_name FROM person WHERE first_name LIKE 'Mar_am';` then `\w 3.2.sql`
(`'Mar%am'` matches the same people.)

**3.3** `INSERT INTO person (id, last_name) VALUES (101, 'nelson');`

**3.4** `SELECT id, first_name, last_name FROM person WHERE last_name ILIKE 'nelson';` then `\w 3.4.sql`
(`LIKE 'Nelson'` only finds Joseph and Mark - `LIKE` is case-sensitive.)

**3.5** `SELECT id, first_name, last_name FROM person WHERE phone_number IS NULL;` then `\w 3.5.sql`
(`IS NOT NULL` gives everyone who has one.)

**3.6** `SELECT id, first_name, last_name FROM person ORDER BY id OFFSET 10 LIMIT 10;` then `\w 3.6.sql`
(or `... ORDER BY id OFFSET 10 ROWS FETCH FIRST 10 ROWS ONLY;`)
