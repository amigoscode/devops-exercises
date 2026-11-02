# Solutions - Databases & PostgreSQL

## Tier 1
**1.1** (drill, optional - uses the Linux shell)
```
\! pg_lsclusters
```
`Ver Cluster Port Status Owner    Data directory              Log file`
`16  main    5432 online postgres /var/lib/postgresql/16/main ...`

**1.2**
```
SELECT version();
\w 1.2.sql
```
`PostgreSQL 16.x (Ubuntu ...) on ...-linux-gnu, compiled by gcc ..., 64-bit`

**1.3** (drill, optional - uses the Linux shell)
```
\! psql --version
\! which psql
```
`psql (PostgreSQL) 16.x ...` and `/usr/bin/psql`.

## Tier 2
**2.1**
```
SHOW port;
\w 2.1.sql
```

**2.2**
```
SELECT pg_postmaster_start_time();
\w 2.2.sql
```

**2.3**
```
SELECT * FROM customers;
\w 2.3.sql
```

## Tier 3
**3.1**
```
SHOW data_directory;
\w 3.1.sql
```
`/var/lib/postgresql/16/main`

**3.2**
```
SHOW config_file;
\w 3.2.sql
```
`/etc/postgresql/16/main/postgresql.conf`

**3.3** (drill, optional - uses the Linux shell)
```
\! grep -n '^port' /etc/postgresql/16/main/postgresql.conf
```
`64:port = 5432				# (change requires restart)`

### Answers
1. An organised collection of data. A relational database stores it in **tables** made of
   rows and columns, and tables can be related to each other.
2. Relational Database Management System - software to define, create, maintain and
   control access to relational databases. MySQL, Oracle, SQL Server (and PostgreSQL).
3. `CREATE`/`DROP` (and `ALTER`) = DDL, `INSERT`/`UPDATE`/`DELETE` = DML, `GRANT`/`REVOKE`
   = DCL, `COMMIT`/`ROLLBACK` = TCL, `SELECT` = DQL.
4. Advantages: ACID compliance, structured data, complex queries. Disadvantage:
   scaling to very, very large data sets (where NoSQL scales more easily).
5. You learn the real SQL syntax and commands (no clicking), solve problems yourself, get
   faster with shortcuts, understand your environment, and use fewer resources - and the
   same `psql` works on every operating system.
