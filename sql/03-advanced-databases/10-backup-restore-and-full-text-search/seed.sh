#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox (with a backups/ folder) + the "my_db"
# database: cars, blog articles and their comments. Last night's backup is in
# ~/sandbox/backups/nightly.tar - and this morning somebody emptied the comment table.
set -euo pipefail
SB="$HOME/sandbox"; DB=my_db
rm -rf "$SB"; mkdir -p "$SB/backups"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

for d in "$DB" my_db_from_dump; do dropdb --if-exists "$d"; done
createdb "$DB"
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" <<'SQL'
CREATE TABLE car (
    id    SERIAL PRIMARY KEY,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year  INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);
INSERT INTO car (brand, model, year, price) VALUES
    ('Toyota', 'Corolla', 2021, 18500.00), ('Ford', 'Focus', 2019, 12900.00),
    ('Tesla', 'Model 3', 2023, 39990.00),  ('BMW', '320d', 2020, 24500.00),
    ('Honda', 'Civic', 2022, 21000.00),    ('Kia', 'Niro', 2024, 29950.00),
    ('Audi', 'A3', 2018, 15750.00),        ('Mercedes', 'C200', 2021, 33400.00),
    ('Volkswagen', 'Golf', 2020, 17200.00), ('Hyundai', 'Ioniq 5', 2023, 41000.00),
    ('Mazda', 'MX-5', 2019, 19900.00),     ('Nissan', 'Leaf', 2022, 22500.00),
    ('Volvo', 'XC40', 2024, 38900.00),     ('Peugeot', '208', 2021, 14300.00),
    ('Skoda', 'Octavia', 2020, 16800.00);

-- The article table from the full-text search exercise
CREATE TABLE article (
    id            SERIAL PRIMARY KEY,
    title         TEXT,
    body          TEXT,
    search_vector TSVECTOR
);
INSERT INTO article (title, body) VALUES
('PostgreSQL Tips and Tricks', 'Learn the most efficient techniques for optimizing queries in PostgreSQL and improving overall database performance. Indexes are the first tool to reach for.'),
('Exploring New Features in MySQL 8.0', 'MySQL 8.0 comes packed with features that take performance and scalability to new heights, including invisible indexes.'),
('Choosing Between PostgreSQL and MySQL', 'Both PostgreSQL and MySQL are popular database systems, but which one is right for your project? This article compares their performance, indexing and licensing.'),
('How B-Tree Indexes Work', 'A B-tree index keeps keys sorted so lookups, range scans and ORDER BY are fast. Most relational engines use them by default.'),
('GIN Indexes for Full Text Search in PostgreSQL', 'PostgreSQL uses GIN indexes to make full text search fast. A GIN index maps every lexeme to the rows that contain it.'),
('Full Text Search Explained', 'Full text search finds documents by the words that carry meaning instead of exact strings. It powers the search box on blogs and documentation sites.'),
('Search Is Not Full Text', 'A plain text column with LIKE is not a search engine: a full table scan reads every row, and the text has to match exactly.'),
('Data Modelling for Beginners', 'Good data modelling starts with entities and relationships. Normalise first, then denormalise only where reads demand it.'),
('Datasets for Machine Learning', 'Where to find clean datasets for training AI models, and how to label your own data responsibly.'),
('Migrating from MySQL to PostgreSQL', 'A step-by-step guide to moving your schema, rows and indexes from MySQL into PostgreSQL without downtime.'),
('PostgreSQL Performance Tuning', 'Tune shared_buffers, work_mem and autovacuum to get the best performance out of PostgreSQL. Measure performance before and after every change, because PostgreSQL performance depends on your workload.'),
('Why Your Database Is Slow', 'Missing indexes, N+1 queries and chatty ORMs are the usual suspects when database performance drops. PostgreSQL ships EXPLAIN ANALYZE to find them.'),
('The Rise of AI Assistants', 'AI assistants now write code, answer questions and summarise documents. The AI revolution is changing how developers work.'),
('Inside the AI Revolution', 'The AI revolution is driven by cheap compute, huge datasets and better models.'),
('Large Language Models in Production', 'Serving large language models needs GPUs, caching and careful monitoring of latency and cost.'),
('Python vs Java for Backend Development', 'Python is quick to write, Java is fast at runtime. Both have mature frameworks and huge communities.'),
('Getting Started with Rust', 'Rust gives you memory safety without a garbage collector. The borrow checker feels strict at first.'),
('Java 21 Virtual Threads', 'Virtual threads make blocking code scale. Thousands of concurrent requests no longer need thousands of platform threads.'),
('Kubernetes for Developers', 'Kubernetes schedules containers, restarts them when they crash and scales them under load.'),
('Apple Unveils a New iPhone', 'The new iPhone brings a faster chip, a better camera and longer battery life.'),
('Samsung Galaxy Review', 'The Galaxy has a bright screen and a great camera, but the battery could be better.'),
('The Evolution of Mobile Payments', 'Mobile payments are on the rise. Learn how technologies like Apple Pay and Google Wallet are changing the way we spend money.'),
('How Google Ranks Pages', 'Search engines rank pages by relevance and authority. Full text search in your database works on the same idea, at a smaller scale.'),
('Big Data Pipelines with Kafka', 'Kafka moves data between services in real time, and keeps it durable on disk.'),
('PostgreSQL JSONB in Practice', 'Store flexible documents in PostgreSQL with JSONB and query them with GIN indexes. Performance stays good if you index the keys you filter on, and bad performance usually means a missing index.'),
('Microsoft and OpenAI', 'Microsoft invested billions in OpenAI and ships its models across Azure and Office.'),
('Choosing a Database for a Startup', 'Start with PostgreSQL unless you have a reason not to: one database can cover relational data, JSON, queues and search.'),
('MySQL Replication Basics', 'Replicas copy data from a primary so reads scale out. MySQL supports both asynchronous and semi-synchronous replication.'),
('Measuring Performance in Java', 'Profilers, JFR and microbenchmarks help you find where a Java service spends its time. Performance work starts with measurement.'),
('Mobile Phones and Battery Life', 'Phone makers keep promising two-day battery life. Screens, radios and background apps decide whether your phone lasts.');

