# Database Design & Implementation - Hands-On Exercises

Where SQL turns into **design**. You'll go from an idea to a schema the way the
course does it: capture the entities, give them attributes, keys and data types,
work out the cardinality of every relationship, implement one-to-one, one-to-many
and many-to-many in real PostgreSQL, then normalize the result to 1NF, 2NF and
3NF. Two exercises close the course: extending the YouTube design and designing
the Tick Trade marketplace from a blank page.

The grader doesn't just read your tables: it **tries to break them**, inserting
rows that must be accepted and rows that must be rejected.

## Quick start

From the repo root:

```bash
./academy.sh        # macOS, Linux, WSL, Git Bash, Codespaces
academy.cmd         # Windows
```

Pick **Database Design & Implementation**, choose a section and press `enter`:
you get a fresh sandbox with a real PostgreSQL 16 server and land straight in
`psql`, connected to the section's database, with the questions printed at the
top. Run each query, then save it with `\w 1.1.sql` (use the question's number).
`:questions` shows the questions again, `:check` grades your work, and `exit`
takes you back with your progress saved. Press `r` in the Academy for a fresh
start. You never need the Linux shell: everything happens at the `psql` prompt.

**Docker is the only thing you need installed.** (Codespaces works too - zero install.)
For the ERD drills, [diagrams.net](https://app.diagrams.net) runs in your browser.

## Sections

| # | Section | Course § | Skills |
|---|---------|----------|--------|
| 01 | [Designing a Database](01-designing-a-database/) | 2 | entities, attributes, `PRIMARY KEY`, `UNIQUE`, data types, `CHECK`, `NOT NULL`, foreign keys, cardinality, one-to-one / one-to-many / many-to-many, composite keys |
| 02 | [Database Normalization](02-normalization/) | 3 | 1NF atomic values, 2NF partial dependencies, 3NF transitive dependencies, splitting tables without losing data |
| 03 | [Exercise 1: Videos, Views, Likes & Comments](03-exercise-1-youtube/) | 4 | extending an ERD, link tables, nullable foreign keys, inserting and querying your own design |
| 04 | [Exercise 2: Tick Trade Marketplace](04-exercise-2-tick-trade/) | 5 | open-ended design from a brief, `CHECK` / `ENUM`, one-to-one invoices, a full schema with data |

Each section: `README.md` (3-tier tasks) · `seed.sh` · `verify.sh` (tests your
schema) · `solutions.md`.

## How grading works

- **Tables you build** are graded on the live database by their structure (primary
  keys, foreign keys, `NOT NULL`, types) and, above all, their **behaviour**: the
  grader inserts test rows inside a transaction it rolls back, so a duplicate
  email, an order for a product that doesn't exist or a second subscription to the
  same channel must be rejected, while valid rows must go in. Checking never
  changes your data.
- **Design is open-ended** in the exercises: any design that enforces the rules
  passes. Table names (and the few columns a task names) are fixed; your other
  column names are free, because foreign keys are found by what they reference.
- **Queries** you're asked for are saved with `\w <task>.sql` (in psql,
  `\w 3.2.sql` writes your last query to the file `3.2.sql` in your sandbox
  folder) and their rows are compared with a reference query, on an untouched
  copy of the data where the section has one, otherwise on your own tables.

Stuck? Each section's `solutions.md` has the full SQL (in the Academy, press `s`).
