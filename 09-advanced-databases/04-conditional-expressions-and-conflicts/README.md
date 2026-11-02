# 04 · Conditional Expressions & Conflicts

> Maps to **Advanced Databases → Sections 10-11: Conditional Expressions, Dealing With Conflicts**
> (`COALESCE`, `NULLIF`, `CASE WHEN ... THEN ... ELSE ... END`, `ON CONFLICT DO NOTHING`, `ON CONFLICT DO UPDATE` / upsert, `EXCLUDED`)

Real data has gaps (`NULL` phone numbers), traps (dividing by zero) and
inconsistencies (`M` vs `MALE`), and real writes collide: a retried request, a
double-clicked button, a batch that runs twice. Conditional expressions handle the
first in the query itself; `ON CONFLICT` turns an insert that would crash into one
that is safe to run again and again.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Conditional Expressions & Conflicts** and
press `enter`. You land in `psql`, connected to the `my_db` database. Run each query,
then save it with `\w 1.1.sql` (use the question's number). `:questions` shows the
questions again, `:check` grades your work, and `exit` takes you back with your
progress saved. Press `r` in the Academy for a fresh start.

---

## Tier 1 - COALESCE, NULLIF and CASE *(hint: `COALESCE(a, b, 'default')`, `NULLIF(a, b)`, `CASE WHEN ... THEN ... ELSE ... END`)*

**1.1 (drill)** Try `SELECT COALESCE(NULL, NULL, 'hello');`, `SELECT NULLIF(1, 1), NULLIF(2, 1);`
and `SELECT 10 / 0;`, then `SELECT 10 / NULLIF(0, 0);`.

**1.2 (graded)** List every person's `first_name`, `last_name` and phone number,
showing `Unknown` when they have none. Save it as `1.2.sql`.

**1.3 (graded)** For each `campaign`, show the `name` and its click-through rate as a
whole-number percentage, `clicks * 100 / impressions` (integer division). Some
campaigns have `0` impressions: they must show `0` instead of crashing the query
(`NULLIF` + `COALESCE`). Save it as `1.3.sql`.

**1.4 (graded)** `gender` mixes `M`/`MALE` and `F`/`FEMALE`. List `first_name`,
`last_name` and the gender spelled out: `M` becomes `MALE`, `F` becomes `FEMALE`,
anything else stays as it is. Save it as `1.4.sql`.

**1.5 (graded)** Count people per gender in **one row with two columns**, the number
of men and the number of women (in that order), counting `M` as a man and `F` as a
woman: `COUNT(CASE WHEN ... THEN 1 END)`. Save it as `1.5.sql`.

**1.6 (graded)** Now fix the data itself: one `UPDATE` with a `CASE` so every `M`
becomes `MALE` and every `F` becomes `FEMALE`, and nobody else changes.

## Tier 2 - Dealing with conflicts *(hint: `INSERT ... ON CONFLICT (id) DO NOTHING`, `... DO UPDATE SET col = EXCLUDED.col`)*

These two are scripts the grader runs **twice in a row** (then rolls back), so they
must be safe to repeat. Run your `INSERT`, save it with `\w 2.1.sql`, then run the
saved file again with `\i 2.1.sql` and check that it still works.

**2.1 (graded)** The signup service resends people it already sent. Save as
`2.1.sql` one `INSERT` of these two rows that never fails, inserts Ada and
**ignores** row 3 (which already exists), keeping the stored Mark untouched:
```
(3,  'Marcus', 'Barajas',  'FEMALE', '1985-10-17', '001-308-674-9013x649', 'Rwanda')
(11, 'Ada',    'Lovelace', 'FEMALE', '1990-12-10', NULL,                   'United Kingdom')
```
(columns: `id, first_name, last_name, gender, dob, phone_number, country_of_origin`)

**2.2 (graded)** Mark got a new phone. The profile service sends whole rows, in its
own capitals. Save as `2.2.sql` an **upsert** of these two rows where a new
id is inserted and an existing id only gets its `phone_number` updated (the stored
names stay `Mark Barajas`):
```
(3,  'MARK',  'BARAJAS', 'FEMALE', '1985-10-17', '+44 7700 900123', 'Rwanda')
(12, 'Grace', 'Hopper',  'FEMALE', '1906-12-09', '+1 202 555 0199', 'United States')
```

## Tier 3 - An idempotent batch upsert *(goal only)*

> **Scenario:** the video player records which lectures each enrollment completed in
> `lecture_progress`. It never had a unique key, so retries left duplicate
> `(enrollment_id, lecture_id)` rows, and every night a batch of events lands in
> `incoming_progress`.

**3.1 (graded)** Clean up and protect the table: for each `(enrollment_id, lecture_id)`
pair keep only the **most recently updated** row (latest `updated_at`; careful, that's
not always the highest `id`), then add a unique constraint on
`(enrollment_id, lecture_id)`.

**3.2 (graded)** Save as `3.2.sql` **one** `INSERT ... SELECT ... ON CONFLICT`
statement (`\w 3.2.sql`, then `\i 3.2.sql` to run it again) that applies the whole `incoming_progress` batch to `lecture_progress`
(`completed` and `updated_at = event_at`). Running it twice must give the same
result as running it once. Two traps are in the batch:
- the same pair can appear twice in one batch: only its **latest** event counts
  (Postgres refuses to update one row twice in a single statement)
- an event older than what's stored must **not** overwrite it (`DO UPDATE ... WHERE`)

## Self-check questions

1. What does `COALESCE(phone_number, other_phone, 'Unknown')` return when both
   columns are `NULL`?
2. Why does `10 / NULLIF(x, 0)` never fail with "division by zero"?
3. What does `EXCLUDED` refer to inside `ON CONFLICT ... DO UPDATE`?
4. Why does `ON CONFLICT (enrollment_id, lecture_id)` need a unique constraint or
   index on exactly those columns?
5. What makes an upsert *idempotent*, and why does that matter for retries?
