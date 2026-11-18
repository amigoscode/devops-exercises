#!/usr/bin/env bash
# Runs INSIDE the container. Grades the tables you created in my_db and the files
# you saved in the sandbox folder (~/sandbox).
set -uo pipefail
SB="$HOME/sandbox"; DB=my_db
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# run FILE DB - run a saved query inside a transaction that is rolled back
run(){ { echo 'BEGIN;'; cat "$1"; echo; echo ';'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# cols TABLE - "name type, ..." for a table in public, sorted by column name ("" if missing)
cols(){ q "SELECT string_agg(a.attname || ' ' || format_type(a.atttypid, a.atttypmod), ', ' ORDER BY a.attname)
           FROM pg_attribute a WHERE a.attrelid = to_regclass('public.$1') AND a.attnum > 0 AND NOT a.attisdropped"; }

echo "Tier 1 - Semicolons and case"
[[ "$(q "SELECT to_regclass('public.foo_bar') IS NULL")" == t ]] \
  && ok "1.2 foo_bar is gone - the DROP TABLE ran once you ended it with ;" \
  || no "1.2 foo_bar still exists: type DROP TABLE foo_bar and finish it with a semicolon"

echo "Tier 2 - Naming conventions and the query buffer"
if [[ "$(cols person_address)" == "date_moved_in date, id integer, post_code text, street_name text" ]] \
   && [[ "$(q "SELECT to_regclass('public.personaddresses') IS NULL AND to_regclass('public.\"PersonAddresses\"') IS NULL")" == t ]]; then
  ok "2.1 person_address (id, street_name, post_code, date_moved_in) - snake_case and singular"
else
  no "2.1 create person_address with id INTEGER, street_name TEXT, post_code TEXT, date_moved_in DATE (and no PersonAddresses table)"
fi
[[ "$(cols customer_order)" == "date date, description text, id integer" ]] \
  && ok "2.2 customer_order (id, date, description) exists - ORDER is reserved, customer_order isn't" \
  || no "2.2 create customer_order with id INTEGER, date DATE, description TEXT (fix the failed statement with \\e)"
f="$SB/2.3.sql"
if [[ -s "$f" ]] && grep -Eiq 'select[[:space:]]+\*[[:space:]]+from[[:space:]]+(public\.)?customer_order' "$f" \
   && run "$f" "$DB" >/dev/null; then
  ok "2.3 2.3.sql holds SELECT * FROM customer_order (saved with \\w)"
else
  no "2.3 run SELECT * FROM customer_order; then save it with \\w 2.3.sql"
fi

echo "Tier 3 - Run SQL from a file"
want="country_of_origin character varying(50), dob date, first_name character varying(50), gender character(1), id integer, last_name character varying(50), phone_number character varying(15)"
[[ "$(cols person)" == "$want" ]] \
  && ok "3.1 person exists with its seven columns (run from query.sql)" \
  || no "3.1 run query.sql from psql with \\i query.sql so the person table exists"
log="$SB/passport.log"
if [[ "$(cols passport)" == "expiry_date date, id integer, passport_number character varying(20)" ]] \
   && [[ -s "$SB/passport.sql" ]] && grep -Eiq 'create[[:space:]]+table[[:space:]]+passport' "$SB/passport.sql" \
   && [[ -s "$log" ]] && grep -q '^CREATE TABLE$' "$log"; then
  ok "3.2 passport.sql written with \\w and run with \\i, its CREATE TABLE reply captured in passport.log with \\o"
else
  no "3.2 type CREATE TABLE passport (id INTEGER, passport_number VARCHAR(20), expiry_date DATE) with no ;, then \\w passport.sql, \\r, \\o passport.log, \\i passport.sql, \\o"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Semicolons, naming, the query buffer and script files - the habits behind every query."
