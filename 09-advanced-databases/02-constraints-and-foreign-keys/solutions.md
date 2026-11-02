# Solutions - Constraints & Foreign Keys

Run these in `psql` (you land in `my_db`). `\d person` / `\d car` show the result.

## Tier 1 - Constraints on an existing table

**1.1**
```sql
ALTER TABLE person ADD CONSTRAINT pk_person_id PRIMARY KEY (id);
```

**1.2**
```sql
ALTER TABLE person
  ALTER COLUMN first_name SET NOT NULL,
  ALTER COLUMN last_name SET NOT NULL,
  ALTER COLUMN gender SET NOT NULL,
  ALTER COLUMN dob SET NOT NULL,
  ALTER COLUMN country_of_origin SET NOT NULL,
  ADD CONSTRAINT unique_phone_number UNIQUE (phone_number);
```
`UNIQUE` allows any number of `NULL`s, so people without a phone are fine.

**1.3**
```sql
\d person
ALTER TABLE person DROP CONSTRAINT check_country_of_origin;
```

## Tier 2 - Constraints on car and the foreign key

**2.1**
```sql
ALTER TABLE car
  ADD CONSTRAINT pk_car_id PRIMARY KEY (id),
  ALTER COLUMN brand SET NOT NULL,
  ALTER COLUMN model SET NOT NULL,
  ALTER COLUMN price SET DEFAULT 0.0,
  ADD CONSTRAINT check_price CHECK (price >= 0),
  ALTER COLUMN mileage SET DEFAULT 0,
  ADD CONSTRAINT check_mileage CHECK (mileage >= 0),
  ALTER COLUMN is_electric SET DEFAULT FALSE;
```

**2.2**
```sql
ALTER TABLE car
  ADD CONSTRAINT fk_car_owner_id FOREIGN KEY (owner_id) REFERENCES person(id);
```
`\d person` now shows *Referenced by: TABLE "car" CONSTRAINT "fk_car_owner_id"*.
`DELETE FROM person WHERE id = 2;` fails: John still owns cars.

**2.3**
```sql
SELECT id FROM person WHERE first_name = 'Jamila' AND last_name = 'Bob';  -- 1
UPDATE car SET owner_id = 1 WHERE brand = 'Tesla' AND model = 'Cybertruck';
UPDATE car SET owner_id = 9999 WHERE id = 5;
-- ERROR: insert or update on table "car" violates foreign key constraint "fk_car_owner_id"
-- DETAIL: Key (owner_id)=(9999) is not present in table "person".
```

## Tier 3 - Real-world constraint work

**3.1** Clean first, then constrain:
```sql
-- later copies of the same passport number
DELETE FROM passport p
USING passport keep
WHERE p.passport_number = keep.passport_number
  AND p.id > keep.id;

-- passports of people who don't exist
DELETE FROM passport
WHERE NOT EXISTS (SELECT 1 FROM person WHERE person.id = passport.person_id);

ALTER TABLE passport
  ADD CONSTRAINT unique_passport_number UNIQUE (passport_number),
  ADD CONSTRAINT fk_passport_person_id FOREIGN KEY (person_id) REFERENCES person(id);
```
Running the `ALTER TABLE` first fails with *could not create unique index* /
*violates foreign key constraint*: that's the database telling you to clean up.

**3.2**
```sql
CREATE TABLE insurance_policy (
  id            BIGSERIAL,
  policy_number VARCHAR(20) NOT NULL,
  car_id        BIGINT NOT NULL,
  premium       NUMERIC(10,2) NOT NULL,
  start_date    DATE NOT NULL,
  end_date      DATE NOT NULL,
  CONSTRAINT pk_insurance_policy_id PRIMARY KEY (id),
  CONSTRAINT unique_policy_number UNIQUE (policy_number),
  CONSTRAINT fk_insurance_policy_car_id FOREIGN KEY (car_id) REFERENCES car(id),
  CONSTRAINT check_premium CHECK (premium > 0),
  CONSTRAINT check_policy_dates CHECK (end_date > start_date)
);
```
It needs `car`'s primary key from 2.1: a foreign key can only reference a primary key
or unique column.

**3.3**
```sql
\d car_listing
ALTER TABLE car_listing
  DROP CONSTRAINT fk_car_listing_dealership_id,
  ADD CONSTRAINT fk_car_listing_dealership_id
    FOREIGN KEY (dealership_id) REFERENCES dealership(id);
```
Now `DELETE FROM dealership WHERE id = 1;` fails with *is still referenced from table
"car_listing"*. You decide what happens to those listings (move them, archive them,
soft-delete the dealership) instead of Postgres deleting them behind your back.
