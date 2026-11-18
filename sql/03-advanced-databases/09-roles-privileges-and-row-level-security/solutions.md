# Solutions - Roles, Privileges & Row-Level Security

## Tier 1

**1.1**
```sql
CREATE ROLE jamila WITH LOGIN PASSWORD 'password';
```
then log in as her (psql asks for the password, `password`), and come back:
```
\c company jamila localhost
SELECT current_user;          -- jamila
\c dbname=company
```

**1.2**
```sql
ALTER ROLE ci_runner WITH NOSUPERUSER CREATEDB;
```

**1.3**
```sql
DROP ROLE old_contractor;
-- ERROR:  role "old_contractor" cannot be dropped because some objects depend on it
-- DETAIL:  privileges for table car
REVOKE ALL PRIVILEGES ON car FROM old_contractor;   -- or: DROP OWNED BY old_contractor;
DROP ROLE old_contractor;
```

**1.4** `\du`, `\du+`, `SET ROLE jamila;`, `SELECT current_user;`, `SELECT * FROM car;`,
`ALTER ROLE jamila SUPERUSER;`, `RESET ROLE;`

## Tier 2

**2.1**
```sql
GRANT SELECT ON car TO jamila;

SET ROLE jamila;
SELECT * FROM car;         -- works
DELETE FROM car;           -- permission denied
RESET ROLE;
```

**2.2**
```sql
CREATE ROLE dev_team;
CREATE ROLE data_team;
CREATE ROLE alex WITH LOGIN PASSWORD 'password';
GRANT dev_team TO alex;
GRANT data_team TO alex;
GRANT data_team TO jamila;
```

**2.3**
```sql
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO dev_team;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dev_team;
GRANT ALL PRIVILEGES ON DATABASE company TO data_team;

SET ROLE alex;
INSERT INTO car (make, model, year, price) VALUES ('Fiat', '500', 2024, 15000);
UPDATE car SET price = 14500 WHERE make = 'Fiat';
DELETE FROM car WHERE make = 'Fiat';   -- permission denied
RESET ROLE;
```

## Tier 3

**3.1**
```sql
CREATE POLICY "allow_select_own_employee"
ON employee
FOR SELECT
USING (username = current_user);

ALTER TABLE employee ENABLE ROW LEVEL SECURITY;

SET ROLE dpatel;
SELECT * FROM employee;   -- only Divya's row
RESET ROLE;
```

**3.2**
```sql
CREATE POLICY "allow_managers_to_insert_new_employee"
ON employee
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM employee
        WHERE username = current_user
          AND role = 'Manager'
    )
);

SET ROLE jane;
INSERT INTO employee (username, name, role, department)
VALUES ('fubar', 'Foo Bar', 'Sales Executive', 'Marketing');   -- works
RESET ROLE;
```

**3.3**
```sql
-- This version recurses (the policy on employee queries employee):
--   USING (EXISTS (SELECT 1 FROM employee WHERE username = current_user AND role = 'Manager'))
CREATE POLICY "allow_managers_to_select_all"
ON employee
FOR SELECT
USING (current_setting('session.user_role', true) = 'Manager');
-- the second argument (missing_ok = true) returns NULL instead of an error when unset

SET ROLE jane;
SET session.user_role = 'Manager';
SELECT * FROM employee;               -- everyone
SET session.user_role = 'Developer';
SELECT * FROM employee;               -- only Jane
RESET ROLE;
```

**3.4**
```sql
CREATE POLICY "allow_update_own_employee"
ON employee
FOR UPDATE
USING (username = current_user)          -- which rows you may update
WITH CHECK (username = current_user);    -- what the row must look like afterwards

SET ROLE dpatel;
UPDATE employee SET name = 'Divya P.' WHERE username = 'dpatel';   -- UPDATE 1
UPDATE employee SET name = 'Hacked'   WHERE username = 'jane';     -- UPDATE 0
UPDATE employee SET username = 'boss' WHERE username = 'dpatel';   -- ERROR: new row violates row-level security policy
RESET ROLE;
```
