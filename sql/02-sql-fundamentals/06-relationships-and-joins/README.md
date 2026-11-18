# 06 · Relationships and Joins

> Maps to **SQL and Databases Fundamentals → Section 14: Relationships**, **Section 15: Joins** and **Section 16: Order of SQL**
> (one-to-one / one-to-many / many-to-many, `PRIMARY KEY`, `FOREIGN KEY ... REFERENCES`, `INNER`/`LEFT`/`RIGHT`/`FULL JOIN`, joins with `IS NULL`, `table.*`, `USING`, the order SQL runs in)

Real data lives in more than one table: people in `person`, cars in `car`. A primary
key and a foreign key are what link them, and joins are how you bring them back
together in one result - "who owns which car", "who has no car", "which cars have no
owner". This is the part of SQL you'll use in almost every real query.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **SQL and Databases Fundamentals → Relationships and Joins** and press `enter`.
You land in `psql`, connected to the `my_db` database. Run each query, then save it
with `\w 1.1.sql` (use the question's number). `:questions` shows the questions
again, `:check` grades your work, and `exit` takes you back with your progress saved.
Press `r` in the Academy for a fresh start.

`my_db` is where Modifying Data left it: `person` (101 people, Samba Nelson is 101) and
`car` (97 cars), with no keys and no link between them yet. Your saved queries are
graded against an untouched copy that already has the keys and the three owned cars
from Tier 1.

---

## Tier 1 - Primary and foreign keys *(hint: `ALTER TABLE ... ADD CONSTRAINT name PRIMARY KEY (col)` / `FOREIGN KEY (col) REFERENCES table (col)`)*

One person can own **many** cars, each car has **at most one** owner: a one-to-many
relationship. The `car` table gets an `owner_id` column that points at `person.id`.

**1.1 (graded)** First try the link straight away:
`ALTER TABLE car ADD owner_id INTEGER, ADD CONSTRAINT fk_person FOREIGN KEY (owner_id) REFERENCES person (id);`
It fails: *there is no unique constraint matching given keys for referenced table
"person"* - `person.id` isn't unique yet. Make `id` the **primary key** of `person`
(name the constraint `pk_id`). `\d person` should then show `"pk_id" PRIMARY KEY`.

**1.2 (graded)** Now run the statement from 1.1 again: `car` gets an `owner_id INTEGER`
column with a foreign key `fk_person` that references `person (id)`. `\d car` shows
it under *Foreign-key constraints*.

**1.3 (graded)** Assign cars with `UPDATE car SET owner_id = ... WHERE id = ...`: Ahmed
(person `1`) owns the Lamborghini Huracan (car `5`) and the Tesla Model Y (car `4`),
Aisha (person `2`) owns the Tesla Model 3 (car `2`). No other car has an owner. (Forgot
the `WHERE` and gave Ahmed all 97 cars, like the video? Undo it with
`UPDATE car SET owner_id = NULL;` and redo the three.)

## Tier 2 - INNER, LEFT and RIGHT JOIN *(hint: `FROM person JOIN car ON person.id = car.owner_id`)*

**2.1 (drill)** Run `SELECT * FROM person JOIN car ON person.id = car.owner_id;` - the
rows are too wide for the screen. `\x auto` switches to **expanded display** whenever a
result doesn't fit (`\x` toggles it by hand).

**2.2 (graded)** `INNER JOIN` (or just `JOIN`): `person.first_name`,
`person.last_name`, `car.brand` and `car.model` for every person who owns a car. Save
it with `\w 2.2.sql`.

**2.3 (graded)** `LEFT JOIN`: the same four columns for **every** person - with their
cars if they have any, `NULL`s if they don't. Save it with `\w 2.3.sql`.

**2.4 (graded)** `LEFT JOIN` with a `NULL` check: `person.id`, `first_name` and
`last_name` of the people who **don't** own a car (marketing wants to send them an
offer). Save it with `\w 2.4.sql`.

**2.5 (graded)** `RIGHT JOIN`: `first_name`, `last_name`, `brand` and `model` for
**every car** - with its owner if it has one. Keep `FROM person` and join `car` on the
right. Save it with `\w 2.5.sql`.

**2.6 (graded)** `RIGHT JOIN` with a `NULL` check: `car.id`, `brand` and `model` of the
cars **without** an owner. Save it with `\w 2.6.sql`.

## Tier 3 - FULL JOIN, column names, USING and the order of SQL *(goal only)*

**3.1 (graded)** Everything from both tables: `SELECT *` from `person` `FULL JOIN`
`car` - people with cars, people without cars and cars without owners. Save it with
`\w 3.1.sql`.

**3.2 (graded)** Only the unmatched rows from both sides: `first_name`, `last_name`,
`brand` and `model` of the people without a car **and** the cars without an owner, in
one query. Save it with `\w 3.2.sql`.

**3.3 (drill)** Two more joins from the lecture notes: a `CROSS JOIN` pairs every row
with every row - predict `SELECT COUNT(*) FROM person CROSS JOIN car;` before you run
it. A **self join** joins a table to itself with two aliases (`FROM person p1 JOIN
person p2 ON ...`) to compare rows of the same table.

**3.4 (graded)** Both tables have an `id` column, so `SELECT car.*, person.*` gives
you two columns called `id`, and `table.*` can't rename them. For the owned cars,
return columns named exactly `car_id`, `person_id`, `first_name`, `brand` and `model`.
Save it with `\w 3.4.sql`.

**3.5 (graded)** `USING (column)` replaces `ON a.col = b.col` when both columns have
the **same name**. Rename `person.id` to `person_id` and `car.owner_id` to `person_id`
(`ALTER TABLE ... RENAME COLUMN ... TO ...`), write the inner join from 2.2 with
`USING (person_id)` and save it with `\w 3.5.sql`. Then, like the video, rename
both columns **back** to `id` and `owner_id`.

**3.6 (graded)** Postgres runs a query in this order: `FROM`/`JOIN` → `WHERE` →
`GROUP BY` → `HAVING` → `SELECT` → `ORDER BY` → `LIMIT`. Put it to work: for every
person who owns a car, `first_name`, `last_name` and how many cars they own (as
`cars`), the biggest owner first. Save it with `\w 3.6.sql`.

## Self-check questions

1. Give an example of a one-to-one, a one-to-many and a many-to-many relationship. How
   is many-to-many usually implemented?
2. Why couldn't `owner_id` reference `person.id` until `id` was a primary key?
3. A `LEFT JOIN` returned 102 rows for 101 people. How is that possible?
4. Which `WHERE` turns a `LEFT JOIN` into "people without a car", and why does a
   `RIGHT JOIN` give the same result as a `LEFT JOIN` with the tables swapped?
5. Why can you `ORDER BY cars` (an alias from `SELECT`) but not use it in `WHERE`?
