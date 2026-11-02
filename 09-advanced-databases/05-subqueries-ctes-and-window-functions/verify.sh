#!/usr/bin/env bash
# Runs INSIDE the container. Grades the queries you saved in ~/sandbox/<task>.sql
# against an untouched copy of the data.
set -uo pipefail
SB="$HOME/sandbox"; DB=my_db; REF="${DB}_ref"   # REF: untouched copy made by seed.sh
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# run FILE DB - run a saved query inside a transaction that is rolled back, so
#               checking never changes anything
run(){ { echo 'BEGIN;'; cat "$1"; printf '\n;\n'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# same_rows FILE REFSQL [DB] - FILE returns the same rows as the reference query
#                              (any order). Default DB: the untouched copy.
same_rows(){ local d="${3:-$REF}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d" | sort) <(sort <<<"$want") >/dev/null; }
# mentions FILE REGEX - the saved query uses a given construct (case-insensitive, across lines)
mentions(){ [[ -s "$1" ]] && tr '\n' ' ' <"$1" | grep -Eqi "$2"; }

echo "Tier 1 - Subqueries"
same_rows "$SB/1.1.sql" "SELECT first_name, last_name FROM person WHERE id IN (SELECT owner_id FROM car WHERE price > (SELECT AVG(price) FROM car))" \
  && ok "1.1 1.1.sql lists owners of a car priced above the average" \
  || no "1.1 1.1.sql must list first_name, last_name WHERE id IN (owners of cars with price > (SELECT AVG(price) FROM car)) - each person once"

same_rows "$SB/1.2.sql" "SELECT first_name, last_name FROM person p WHERE NOT EXISTS (SELECT 1 FROM car c WHERE c.owner_id = p.id)" \
  && mentions "$SB/1.2.sql" 'not[[:space:]]+exists' \
  && ok "1.2 1.2.sql lists the people without a car using NOT EXISTS" \
  || no "1.2 1.2.sql must list first_name, last_name of people with no car: WHERE NOT EXISTS (SELECT 1 FROM car WHERE car.owner_id = person.id)"

same_rows "$SB/1.3.sql" "SELECT first_name, last_name FROM person WHERE id IN (SELECT owner_id FROM car WHERE price < ALL (SELECT price FROM car WHERE brand = 'Tesla'))" \
  && ok "1.3 1.3.sql lists owners of a car cheaper than every Tesla" \
  || no "1.3 1.3.sql: owners of a car with price < ALL (SELECT price FROM car WHERE brand = 'Tesla') - first_name, last_name, each person once"

same_rows "$SB/1.4.sql" "SELECT first_name, last_name FROM person WHERE id IN (SELECT owner_id FROM car GROUP BY owner_id HAVING count(*) > 1)" \
  && ok "1.4 1.4.sql lists the people who own more than one car" \
  || no "1.4 1.4.sql: first_name, last_name WHERE id IN (SELECT owner_id FROM car GROUP BY owner_id HAVING count(*) > 1)"

echo "Tier 2 - Common table expressions"
same_rows "$SB/2.1.sql" "SELECT e.name, d.name FROM employee e JOIN department d ON d.id = e.department_id WHERE d.name = 'IT'" \
  && mentions "$SB/2.1.sql" 'with[[:space:]]+it_employee[[:space:]]+as' \
  && ok "2.1 2.1.sql uses the it_employee CTE to list IT employees with their department" \
  || no "2.1 2.1.sql: WITH it_employee AS (SELECT * FROM employee WHERE department_id = 3) SELECT it.name, department.name FROM it_employee it JOIN department ..."

same_rows "$SB/2.2.sql" "SELECT d.name, e.name FROM employee e JOIN department d ON d.id = e.department_id WHERE d.name IN ('Marketing', 'IT')" \
  && mentions "$SB/2.2.sql" 'union' && mentions "$SB/2.2.sql" 'with[[:space:]]+marketing[[:space:]]+as' && mentions "$SB/2.2.sql" ',[[:space:]]*it[[:space:]]+as' \
  && ok "2.2 2.2.sql combines the marketing and it CTEs with UNION" \
  || no "2.2 2.2.sql: WITH marketing AS (...), it AS (...) SELECT 'Marketing', name FROM marketing UNION SELECT 'IT', name FROM it"

same_rows "$SB/2.3.sql" "WITH headcount AS (SELECT d.name, count(*) AS n FROM department d JOIN employee e ON e.department_id = d.id GROUP BY d.name)
  SELECT name, n FROM headcount WHERE n > (SELECT AVG(n) FROM headcount)" \
  && ok "2.3 2.3.sql lists the departments with more employees than average" \
  || no "2.3 2.3.sql: department name + headcount, only where headcount > the average headcount (strictly more)"

echo "Tier 3 - Window functions on sales"
same_rows "$SB/3.1.sql" "SELECT customer_name, sale_date, product, ROW_NUMBER() OVER (PARTITION BY customer_name ORDER BY sale_date) FROM transaction" \
  && ok "3.1 3.1.sql numbers each customer's purchases by date" \
  || no "3.1 3.1.sql: customer_name, sale_date, product, ROW_NUMBER() OVER (PARTITION BY customer_name ORDER BY sale_date)"

same_rows "$SB/3.2.sql" "SELECT customer_name, sale_date, product, SUM(price * quantity) OVER (PARTITION BY customer_name ORDER BY sale_date) FROM transaction" \
  && ok "3.2 3.2.sql shows each customer's running total of spend" \
  || no "3.2 3.2.sql: customer_name, sale_date, product, SUM(price * quantity) OVER (PARTITION BY customer_name ORDER BY sale_date)"

same_rows "$SB/3.3.sql" "SELECT customer_name, product, price FROM (SELECT *, RANK() OVER (PARTITION BY customer_name ORDER BY price DESC) AS r FROM transaction) t WHERE r = 1" \
  && ok "3.3 3.3.sql shows each customer's top-priced purchase(s), ties included" \
  || no "3.3 3.3.sql: customer_name, product, price where RANK() OVER (PARTITION BY customer_name ORDER BY price DESC) = 1 (John has a tie: both laptops)"

same_rows "$SB/3.4.sql" "SELECT customer_name, sale_date, price, LAG(price) OVER (PARTITION BY customer_name ORDER BY sale_date) FROM transaction" \
  && ok "3.4 3.4.sql shows each purchase next to the customer's previous price" \
  || no "3.4 3.4.sql: customer_name, sale_date, price, LAG(price) OVER (PARTITION BY customer_name ORDER BY sale_date)"

same_rows "$SB/3.5.sql" "SELECT customer_name, sale_date, product, LAST_VALUE(product) OVER (PARTITION BY customer_name ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM transaction" \
  && ok "3.5 3.5.sql shows each customer's last product on every row" \
  || no "3.5 3.5.sql: LAST_VALUE(product) OVER (PARTITION BY customer_name ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Subqueries, CTEs & Window Functions complete."
