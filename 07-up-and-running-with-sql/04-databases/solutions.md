# Solutions - Databases

## Tier 1
**1.1** (drill)
```
\l
\d                     -- Did not find any relations.
\h CREATE DATABASE
```

**1.2**
```
CREATE DATABASE my_db;
CREATE DATABASE my_db;     -- ERROR:  database "my_db" already exists
```

**1.3**
```
\c my_db                   -- You are now connected to database "my_db" as user "student".
\o 1.3.txt
SELECT current_database(), current_user;
\o
\c student
```
`1.3.txt`: `my_db | student`.

**1.4**
```
\c template0
-- connection to server ... failed: FATAL:  database "template0" is not currently accepting connections
-- Previous connection kept
SELECT datname, datallowconn FROM pg_database WHERE datname = 'template0';
\w 1.4.sql
```
`template0 | f` - `datallowconn` is false, so nobody can connect to it.

## Tier 2
**2.1**
```
ALTER DATABASE tset_db RENAME TO test_db;
```

**2.2**
```
DROP DATABASE old_app;
```

## Tier 3
**3.1**
```
\c staging
ALTER DATABASE staging RENAME TO staging_old;
-- ERROR:  current database cannot be renamed
\c postgres
ALTER DATABASE staging RENAME TO staging_old;
CREATE DATABASE staging;
\l
```

### Answers
1. No - every object belongs to one and only one database.
2. `CREATE DATABASE` is SQL: psql sends it to the server only once the statement ends
   with `;`. `\c` is a psql meta-command, run by psql itself as soon as you press enter.
3. Your session is using it. Connect to another database first (`\c postgres`), then
   rename or drop it. (Other open connections block it too.)
4. Every application and client that connects by the old name stops working the moment
   it changes - you have to think about everyone using it before you rename or drop.
