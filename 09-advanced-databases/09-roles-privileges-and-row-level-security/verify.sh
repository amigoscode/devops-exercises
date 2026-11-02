#!/usr/bin/env bash
# Runs INSIDE the container. Grades roles, privileges and row-level security in the
# "company" database by acting as each role (SET ROLE) inside transactions that are
# rolled back, so checking never changes your data.
set -uo pipefail
SB="$HOME/sandbox"; DB=company
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL - run SQL as you (a superuser), bare output
q(){ psql -X -A -t -q -d "$DB" -c "$1" 2>/dev/null; }
# as ROLE SQL - run SQL as ROLE in a rolled-back transaction; non-zero exit on the first error
as(){ { echo 'BEGIN;'; echo "SET ROLE $1;"; printf '%s\n' "$2"; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>/dev/null; }
# attrs ROLE - login|superuser|createdb, e.g. "t|f|t" (empty if the role doesn't exist)
attrs(){ q "SELECT concat_ws('|', left(rolcanlogin::text, 1), left(rolsuper::text, 1), left(rolcreatedb::text, 1)) FROM pg_roles WHERE rolname = '$1'"; }
member(){ [[ "$(q "SELECT pg_has_role('$1', '$2', 'MEMBER')")" == t ]]; }
NEWCAR="INSERT INTO car (make, model, year, price) VALUES ('Fiat', '500', 2024, 15000)"
NEWEMP="INSERT INTO employee (username, name, role, department) VALUES ('fubar', 'Foo Bar', 'Sales Executive', 'Marketing')"
# changed ROLE SQL - how many rows an UPDATE changed, run as ROLE
changed(){ as "$1" "WITH u AS ($2 RETURNING 1) SELECT count(*) FROM u;"; }

echo "Tier 1 - Roles"
if [[ "$(attrs jamila)" == 't|f|f' ]] \
   && [[ "$(PGPASSWORD=password psql -X -A -t -h localhost -U jamila -d "$DB" -c 'SELECT current_user' 2>/dev/null)" == jamila ]]; then
  ok "1.1 jamila can log in with her password (and has no extra powers)"
else
  no "1.1 CREATE ROLE jamila WITH LOGIN PASSWORD 'password'; (no SUPERUSER or other attributes)"
fi

if [[ "$(attrs ci_runner)" == 't|f|t' ]]; then
  ok "1.2 ci_runner is no longer a superuser but can still log in and create databases"
else
  no "1.2 ALTER ROLE ci_runner: remove SUPERUSER (NOSUPERUSER), keep LOGIN, add CREATEDB"
fi

if [[ -z "$(attrs old_contractor)" ]] && [[ "$(q 'SELECT count(*) FROM car')" -ge 6 ]]; then
  ok "1.3 old_contractor is gone (and the car table is still there)"
else
  no "1.3 drop the role old_contractor - DROP ROLE complains while it still has privileges, so revoke them first"
fi

echo "Tier 2 - Privileges and groups"
if [[ -n "$(attrs jamila)" ]] && [[ "$(as jamila 'SELECT count(*) FROM car;')" -ge 6 ]] \
   && ! as jamila "$NEWCAR;" >/dev/null && ! as jamila 'UPDATE car SET price = 1;' >/dev/null \
   && ! as jamila 'DELETE FROM car;' >/dev/null && ! as jamila 'SELECT count(*) FROM employee;' >/dev/null; then
  ok "2.1 jamila can SELECT from car - and can't INSERT, UPDATE, DELETE or read employee"
else
  no "2.1 GRANT SELECT ON car TO jamila; - read-only, on that table only"
fi

if [[ "$(attrs dev_team)" == f\|* && "$(attrs data_team)" == f\|* && "$(attrs alex)" == t\|f\|* ]] \
   && member alex dev_team && member alex data_team && member jamila data_team && ! member jamila dev_team \
   && [[ "$(PGPASSWORD=password psql -X -A -t -h localhost -U alex -d "$DB" -c 'SELECT current_user' 2>/dev/null)" == alex ]]; then
  ok "2.2 dev_team and data_team are groups; alex is in both, jamila only in data_team"
else
  no "2.2 CREATE ROLE dev_team / data_team (no LOGIN); CREATE ROLE alex WITH LOGIN PASSWORD 'password'; GRANT dev_team, data_team TO alex; GRANT data_team TO jamila"
fi

if member alex dev_team && member jamila data_team \
   && [[ "$(as alex "$NEWCAR; UPDATE car SET price = price + 1 WHERE make = 'Fiat'; SELECT count(*) FROM car WHERE make = 'Fiat';")" == 1 ]] \
   && ! as alex 'DELETE FROM car;' >/dev/null \
   && as alex 'SELECT count(*) FROM employee;' >/dev/null \
   && as jamila 'CREATE SCHEMA data_sandbox;' >/dev/null \
   && ! as dpatel 'CREATE SCHEMA nope;' >/dev/null; then
  ok "2.3 dev_team can SELECT/INSERT/UPDATE (not DELETE) every table; data_team has ALL on the company database"
else
  no "2.3 GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO dev_team (+ USAGE on the sequences); GRANT ALL PRIVILEGES ON DATABASE company TO data_team"
fi

echo "Tier 3 - Row-level security for the HR app"
if [[ "$(q "SELECT relrowsecurity FROM pg_class WHERE oid = 'employee'::regclass")" == t ]] \
   && [[ "$(as dpatel "SELECT string_agg(username, ',') FROM employee;")" == dpatel ]] \
   && [[ "$(as tcohen "SELECT string_agg(username, ',') FROM employee;")" == tcohen ]] \
   && [[ "$(as jane "SELECT string_agg(username, ',') FROM employee;")" == jane ]]; then
  ok "3.1 RLS is on: each employee sees only their own row"
else
  no "3.1 ALTER TABLE employee ENABLE ROW LEVEL SECURITY + a FOR SELECT policy USING (username = current_user)"
fi

if [[ "$(as jane "$NEWEMP; SELECT 'inserted';")" == inserted ]] && ! as dpatel "$NEWEMP;" >/dev/null \
   && ! as tcohen "$NEWEMP;" >/dev/null; then
  ok "3.2 managers (jane) can add employees; everyone else is blocked"
else
  no "3.2 a FOR INSERT policy WITH CHECK (EXISTS (SELECT 1 FROM employee WHERE username = current_user AND role = 'Manager'))"
fi

TOTAL="$(q 'SELECT count(*) FROM employee')"
if [[ "$(as jane "SET session.user_role = 'Manager'; SELECT count(*) FROM employee;")" == "$TOTAL" ]] \
   && [[ "$(as jane "SET session.user_role = 'Developer'; SELECT count(*) FROM employee;")" == 1 ]] \
   && [[ "$(as jane 'SELECT count(*) FROM employee;')" == 1 ]] && [[ "$(as dpatel 'SELECT count(*) FROM employee;')" == 1 ]]; then
  ok "3.3 with session.user_role = 'Manager' every row is visible; otherwise only your own (and no error when it isn't set)"
else
  no "3.3 a FOR SELECT policy USING (current_setting('session.user_role', true) = 'Manager') - no recursion, no error when unset"
fi

if [[ "$(changed dpatel "UPDATE employee SET name = 'Divya P.' WHERE username = 'dpatel'")" == 1 ]] \
   && [[ "$(changed dpatel "UPDATE employee SET name = 'Hacked' WHERE username = 'jane'")" == 0 ]] \
   && [[ "$(changed tcohen "UPDATE employee SET department = 'Sales'")" == 1 ]] \
   && ! as dpatel "UPDATE employee SET username = 'boss' WHERE username = 'dpatel';" >/dev/null; then
  ok "3.4 employees can update only their own row, and can't change its username"
else
  no "3.4 a FOR UPDATE policy USING (username = current_user) WITH CHECK (username = current_user)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Roles, privileges and row-level security done - least privilege, down to the row."
