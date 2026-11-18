# Solutions - Transactions

Scripts are typed in psql with `\;` between statements and a normal `;` at the end, so
they run in one go and `\w` saves the whole script. `\i N.N.sql` runs a saved script
statement by statement, the way the grader does.

## Tier 1

**1.1** (in psql, one statement at a time)
```sql
BEGIN;
UPDATE account SET balance = balance - 5 WHERE id = 1;
UPDATE account SET balance = balance + 5 WHERE id = 2;
COMMIT;
```

**1.2**
```sql
BEGIN;
UPDATE account SET balance = balance - 5 WHERE id = 1;
SELECT * FROM account ORDER BY id;                         -- you see 95.00
SELECT * FROM dblink('dbname=bank', 'SELECT id, balance FROM account ORDER BY id')
       AS t(id INT, balance NUMERIC);                      -- the other session sees 100.00
ROLLBACK;
```

**1.3**
```sql
BEGIN \;
UPDATE account SET balance = balance - 5 WHERE id = 1 \;   -- UPDATE 1
UPDATE account SET balance = balance + 5 WHERE id = 99 \;  -- UPDATE 0: no such account
ROLLBACK;
```
then `\w 1.3.sql`

## Tier 2

**2.1**
```sql
BEGIN \;
INSERT INTO account (owner, balance) VALUES ('Fay', 500.00) \;
SAVEPOINT before_mistake \;
UPDATE account SET balance = 0 \;                -- oops: UPDATE 6
ROLLBACK TO SAVEPOINT before_mistake \;
COMMIT;
```
then `\w 2.1.sql`

**2.2**
```sql
BEGIN \;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ \;   -- SERIALIZABLE also works
SHOW transaction_isolation \;
SELECT SUM(balance) AS total FROM account \;
COMMIT;
```
then `\w 2.2.sql` (`BEGIN ISOLATION LEVEL REPEATABLE READ` is the one-line form.)

**2.3**
```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM account WHERE id = 3;
SELECT dblink_exec('dbname=bank', 'UPDATE account SET balance = balance + 1 WHERE id = 3');
SELECT balance FROM account WHERE id = 3;    -- same value as before
COMMIT;
SELECT balance FROM account WHERE id = 3;    -- now you see the +1.00
```

## Tier 3

**3.1**
```sql
BEGIN \;
UPDATE account SET balance = balance - 30 WHERE id = 3 \;
UPDATE account SET balance = balance + 30 WHERE id = 4 \;
COMMIT;
```
then `\w 3.1.sql`. If either UPDATE fails (the CHECK rule, a trigger, a lost
connection), the transaction is aborted and `COMMIT` turns into a rollback, so neither
change is saved. Without `BEGIN`, each UPDATE commits on its own and a failure leaves
money missing or created.

**3.2**
```sql
BEGIN \;
UPDATE account SET balance = balance - 20 WHERE id = 3 \;
UPDATE account SET balance = balance + 20 WHERE id = 4 \;
SAVEPOINT before_eve \;
UPDATE account SET balance = balance - 500 WHERE id = 3 \;  -- ERROR: violates check constraint
UPDATE account SET balance = balance + 500 WHERE id = 5 \;  -- ERROR: transaction is aborted
ROLLBACK TO SAVEPOINT before_eve \;                         -- back to a working transaction
COMMIT;                                                     -- keeps the 20.00 payment
```
then `\w 3.2.sql`. Sent together, the server stops at the first error, so type
`ROLLBACK;` and run `\i 3.2.sql` to see the whole script work: Carla 230.00, Dev 60.00,
Eve 0.00.