CREATE TABLE comment (
    id         SERIAL PRIMARY KEY,
    article_id INT NOT NULL REFERENCES article (id),
    author     VARCHAR(50) NOT NULL,
    body       TEXT NOT NULL,
    created_at DATE NOT NULL
);
INSERT INTO comment (article_id, author, body, created_at) VALUES
(1, 'Ana', 'The EXPLAIN tip saved my week.', '2024-03-01'),
(1, 'Ben', 'Would love a follow-up on partial indexes.', '2024-03-02'),
(3, 'Carla', 'We picked PostgreSQL for the JSONB support.', '2024-03-02'),
(5, 'Dev', 'GIN plus tsvector is so fast.', '2024-03-03'),
(5, 'Eve', 'How big did the index get?', '2024-03-04'),
(6, 'Fay', 'Finally a clear explanation of lexemes.', '2024-03-04'),
(8, 'Gus', 'Normalise first - noted.', '2024-03-05'),
(11, 'Hana', 'work_mem was our bottleneck too.', '2024-03-05'),
(11, 'Ivan', 'Measure first, tune second.', '2024-03-06'),
(12, 'Jo', 'N+1 queries everywhere in our ORM code.', '2024-03-06'),
(13, 'Kim', 'Assistants write half my tests now.', '2024-03-07'),
(14, 'Leo', 'Cheap compute is the real story.', '2024-03-07'),
(18, 'Mia', 'Virtual threads changed how we write services.', '2024-03-08'),
(19, 'Nia', 'Kubernetes restarts are a lifesaver at 3am.', '2024-03-08'),
(20, 'Omar', 'The camera is the only reason to upgrade.', '2024-03-09'),
(22, 'Pia', 'I have not used cash in two years.', '2024-03-09'),
(23, 'Raj', 'Relevance is everything in search.', '2024-03-10'),
(25, 'Sara', 'JSONB with a GIN index is a great combo.', '2024-03-10'),
(27, 'Tom', 'Boring technology wins - start with PostgreSQL.', '2024-03-11'),
(30, 'Uma', 'My phone dies by 6pm every day.', '2024-03-11');
SQL

# Last night's backup (tar format), taken before this morning's accident...
pg_dump -F t -d "$DB" -f "$SB/backups/nightly.tar"
# ...when someone ran this on the live database:
psql -X -q -d "$DB" -c "TRUNCATE comment"

# The Academy opens psql connected to this database (it reads this line).
sed -i '/^export PGDATABASE=/d' ~/.bashrc
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "could not set PGDATABASE in ~/.bashrc"; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database. Backups go in the backups folder."
