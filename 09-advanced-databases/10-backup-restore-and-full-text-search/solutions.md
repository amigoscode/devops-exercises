# Solutions - Backup, Restore & Full-Text Search

## Tier 1 (in psql; the PostgreSQL tools run through `\!`)

**1.1**
```
\! pg_dump -d my_db -f backups/backup.sql
```

**1.2**
```
\! pg_dump -F t -d my_db -f backups/backup.tar
```

**1.3**
```sql
CREATE DATABASE my_db_from_dump;
```
```
\! pg_restore -d my_db_from_dump backups/backup.tar
\c my_db_from_dump
\dt
\c my_db
```
(plain SQL instead: `CREATE DATABASE my_db_from_sql;`, `\c my_db_from_sql`,
`\i backups/backup.sql`, `\c my_db`)

**1.4**
```
\! pg_dumpall -f backups/all-dbs.sql
```

## Tier 2

**2.1**
```
\copy car TO 'backups/car.csv' DELIMITER ',' CSV HEADER
```
(The video's server-side version, `COPY car TO '/full/path/car.csv' DELIMITER ',' CSV
HEADER;`, writes the file as the server's own OS user, on the server's machine.)

**2.2**
```
\copy (SELECT id, brand FROM car) TO 'backups/car2.csv' DELIMITER ',' CSV HEADER
```

**2.3**
```sql
SELECT id, title
FROM article
WHERE to_tsvector('english', title || ' ' || body) @@ to_tsquery('english', 'postgresql & index');
```
then `\w 2.3.sql`

**2.4**
```sql
SELECT id, title
FROM article
WHERE to_tsvector('english', title || ' ' || body) @@ phraseto_tsquery('english', 'full text search');
```
then `\w 2.4.sql`

**2.5**
```sql
SELECT id, title
FROM article
WHERE to_tsvector('english', title || ' ' || body) @@ to_tsquery('english', 'data:* & !mysql');
```
then `\w 2.5.sql`

**2.6** `SELECT to_tsvector('english', 'I love databases and PostgreSQL is the best');`
gives `'best':8 'databas':3 'love':2 'postgresql':5`: stop words are gone, the numbers
are positions, and words are reduced to their stem.

## Tier 3

**3.1**
```sql
UPDATE article
SET search_vector = to_tsvector('english', coalesce(title, '') || ' ' || coalesce(body, ''));

CREATE INDEX idx_search_vector ON article USING GIN (search_vector);

SET enable_seqscan = off;
EXPLAIN SELECT id FROM article WHERE search_vector @@ to_tsquery('english', 'postgresql');
-- Bitmap Index Scan on idx_search_vector
RESET enable_seqscan;
```

**3.2**
```sql
CREATE FUNCTION update_search_vector() RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := to_tsvector('english', coalesce(NEW.title, '') || ' ' || coalesce(NEW.body, ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER search_vector_update
BEFORE INSERT OR UPDATE ON article
FOR EACH ROW EXECUTE FUNCTION update_search_vector();
```
(Another way to do 3.1 and 3.2 in one step is a generated column:
`ALTER TABLE article DROP COLUMN search_vector, ADD COLUMN search_vector tsvector
GENERATED ALWAYS AS (to_tsvector('english', coalesce(title, '') || ' ' || coalesce(body, ''))) STORED;`
and then the GIN index.)

**3.3**
```sql
SELECT id, title
FROM article
WHERE search_vector @@ to_tsquery('english', 'postgresql & performance')
ORDER BY ts_rank(search_vector, to_tsquery('english', 'postgresql & performance')) DESC
```
then `\w 3.3.sql`. (Typed without a `;`, the query waits in psql's buffer and `\w`
saves it as it is. Type `;` to run it.)

**3.4**
```
\! pg_restore -l backups/nightly.tar
\! pg_restore --data-only -t comment -d my_db backups/nightly.tar
SELECT count(*) FROM comment;
```
`pg_restore -l` lists what's inside the backup. The `SELECT` returns 20.
