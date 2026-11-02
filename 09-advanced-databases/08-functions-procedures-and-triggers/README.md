# 08 · Functions, Procedures & Triggers

> Maps to **Advanced Databases → Section 17: Functions, Stored Procedures and Triggers**
> (`CREATE FUNCTION`, PL/pgSQL, `RETURNS`, `\df`, `CREATE PROCEDURE`, `CALL`, `FOUND`,
> `RAISE EXCEPTION`, trigger functions, `NEW` / `OLD`, `CREATE TRIGGER`)

Some logic belongs next to the data: a calculation every service needs, a money transfer
that must check its own rules, or a rule like "every new user gets a role" that has to
run however the row arrives. Functions, procedures and triggers are how you put that
logic in PostgreSQL. You'll also find them in every Supabase project and in most
legacy codebases.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Functions, Procedures & Triggers** and press
`enter`. You land in `psql`, connected to the `platform` database. Everything here is
graded on the live database, so there are no files to save. `:questions` shows the
questions again, `:check` grades your work, and `exit` takes you back with your progress
saved. Press `r` in the Academy for a fresh start.

---

**Long statements in psql.** Type a `CREATE FUNCTION` over as many lines as you like:
psql knows a `;` between the `$$` marks is part of the body, so nothing runs until the
`;` after `LANGUAGE plpgsql`. To fix one, press the up arrow (the whole statement comes
back), edit it and press `enter`. Always write `CREATE OR REPLACE` so you can run it
again.

The `platform` database has:

- `account (id, owner, balance)`: Ana 100.00, Ben 100.00, Carla 250.00. There's **no**
  `CHECK` rule this time, so your code has to protect the balances.
- `account_audit (id, account_id, old_balance, new_balance, changed_at)`: empty for now.
- A small course platform: `app_user (id, email, full_name, signup_role)`,
  `user_role (user_id, role)`, `course`, `course_enrollment (id, student_id, course_id,
  progress)` and `certificate (id, course_id, student_id, issued_at)`. `app_role` is an
  enum: `'student'`, `'instructor'`, `'admin'`.

```sql
CREATE OR REPLACE FUNCTION name(a INTEGER, b INTEGER)
RETURNS INTEGER AS $$
BEGIN                       -- not a transaction: just the start of the body
    RETURN a + b;
END;
$$ LANGUAGE plpgsql;
```

## Tier 1 - Functions *(hint: `CREATE OR REPLACE FUNCTION ... RETURNS ... AS $$ BEGIN ... END; $$ LANGUAGE plpgsql;`)*

**1.1 (graded)** Write the function from the video: `add_numbers(n1 INTEGER, n2 INTEGER)`
returns their sum as an `INTEGER`, in PL/pgSQL. `SELECT add_numbers(10, 7);` gives `17`.

**1.2 (graded)** Write `account_balance(acc_id INTEGER)`, which returns that account's
balance as a `NUMERIC`. Use `DECLARE` for a variable and `SELECT balance INTO ...`.
For an id that doesn't exist it returns `NULL`.

**1.3 (drill)** List your functions with `\df`, print one's source with
`\sf add_numbers`, and call both functions with a few inputs.

## Tier 2 - Stored procedures and your first trigger *(hint: `CREATE OR REPLACE PROCEDURE ...`, run with `CALL`)*

**2.1 (graded)** Create the procedure `transfer_funds(from_acc INT, to_acc INT, amount
NUMERIC)`. It takes `amount` from one account and adds it to the other.
`CALL transfer_funds(1, 2, 30);` moves 30.00 from Ana to Ben.

**2.2 (graded)** Right now, a transfer to an account that doesn't exist makes the money
vanish. Make `transfer_funds` **raise an exception** (`RAISE EXCEPTION '...'`) when:
- the sender doesn't exist (after the `UPDATE`, check `IF NOT FOUND THEN`),
- the sender would end up **below 0** (moving the whole balance is fine),
- the receiver doesn't exist.

Because the exception aborts the whole `CALL`, a failed transfer changes nothing. Don't
put `COMMIT` in the procedure: the caller decides. Try `BEGIN; CALL ...; ROLLBACK;` and
watch the transfer disappear.

**2.3 (graded)** Every new user needs a row in `user_role`. Write a trigger function that
`RETURNS TRIGGER` and inserts `NEW.id` with the user's `signup_role`, or `'student'` if
they didn't pick one. Attach it with an `AFTER INSERT ... FOR EACH ROW` trigger on
`app_user`.

## Tier 3 - Triggers the platform relies on *(goal only)*

> **Scenario:** These run in production for every student. They have to be right, and
> they have to be quiet when there's nothing to do.

**3.1 (graded)** When a student's `course_enrollment.progress` is updated to **100**,
issue a `certificate` for that course and student. If they already have one (say, the
row is updated again), don't create a duplicate. Below 100, issue nothing.

**3.2 (graded)** Auditors want a trail of every balance change. Add a trigger on
`account` that writes `(account_id, old_balance, new_balance)` to `account_audit` for
each row whose balance **actually changes**. Renaming an owner, or `SET balance =
balance`, must not log anything.

**3.3 (graded)** Write `account_history(acc_id INT)`, a function that
`RETURNS TABLE (changed_at TIMESTAMPTZ, old_balance NUMERIC, new_balance NUMERIC)` with
that account's rows from `account_audit`, **oldest first**. (In PL/pgSQL the output
columns share names with the table's columns, so qualify them with an alias like
`a.old_balance`, or write the function in `LANGUAGE sql`.)

## Self-check questions

1. What can a procedure do that a function can't, and how do you run each one?
2. What does `FOUND` tell you after an `UPDATE`, and why check it?
3. In a trigger function, what are `NEW` and `OLD`? Which ones exist for an INSERT, an
   UPDATE and a DELETE?
4. `BEFORE` or `AFTER`: which would you use to change a row before it's saved, and which
   to write to another table?
5. Triggers run behind the scenes. What makes them hard to debug, and how would you
   keep them predictable?
