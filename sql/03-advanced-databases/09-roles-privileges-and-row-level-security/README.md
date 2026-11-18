# 09 · Roles, Privileges & Row-Level Security

> Maps to **Advanced Databases → Section 18: Roles, Groups and Privileges** and
> **Section 21: Row-Level Security**
> (`CREATE ROLE`, attributes, `\du`, `SET ROLE`, `GRANT` / `REVOKE`, group roles,
> `ENABLE ROW LEVEL SECURITY`, `CREATE POLICY`, `USING` / `WITH CHECK`, `current_setting`)

Who can touch which data is one of the first questions in any security review.
Privileges decide which tables a role can read or change. Row-level security goes
further and decides which **rows** each user sees, which is how multi-tenant apps and
Supabase projects keep one customer's data away from another's. Get it wrong and you're
either blocking your own team or leaking data.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Advanced Databases → Roles, Privileges & Row-Level Security** and
press `enter`. You land in `psql`, connected to the `company` database as `student`, a
superuser. Everything here is graded on the live database, so there are no files to
save. `:questions` shows the questions again, `:check` grades your work, and `exit` takes
you back with your progress saved. Press `r` in the Academy for a fresh start.

---

The `company` database has two tables: `car (id, make, model, year, price)` and the
`employee (id, username, name, role, department)` table from the row-level security
videos. Its first row is you (`student`), and `jane` is a Manager.

Roles that already exist: `old_contractor`, `ci_runner`, and the HR app's `jane`,
`dpatel` and `tcohen`. Those three are members of a group role `staff` that can
`SELECT`, `INSERT` and `UPDATE` `employee`. Every login role's password is `password`.

**Acting as another role.** `SET ROLE jamila;` switches who you are (check with
`SELECT current_user;`), and `RESET ROLE;` switches back. To really **log in** as a role,
with its password, reconnect from psql:

- `\c company jamila localhost` connects to database `company` as role `jamila` on host
  `localhost`. psql asks for jamila's password.
- `\conninfo` shows who and where you are now.
- `\c dbname=company` takes you back to yourself (`student`).

Why `localhost`? Connections that don't name a host use *peer* authentication, which
only lets you in as your own user, so `\c company jamila` is refused. Over `localhost`
the server asks for a password instead. A wrong password keeps your current connection.
Superusers skip privilege and RLS checks, so always test as the role itself.

## Tier 1 - Roles *(hint: `CREATE ROLE name WITH LOGIN PASSWORD '...';`, `ALTER ROLE`, `DROP ROLE`)*

**1.1 (graded)** Create the role `jamila` with **LOGIN** and the password `password`, and
nothing else. Prove it works: `\c company jamila localhost`, type the password,
`SELECT current_user;`, then `\c dbname=company` to come back.

**1.2 (graded)** Someone made `ci_runner` a **SUPERUSER** "because it needed to create
test databases". That's far too much power. Take superuser away, keep its LOGIN, and give
it exactly the attribute it needs: **CREATEDB**.

**1.3 (graded)** `old_contractor` left the company. Drop the role. PostgreSQL refuses
while the role still holds privileges, so read the error and clean those up first.

**1.4 (drill)** Look around: `\du` and `\du+`. `SET ROLE jamila;`, then
`SELECT current_user;` and `SELECT * FROM car;` (permission denied).
Try `ALTER ROLE jamila SUPERUSER;` as jamila (denied). `RESET ROLE;`

## Tier 2 - Privileges and groups *(hint: `GRANT ... ON ... TO ...;` / `REVOKE ... FROM ...;` / `GRANT group TO user;`)*

**2.1 (graded)** Jamila needs to **read** the `car` table, and do nothing else with it.
She mustn't be able to insert, update or delete cars, and she still can't see `employee`.

**2.2 (graded)** Set up teams the way the video does:
- two group roles **without** LOGIN: `dev_team` and `data_team`,
- a new login role `alex` (password `password`) who belongs to **both** teams,
- `jamila` joins `data_team` only.

**2.3 (graded)** Give the teams their privileges:
- `dev_team` can `SELECT`, `INSERT` and `UPDATE` (but **not** `DELETE`) every table in
  schema `public`. For `INSERT` to fill in `id` (a `SERIAL`), the team also needs
  `USAGE` on the sequences in that schema.
- `data_team` gets **all privileges on the `company` database**.

Test it as alex (`SET ROLE alex;`, or log in with `\c company alex localhost`): add a
car, update it, then try to delete one.

## Tier 3 - Row-level security for the HR app *(goal only)*

> **Scenario:** The HR app connects as each employee's own role. Right now `dpatel`
> can read everyone's record. Lock `employee` down row by row. Test every policy with
> `SET ROLE jane;` / `SET ROLE dpatel;`, not as `student`, which bypasses RLS.

**3.1 (graded)** Turn on row-level security for `employee` and add a policy so each
employee can **select only their own row** (where `username` is the current user).

**3.2 (graded)** Only **managers** may add employees. Add an insert policy that lets the
current user insert a row only if *they* have `role = 'Manager'` in `employee`. Jane can
add `('fubar', 'Foo Bar', 'Sales Executive', 'Marketing')`, and dpatel can't.

**3.3 (graded)** Managers must see everyone. A select policy that queries `employee` from
inside its own policy fails with *infinite recursion detected* (try it). Use the video's
fix instead: the app runs `SET session.user_role = 'Manager';` for managers, and the
policy reads it with `current_setting(...)`. A user who never sets the variable must
still see their own row, not get an error (look up the second argument of
`current_setting`).

**3.4 (graded)** Employees can **update their own row only**, and they can't change its
`username` (that would hand the row to someone else). Updating anyone else's row changes
0 rows, and changing your own username is rejected.

## Self-check questions

1. A user and a group are both "roles" in PostgreSQL. What actually makes one of them a
   group?
2. Why is handing out `SUPERUSER` a bad idea, and what attributes or grants should you
   reach for instead?
3. In a policy, what is the difference between `USING` and `WITH CHECK`? Which one
   does an INSERT policy need?
4. RLS is enabled but there are no policies at all. What can a normal role see?
5. In 3.3, any user could run `SET session.user_role = 'Manager'` themselves. Why does
   that only work when the app (not the user) sets the variable, and what would be safer?
