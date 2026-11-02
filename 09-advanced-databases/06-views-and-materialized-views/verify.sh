#!/usr/bin/env bash
# Runs INSIDE the container. Grades the views you created in the "sales" database
# and the queries you saved with \w (~/sandbox/<task>.sql). Every behaviour test runs in a
# transaction that is rolled back, so checking never changes your data.
set -uo pipefail
SB="$HOME/sandbox"; DB=sales
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL - run SQL, bare output
q(){ psql -X -A -t -q -d "$DB" -c "$1" 2>/dev/null; }
# tx SQL - run statements in a transaction that is rolled back (fails on the first error)
tx(){ { echo 'BEGIN;'; printf '%s\n' "$1"; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>/dev/null; }
# run FILE [PRE] - run a saved query (after optional PRE statements) in a rolled-back transaction
run(){ { echo 'BEGIN;'; printf '%s\n' "${2:-}"; cat "$1"; echo; echo ';'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>/dev/null; }
# kind NAME - v = view, m = materialized view, r = table
kind(){ q "SELECT relkind FROM pg_class WHERE oid = to_regclass('$1')"; }
# cols NAME - the column names, in order
cols(){ q "SELECT string_agg(attname, ',' ORDER BY attnum) FROM pg_attribute WHERE attrelid = to_regclass('$1') AND attnum > 0 AND NOT attisdropped"; }
# same A B - same rows, any order (and not empty)
same(){ [[ -n "$1" ]] && diff <(sort <<<"$1") <(sort <<<"$2") >/dev/null; }

ALL='id,sale_date,customer_name,product,quantity,price'
NEW_SALE="INSERT INTO transaction (sale_date, customer_name, product, quantity, price)"

echo "Tier 1 - Views"
if [[ "$(kind sold_laptops)" == v && "$(cols sold_laptops)" == "$ALL" ]] \
   && same "$(q 'SELECT * FROM sold_laptops')" "$(q "SELECT * FROM transaction WHERE product = 'Laptop'")" \
   && [[ "$(tx "$NEW_SALE VALUES ('2024-02-01', 'Zara', 'Laptop', 1, 999.00);
               SELECT count(*) FROM sold_laptops WHERE customer_name = 'Zara';")" == 1 ]]; then
  ok "1.1 sold_laptops is a view of every laptop sale (all columns) and shows new sales straight away"
else
  no "1.1 create the VIEW sold_laptops: SELECT * FROM transaction WHERE product = 'Laptop' (a view, not a table)"
fi

f="$SB/1.2.sql"
if [[ -s "$f" && "$(kind sold_laptops)" == v ]] \
   && same "$(run "$f")" "$(q "SELECT customer_name, price FROM transaction WHERE product = 'Laptop'")" \
   && ! run "$f" 'DROP VIEW IF EXISTS sold_laptops CASCADE;' >/dev/null; then
  ok "1.2 1.2.sql reads customer_name and price from the sold_laptops view"
else
  no "1.2 save as 1.2.sql (\\w 1.2.sql) a query of customer_name, price FROM sold_laptops (query the view, not the table)"
fi

f="$SB/1.3.sql"; norm(){ tr -s ' \n\t' ' ' | sed 's/^ //; s/ $//'; }
got="$(run "$f" 2>/dev/null | norm)"
if [[ -s "$f" && -n "$got" ]] && [[ "$(kind sold_laptops)" == v ]] \
   && { [[ "$got" == "$(q "SELECT pg_get_viewdef('sold_laptops', true)" | norm)" ]] \
        || [[ "$got" == "$(q "SELECT pg_get_viewdef('sold_laptops')" | norm)" ]]; }; then
  ok "1.3 1.3.sql returns the SQL behind sold_laptops"
else
  no "1.3 save as 1.3.sql (\\w 1.3.sql) a query that returns the view's SQL: SELECT pg_get_viewdef('sold_laptops', true);"
fi

echo "Tier 2 - Views that do more, and materialized views"
SPEND="SELECT customer_name, sum(quantity * price), count(*) FROM transaction GROUP BY customer_name"
if [[ "$(kind customer_spend)" == v && "$(cols customer_spend)" == "customer_name,total_spent,orders" ]] \
   && same "$(q 'SELECT customer_name, total_spent, orders FROM customer_spend')" "$(q "$SPEND")" \
   && [[ "$(tx "$NEW_SALE VALUES ('2024-02-01', 'Ravi', 'Mouse', 4, 25.00);
               SELECT total_spent, orders FROM customer_spend WHERE customer_name = 'Ravi';")" \
         == "$(tx "$NEW_SALE VALUES ('2024-02-01', 'Ravi', 'Mouse', 4, 25.00); $SPEND HAVING customer_name = 'Ravi';" | cut -d'|' -f2-)" ]]; then
  ok "2.1 customer_spend: one row per customer with total_spent (quantity x price) and orders"
else
  no "2.1 create the VIEW customer_spend (customer_name, total_spent, orders): total_spent = SUM(quantity * price), orders = COUNT(*), per customer"
fi

if [[ "$(q "SELECT count(*) FROM transaction WHERE customer_name = 'Fatima' AND product = 'Laptop' AND sale_date = '2024-01-15'")" == 0 ]] \
   && [[ "$(q "SELECT count(*) FROM transaction WHERE NOT (customer_name = 'Fatima' AND product = 'Phone' AND price = 1800)")" == 19 ]] \
   && [[ "$(kind sold_laptops)" == v ]]; then
  ok "2.2 Fatima's cancelled laptop sale (2024-01-15) is gone - and nothing else"
else
  no "2.2 delete Fatima's 2024-01-15 laptop sale through the view (DELETE FROM sold_laptops WHERE ...) - only that one row"
fi

if [[ "$(kind sold_phones)" == m && "$(cols sold_phones)" == "$ALL" ]] \
   && [[ "$(q "SELECT count(*) FROM sold_phones WHERE product <> 'Phone'")" == 0 ]] \
   && [[ "$(q "SELECT count(*) FROM sold_phones WHERE id IN (6, 9, 16, 19)")" == 4 ]] \
   && [[ "$(tx "$NEW_SALE VALUES ('2024-02-01', 'Zara', 'Phone', 1, 650.00);
               REFRESH MATERIALIZED VIEW sold_phones;
               SELECT count(*) FROM sold_phones WHERE customer_name = 'Zara';")" == 1 ]]; then
  ok "2.3 sold_phones is a materialized view of every phone sale"
else
  no "2.3 create the MATERIALIZED VIEW sold_phones: SELECT * FROM transaction WHERE product = 'Phone'"
fi

if [[ "$(q "SELECT count(*) FROM transaction WHERE customer_name = 'Fatima' AND product = 'Phone' AND quantity = 1 AND price = 1800")" == 1 ]] \
   && [[ "$(kind sold_phones)" == m ]] \
   && [[ "$(q "SELECT count(*) FROM sold_phones WHERE customer_name = 'Fatima' AND price = 1800")" == 1 ]] \
   && [[ "$(q 'SELECT count(*) FROM sold_phones')" == "$(q "SELECT count(*) FROM transaction WHERE product = 'Phone'")" ]]; then
  ok "2.4 the new 1800.00 phone sale is in the table and, after a refresh, in sold_phones"
else
  no "2.4 insert Fatima's phone sale (2024-01-20, qty 1, 1800.00), then REFRESH MATERIALIZED VIEW sold_phones so it shows up"
fi

echo "Tier 3 - Finance dashboard"
BIG="SELECT customer_name, sum(quantity * price) FROM transaction GROUP BY customer_name HAVING sum(quantity * price) > 1500"
if [[ "$(kind big_spenders)" == v && "$(cols big_spenders)" == "customer_name,total_spent" ]] \
   && [[ "$(q "SELECT count(*) FROM information_schema.view_table_usage WHERE view_name = 'big_spenders' AND table_name = 'customer_spend'")" -ge 1 ]] \
   && same "$(q 'SELECT customer_name, total_spent FROM big_spenders')" "$(q "$BIG")" \
   && [[ "$(tx "$NEW_SALE VALUES ('2024-02-01', 'David', 'Tablet', 1, 500.00);
               SELECT count(*) FROM big_spenders WHERE customer_name = 'David';")" == 1 ]]; then
  ok "3.1 big_spenders is built on customer_spend and lists customers who spent more than 1500"
else
  no "3.1 create the VIEW big_spenders (customer_name, total_spent) FROM customer_spend, only customers with total_spent > 1500"
fi

PS="SELECT product, sum(quantity), sum(quantity * price) FROM transaction GROUP BY product"
if [[ "$(kind product_sales)" == m && "$(cols product_sales)" == "product,units_sold,revenue" ]] \
   && same "$(q 'SELECT product, units_sold, revenue FROM product_sales')" "$(q "$PS")" \
   && [[ "$(q "SELECT count(*) FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[0]
              WHERE i.indrelid = to_regclass('product_sales') AND i.indisunique AND i.indnatts = 1 AND a.attname = 'product'")" -ge 1 ]]; then
  ok "3.2 product_sales is an up-to-date materialized view with a unique index on product"
else
  no "3.2 MATERIALIZED VIEW product_sales (product, units_sold, revenue) matching today's data, plus a UNIQUE index on product"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Views and materialized views done - simpler queries, and fast ones when you need them."
