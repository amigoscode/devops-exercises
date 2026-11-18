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
USING_DB="${DB}_using"   # the untouched copy with both join columns renamed to person_id (3.5)
# fails SQL - true if SQL errors (run in a transaction that is rolled back)
fails(){ ! psql -X -q -v ON_ERROR_STOP=1 -d "$DB" -c 'BEGIN' -c "$1" -c 'ROLLBACK' >/dev/null 2>&1; }
JOIN_ON="FROM person JOIN car ON person.id = car.owner_id"

echo "Tier 1 - Primary and foreign keys"
pk="SELECT c.conname || ':' || string_agg(a.attname, ',') FROM pg_constraint c
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
    WHERE c.conrelid = to_regclass('public.person') AND c.contype = 'p' GROUP BY c.conname"
[[ "$(q "$pk")" == "pk_id:id" ]] && fails "INSERT INTO person (id, last_name) VALUES (1, 'Duplicate')" \
  && ok "1.1 person.id is the primary key pk_id - a duplicate id is rejected" \
  || no "1.1 ALTER TABLE person ADD CONSTRAINT pk_id PRIMARY KEY (id); (renamed id for 3.5? rename it back)"
fk="SELECT c.conname || ':' || ka.attname || '->' || c.confrelid::regclass || '.' || fa.attname || ':' || format_type(ka.atttypid, ka.atttypmod)
    FROM pg_constraint c
    JOIN pg_attribute ka ON ka.attrelid = c.conrelid  AND ka.attnum = c.conkey[1]
    JOIN pg_attribute fa ON fa.attrelid = c.confrelid AND fa.attnum = c.confkey[1]
    WHERE c.conrelid = to_regclass('public.car') AND c.contype = 'f'"
[[ "$(q "$fk")" == "fk_person:owner_id->person.id:integer" ]] && fails "UPDATE car SET owner_id = 9999 WHERE id = 1" \
  && ok "1.2 car.owner_id is a foreign key (fk_person) to person.id - unknown owners are rejected" \
  || no "1.2 ALTER TABLE car ADD owner_id INTEGER, ADD CONSTRAINT fk_person FOREIGN KEY (owner_id) REFERENCES person (id);"
[[ "$(q "SELECT string_agg(id || ':' || owner_id, ',' ORDER BY id) FROM car WHERE owner_id IS NOT NULL")" == "2:2,4:1,5:1" ]] \
  && ok "1.3 Ahmed owns cars 4 and 5, Aisha owns car 2 - no other car has an owner" \
  || no "1.3 UPDATE car SET owner_id = 1 WHERE id = 5; (and id 4), owner_id = 2 WHERE id = 2 - only those three"

echo "Tier 2 - INNER, LEFT and RIGHT JOIN"
same_rows "$SB/2.2.sql" "SELECT person.first_name, person.last_name, car.brand, car.model $JOIN_ON" \
  && ok "2.2 2.2.sql joins people to the cars they own (INNER JOIN)" \
  || no "2.2 2.2.sql: person.first_name, person.last_name, car.brand, car.model FROM person JOIN car ON person.id = car.owner_id"
same_rows "$SB/2.3.sql" "SELECT person.first_name, person.last_name, car.brand, car.model FROM person LEFT JOIN car ON person.id = car.owner_id" \
  && ok "2.3 2.3.sql lists every person, with their cars if any (LEFT JOIN)" \
  || no "2.3 2.3.sql: the same four columns FROM person LEFT JOIN car ON person.id = car.owner_id"
same_rows "$SB/2.4.sql" "SELECT person.id, person.first_name, person.last_name FROM person LEFT JOIN car ON person.id = car.owner_id WHERE car.id IS NULL" \
  && ok "2.4 2.4.sql finds the people without a car (LEFT JOIN + IS NULL)" \
  || no "2.4 2.4.sql: person.id, first_name, last_name FROM person LEFT JOIN car ... WHERE car.id IS NULL"
same_rows "$SB/2.5.sql" "SELECT person.first_name, person.last_name, car.brand, car.model FROM person RIGHT JOIN car ON person.id = car.owner_id" \
  && ok "2.5 2.5.sql lists every car, with its owner if any (RIGHT JOIN)" \
  || no "2.5 2.5.sql: first_name, last_name, brand, model FROM person RIGHT JOIN car ON person.id = car.owner_id"
same_rows "$SB/2.6.sql" "SELECT car.id, car.brand, car.model FROM person RIGHT JOIN car ON person.id = car.owner_id WHERE person.id IS NULL" \
  && ok "2.6 2.6.sql finds the cars without an owner (RIGHT JOIN + IS NULL)" \
  || no "2.6 2.6.sql: car.id, brand, model FROM person RIGHT JOIN car ... WHERE person.id IS NULL"

echo "Tier 3 - FULL JOIN, column names, USING and the order of SQL"
same_rows "$SB/3.1.sql" "SELECT * FROM person FULL JOIN car ON person.id = car.owner_id" \
  && ok "3.1 3.1.sql returns everything from both tables (FULL JOIN)" \
  || no "3.1 3.1.sql: SELECT * FROM person FULL JOIN car ON person.id = car.owner_id"
same_rows "$SB/3.2.sql" "SELECT person.first_name, person.last_name, car.brand, car.model FROM person FULL JOIN car ON person.id = car.owner_id WHERE person.id IS NULL OR car.id IS NULL" \
  && ok "3.2 3.2.sql returns only the unmatched people and cars (FULL JOIN + NULL check)" \
  || no "3.2 3.2.sql: first_name, last_name, brand, model FROM person FULL JOIN car ... WHERE person.id IS NULL OR car.id IS NULL"
same_rows "$SB/3.4.sql" "SELECT car.id, person.id, person.first_name, car.brand, car.model $JOIN_ON" \
  && [[ "$(heads "$SB/3.4.sql")" == "car_id|person_id|first_name|brand|model" ]] \
  && ok "3.4 3.4.sql names the two ids car_id and person_id" \
  || no "3.4 3.4.sql: car.id AS car_id, person.id AS person_id, person.first_name, car.brand, car.model for the owned cars"
same_rows "$SB/3.5.sql" "SELECT person.first_name, person.last_name, car.brand, car.model FROM person JOIN car USING (person_id)" "$USING_DB" \
  && grep -Eiq 'using[[:space:]]*\([[:space:]]*person_id[[:space:]]*\)' "$SB/3.5.sql" \
  && [[ "$(q "SELECT count(*) FROM information_schema.columns WHERE table_schema = 'public'
              AND ((table_name = 'person' AND column_name = 'id') OR (table_name = 'car' AND column_name = 'owner_id'))")" == 2 ]] \
  && ok "3.5 3.5.sql joins with USING (person_id), and the columns are back to id / owner_id" \
  || no "3.5 3.5.sql: the 2.2 join written with JOIN car USING (person_id) - then rename the columns back to person.id and car.owner_id"
same_ordered "$SB/3.6.sql" "SELECT person.first_name, person.last_name, COUNT(*) AS cars $JOIN_ON GROUP BY person.id, person.first_name, person.last_name ORDER BY cars DESC" \
  && [[ "$(heads "$SB/3.6.sql")" == "first_name|last_name|cars" ]] \
  && ok "3.6 3.6.sql counts the cars per owner, biggest owner first" \
  || no "3.6 3.6.sql: first_name, last_name, COUNT(*) AS cars ... JOIN ... GROUP BY the person ... ORDER BY cars DESC"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Keys, relationships and every kind of join - you can query across tables."
