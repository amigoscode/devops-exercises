# 05 · Modifying Data

> Maps to **SQL and Databases Fundamentals → Section 13: Modifying Data**
> (`DELETE FROM ... WHERE`, `UPDATE ... SET ... WHERE`, updating several columns, CRUD)

Reading data can't hurt anyone - changing it can. `DELETE` and `UPDATE` are where one
forgotten `WHERE` wipes or overwrites every row in a table, so the habit you build
here is the important part: write the `WHERE`, check it with a `SELECT` first, and
target a single row by its unique `id`.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **SQL and Databases Fundamentals → Modifying Data** and press `enter`.
You land in `psql`, connected to the `my_db` database. Run each query, then save it
with `\w 1.1.sql` (use the question's number). `:questions` shows the questions
again, `:check` grades your work, and `exit` takes you back with your progress saved.
Press `r` in the Academy for a fresh start.

`my_db` holds `person` (with the lowercase `nelson`, id 101, from Filtering Data),
`car` (100 cars) and the `example` table from the `COUNT` video. Most tasks here are
graded on the live data, so if you delete too much, press `r` and start again.

---

## Tier 1 - DELETE *(hint: `DELETE FROM table WHERE condition;` - never without the `WHERE` unless you mean every row)*

**1.1 (graded)** The `example` table (ids `1`, `2`, `NULL`, `NULL`, `3`) has served its
purpose. Empty it with a `DELETE` that has **no** `WHERE` (psql reports `DELETE 5`),
check it's empty, then drop the table altogether.

**1.2 (graded)** Delete every `GMC` car - and nothing else.

**1.3 (graded)** Delete the BYD **Song** only. There are three BYDs, and two identical
cars could share a model and price, so target it by its unique `id` (look it up with
a `SELECT` first).

## Tier 2 - UPDATE *(hint: `UPDATE table SET column = value, other = value WHERE condition;`)*

**2.1 (graded)** Everyone without a phone number should show `unknown` instead of an
empty value. Update `phone_number` to `'unknown'` for exactly those people (psql says
`UPDATE 17`).

**2.2 (graded)** Person 101 only has a last name. Set their `first_name` to `Samba` -
for that person only.

**2.3 (graded)** In **one** `UPDATE`, give person 101 the last name `Nelson`
(capitalised), gender `M` and country of origin `Guinea-Bissau`.

**2.4 (graded)** Finally set person 101's date of birth to 30 January 2000.

**2.5 (drill)** Run `UPDATE person SET first_name = 'Ghost' WHERE id = 1000;` and
`DELETE FROM person WHERE id = 1000;`. psql answers `UPDATE 0` / `DELETE 0`: no row
matched, nothing changed. That number is how you confirm a statement touched what you
expected.

## Tier 3 - CRUD on the car table *(goal only)*

**3.1 (graded)** **C**reate: the dealership bought a car - id `101`, `Toyota`
`Supra`, price `55000.00`, mileage `3000`, not electric.

**3.2 (graded)** **R**ead: query the `brand`, `model` and `price` of every Ferrari.
Save it with `\w 3.2.sql`.

**3.3 (graded)** **U**pdate: Ferrari prices go up by 10%. Raise the price of every
Ferrari (and only Ferraris) to its current price × 1.10. Run your 3.2 query again to
see the new prices.

**3.4 (graded)** **D**elete: the dealership stops selling **non-electric** cars that
have done **22000 miles or more**. Delete exactly those - electric cars with high
mileage stay.

## Self-check questions

1. What happens if you run `DELETE FROM car;` or `UPDATE person SET dob = '2000-01-30';`
   without a `WHERE`?
2. Why delete or update a single row by its `id` rather than by `brand` or `model`?
3. How do you change three columns of the same row in one statement?
4. What do the numbers in `DELETE 2` and `UPDATE 0` tell you?
5. What does CRUD stand for, and which SQL statement goes with each letter?
