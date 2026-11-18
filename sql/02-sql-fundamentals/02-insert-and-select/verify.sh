#!/usr/bin/env bash
# Runs INSIDE the container. Grades the queries you saved in ~/sandbox/<task>.sql
# and the data you loaded into my_db.
set -uo pipefail
SB="$HOME/sandbox"; DB=my_db; REF="${DB}_ref"   # REF: untouched copy made by seed.sh
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# wrap FILE [PRE] [POST] - the saved file inside a transaction that is rolled back,
#                          so checking never changes anything (works with or without a final ;)
wrap(){ echo 'BEGIN;'; [[ -n "${2:-}" ]] && echo "$2"; cat "$1"; echo; echo ';'; [[ -n "${3:-}" ]] && echo "$3"; echo 'ROLLBACK;'; }
# run FILE DB - run a saved query (rolled back), bare output
run(){ wrap "$1" | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# same_rows FILE REFSQL [DB]    - FILE returns the same rows as the reference query
#                                 (any order). Default DB: the untouched copy.
same_rows(){ local d="${3:-$REF}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d" | sort) <(sort <<<"$want") >/dev/null; }
# same_ordered FILE REFSQL [DB] - ... and in the same order (ORDER BY tasks)
same_ordered(){ local d="${3:-$REF}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d") <(cat <<<"$want") >/dev/null; }
# heads FILE [DB] - the column names FILE's query returns, as "a|b|c"
heads(){ [[ -s "$1" ]] && wrap "$1" | psql -X -A -q -v ON_ERROR_STOP=1 -d "${2:-$REF}" 2>/dev/null | head -1; }
# inserted FILE - replay a saved INSERT on an empty person table (rolled back) and
#                 print the rows it inserted
inserted(){ [[ -s "$1" ]] && wrap "$1" 'DELETE FROM person;' \
  'SELECT id, first_name, last_name, gender, dob, phone_number, country_of_origin FROM person ORDER BY id;' \
  | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$REF" 2>/dev/null; }

echo "Tier 1 - INSERT and SELECT"
[[ "$(inserted "$SB/1.1.sql")" == "1|Jamila|Bah|F|1997-01-20|123-456-789|Guinea-Bissau" ]] \
  && ok "1.1 1.1.sql inserts Jamila Bah with all seven values" \
  || no "1.1 run an INSERT INTO person (...) VALUES (...) for Jamila (all 7 columns, text and dates in single quotes) and save it with \\w 1.1.sql"
[[ "$(inserted "$SB/1.2.sql")" == "2|Alex|Yu|M|1980-09-04|000-000-000|Italy" ]] \
  && ok "1.2 1.2.sql inserts Alex Yu with all seven values" \
  || no "1.2 run the INSERT for Alex (id 2, Alex, Yu, M, 1980-09-04, 000-000-000, Italy) and save it with \\w 1.2.sql"
same_rows "$SB/1.3.sql" "SELECT first_name, last_name, dob FROM person" \
  && ok "1.3 1.3.sql selects first_name, last_name and dob of everyone" \
  || no "1.3 1.3.sql must return first_name, last_name, dob (in that order) for every person"

echo "Tier 2 - Sample data, aliases and ORDER BY"
snap="SELECT count(*) || ':' || md5(string_agg(p::text, '|' ORDER BY p::text)) FROM person p"
[[ "$(q "$snap")" == "$(q "$snap" "$REF")" && "$(q "SELECT count(*) FROM person")" == 100 ]] \
  && ok "2.1 person holds exactly the 100 sample people" \
  || no "2.1 DELETE FROM person; then \\i sample-data.sql - person must hold exactly the 100 sample people"
same_rows "$SB/2.2.sql" "SELECT first_name, last_name, dob FROM person" \
  && [[ "$(heads "$SB/2.2.sql")" == "name|surname|date_of_birth" ]] \
  && ok "2.2 2.2.sql renames the columns to name, surname, date_of_birth" \
  || no "2.2 2.2.sql: first_name AS name, last_name AS surname, dob AS date_of_birth for everyone"
same_ordered "$SB/2.3.sql" "SELECT id, first_name, last_name FROM person ORDER BY id DESC" \
  && ok "2.3 2.3.sql lists id, first_name, last_name from the highest id down" \
  || no "2.3 2.3.sql: id, first_name, last_name of everyone, ORDER BY id DESC"
same_ordered "$SB/2.4.sql" "SELECT first_name, last_name, country_of_origin FROM person ORDER BY first_name, last_name DESC" \
  && ok "2.4 2.4.sql sorts by first_name A-Z, then last_name Z-A" \
  || no "2.4 2.4.sql: first_name, last_name, country_of_origin ORDER BY first_name (ASC), then last_name DESC"

echo "Tier 3 - Remove duplicates"
same_ordered "$SB/3.1.sql" "SELECT DISTINCT country_of_origin FROM person ORDER BY country_of_origin" \
  && ok "3.1 3.1.sql lists each country once, A-Z" \
  || no "3.1 3.1.sql: only country_of_origin, no duplicates (DISTINCT), sorted A-Z"
same_ordered "$SB/3.2.sql" "SELECT DISTINCT country_of_origin, gender FROM person ORDER BY country_of_origin, gender" \
  && ok "3.2 3.2.sql lists each country + gender combination once, sorted" \
  || no "3.2 3.2.sql: DISTINCT country_of_origin, gender, ordered by country then gender"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can put data in and get it back out - sorted, renamed and de-duplicated."
