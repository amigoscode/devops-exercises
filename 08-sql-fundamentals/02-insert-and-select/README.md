# 02 · Insert and Select

> Maps to **SQL and Databases Fundamentals → Section 9: Insert and Query Data**
> (`INSERT INTO`, `SELECT`, aliases with `AS`, loading sample data, `ORDER BY` `ASC`/`DESC`, `DISTINCT`)

A table is only useful once data goes in and comes back out. `INSERT` and `SELECT`
are the two statements you'll type more than any other, and `ORDER BY` and
`DISTINCT` turn a raw dump of rows into an answer someone can read. Here you fill
the `person` table and then query 100 sample people.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **SQL and Databases Fundamentals → Insert and Select** and press `enter`.
You land in `psql`, connected to the `my_db` database. Run each query, then save it
with `\w 1.1.sql` (use the question's number). `:questions` shows the questions
again, `:check` grades your work, and `exit` takes you back with your progress saved.
Press `r` in the Academy for a fresh start.

Your saved queries are graded against an untouched copy of the 100 sample people, so
experimenting in `my_db` never breaks a query you've already saved.

---

## Tier 1 - INSERT and SELECT *(hint: `INSERT INTO person (col, ...) VALUES (...);` and `SELECT col, ... FROM person;`)*

`my_db` has an empty `person` table (`\d person` shows its columns). Text and dates
go in **single quotes**, dates as `'YYYY-MM-DD'`, and `gender` takes one character.

**1.1 (graded)** Insert Jamila into `person`: id `1`, first name `Jamila`, last name
`Bah`, gender `F`, date of birth 20 January 1997, phone number `123-456-789`, country
of origin `Guinea-Bissau`. List all seven columns. Right after it runs, save it with
`\w 1.1.sql` (it's graded by replaying it on an empty `person` table).

**1.2 (graded)** Insert Alex the same way: id `2`, `Alex`, `Yu`, gender `M`, born
4 September 1980, phone `000-000-000`, country `Italy`. Save it with `\w 1.2.sql`.

**1.3 (graded)** Query the `first_name`, `last_name` and `dob` of every person. Save
it with `\w 1.3.sql`.

**1.4 (drill)** Run `SELECT * FROM person;` - `*` means every column. Once the table
has more rows than fit on screen, psql opens a **pager**: `space` for the next page,
`/USA` then `enter` to search (`n` for the next hit), `q` to quit. `\pset pager off`
prints everything straight to the console, `\pset pager on` brings the pager back.

## Tier 2 - Sample data, aliases and ORDER BY

**2.1 (graded)** Start fresh like the video: remove Jamila and Alex with
`DELETE FROM person;` (you'll learn `DELETE` properly in section 05), then load the
100 sample people from `sample-data.sql` with `\i sample-data.sql`. `person` must end up
holding exactly those 100 people.

**2.2 (graded)** An alias renames a column in the output only. Query every person's
`first_name`, `last_name` and `dob`, renamed to `name`, `surname` and
`date_of_birth`. Save it with `\w 2.2.sql`.

**2.3 (graded)** Query `id`, `first_name` and `last_name` of everyone, highest id
first. Save it with `\w 2.3.sql`.

**2.4 (graded)** Query `first_name`, `last_name` and `country_of_origin` of everyone,
sorted by `first_name` A→Z and, where first names are equal, by `last_name` **Z→A**.
Save it with `\w 2.4.sql`.

## Tier 3 - Remove duplicates *(goal only)*

**3.1 (graded)** Marketing wants the list of countries our people come from:
`country_of_origin` only, each country once, A→Z. Save it with `\w 3.1.sql`.

**3.2 (graded)** Now every unique combination of `country_of_origin` and `gender`,
sorted by country and then gender. Save it with `\w 3.2.sql`.

## Self-check questions

1. Why does the order of the values in `VALUES (...)` matter, and what happens if it
   doesn't match the column list?
2. What does an alias change, and what does it leave alone?
3. What's the default direction of `ORDER BY`, and how does a second sort column work?
4. How does `DISTINCT` behave when you give it two columns instead of one?
