# 01 · Designing a Database

> Maps to **Database Design & Implementation → Section 2: Database Design**
> (entities, attributes, primary keys, unique constraints, data types, foreign keys, cardinality, one-to-one, one-to-many, many-to-many, composite keys)

Before you store a single row you decide **what** to store and **how the pieces
relate**. Get that right and the database protects your data for you: no two
users with the same email, no channel without an owner, no one subscribing twice.
You'll design the core of a YouTube-like platform exactly as the course does, then
turn the ERD into real PostgreSQL tables and prove every rule is enforced.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Database Design & Implementation → Designing a Database** and
press `enter`. You land in `psql`, connected to the empty `youtube` database where
you build the tables. Run each query, then save it with `\w 3.2.sql` (use the
question's number). `:questions` shows the questions again, `:check` grades your
work, and `exit` takes you back with your progress saved. Press `r` in the Academy for
a fresh start.

---

## The design you're implementing

The ERD from the course (draw yours in [diagrams.net](https://app.diagrams.net),
*Entity Relation* shapes). `PK` primary key, `FK` foreign key, `UN1` unique:

```
user_profile                    youtube_account                 youtube_channel
PK  id          BIGSERIAL       PK,FK id         BIGINT         PK  id                 BIGSERIAL
    first_name  TEXT                  created_at TIMESTAMP      FK  youtube_account_id BIGINT
    last_name   TEXT                                            UN1 channel_name       TEXT
UN1 email       TEXT                                                created_at         TIMESTAMP
    gender      TEXT  (note: MALE or FEMALE)
    created_at  TIMESTAMP                       channel_subscriber
                                                PK,FK youtube_account_id BIGINT
                                                PK,FK youtube_channel_id BIGINT
                                                      created_at         TIMESTAMP

user_profile ||----o| youtube_account       a profile has zero or one account; an account belongs to one and only one profile
youtube_account ||----|< youtube_channel    an account has one or many channels; a channel belongs to one and only one account
youtube_account ||----o< channel_subscriber >o----|| youtube_channel
                                            many-to-many: an account subscribes to many channels, a channel has many subscribers
```

**Cardinality → SQL.** Crow's-foot ends read *minimum, maximum*: `||` one and only
one, `o|` zero or one, `|<` one or many, `o<` zero or many.

| Relationship | How the course builds it |
|---|---|
| one-to-one | the child's primary key **is** the foreign key (`id BIGINT PRIMARY KEY REFERENCES user_profile (id)`) - a profile id can appear only once |
| one-to-many | a `NOT NULL` foreign key **without** a unique constraint on the many side |
| many-to-many | a **link (bridge) table** holding both foreign keys, with a **composite primary key** of the two so a pair can exist only once |

All timestamps are `TIMESTAMP` (= `TIMESTAMP WITHOUT TIME ZONE`). Use exactly these
table and column names: the data file in Tier 3 and the grader rely on them.

## Tier 1 - Entities, attributes and keys *(hint: `CREATE TABLE user_profile ( id BIGSERIAL PRIMARY KEY, ... );`)*

**1.1 (drill)** Open [diagrams.net](https://app.diagrams.net), expand **Entity
Relation** and capture the entities of the platform as boxes: user profile,
YouTube account, YouTube channel, video, likes, comments, subscribers. Then turn
`user_profile` into a table shape with its attributes, `PK`, `UN1` and a data-type
column.

**1.2 (graded)** Create the `user_profile` table: `id` (`BIGSERIAL`, the primary
key), `first_name`, `last_name`, `email`, `gender` (all `TEXT`) and `created_at`
(`TIMESTAMP`).

**1.3 (graded)** Enforce the design's rules on `user_profile`: `email` is **unique**,
`gender` can only be `'MALE'` or `'FEMALE'` (a `CHECK` constraint), and **no column
accepts NULL**. (Drop and re-create the table, or use `ALTER TABLE ... ADD
CONSTRAINT` / `ALTER COLUMN ... SET NOT NULL`.)

## Tier 2 - Relationships *(hint: `REFERENCES other_table (id)`; `PRIMARY KEY (a, b)`)*

**2.1 (graded)** Create `youtube_account` as a **one-to-one** with `user_profile`:
its primary key `id` (`BIGINT`) is also the foreign key to `user_profile (id)`,
plus `created_at` (`TIMESTAMP`, required). A profile with two accounts must be
impossible.

**2.2 (graded)** Create `youtube_channel` as a **one-to-many** from
`youtube_account`: `id` (`BIGSERIAL` primary key), `youtube_account_id` (`BIGINT`,
required, foreign key to `youtube_account (id)`), `channel_name` (`TEXT`, required,
unique) and `created_at` (`TIMESTAMP`, required). One account may own many
channels; a channel can't exist without an account.

**2.3 (graded)** Create the link table `channel_subscriber` for the
**many-to-many** between accounts and channels: `youtube_account_id` and
`youtube_channel_id` (`BIGINT` foreign keys to each table), `created_at`
(`TIMESTAMP`, required) and a **composite primary key** of the two ids, so an
account can subscribe to a channel only once.

**2.4 (drill)** In your diagram, replace the plain arrows with crow's-foot
cardinalities (Style → Line start / Line end) and read each relationship out loud
in both directions: "a profile has zero or one account; an account belongs to one
and only one profile".

## Tier 3 - Put the design to work *(goal only)*

**3.1 (graded)** Load the course's sample data into your tables: the file
`sample-data.sql`, already in your folder (5 profiles, 3 accounts, 4 channels, 4
subscriptions). In psql, `\i` runs a file: `\i sample-data.sql`. If a row is
rejected, your schema doesn't match the design yet: fix it and load again (the
file empties the four tables first).

**3.2 (graded)** List every channel's `channel_name` with its **number of
subscribers**, including channels nobody has subscribed to yet (they show `0`).
Save it with `\w 3.2.sql`.

**3.3 (graded)** List the `first_name` and `last_name` of everyone subscribed to
the channel **MariamBeauty**. Save it with `\w 3.3.sql`.

## Self-check questions

1. What is the difference between an entity and an attribute, and how does each
   show up in SQL?
2. A primary key and a `UNIQUE` column both stop duplicates. What can a `UNIQUE`
   column hold that a primary key can't?
3. Why does `youtube_account` use `BIGINT` for its id while `user_profile` uses
   `BIGSERIAL`?
4. What single difference in the SQL turns a one-to-one into a one-to-many?
5. What would go wrong if `channel_subscriber` had its own `id BIGSERIAL PRIMARY
   KEY` instead of the composite key?
