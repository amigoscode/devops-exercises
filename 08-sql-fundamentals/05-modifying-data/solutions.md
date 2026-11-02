# Solutions - Modifying Data

Run these in `psql` (connected to `my_db`). Before any `DELETE` or `UPDATE`, run the
same `WHERE` as a `SELECT` to see which rows it will touch.

## Tier 1
**1.1**
```
SELECT * FROM example;
DELETE FROM example;          -- DELETE 5
SELECT * FROM example;        -- (0 rows)
DROP TABLE example;
```

**1.2**
```sql
SELECT * FROM car WHERE brand = 'GMC';
DELETE FROM car WHERE brand = 'GMC';   -- DELETE 2
```

**1.3**
```sql
SELECT * FROM car WHERE brand = 'BYD';   -- the Song is id 15
DELETE FROM car WHERE id = 15;           -- DELETE 1
```

## Tier 2
**2.1** `UPDATE person SET phone_number = 'unknown' WHERE phone_number IS NULL;` (`UPDATE 17`)

**2.2** `UPDATE person SET first_name = 'Samba' WHERE id = 101;`

**2.3**
```sql
UPDATE person
SET last_name = 'Nelson', gender = 'M', country_of_origin = 'Guinea-Bissau'
WHERE id = 101;
```

**2.4** `UPDATE person SET dob = '2000-01-30' WHERE id = 101;`

**2.5** `UPDATE 0` and `DELETE 0` - there is no person 1000.

## Tier 3
**3.1**
```sql
INSERT INTO car (id, brand, model, price, mileage, is_electric)
VALUES (101, 'Toyota', 'Supra', 55000.00, 3000, FALSE);
```

**3.2** `SELECT brand, model, price FROM car WHERE brand = 'Ferrari';` then `\w 3.2.sql`

**3.3** `UPDATE car SET price = price * 1.10 WHERE brand = 'Ferrari';` (`UPDATE 6`)

**3.4**
```sql
SELECT * FROM car WHERE is_electric = FALSE AND mileage >= 22000;
DELETE FROM car WHERE is_electric = FALSE AND mileage >= 22000;   -- DELETE 3
```
