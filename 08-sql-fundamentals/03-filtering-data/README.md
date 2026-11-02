# 03 · Filtering Data

> Maps to **SQL and Databases Fundamentals → Section 10: Filtering Data**
> (`WHERE`, comparison operators, booleans, `AND`/`OR`, `IN`/`NOT IN`, `BETWEEN`, `LIKE`/`ILIKE`, `IS NULL`, `FETCH`/`LIMIT`/`OFFSET`)

Nobody wants all 100 rows - they want "the women from Pakistan", "everyone born after
2000", "the next 10". The `WHERE` clause is how you ask for exactly the rows you need,
and it's the same `WHERE` you'll later put on `UPDATE` and `DELETE`, where getting it
wrong costs real data.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **SQL and Databases Fundamentals → Filtering Data** and press `enter`.
You land in `psql`, connected to the `my_db` database. Run each query, then save it
with `\w 1.1.sql` (use the question's number). `:questions` shows the questions
again, `:check` grades your work, and `exit` takes you back with your progress saved.
Press `r` in the Academy for a fresh start.

`my_db` holds the 100 sample people from the previous section. Your saved queries are
graded against an untouched copy of that data (which already includes the person you
add in 3.3).

---

## Tier 1 - WHERE and comparison operators *(hint: `SELECT ... FROM person WHERE column = 'value';` - also `<>`/`!=`, `<`, `<=`, `>`, `>=`)*

**1.1 (graded)** Every column (`*`) of everyone from the `USA`. Save it with
`\w 1.1.sql`.

**1.2 (graded)** `first_name` and `last_name` of all the women (`gender` is `F`). Save
it with `\w 1.2.sql`.

**1.3 (graded)** `first_name`, `last_name` and `country_of_origin` of everyone who is
**not** from the `UK`. Save it with `\w 1.3.sql`.

**1.4 (graded)** `first_name`, `last_name` and `dob` of everyone born **on or after**
1 January 2000 (dates in single quotes: `'2000-01-01'`). Save it with
`\w 1.4.sql`.

## Tier 2 - Booleans, AND/OR, IN and BETWEEN

**2.1 (drill)** A `WHERE` condition is just an expression that is true or false. Try
`SELECT 'A' = 'A' AS result;`, `SELECT 1 < 2 AND 'A' = 'B';`,
`SELECT 1 < 1 OR 'B' = 'B';` and `SELECT (1 <= 1 AND 'A' <> 'A') OR 'B' = 'B';`.
Predict each `t`/`f` before you press `enter`.

**2.2 (graded)** `first_name`, `last_name` and `dob` of the **men** from the **UK**
born **before** 1 January 2000 - all three conditions at once. Save it with
`\w 2.2.sql`.

**2.3 (graded)** `first_name`, `last_name` and `country_of_origin` of the **women**
from **Iraq or Pakistan**. Careful: `AND` is evaluated before `OR`, so group the
conditions that belong together. Save it with `\w 2.3.sql`.

**2.4 (graded)** `id`, `first_name`, `last_name` and `country_of_origin` of everyone
from `Egypt`, `USA`, `Jordan` or `UK` - with `IN`, not four `OR`s. Save it with
`\w 2.4.sql`.

**2.5 (graded)** The same four columns for everyone from **any other** country. Save
it with `\w 2.5.sql`.

**2.6 (graded)** `id`, `first_name`, `last_name` and `dob` of everyone born between
15 August 2000 and 25 April 2010, **both days included**. Save it with
`\w 2.6.sql`.

## Tier 3 - Patterns, NULLs and paging *(goal only)*

**3.1 (graded)** `first_name` and `last_name` of everyone whose first name starts with
`M`. Save it with `\w 3.1.sql`.

**3.2 (graded)** The name is spelled both `Maryam` and `Mariam` in the data. Find
`id`, `first_name` and `last_name` of every Maryam/Mariam with **one** pattern. Save it
with `\w 3.2.sql`.

**3.3 (graded)** Like the video, insert a person with only an id and a last name: id
`101`, last name `nelson` - all lowercase - and nothing else.

**3.4 (graded)** `id`, `first_name` and `last_name` of everyone whose last name is
Nelson, **whatever the letter case** (there are now three). Save it with
`\w 3.4.sql`.

**3.5 (graded)** `id`, `first_name` and `last_name` of everyone **without** a phone
number. Save it with `\w 3.5.sql`.

**3.6 (graded)** Page two: `id`, `first_name` and `last_name` ordered by `id`,
**skipping the first 10** and returning the **next 10**. Save it with
`\w 3.6.sql`.

## Self-check questions

1. In which order does Postgres evaluate `FROM`, `WHERE`, `SELECT` and `ORDER BY`?
2. Why does `country_of_origin = 'Iraq' OR country_of_origin = 'Pakistan' AND gender = 'F'`
   not mean "women from Iraq or Pakistan"?
3. Why can't you find missing phone numbers with `phone_number = NULL`?
4. What's the difference between `LIKE` and `ILIKE`, and between `%` and `_`?
5. `FETCH FIRST 10 ROWS ONLY` and `LIMIT 10` - which is the SQL standard, and why do
   paging queries need an `ORDER BY`?
