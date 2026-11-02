# Solutions - Designing a Database

Run these in `psql` (the Academy connects you to the `youtube` database).

## Tier 1 - Entities, attributes and keys

**1.1** Drill: in diagrams.net, *Entity Relation* → drag a **Table** shape per entity.
Rows are attributes; mark `PK` for the primary key and `UN1` for the unique email;
add a column to the right for the data types (`BIGSERIAL`, `TEXT`, `TIMESTAMP`).

**1.2** + **1.3** in one statement (the course's final version):
```sql
CREATE TABLE IF NOT EXISTS user_profile (
    id         BIGSERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name  TEXT NOT NULL,
    email      TEXT NOT NULL UNIQUE,
    gender     TEXT NOT NULL CHECK (gender IN ('MALE', 'FEMALE')),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
```
If you created it without the rules first (1.2 only), add them afterwards:
```sql
ALTER TABLE user_profile ADD CONSTRAINT user_profile_email_key UNIQUE (email);
ALTER TABLE user_profile ADD CONSTRAINT user_profile_gender_check CHECK (gender IN ('MALE', 'FEMALE'));
ALTER TABLE user_profile ALTER COLUMN first_name SET NOT NULL, ALTER COLUMN last_name SET NOT NULL,
  ALTER COLUMN email SET NOT NULL, ALTER COLUMN gender SET NOT NULL, ALTER COLUMN created_at SET NOT NULL;
```
(The primary key `id` is already NOT NULL.)

## Tier 2 - Relationships

**2.1** One-to-one: the primary key is also the foreign key.
```sql
CREATE TABLE IF NOT EXISTS youtube_account (
    id         BIGINT PRIMARY KEY REFERENCES user_profile (id),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
```

**2.2** One-to-many: a NOT NULL foreign key with no unique constraint on it.
```sql
CREATE TABLE IF NOT EXISTS youtube_channel (
    id                 BIGSERIAL PRIMARY KEY,
    youtube_account_id BIGINT NOT NULL REFERENCES youtube_account (id),
    channel_name       TEXT NOT NULL UNIQUE,
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
```

**2.3** Many-to-many: a link table with a composite primary key.
```sql
CREATE TABLE IF NOT EXISTS channel_subscriber (
    youtube_account_id BIGINT REFERENCES youtube_account (id),
    youtube_channel_id BIGINT REFERENCES youtube_channel (id),
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (youtube_account_id, youtube_channel_id)
);
```

**2.4** Drill: select each line → *Style* → *Line start* / *Line end*:
`user_profile` *one and only one* → `youtube_account` *zero or one*;
`youtube_account` *one and only one* → `youtube_channel` *one or many*;
both `youtube_account` and `youtube_channel` *one and only one* → `channel_subscriber`
*zero or many*.

## Tier 3 - Put the design to work

**3.1**
```
\i sample-data.sql
```

**3.2**
```sql
SELECT c.channel_name, count(s.youtube_account_id) AS subscribers
FROM youtube_channel c
LEFT JOIN channel_subscriber s ON s.youtube_channel_id = c.id
GROUP BY c.id, c.channel_name;
```
then `\w 3.2.sql`. (`count(*)` would count 1 for a channel with no
subscribers - count a column from the right-hand table instead.)

**3.3**
```sql
SELECT p.first_name, p.last_name
FROM youtube_channel c
JOIN channel_subscriber s ON s.youtube_channel_id = c.id
JOIN user_profile p ON p.id = s.youtube_account_id   -- account id = profile id (one-to-one)
WHERE c.channel_name = 'MariamBeauty';
```
then `\w 3.3.sql`.
