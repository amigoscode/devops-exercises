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

echo "Tier 1 - GROUP BY and COUNT"
snap="SELECT count(*) || ':' || md5(string_agg(c::text, '|' ORDER BY c::text)) FROM car c"
[[ "$(q "SELECT count(*) FROM car")" == 100 && "$(q "$snap")" == "$(q "$snap" "$REF")" ]] \
  && ok "1.1 car holds the 100 cars from car.sql" \
  || no "1.1 run \\i car.sql so my_db has the car table with its 100 cars (once)"
same_rows "$SB/1.2.sql" "SELECT COUNT(*) FROM car" \
  && ok "1.2 1.2.sql counts the cars" \
  || no "1.2 1.2.sql: SELECT COUNT(*) FROM car - one number"
same_rows "$SB/1.3.sql" "SELECT brand, COUNT(*) FROM car GROUP BY brand" \
  && ok "1.3 1.3.sql counts the cars of each brand" \
  || no "1.3 1.3.sql: brand, COUNT(*) ... GROUP BY brand"
same_rows "$SB/1.4.sql" "SELECT COUNT(*), COUNT(phone_number) FROM person" \
  && ok "1.4 1.4.sql returns all people and the people with a phone number" \
  || no "1.4 1.4.sql: one row with COUNT(*) and COUNT(phone_number) from person"

echo "Tier 2 - SUM, MIN/MAX/AVG and HAVING"
same_rows "$SB/2.1.sql" "SELECT SUM(price) FROM car" \
  && ok "2.1 2.1.sql adds up the price of every car" \
  || no "2.1 2.1.sql: SELECT SUM(price) FROM car"
same_rows "$SB/2.2.sql" "SELECT brand, is_electric, SUM(price) FROM car GROUP BY brand, is_electric" \
  && ok "2.2 2.2.sql totals the price per brand and is_electric" \
  || no "2.2 2.2.sql: brand, is_electric, SUM(price) ... GROUP BY brand, is_electric"
same_rows "$SB/2.3.sql" "SELECT brand, MIN(price), MAX(price), AVG(price) FROM car GROUP BY brand" \
  && ok "2.3 2.3.sql returns min, max and average price per brand" \
  || no "2.3 2.3.sql: brand, MIN(price), MAX(price), AVG(price) ... GROUP BY brand (unrounded)"
same_rows "$SB/2.5.sql" "SELECT brand, COUNT(*) FROM car GROUP BY brand HAVING COUNT(*) >= 3" \
  && ok "2.5 2.5.sql keeps the brands with at least 3 cars (HAVING)" \
  || no "2.5 2.5.sql: brand, COUNT(*) ... GROUP BY brand HAVING COUNT(*) >= 3"
same_rows "$SB/2.6.sql" "SELECT brand, COUNT(*) FROM car WHERE is_electric GROUP BY brand HAVING COUNT(*) >= 3" \
  && ok "2.6 2.6.sql counts only electric cars, brands with at least 3 (WHERE + HAVING)" \
  || no "2.6 2.6.sql: WHERE is_electric = TRUE before GROUP BY brand, then HAVING COUNT(*) >= 3"
same_rows "$SB/2.7.sql" "SELECT brand, SUM(price) FROM car GROUP BY brand HAVING SUM(price) >= 100000 AND AVG(price) > 40000" \
  && ok "2.7 2.7.sql keeps brands totalling >= 100000 with an average above 40000" \
  || no "2.7 2.7.sql: brand, SUM(price) ... GROUP BY brand HAVING SUM(price) >= 100000 AND AVG(price) > 40000"

echo "Tier 3 - Mathematical operators and functions"
same_rows "$SB/3.2.sql" "SELECT brand, model, price, ROUND(price * .10, 2), ROUND(price - price * .10, 2) FROM car" \
  && [[ "$(heads "$SB/3.2.sql")" == "brand|model|price|10%|offer" ]] \
  && ok "3.2 3.2.sql: brand, model, price, \"10%\" and offer, rounded to 2 decimals" \
  || no "3.2 3.2.sql: brand, model, price, ROUND(price * .10, 2) AS \"10%\", ROUND(price - price * .10, 2) AS offer"
same_ordered "$SB/3.3.sql" "SELECT brand, MAX(price), ROUND(AVG(price), 2) FROM car GROUP BY brand ORDER BY MAX(price) DESC LIMIT 5" \
  && ok "3.3 3.3.sql returns the 5 brands with the most expensive car, priciest first" \
  || no "3.3 3.3.sql: brand, MAX(price), ROUND(AVG(price), 2) ... GROUP BY brand ORDER BY MAX(price) DESC LIMIT 5"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Rows into answers: counts, totals, averages and a promotion report."
