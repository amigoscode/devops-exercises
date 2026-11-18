# Solutions - Working with Tables

## Tier 1
**1.1** (drill)
```
\h CREATE TABLE
\dt
\d custmer
```

**1.2**
```
CREATE TABLE car ();
\dt
```

**1.3**
```
ALTER TABLE custmer RENAME TO customer;
```

**1.4**
```
DROP TABLE temp_import;
```

## Tier 2
**2.1**
```
CREATE TABLE person (
    id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender CHAR(1),
    date_of_birth DATE,
    phone_number VARCHAR(15),
    country_of_origin VARCHAR(50)
);
```

**2.2**
```
ALTER TABLE customer RENAME COLUMN emial TO email;
\d customer
```

**2.3**
```
\o person.txt
\d person
\o
```

## Tier 3
**3.1**
```
CREATE TABLE course (
    id INTEGER,
    title VARCHAR(100),
    description TEXT,
    level CHAR(1),
    published_on DATE
);
```

### Answers
1. A **field** is a column (e.g. `first_name`), a **record** is one row - a group of
   fields describing one thing (one person) - and a **value** is what's stored in one
   field of one record (`John`).
2. `VARCHAR(n)` when you want to limit how many characters go in (a name, a country);
   `TEXT` for text of any length. A phone number can contain `+`, `-` and leading zeros
   and you never do maths with it, so it's text.
3. No - tables go into the default `public` schema, so both create `public.person`.
4. Constraints: `NOT NULL` to require a value, a `PRIMARY KEY` to uniquely identify each
   row, `UNIQUE` for values such as phone numbers, `CHECK` for allowed genders.
