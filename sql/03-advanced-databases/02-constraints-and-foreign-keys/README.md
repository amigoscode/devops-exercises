# 02 · Constraints & Foreign Keys

> Maps to **Advanced Databases → Sections 5-6: Constraints, Foreign Keys**
> (`PRIMARY KEY`, `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`, `FOREIGN KEY ... REFERENCES`, `ADD`/`DROP CONSTRAINT`, naming constraints, `ON DELETE CASCADE`)

Constraints are the database refusing bad data for you: no person without a name,
no negative price, no car owned by someone who doesn't exist. Application code has
bugs, scripts get run twice, imports are dirty. The constraint is the last line of
defence, and adding one to a table that already has rows means cleaning the data first.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Constraints & Foreign Keys** and press
`enter`. You land in `psql`, connected to the `my_db` database. Every task here
changes the database itself, and the grader tests it by trying to insert bad rows (in
a transaction it rolls back); `\d table` shows a table's constraints. `:questions`
shows the questions again, `:check` grades your work, and `exit` takes you back with
your progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - Constraints on an existing table *(hint: `ALTER TABLE person ADD CONSTRAINT name ...`)*

`person` and `car` were created with **no constraints at all**: try
`INSERT INTO person (id) VALUES (NULL);` and see it work. Fix `person` first.

**1.1 (graded)** Add a primary key on `person(id)` named `pk_person_id`.

**1.2 (graded)** Make `first_name`, `last_name`, `gender`, `dob` and
`country_of_origin` `NOT NULL` (`ALTER COLUMN ... SET NOT NULL`), and add a
constraint named `unique_phone_number` so no two people share a phone number.
`phone_number` itself stays optional: not everyone has one.

**1.3 (graded)** Someone added a `CHECK` that only lets people come from the UK or
the USA (find its name with `\d person`). Requirements changed: **drop** it, so
`Brazil` is a valid `country_of_origin`.

## Tier 2 - Constraints on car and the foreign key *(hint: `ADD CONSTRAINT ... CHECK (...)`, `ALTER COLUMN ... SET DEFAULT ...`)*

**2.1 (graded)** Fix `car` in one `ALTER TABLE` (comma-separated actions) or several:
- a primary key on `id` (call it `pk_car_id`)
- `brand` and `model` are `NOT NULL`
- `price` defaults to `0.0` and has a check `check_price` that it is `>= 0`
- `mileage` defaults to `0` and has a check `check_mileage` that it is `>= 0`
- `is_electric` defaults to `false`

**2.2 (graded)** Link each car to its owner: add a foreign key named
`fk_car_owner_id` from `car(owner_id)` to `person(id)`. Leave the delete behaviour at
its default: deleting a person who still owns a car must be refused.

**2.3 (graded)** Jamila Bob has just bought the `Tesla Cybertruck` (it has no owner
yet). Update the car so its `owner_id` points at her. Then try pointing it at an id
that doesn't exist and read the error.

## Tier 3 - Real-world constraint work *(goal only)*

**3.1 (graded)** `passport` came from a legacy import and is dirty. Make
`passport_number` **unique** and `person_id` a **foreign key** to `person(id)`. You'll
have to clean the data first: some passport numbers appear twice (keep the row with
the **lowest** `id`, delete the later copies) and some rows point at people who don't
exist (delete those). Delete nothing else.

**3.2 (graded)** Create `insurance_policy` with **named** constraints:
- `id BIGSERIAL`, primary key named `pk_insurance_policy_id`
- `policy_number VARCHAR(20)`, required and unique
- `car_id`, required, a foreign key named `fk_insurance_policy_car_id` to `car(id)`
  (no cascade: a car with a policy can't be deleted)
- `premium NUMERIC(10,2)`, required and greater than `0`
- `start_date` and `end_date` `DATE`, both required, and `end_date` must be after
  `start_date`

**3.3 (graded)** A teammate created `car_listing.dealership_id` with
`ON DELETE CASCADE`, so deleting a dealership silently wipes all its listings. Change
the foreign key so deleting a dealership that still has listings is **refused**
(drop the constraint and add it back without the cascade). Don't lose any listing.

## Self-check questions

1. Why does adding `NOT NULL` or `UNIQUE` to a table that already has rows sometimes
   fail, and what do you do about it?
2. What is the difference between a primary key and a unique constraint?
3. Why name your constraints (`pk_car_id`, `fk_car_owner_id`) instead of keeping the
   names Postgres generates?
4. What does `ON DELETE CASCADE` do, and why is it dangerous on real data?
