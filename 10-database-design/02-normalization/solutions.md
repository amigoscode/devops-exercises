# Solutions - Database Normalization

Run these in `psql` (the Academy connects you to the `normalization` database).

## Tier 1 - First normal form (1NF)

**1.1**
```sql
SELECT id, first_name, phone_numbers
FROM user_profile
WHERE phone_numbers LIKE '%,%';
```
then `\w 1.1.sql`.

**1.2**
```sql
CREATE TABLE phone_number (
    id              BIGSERIAL PRIMARY KEY,
    user_profile_id BIGINT NOT NULL REFERENCES user_profile (id),
    phone_number    TEXT NOT NULL UNIQUE
);
```

**1.3** Split each list into rows, then drop the old column:
```sql
INSERT INTO phone_number (user_profile_id, phone_number)
SELECT id, trim(n)
FROM user_profile, unnest(string_to_array(phone_numbers, ',')) AS n;

ALTER TABLE user_profile DROP COLUMN phone_numbers;
```
(Typing the eleven `INSERT`s by hand works just as well.)

## Tier 2 - Second normal form (2NF)

**2.1**
```sql
CREATE TABLE address (
    id              BIGSERIAL PRIMARY KEY,
    user_profile_id BIGINT NOT NULL REFERENCES user_profile (id),
    address         TEXT NOT NULL,
    postcode        TEXT NOT NULL
);
INSERT INTO address (user_profile_id, address, postcode)
SELECT id, address, postcode FROM user_profile;

ALTER TABLE user_profile DROP COLUMN address, DROP COLUMN postcode;
```

**2.2** The category belongs to the channel (the part of the key it depends on):
```sql
ALTER TABLE youtube_channel ADD COLUMN category TEXT;

UPDATE youtube_channel c
SET category = s.youtube_channel_category
FROM channel_subscriber s
WHERE s.youtube_channel_id = c.id;

ALTER TABLE channel_subscriber DROP COLUMN youtube_channel_category;
```

## Tier 3 - Third normal form (3NF)

**3.1**
```sql
CREATE TABLE winner (
    name          TEXT PRIMARY KEY,
    date_of_birth DATE NOT NULL
);
INSERT INTO winner (name, date_of_birth)
SELECT DISTINCT winner, winner_date_of_birth FROM tournament_winner;

ALTER TABLE tournament_winner
    ADD CONSTRAINT tournament_winner_winner_fkey FOREIGN KEY (winner) REFERENCES winner (name),
    DROP COLUMN winner_date_of_birth;
```

**3.2**
```sql
SELECT t.tournament, t.year, t.winner, w.date_of_birth
FROM tournament_winner t
JOIN winner w ON w.name = t.winner;
```
then `\w 3.2.sql`.

**3.3**
```sql
UPDATE winner SET date_of_birth = '1975-07-12' WHERE name = 'Al Fredrickson';
```
`UPDATE 1` - before 3.1 the same fix meant updating three rows (and missing one
would leave the data contradicting itself).
