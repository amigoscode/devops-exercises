# 05 · Working with Tables

> Maps to **Up and Running with SQL and Databases → Section 7: Working with Tables**
> (tables, columns and rows, data types, `CREATE TABLE`, `\dt`, `\d table`, `ALTER TABLE ... RENAME TO`, `RENAME COLUMN`, `DROP TABLE`, the `public` schema)

A table is a collection of related data organised in **rows** and **columns**. Each
column is a **field** with a **data type** - numbers, text, dates - and each row is a
**record**. Picking the right type (`INTEGER`, `VARCHAR(50)`, `CHAR(1)`, `DATE`,
`TEXT`...) makes the data easier to query and work with. Here you'll create, describe,
rename and drop tables, and build the `person` table from the videos.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Up and Running with SQL and Databases → Working with Tables** and
press `enter`. You land in `psql`, connected to the `my_db` database. End every SQL
statement with `;`. To save what a psql command prints, send it to a file with
`\o person.txt`, run the command, then type `\o` to get the screen back. `:questions`
shows the questions again, `:check` grades your work, and `exit` takes you back with your
progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - Create, rename and drop tables *(hint: `CREATE TABLE name ();`, `ALTER TABLE old RENAME TO new;`, `DROP TABLE name;`)*

**1.1 (drill)** You're connected to `my_db` (the prompt says `my_db=#`). Run
`\h CREATE TABLE`, then `\dt` to list the tables someone already created and
`\d custmer` to describe one: its columns, their types, nullable and default.

**1.2 (graded)** Create a table called `car` with **no columns yet**, the way the
video starts with `person`. Check it appears in `\dt`.

**1.3 (graded)** The `custmer` table has a typo in its name. Rename it to `customer`
(keep the table and its rows - don't drop it).

**1.4 (graded)** `temp_import` was only needed once. Drop it (remember: `DROP TABLE`
throws away every row in the table) - and nothing else.

## Tier 2 - Columns and data types *(hint: `CREATE TABLE person (column_name TYPE, ...);`)*

**2.1 (graded)** Create the improved `person` table from the videos, with exactly
these columns:

| Column | Type |
|--------|------|
| `id` | `INTEGER` |
| `first_name` | `VARCHAR(50)` |
| `last_name` | `VARCHAR(50)` |
| `gender` | `CHAR(1)` |
| `date_of_birth` | `DATE` |
| `phone_number` | `VARCHAR(15)` |
| `country_of_origin` | `VARCHAR(50)` |

Made a mistake? `DROP TABLE person;`, press the up arrow and fix it.

**2.2 (graded)** Like the `phone_numebr` typo in the video, the `customer` table has a
column called `emial`. Rename that column to `email` (keep the data in it).

**2.3 (graded)** Describe your `person` table with `\d person` and save that
description in `person.txt`. Notice the title says `public.person`: tables
go into the `public` schema unless you say otherwise.

## Tier 3 - Design a table *(goal only)*

**3.1 (graded)** Amigoscode wants a `course` table. Pick the right data type for each
column:
- `id` - a whole number
- `title` - text of at most 100 characters
- `description` - text of any length
- `level` - exactly one character (`B`, `I` or `A`)
- `published_on` - a calendar date

## Self-check questions

1. What's the difference between a field, a record and a value?
2. When would you choose `VARCHAR(50)` over `TEXT`, and why is a phone number stored as
   text rather than a number?
3. Is `CREATE TABLE person (...)` different from `CREATE TABLE public.person (...)`?
4. Your `person` table accepts a person with no name and two people with the same `id`.
   What's missing? (You'll fix it with constraints in the next course.)
