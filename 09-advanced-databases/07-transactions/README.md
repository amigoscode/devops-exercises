# 07 · Transactions

> Maps to **Advanced Databases → Section 16: Transactions**
> (ACID, `BEGIN` / `COMMIT` / `ROLLBACK`, isolation levels, `SAVEPOINT` /
> `ROLLBACK TO SAVEPOINT`)

A transaction runs several statements as one unit of work: either all of them are
saved, or none are. Without one, a crash between "take 100 from Ana" and "give 100 to
Ben" loses the money. Every payment, order and stock update you write in a backend
depends on this.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Transactions** and press `enter`. You land
in `psql`, connected to the `bank` database. Run each script, then save it with
`\w 1.3.sql` (use the question's number). `:questions` shows the questions again,
`:check` grades your work, and `exit` takes you back with your progress saved. Press `r`
in the Academy for a fresh start.

---

The `bank` database has one table, `account (id, owner, balance)`, with a
`CHECK (balance >= 0)` rule, so an account can never go below zero:

| id | owner | balance |
|----|-------|---------|
| 1 | Ana | 100.00 |
| 2 | Ben | 100.00 |
| 3 | Carla | 250.00 |
| 4 | Dev | 40.00 |
| 5 | Eve | 0.00 |

**Writing a script in psql.** Most tasks ask for a **script**: several statements saved
in one file. End each statement with `\;` instead of `;`, and only the last one with a
normal `;`:

```sql
BEGIN \;
UPDATE account SET balance = balance - 5 WHERE id = 1 \;
SELECT * FROM account ORDER BY id \;
ROLLBACK;
```

`\;` tells psql "keep collecting, don't send yet", so the whole script goes to the server
in one go when you type the final `;`, and `\w 1.3.sql` then saves **all** of it. Made a
mistake? Press the up arrow to bring the whole script back, fix it, run it and `\w`
again. `\i 1.3.sql` runs a saved script one statement at a time, which is exactly how
`:check` runs it.

One difference to know: when statements are sent together, the server stops at the
first error and skips the rest. `\i` carries on after an error, the way a script file
does. So for a script that has to keep going after an error (3.2), run it with `\i` to
see what the grader sees. If psql says *current transaction is aborted*, type
`ROLLBACK;` to get a working session back.

**How scripts are graded:** `:check` runs each saved script the way `\i` does, on a
**fresh copy of the table above**, then looks at the balances and the server's replies
(`BEGIN`, `UPDATE 1`, `ROLLBACK`, `ERROR`...). So it doesn't matter what you did in the
live database while trying things. Don't put `\c` in a script.

**A second session from SQL.** Two drills need a second session, so you can watch one
transaction from outside. `dblink` (already installed in `bank`) runs a statement over its
own, separate connection, just like another user would:

```sql
SELECT * FROM dblink('dbname=bank', 'SELECT id, balance FROM account ORDER BY id')
       AS t(id INT, balance NUMERIC);                                 -- read from outside
SELECT dblink_exec('dbname=bank', 'UPDATE account SET balance = balance + 1 WHERE id = 3');
                                                                      -- change from outside
```

**ACID** in one line each: **A**tomicity (all or nothing), **C**onsistency (rules such
as the `CHECK` always hold), **I**solation (transactions don't see each other's
unfinished work), **D**urability (once committed, it survives a crash).

## Tier 1 - BEGIN, COMMIT and ROLLBACK *(hint: `BEGIN;` ... `COMMIT;` or `ROLLBACK;`)*

**1.1 (graded)** In the live database, move **5.00 from Ana (account 1) to Ben (account
2)** in one transaction and commit it. Afterwards Ana has 95.00 and Ben has 105.00.

**1.2 (drill)** Start a transaction, take 5.00 from account 1, and **before** you commit,
look at the table from a second session with the `dblink` read above. That session
still sees the old balance: PostgreSQL's default level, **Read Committed**, only shows
committed data. Inside your own transaction you do see the change. Then `ROLLBACK;`.

**1.3 (graded)** Write a script and save it as `1.3.sql`: a transaction that takes 5.00
from account 1, then tries to add it to account **99** (it doesn't exist, so psql replies
`UPDATE 0`). The money would vanish, so the script ends with `ROLLBACK`, and the table is
exactly as it was.

## Tier 2 - Savepoints and isolation levels *(hint: `SAVEPOINT name;` / `ROLLBACK TO SAVEPOINT name;`)*

**2.1 (graded)** Write a script and save it as `2.1.sql`. In one transaction: open an
account for **Fay** with **500.00**, create a savepoint, then make a mistake: set
**every** balance to 0 (`UPDATE account SET balance = 0;`). Undo only the mistake by rolling back to the
savepoint, and commit. Fay's account must survive, and every other balance must be
unchanged.

**2.2 (graded)** The month-end report reads the table several times and must see the same
data each time, even if payments commit in between. Save a script as `2.2.sql`: start a
transaction at the isolation level that guarantees **a row read twice has the same
value**, show the level with `SHOW transaction_isolation;`, select the total of all
balances, and commit.

**2.3 (drill)** Watch an isolation level work. In psql:
`BEGIN; SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; SELECT balance FROM account WHERE id = 3;`
Then change it from another session with the `dblink_exec` line above (it adds 1.00 to
Carla and commits straight away). Read it again inside your transaction: it hasn't
changed. `COMMIT;` and read it once more. Try the same with the default (Read Committed) and compare. (PostgreSQL accepts
`READ UNCOMMITTED` but treats it as Read Committed: there are no dirty reads.)

## Tier 3 - Payments that can't lose money *(goal only)*

> **Scenario:** The payments service runs your scripts. Networks drop and accounts run
> dry, so a payment must never be half done.

**3.1 (graded)** Save a script as `3.1.sql` that moves **30.00 from Carla (3) to Dev (4)**.
It must be all or nothing. The grader also runs it when the credit to Dev fails, and
when Carla doesn't have enough money. In both cases **no** balance may change.

**3.2 (graded)** Save a script as `3.2.sql`. Carla pays two bills in one transaction:
**20.00 to Dev (4)**, then **500.00 to Eve (5)**. The second payment breaks the `CHECK`
rule, so you get an error and the transaction is aborted. Keep the first payment and
drop the second, so that after the commit Carla has 230.00, Dev 60.00 and Eve 0.00.
Make the script actually attempt the 500.00 payment, and check it with `\i 3.2.sql`.

## Self-check questions

1. What does each letter of ACID guarantee? Give a bank example for one of them.
2. After an error inside `BEGIN`, PostgreSQL says "current transaction is aborted". What
   does `COMMIT` do at that point?
3. What is the difference between `ROLLBACK` and `ROLLBACK TO SAVEPOINT x`?
4. Which isolation level is PostgreSQL's default, and what can't it guarantee that
   Repeatable Read can?
5. Why is "check the balance, then update it" in two separate statements risky without
   a transaction?
