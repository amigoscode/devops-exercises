# Solutions - Relationships and Joins

Run these in `psql` (connected to `my_db`). Save each query with
`\w <task>.sql` right after it runs.

## Tier 1
**1.1**
```
ALTER TABLE car ADD owner_id INTEGER,
    ADD CONSTRAINT fk_person FOREIGN KEY (owner_id) REFERENCES person (id);
-- ERROR:  there is no unique constraint matching given keys for referenced table "person"
ALTER TABLE person ADD CONSTRAINT pk_id PRIMARY KEY (id);
```

**1.2**
```sql
ALTER TABLE car ADD owner_id INTEGER,
    ADD CONSTRAINT fk_person FOREIGN KEY (owner_id) REFERENCES person (id);
```

**1.3**
```sql
UPDATE car SET owner_id = 1 WHERE id = 5;
UPDATE car SET owner_id = 1 WHERE id = 4;
UPDATE car SET owner_id = 2 WHERE id = 2;
SELECT * FROM car WHERE owner_id IS NOT NULL;
```

## Tier 2
**2.1** `\x auto`, then `SELECT * FROM person JOIN car ON person.id = car.owner_id;`

**2.2**
```
SELECT person.first_name, person.last_name, car.brand, car.model
FROM person
JOIN car ON person.id = car.owner_id;
\w 2.2.sql
```
(`INNER JOIN` is the same as `JOIN`.)

**2.3**
```
SELECT person.first_name, person.last_name, car.brand, car.model
FROM person
LEFT JOIN car ON person.id = car.owner_id;
\w 2.3.sql
```

**2.4**
```
SELECT person.id, person.first_name, person.last_name
FROM person
LEFT JOIN car ON person.id = car.owner_id
WHERE car.id IS NULL;
\w 2.4.sql
```

**2.5**
```
SELECT person.first_name, person.last_name, car.brand, car.model
FROM person
RIGHT JOIN car ON person.id = car.owner_id;
\w 2.5.sql
```
(Same result: `FROM car LEFT JOIN person ON person.id = car.owner_id`.)

**2.6**
```
SELECT car.id, car.brand, car.model
FROM person
RIGHT JOIN car ON person.id = car.owner_id
WHERE person.id IS NULL;
\w 2.6.sql
```

## Tier 3
**3.1** `SELECT * FROM person FULL JOIN car ON person.id = car.owner_id;` then `\w 3.1.sql` (`FULL OUTER JOIN` is the same.)

**3.2**
```
SELECT person.first_name, person.last_name, car.brand, car.model
FROM person
FULL JOIN car ON person.id = car.owner_id
WHERE person.id IS NULL OR car.id IS NULL;
\w 3.2.sql
```

**3.3** `SELECT COUNT(*) FROM person CROSS JOIN car;` is 101 × 97 = 9797.

**3.4**
```
SELECT car.id AS car_id, person.id AS person_id, person.first_name, car.brand, car.model
FROM person
JOIN car ON person.id = car.owner_id;
\w 3.4.sql
```

**3.5**
```sql
ALTER TABLE person RENAME COLUMN id TO person_id;
ALTER TABLE car RENAME COLUMN owner_id TO person_id;

SELECT person.first_name, person.last_name, car.brand, car.model
FROM person
JOIN car USING (person_id);
\w 3.5.sql

ALTER TABLE car RENAME COLUMN person_id TO owner_id;
ALTER TABLE person RENAME COLUMN person_id TO id;
```

**3.6**
```
SELECT person.first_name, person.last_name, COUNT(*) AS cars
FROM person
JOIN car ON person.id = car.owner_id
GROUP BY person.id, person.first_name, person.last_name
ORDER BY cars DESC;
\w 3.6.sql
```
