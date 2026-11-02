# Solutions - Exploring the PostgreSQL Server

## Tier 1
**1.1** (drill)
```
\du
\l
SHOW config_file;     -- /etc/postgresql/16/main/postgresql.conf
SHOW hba_file;        -- /etc/postgresql/16/main/pg_hba.conf
```

**1.2**
```
\conninfo
-- You are connected to database "student" as user "student" via socket in "/var/run/postgresql" at port "5432".
SELECT current_database(), current_user, current_setting('port');
\w 1.2.sql
```
`student | student | 5432` - the defaults the video spells out with the `-U`, `-d` and `-p`
flags.

## Tier 2
**2.1** (drill, optional - uses the Linux shell)
```
\! sudo service postgresql stop
SELECT 1;
-- server closed the connection unexpectedly ... The connection to the server was lost.
\! sudo service postgresql start
\c dbname=student
\! psql --help
```

**2.2**
```
\c postgres
-- You are now connected to database "postgres" as user "student".
\o 2.2.txt
\i 1.2.sql
\o
\c student
```
`2.2.txt`: `postgres | student | 5432`.

**2.3**
```
\password
-- Enter new password for user "student": (type it twice, e.g. student)
\c postgres student localhost 5432
-- Password for user student:
-- You are now connected to database "postgres" as user "student" on host "localhost" (address "::1") at port "5432".
\o 2.3.txt
SELECT current_database(), current_user, inet_server_addr(), inet_server_port();
\o
```
`2.3.txt`: `postgres | student | ::1 | 5432` (or `127.0.0.1`). Over the default socket
connection `inet_server_addr()` and `inet_server_port()` are empty.

## Tier 3
**3.1**
```
SELECT name, setting
FROM pg_settings
WHERE name IN ('port', 'data_directory', 'config_file', 'hba_file');
\w 3.1.sql
```

**3.2** (drill, optional - uses the Linux shell)
```
\! sudo pg_createcluster 16 second --port 5433 --start
\! pg_lsclusters
-- 16  main   5432 online ... / 16  second 5433 online ...
\c postgres student - 5433
-- FATAL:  role "student" does not exist
\! sudo -u postgres psql -p 5433 -c 'SHOW data_directory'
-- /var/lib/postgresql/16/second
```

### Answers
1. `localhost` and port `5432`.
2. Your operating-system user name, as both the role and the database. A fresh Ubuntu
   installation only has the `postgres` role, so `psql` fails with *role "..." does not
   exist* until you connect as the `postgres` role (as the Ubuntu video does) or create
   your own role - the same error the second server gave you in 3.2.
3. `-U postgres` picks the **role** you log in as (and, by default, a database of the same
   name); `-d postgres` picks the **database** you connect to, keeping your own role.
   `\c postgres` is the `-d` one: it changes the database and keeps your role.
4. A port can only be used by one server at a time; the client picks the server by its
   port (`-p 5433`).
5. It's the server's main configuration file: port, maximum connections, memory, SSL,
   logging, write-ahead log... (`pg_hba.conf` controls who may connect and how).
