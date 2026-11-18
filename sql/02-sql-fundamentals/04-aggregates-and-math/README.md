# 04 · Aggregates and Math

> Maps to **SQL and Databases Fundamentals → Section 11: Grouping and Aggregate Functions** and **Section 12: Mathematical Operators and Functions**
> (`GROUP BY`, `COUNT`, `SUM`, `MIN`/`MAX`/`AVG`, `HAVING`, `+ - * / ^ %`, `ROUND`)

"How many cars per brand?", "What's the average price?", "Which brands are worth over
100k?" - managers ask for summaries, not rows. Grouping and aggregate functions turn a
table into those answers, and arithmetic in the `SELECT` lets you build a report (like
a 10% promotion) straight from the data.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **SQL and Databases Fundamentals → Aggregates and Math** and press `enter`.
You land in `psql`, connected to the `my_db` database. Run each query, then save it
with `\w 1.1.sql` (use the question's number). `:questions` shows the questions
again, `:check` grades your work, and `exit` takes you back with your progress saved.
Press `r` in the Academy for a fresh start.

`my_db` holds the `person` table from the previous sections. Your saved queries are
graded against an untouched copy of the data (with the `car` table from 1.1 already
loaded).

---

## Tier 1 - GROUP BY and COUNT *(hint: `SELECT col, COUNT(*) FROM car GROUP BY col;`)*

**1.1 (graded)** The new data set: the file `car.sql` in your sandbox folder creates a `car` table
(`id`, `brand`, `model`, `price`, `mileage`, `is_electric`) and inserts 100 cars. Run
it with `\i car.sql` so `my_db` has all 100 cars.

**1.2 (graded)** How many cars are there? One number. Save it with `\w 1.2.sql`.

**1.3 (graded)** How many cars of each brand: `brand` and the count. Save it with
`\w 1.3.sql`.

**1.4 (graded)** `COUNT(*)` counts rows, `COUNT(column)` counts only the non-NULL
values. In **one** query on `person`, return two numbers: how many people there are,
and how many of them have a phone number. Save it with `\w 1.4.sql`.

## Tier 2 - SUM, MIN/MAX/AVG and HAVING

**2.1 (graded)** The total price of all the cars together. Save it with
`\w 2.1.sql`.

**2.2 (graded)** The total price per `brand` **and** `is_electric` (e.g. Audi's
electric cars and Audi's non-electric cars on separate rows): `brand`, `is_electric`,
total. Save it with `\w 2.2.sql`.

**2.3 (graded)** For each `brand`: the cheapest price, the most expensive price and the
average price, in that order (don't round the average). Save it with `\w 2.3.sql`.

**2.4 (drill)** Run `SELECT brand, is_electric, COUNT(*) FROM car GROUP BY brand;`
and read the error: *column "car.is_electric" must appear in the GROUP BY clause or be
used in an aggregate function*. Every column you select must either be grouped or be
inside an aggregate. Fix it by grouping by both.

**2.5 (graded)** `HAVING` filters groups after grouping (`WHERE` filters rows before).
`brand` and car count for the brands with **at least 3** cars. Save it with
`\w 2.5.sql`.

**2.6 (graded)** The same, but count **only electric cars**: brands with at least 3
electric cars. Save it with `\w 2.6.sql`.

**2.7 (graded)** `brand` and total price for the brands whose cars add up to **at
least 100000** and whose average price is **above 40000**. Save it with
`\w 2.7.sql`.

## Tier 3 - Mathematical operators and functions *(goal only)*

**3.1 (drill)** `SELECT` can calculate: try `SELECT 2 + 3 AS result;`, then `2 - 3`,
`2 * 3`, `10 / 2`, `2 ^ 5` and `10 % 3`. Then predict `SELECT 2 * 2 + 10 / 2;` before
running it (BODMAS: division and multiplication before addition).

**3.2 (graded)** There's a 10% promotion. For every car return `brand`, `model`,
`price`, 10% of the price as a column named `10%`, and the price minus that 10% as a
column named `offer` - both **rounded to 2 decimal places**. (An alias that starts
with a digit or contains `%` needs double quotes.) Save it with `\w 3.2.sql`.

**3.3 (graded)** The 5 brands with the most expensive single car: `brand`, its
highest price and its average price rounded to 2 decimal places, sorted by the highest
price (most expensive first), only 5 rows. Save it with `\w 3.3.sql`.

## Self-check questions

1. What does `GROUP BY brand` do on its own, without an aggregate function?
2. What's the difference between `COUNT(*)` and `COUNT(phone_number)`?
3. When do you use `HAVING` instead of `WHERE`, and can a query have both?
4. Why does `SELECT brand, is_electric, COUNT(*) FROM car GROUP BY brand` fail?
5. What does `ROUND(price * .10, 2)` do, and what's the second argument for?
