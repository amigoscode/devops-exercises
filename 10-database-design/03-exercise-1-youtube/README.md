# 03 · Exercise 1: Videos, Views, Likes & Comments

> Maps to **Database Design & Implementation → Section 4: Exercise 1**
> (extending an ERD, choosing cardinalities, one-to-many, many-to-many link tables, composite keys, nullable foreign keys, writing the SQL and adding data)

The course's exercise: so far the platform has `user_profile`, `youtube_account`,
`youtube_channel` and `channel_subscriber`. Now extend the design with
**videos**, their **views**, **likes**, **comments**, and **likes on comments**,
then write the SQL and add data to see it working. There's more than one right
design, so the grader doesn't compare your SQL with one answer: it checks the
rules of the requirement, mostly by trying to insert rows that must go in and rows
that must be rejected.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Database Design & Implementation → Exercise 1: Videos,
Views, Likes & Comments** and press `enter`. You land in `psql`, connected to the
`youtube` database, which already holds section 2's four tables and the course's
sample data. Run each query, then save it with `\w 3.4.sql` (use the question's
number). `:questions` shows the questions again, `:check` grades your work, and
`exit` takes you back with your progress saved. Press `r` in the Academy for a
fresh start.

---

## What's already there

```
user_profile (id PK, first_name, last_name, email UN, gender, created_at)
youtube_account (id PK + FK -> user_profile.id, created_at)                one-to-one
youtube_channel (id PK, youtube_account_id FK, channel_name UN, created_at) one-to-many
channel_subscriber (youtube_account_id FK, youtube_channel_id FK, created_at,
                    PRIMARY KEY (youtube_account_id, youtube_channel_id))   many-to-many
```

Sample data: accounts **1** (Mariam), **2** (Joe) and **4** (Alex) - Jamila (3) and
Bob (5) have no account; channels **1** MariamBeauty, **2** JoeTech, **3**
AlexTutorials, **4** MariamBeautyTutorials. `\d` and `SELECT` around before you
start.

## Rules for your design

- Use the **table names** given in each task (the grader looks for them). Name the
  columns as you like, except the few a task names: the grader finds your foreign
  keys by what they reference, so `video_id` or `video` are both fine.
- Every table has a **primary key**, and every relationship is a real **foreign
  key** (`REFERENCES`).
- Extra columns (`description`, `category`, `created_at`...) are welcome. If you
  add a required column that has a `CHECK`, give it a `DEFAULT` too: the grader
  inserts test rows (in a transaction it rolls back) and fills required columns it
  doesn't know with simple values (text, `1`, `now()`).

## Tier 1 - Videos *(hint: "a channel has zero or many videos" - which side gets the foreign key?)*

**1.1 (drill)** Extend your ERD in [diagrams.net](https://app.diagrams.net) with
`video`, `video_view`, `video_like`, `video_comment` and `video_comment_like`. For
every line, ask the two cardinality questions (minimum and maximum, in both
directions) before you draw the crow's feet.

**1.2 (graded)** Create `video`. Every video belongs to exactly **one channel** (a
channel has zero or many videos). A video has a `title` (required) and a `url`
(required, **unique** - no two videos share a URL).

## Tier 2 - Views and likes *(hint: compare `video_view` and `video_like` - which one allows repeats?)*

**2.1 (graded)** Create `video_view`: a video has zero or many views. You don't
need a YouTube account to watch a video, so a view may have **no account**; when
it has one, it must be a real account. The same account can watch the same video
**many times**, and each watch is a view.

**2.2 (graded)** Create `video_like`: the many-to-many between accounts and
videos. You **must** have an account to like a video, and an account can like a
given video **only once** (it can like many different videos, and a video has
many likes).

## Tier 3 - Comments, then real data *(goal only)*

**3.1 (graded)** Create `video_comment`: an account comments on a video. A comment
needs an account and a video, and its text is required (a `NOT NULL` text column).
An account can comment on the same video **as many times as it wants**.

**3.2 (graded)** Create `video_comment_like`: an account likes a comment, **only
once** per comment.

**3.3 (graded)** Add the data. On **JoeTech** (channel 2) upload a video titled
**Macbook Air M1 Unboxing** with url `https://youtube.com/432423k`. Mariam
(account 1) and Alex (account 4) like it, it gets **two anonymous views**, Alex
comments **Nice video** on it, and Joe (account 2) likes Alex's comment. On
**AlexTutorials** (channel 3) upload **Database Design** with url
`https://youtube.com/932898233` (no likes yet).

**3.4 (graded)** List every video's `title` with its **number of likes**,
including videos with none. Save it with `\w 3.4.sql`.

## Self-check questions

1. Why can `video_view` not use a composite primary key of account and video,
   while `video_like` should?
2. The account column in `video_view` is nullable. What does `NULL` mean there,
   and why doesn't the foreign key complain about it?
3. Your design links likes and comments to `youtube_account`. What would change if
   they were linked to `youtube_channel` instead (a channel liking a video)?
4. Which tables in your design are link (bridge) tables, and what extra
   information does each one carry?
