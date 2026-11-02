# Solutions - psql

## Tier 1
**1.1** (drill)
```
help
\?                 -- space scrolls, q leaves the list
\h
\h CREATE TABLE
\h CREATE DATABASE
```
(`\q` would quit psql and take you back to the Academy.)

**1.2** (drill, optional - uses the Linux shell)
```
\! sudo -u postgres psql -c '\du'
```

**1.3**
```
\o roles.txt
\du
\o
```

## Tier 2
**2.1**
```
\o databases.txt
\l
\o
```

**2.2**
```
\o schemas.txt
\dn
\o
```

**2.3**
```
CREATE TABLE foo ();
SELECT * FROM foo;        -- typed as SELECT * FROM f<Tab>
\o tables.txt
\dt
\o
```

## Tier 3
**3.1**
```
\x
\o report.txt
\i report.sql
\o
\x
```
`report.txt` now shows `-[ RECORD 1 ]` with one line per column
(`connected_as | student`, `port | 5432`, ...).

**3.2** (drill)
```
\timing
\i report.sql      -- prints Time: 0.xxx ms
\d<Tab><Tab>
```

### Answers
1. `\?` is help on psql's own backslash commands; `\h` is help on SQL commands
   (`\h CREATE TABLE` shows one command's syntax).
2. `\l` is a psql meta-command, handled by psql itself as soon as you press enter. SQL is
   sent to the server only when the statement ends with `;` - until then psql keeps
   collecting lines.
3. `\du` the roles, `\l` the databases, `\dt` the tables in the current database, and
   `\d person` the columns, types and other details of the `person` table.
4. `\o FILE` sends every result to that file. Type `\o` on its own to send output back to
   the screen.
