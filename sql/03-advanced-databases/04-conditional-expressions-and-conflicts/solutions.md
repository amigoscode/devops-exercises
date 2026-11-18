# Solutions - Conditional Expressions & Conflicts

Run these in `psql` (you land in `my_db`). For query tasks, run the query, then
save it with `\w <task>.sql` (it lands in your sandbox folder).

## Tier 1 - COALESCE, NULLIF and CASE

**1.1** `COALESCE` returns its first non-`NULL` argument (`hello`). `NULLIF(a, b)` is
`NULL` when `a = b`, otherwise `a` (`NULL`, `2`). `10 / 0` is an error; `10 / NULL` is
just `NULL`.

**1.2**
```sql
SELECT first_name, last_name, COALESCE(phone_number, 'Unknown') AS phone_number
FROM person;
\w 1.2.sql
```

**1.3**
```sql
SELECT name, COALESCE(clicks * 100 / NULLIF(impressions, 0), 0) AS ctr_percent
FROM campaign;
\w 1.3.sql
```
`NULLIF(impressions, 0)` turns a zero into `NULL`, dividing by `NULL` gives `NULL`,
and `COALESCE` turns that into `0`.

**1.4**
```sql
SELECT first_name, last_name,
  CASE
    WHEN gender = 'M' THEN 'MALE'
    WHEN gender = 'F' THEN 'FEMALE'
    ELSE gender
  END AS gender
FROM person;
\w 1.4.sql
```

**1.5**
```sql
SELECT
  COUNT(CASE WHEN gender IN ('MALE', 'M') THEN 1 END)   AS male_count,
  COUNT(CASE WHEN gender IN ('FEMALE', 'F') THEN 1 END) AS female_count
FROM person;
\w 1.5.sql
```
A `CASE` without `ELSE` is `NULL` for the other rows, and `COUNT` skips `NULL`s.

**1.6**
```sql
UPDATE person
SET gender = CASE
               WHEN gender = 'M' THEN 'MALE'
               WHEN gender = 'F' THEN 'FEMALE'
               ELSE gender
             END;
```
(`UPDATE person SET gender = 'MALE' WHERE gender = 'M';` plus the same for `F` works
too; one statement with `CASE` touches the table once.)

## Tier 2 - Dealing with conflicts

**2.1** Run the `INSERT`, then save it and run it again:
```sql
INSERT INTO person (id, first_name, last_name, gender, dob, phone_number, country_of_origin)
VALUES
  (3,  'Marcus', 'Barajas',  'FEMALE', '1985-10-17', '001-308-674-9013x649', 'Rwanda'),
  (11, 'Ada',    'Lovelace', 'FEMALE', '1990-12-10', NULL,                   'United Kingdom')
ON CONFLICT (id) DO NOTHING;
\w 2.1.sql
\i 2.1.sql
```
The first run prints `INSERT 0 1` (Ada goes in, row 3 is skipped); `\i 2.1.sql`
prints `INSERT 0 0` and doesn't fail. Without `ON CONFLICT` it fails with *duplicate key value violates unique
constraint "person_pkey"* and inserts nothing at all.

**2.2**
```sql
INSERT INTO person (id, first_name, last_name, gender, dob, phone_number, country_of_origin)
VALUES
  (3,  'MARK',  'BARAJAS', 'FEMALE', '1985-10-17', '+44 7700 900123', 'Rwanda'),
  (12, 'Grace', 'Hopper',  'FEMALE', '1906-12-09', '+1 202 555 0199', 'United States')
ON CONFLICT (id) DO UPDATE
SET phone_number = EXCLUDED.phone_number;
\w 2.2.sql
\i 2.2.sql
```
`EXCLUDED` is the row you tried to insert. Listing only `phone_number` in `SET`
leaves every other stored column alone.

## Tier 3 - An idempotent batch upsert

**3.1**
```sql
-- see the duplicates
SELECT enrollment_id, lecture_id, count(*)
FROM lecture_progress GROUP BY 1, 2 HAVING count(*) > 1;

-- delete every row that has a more recently updated twin
DELETE FROM lecture_progress lp
USING lecture_progress newer
WHERE lp.enrollment_id = newer.enrollment_id
  AND lp.lecture_id = newer.lecture_id
  AND (lp.updated_at < newer.updated_at
       OR (lp.updated_at = newer.updated_at AND lp.id < newer.id));

ALTER TABLE lecture_progress
  ADD CONSTRAINT unique_enrollment_lecture UNIQUE (enrollment_id, lecture_id);
```
"Keep the highest id" would keep the stale `(2, 1)` row: it was inserted last but
carries an older `updated_at`.

**3.2**
```sql
INSERT INTO lecture_progress (enrollment_id, lecture_id, completed, updated_at)
SELECT DISTINCT ON (enrollment_id, lecture_id)
       enrollment_id, lecture_id, completed, event_at
FROM incoming_progress
ORDER BY enrollment_id, lecture_id, event_at DESC
ON CONFLICT (enrollment_id, lecture_id) DO UPDATE
SET completed  = EXCLUDED.completed,
    updated_at = EXCLUDED.updated_at
WHERE lecture_progress.updated_at < EXCLUDED.updated_at;
\w 3.2.sql
\i 3.2.sql
```
- `DISTINCT ON ... ORDER BY ... event_at DESC` keeps one row per pair, the latest.
  Without it: *ON CONFLICT DO UPDATE command cannot affect row a second time*.
- The `WHERE` on `DO UPDATE` skips stale events, so `(2, 3)` stays completed.
- Running it again changes nothing: the stored rows already have those timestamps,
  so `<` is false. That is what makes the job safe to retry.
