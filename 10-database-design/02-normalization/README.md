# 02 · Database Normalization

> Maps to **Database Design & Implementation → Section 3: Database Normalization**
> (redundancy, 1st normal form, atomic values, 2nd normal form, partial dependencies, 3rd normal form, transitive dependencies)

Normalization is the process of reducing redundancy and dependency so the data
stays correct and queries stay simple. A table that stores a list in one column,
or the same fact on many rows, invites bugs: change a fact in one place, forget
another, and the database now disagrees with itself. Here you take tables that
break each normal form, the same examples as the course, and split them until
every fact is stored exactly once, without losing a single row of data.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Database Design & Implementation → Database Normalization**
and press `enter`. You land in `psql`, connected to the `normalization` database.
Run each query, then save it with `\w 1.1.sql` (use the question's number).
`:questions` shows the questions again, `:check` grades your work, and `exit` takes
you back with your progress saved. Press `r` in the Academy for a fresh start.

---

## The three normal forms (as the course teaches them)

| Form | Rule | Fix |
|---|---|---|
| **1NF** | every column holds a single **atomic** value (no lists, no repeating groups) | move the repeating values to their own table, one row each, with a foreign key back |
| **2NF** | 1NF **and** every column depends on the **entire** primary key (no **partial** dependency) | move the column to the table whose key it really depends on |
| **3NF** | 2NF **and** no **transitive** dependency (a column that depends on the key only *through* another non-key column) | split it into a table keyed by that other column, linked with a foreign key |

The `normalization` database holds the course's examples: `user_profile` (with
`phone_numbers`, `address` and `postcode` columns), `youtube_account`,
`youtube_channel`, `channel_subscriber` (with a `youtube_channel_category`
column) and `tournament_winner`. Look around first: `\d user_profile`,
`SELECT * FROM channel_subscriber;`. Moving data is part of every split: the
grader checks that a `JOIN` of your new tables gives back exactly the rows the old
table held. Use the table and column names given in each task.

## Tier 1 - First normal form (1NF) *(hint: one value per column - a list becomes rows in its own table)*

**1.1 (graded)** Find the rows that break 1NF: list the `id`, `first_name` and
`phone_numbers` of every user whose `phone_numbers` holds **more than one**
number. Save it with `\w 1.1.sql`.

**1.2 (graded)** Create the table `phone_number` as in the course: `id`
(`BIGSERIAL` primary key), `user_profile_id` (`BIGINT`, required, foreign key to
`user_profile (id)`) and `phone_number` (`TEXT`, required, **unique**). A user can
have zero or many phone numbers (one-to-many).

**1.3 (graded)** Move every number into `phone_number`, **one row per number**
(James Bond's `007,0071,0072` becomes three rows), then drop the `phone_numbers`
column from `user_profile`. Type the `INSERT`s by hand or let SQL split the list:
`unnest(string_to_array(phone_numbers, ','))` turns one row into one row per value.

## Tier 2 - Second normal form (2NF) *(hint: ask of every column "does it depend on the whole key?")*

**2.1 (graded)** `postcode` describes the address, not the user. Pull the address
out as the course does: create `address` with `id` (`BIGSERIAL` primary key),
`user_profile_id` (`BIGINT`, required, foreign key to `user_profile (id)`),
`address` and `postcode` (both `TEXT`, required), copy every user's address into
it, then drop `address` and `postcode` from `user_profile`.

**2.2 (graded)** `channel_subscriber`'s primary key is
`(youtube_account_id, youtube_channel_id)`, but `youtube_channel_category`
depends only on `youtube_channel_id`: a partial dependency, and the reason the
same category is repeated on every subscription. Store each channel's category
**once**, in a new `category` column (`TEXT`) on `youtube_channel`, then drop
`youtube_channel_category` from `channel_subscriber`.

## Tier 3 - Third normal form (3NF) *(goal only)*

`tournament_winner (tournament, year, winner, winner_date_of_birth)` is the
course's example (from Wikipedia): the key is `(tournament, year)`, and
`winner_date_of_birth` depends on it only through `winner`. Al Fredrickson's date
of birth is stored once per tournament he won.

**3.1 (graded)** Bring it to 3NF: a new table `winner` with `name` (`TEXT`,
primary key) and `date_of_birth` (`DATE`, required), one row per winner;
`tournament_winner` keeps `tournament`, `year` and `winner`, where `winner` is now
a **foreign key** to `winner (name)`, and loses `winner_date_of_birth`.

**3.2 (graded)** Rebuild the original view from your two tables: `tournament`,
`year`, `winner` and the winner's date of birth for every tournament. Save it
with `\w 3.2.sql`.

**3.3 (graded)** Al Fredrickson's date of birth was recorded wrong: it is
**1975-07-12**. Fix it. In a 3NF design that's one `UPDATE` of one row, and every
tournament he won shows the new date.

## Self-check questions

1. Why does a comma-separated `phone_numbers` column break 1NF, and what goes
   wrong when you need to find who owns `0071`?
2. What does "depends on the entire primary key" mean when the key is made of
   two columns?
3. In `channel_subscriber`, why is `created_at` fine while
   `youtube_channel_category` is not?
4. What is a transitive dependency? Give the chain in the tournament example.
5. Before 3.1, what would it take to fix Al Fredrickson's date of birth, and what
   could go wrong?
