# Solutions - Aggregates and Math

Run each query in `psql`, then save it with `\w <task>.sql`.

## Tier 1
**1.1** `\i car.sql` (`CREATE TABLE`, `INSERT 0 100`). Check with `SELECT * FROM car;`.

**1.2** `SELECT COUNT(*) FROM car;` then `\w 1.2.sql` (100)

**1.3** `SELECT brand, COUNT(*) FROM car GROUP BY brand;` then `\w 1.3.sql`

**1.4** `SELECT COUNT(*), COUNT(phone_number) FROM person;` then `\w 1.4.sql` (101 and 84)

## Tier 2
**2.1** `SELECT SUM(price) FROM car;` then `\w 2.1.sql`

**2.2** `SELECT brand, is_electric, SUM(price) FROM car GROUP BY brand, is_electric;` then `\w 2.2.sql`

**2.3** `SELECT brand, MIN(price), MAX(price), AVG(price) FROM car GROUP BY brand;` then `\w 2.3.sql`

**2.4** `SELECT brand, is_electric, COUNT(*) FROM car GROUP BY brand, is_electric;`

**2.5**
```
SELECT brand, COUNT(*) FROM car
GROUP BY brand
HAVING COUNT(*) >= 3;
\w 2.5.sql
```

**2.6**
```
SELECT brand, COUNT(*) FROM car
WHERE is_electric = TRUE
GROUP BY brand
HAVING COUNT(*) >= 3;
\w 2.6.sql
```
(`WHERE is_electric` works too: it's already a boolean.)

**2.7**
```
SELECT brand, SUM(price) FROM car
GROUP BY brand
HAVING SUM(price) >= 100000 AND AVG(price) > 40000;
\w 2.7.sql
```

## Tier 3
**3.1** `5`, `-1`, `6`, `5`, `32`, `1`; `2 * 2 + 10 / 2` is `9`.

**3.2**
```
SELECT brand, model, price,
       ROUND(price * .10, 2) AS "10%",
       ROUND(price - (price * .10), 2) AS offer
FROM car;
\w 3.2.sql
```

**3.3**
```
SELECT brand, MAX(price), ROUND(AVG(price), 2) AS average_price
FROM car
GROUP BY brand
ORDER BY MAX(price) DESC
LIMIT 5;
\w 3.3.sql
```
