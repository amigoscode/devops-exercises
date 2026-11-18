#!/usr/bin/env bash
# Runs INSIDE the container. Grades the queries you saved in ~/sandbox/<task>.sql
# and the changes you made to my_db.
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

echo "Tier 1 - WHERE and comparison operators"
same_rows "$SB/1.1.sql" "SELECT * FROM person WHERE country_of_origin = 'USA'" \
  && ok "1.1 1.1.sql returns every column for the people from the USA" \
  || no "1.1 1.1.sql: SELECT * FROM person WHERE country_of_origin = 'USA'"
same_rows "$SB/1.2.sql" "SELECT first_name, last_name FROM person WHERE gender = 'F'" \
  && ok "1.2 1.2.sql returns first_name, last_name of the women" \
  || no "1.2 1.2.sql: first_name, last_name WHERE gender = 'F'"
same_rows "$SB/1.3.sql" "SELECT first_name, last_name, country_of_origin FROM person WHERE country_of_origin <> 'UK'" \
  && ok "1.3 1.3.sql returns everyone not from the UK (<> or !=)" \
  || no "1.3 1.3.sql: first_name, last_name, country_of_origin WHERE country_of_origin is not equal to 'UK'"
same_rows "$SB/1.4.sql" "SELECT first_name, last_name, dob FROM person WHERE dob >= '2000-01-01'" \
  && ok "1.4 1.4.sql returns everyone born on or after 2000-01-01 (>=)" \
  || no "1.4 1.4.sql: first_name, last_name, dob WHERE dob >= '2000-01-01' (on or after - not just after)"

echo "Tier 2 - Booleans, AND/OR, IN and BETWEEN"
same_rows "$SB/2.2.sql" "SELECT first_name, last_name, dob FROM person WHERE gender = 'M' AND country_of_origin = 'UK' AND dob < '2000-01-01'" \
  && ok "2.2 2.2.sql returns the men from the UK born before 2000 (AND)" \
  || no "2.2 2.2.sql: first_name, last_name, dob WHERE gender 'M' AND country 'UK' AND dob before 2000-01-01"
same_rows "$SB/2.3.sql" "SELECT first_name, last_name, country_of_origin FROM person WHERE gender = 'F' AND (country_of_origin = 'Iraq' OR country_of_origin = 'Pakistan')" \
  && ok "2.3 2.3.sql returns only the women from Iraq or Pakistan (grouped with parentheses)" \
  || no "2.3 2.3.sql: women from Iraq or Pakistan - gender = 'F' AND (... OR ...); without the parentheses you also get men"
same_rows "$SB/2.4.sql" "SELECT id, first_name, last_name, country_of_origin FROM person WHERE country_of_origin IN ('Egypt', 'USA', 'Jordan', 'UK')" \
  && ok "2.4 2.4.sql returns the people from Egypt, USA, Jordan or UK (IN)" \
  || no "2.4 2.4.sql: id, first_name, last_name, country_of_origin WHERE country_of_origin IN ('Egypt', 'USA', 'Jordan', 'UK')"
same_rows "$SB/2.5.sql" "SELECT id, first_name, last_name, country_of_origin FROM person WHERE country_of_origin NOT IN ('Egypt', 'USA', 'Jordan', 'UK')" \
  && ok "2.5 2.5.sql returns everyone from any other country (NOT IN)" \
  || no "2.5 2.5.sql: the same columns WHERE country_of_origin NOT IN (...the four countries...)"
same_rows "$SB/2.6.sql" "SELECT id, first_name, last_name, dob FROM person WHERE dob BETWEEN '2000-08-15' AND '2010-04-25'" \
  && ok "2.6 2.6.sql returns everyone born 2000-08-15 to 2010-04-25, both days included" \
  || no "2.6 2.6.sql: id, first_name, last_name, dob WHERE dob BETWEEN '2000-08-15' AND '2010-04-25' (both ends included)"

echo "Tier 3 - Patterns, NULLs and paging"
same_rows "$SB/3.1.sql" "SELECT first_name, last_name FROM person WHERE first_name LIKE 'M%'" \
  && ok "3.1 3.1.sql returns everyone whose first name starts with M (LIKE 'M%')" \
  || no "3.1 3.1.sql: first_name, last_name WHERE first_name LIKE 'M%' (% = any characters after the M)"
same_rows "$SB/3.2.sql" "SELECT id, first_name, last_name FROM person WHERE first_name LIKE 'Mar_am'" \
  && grep -Eiq 'like' "$SB/3.2.sql" \
  && ok "3.2 3.2.sql finds both Maryam and Mariam with one pattern" \
  || no "3.2 3.2.sql: id, first_name, last_name with one LIKE pattern matching Maryam and Mariam (_ = exactly one character)"
[[ "$(q "SELECT string_agg(concat_ws('|', id, first_name, last_name, gender, dob, phone_number, country_of_origin), ',') FROM person WHERE id = 101")" == "101|nelson" ]] \
  && ok "3.3 person 101 exists with only the last name 'nelson'" \
  || no "3.3 INSERT INTO person (id, last_name) VALUES (101, 'nelson'); - once, lowercase, no other columns"
same_rows "$SB/3.4.sql" "SELECT id, first_name, last_name FROM person WHERE last_name ILIKE 'nelson'" \
  && ok "3.4 3.4.sql finds all three Nelsons, any letter case (ILIKE)" \
  || no "3.4 3.4.sql: id, first_name, last_name WHERE last_name ILIKE 'nelson' (LIKE is case-sensitive and misses 'nelson')"
same_rows "$SB/3.5.sql" "SELECT id, first_name, last_name FROM person WHERE phone_number IS NULL" \
  && ok "3.5 3.5.sql returns everyone without a phone number (IS NULL)" \
  || no "3.5 3.5.sql: id, first_name, last_name WHERE phone_number IS NULL (= NULL never matches)"
same_ordered "$SB/3.6.sql" "SELECT id, first_name, last_name FROM person ORDER BY id OFFSET 10 LIMIT 10" \
  && ok "3.6 3.6.sql returns rows 11-20 by id (OFFSET 10 LIMIT 10)" \
  || no "3.6 3.6.sql: id, first_name, last_name ORDER BY id, OFFSET 10, LIMIT 10 (or FETCH FIRST 10 ROWS ONLY)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can ask for exactly the rows you need - the WHERE you'll reuse on UPDATE and DELETE."
