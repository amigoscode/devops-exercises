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
# keep - the original cars no task deletes: all of them must still be there
keep(){ [[ "$(q "SELECT count(*) FROM car WHERE id BETWEEN 1 AND 100 AND id NOT IN (15, 41, 74, 75, 89, 90)")" == 94 ]]; }

echo "Tier 1 - DELETE"
[[ "$(q "SELECT to_regclass('public.example') IS NULL")" == t ]] \
  && ok "1.1 the example table is emptied and dropped" \
  || no "1.1 DELETE FROM example; (all 5 rows) then DROP TABLE example;"
[[ "$(q "SELECT count(*) FROM car WHERE brand = 'GMC'")" == 0 ]] && keep \
  && ok "1.2 every GMC is gone - and only the GMCs" \
  || no "1.2 DELETE FROM car WHERE brand = 'GMC'; - no other car may disappear"
[[ "$(q "SELECT count(*) FROM car WHERE id = 15")" == 0 && "$(q "SELECT count(*) FROM car WHERE id IN (13, 14)")" == 2 ]] && keep \
  && ok "1.3 the BYD Song (id 15) is gone, the other two BYDs are still there" \
  || no "1.3 delete only the BYD Song, by its id: DELETE FROM car WHERE id = 15;"

echo "Tier 2 - UPDATE"
[[ "$(q "SELECT count(*) FILTER (WHERE phone_number IS NULL) || '/' || count(*) FILTER (WHERE phone_number = 'unknown') || '/' || count(*) FILTER (WHERE phone_number LIKE '123-456-%') FROM person")" == "0/17/84" ]] \
  && ok "2.1 the 17 missing phone numbers say 'unknown', the real ones are untouched" \
  || no "2.1 UPDATE person SET phone_number = 'unknown' WHERE phone_number IS NULL; (17 rows, nobody else)"
[[ "$(q "SELECT first_name FROM person WHERE id = 101")" == Samba && "$(q "SELECT count(*) FROM person WHERE first_name = 'Samba'")" == 1 ]] \
  && ok "2.2 person 101 is called Samba - and nobody else is" \
  || no "2.2 UPDATE person SET first_name = 'Samba' WHERE id = 101;"
[[ "$(q "SELECT concat_ws('|', last_name, gender, country_of_origin) FROM person WHERE id = 101")" == "Nelson|M|Guinea-Bissau" \
   && "$(q "SELECT count(*) FROM person WHERE country_of_origin = 'Guinea-Bissau'")" == 1 \
   && "$(q "SELECT count(*) FILTER (WHERE gender = 'M') || '/' || count(*) FILTER (WHERE last_name = 'Nelson') FROM person")" == "51/3" ]] \
  && ok "2.3 person 101: Nelson, M, Guinea-Bissau" \
  || no "2.3 UPDATE person SET last_name = 'Nelson', gender = 'M', country_of_origin = 'Guinea-Bissau' WHERE id = 101;"
[[ "$(q "SELECT dob FROM person WHERE id = 101")" == 2000-01-30 && "$(q "SELECT count(*) FROM person WHERE dob = '2000-01-30'")" == 1 ]] \
  && ok "2.4 person 101 was born on 2000-01-30 (and only them)" \
  || no "2.4 UPDATE person SET dob = '2000-01-30' WHERE id = 101;"

echo "Tier 3 - CRUD on the car table"
[[ "$(q "SELECT string_agg(concat_ws('|', id, brand, model, price, mileage, is_electric), ',') FROM car WHERE id = 101")" == "101|Toyota|Supra|55000.00|3000|f" ]] \
  && ok "3.1 car 101 is a Toyota Supra, 55000.00, 3000 miles, not electric" \
  || no "3.1 INSERT INTO car (id, brand, model, price, mileage, is_electric) VALUES (101, 'Toyota', 'Supra', 55000.00, 3000, FALSE);"
same_rows "$SB/3.2.sql" "SELECT brand, model, price FROM car WHERE brand = 'Ferrari'" "$DB" \
  && ok "3.2 3.2.sql reads brand, model, price of every Ferrari" \
  || no "3.2 3.2.sql: SELECT brand, model, price FROM car WHERE brand = 'Ferrari'"
others="SELECT id || ':' || price FROM car WHERE brand <> 'Ferrari' AND id <= 100 ORDER BY id"
[[ "$(q "SELECT string_agg(id || ':' || price, ',' ORDER BY id) FROM car WHERE brand = 'Ferrari'")" == "8:308000.00,9:242000.00,10:330000.00,98:308000.00,99:242000.00,100:330000.00" ]] \
  && [[ -z "$(grep -vxF -f <(q "$others" "$REF") <<<"$(q "$others")")" ]] \
  && ok "3.3 every Ferrari costs 10% more, every other price is unchanged" \
  || no "3.3 UPDATE car SET price = price * 1.10 WHERE brand = 'Ferrari'; (once, Ferraris only)"
[[ "$(q "SELECT count(*) FROM car WHERE NOT is_electric AND mileage >= 22000")" == 0 \
   && "$(q "SELECT count(*) FROM car WHERE id IN (13, 14)")" == 2 ]] && keep \
  && ok "3.4 the non-electric cars with 22000+ miles are gone, electric ones stay" \
  || no "3.4 DELETE FROM car WHERE is_electric = FALSE AND mileage >= 22000; (the electric BYDs must stay)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Create, read, update, delete - with a WHERE every time it matters."
