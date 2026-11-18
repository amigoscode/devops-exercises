# Solutions - Exercise 1: Videos, Views, Likes & Comments

Solutions may vary - this is the course's. Any design that keeps the same rules
passes (different column names, a `UNIQUE (a, b)` instead of a composite primary
key, extra columns...). Run it in `psql` (the Academy connects you to the `youtube` database).

## Tier 1 - Videos

**1.1** Drill: `youtube_channel` *one and only one* → `video` *zero or many*;
`video` *one and only one* → `video_view`, `video_like`, `video_comment` *zero or
many*; `youtube_account` *zero or one* → `video_view` *zero or many* (views can be
anonymous); `youtube_account` *one and only one* → `video_like`, `video_comment`,
`video_comment_like` *zero or many*; `video_comment` *one and only one* →
`video_comment_like` *zero or many*.

**1.2** One-to-many from the channel: a NOT NULL foreign key on the video.
```sql
CREATE TABLE IF NOT EXISTS video (
    id                 BIGSERIAL PRIMARY KEY,
    youtube_channel_id BIGINT NOT NULL REFERENCES youtube_channel (id),
    title              TEXT NOT NULL,
    url                TEXT NOT NULL UNIQUE,
    description        TEXT NOT NULL,
    category           TEXT NOT NULL,
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
```

## Tier 2 - Views and likes

**2.1** Its own `id`, so the same account can view a video many times, and a
**nullable** account foreign key for anonymous views:
```sql
CREATE TABLE IF NOT EXISTS video_view (
    id                 BIGSERIAL PRIMARY KEY,
    youtube_account_id BIGINT REFERENCES youtube_account (id),
    video_id           BIGINT NOT NULL REFERENCES video (id),
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
```

**2.2** A link table with a composite key - one like per account per video:
```sql
CREATE TABLE IF NOT EXISTS video_like (
    youtube_account_id BIGINT NOT NULL REFERENCES youtube_account (id),
    video_id           BIGINT NOT NULL REFERENCES video (id),
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (youtube_account_id, video_id)
);
```

## Tier 3 - Comments, then real data

**3.1** Its own `id` (many comments per account per video):
```sql
CREATE TABLE IF NOT EXISTS video_comment (
    id                 BIGSERIAL PRIMARY KEY,
    youtube_account_id BIGINT NOT NULL REFERENCES youtube_account (id),
    video_id           BIGINT NOT NULL REFERENCES video (id),
    comment            TEXT NOT NULL,
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
```

**3.2**
```sql
CREATE TABLE IF NOT EXISTS video_comment_like (
    youtube_account_id BIGINT NOT NULL REFERENCES youtube_account (id),
    video_comment_id   BIGINT NOT NULL REFERENCES video_comment (id),
    created_at         TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (youtube_account_id, video_comment_id)
);
```

**3.3** (`RETURNING id` shows the ids; here the first video is 1 and the comment 1.)
```sql
INSERT INTO video (youtube_channel_id, title, url, description, category, created_at)
VALUES (2, 'Macbook Air M1 Unboxing', 'https://youtube.com/432423k', 'Unboxing', 'Tech', now())
RETURNING id;
INSERT INTO video (youtube_channel_id, title, url, description, category, created_at)
VALUES (3, 'Database Design', 'https://youtube.com/932898233', 'Master db design', 'Education', now());

INSERT INTO video_like (youtube_account_id, video_id, created_at) VALUES (1, 1, now()), (4, 1, now());
INSERT INTO video_view (youtube_account_id, video_id, created_at) VALUES (NULL, 1, now()), (NULL, 1, now());
INSERT INTO video_comment (youtube_account_id, video_id, comment, created_at)
VALUES (4, 1, 'Nice video', now()) RETURNING id;
INSERT INTO video_comment_like (youtube_account_id, video_comment_id, created_at) VALUES (2, 1, now());
```

**3.4**
```sql
SELECT v.title, count(l.youtube_account_id) AS likes
FROM video v
LEFT JOIN video_like l ON l.video_id = v.id
GROUP BY v.id, v.title;
```
then `\w 3.4.sql`.
