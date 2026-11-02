#!/usr/bin/env bash
# Runs INSIDE the container. Grades the queries you saved in ~/sandbox/<task>.sql
# and the changes you made to the database.
set -uo pipefail
SB="$HOME/sandbox"; DB=my_db; REF="${DB}_ref"   # REF: untouched copy made by seed.sh
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# tq SQL [DB] - run SQL inside a transaction that is rolled back (nothing changes)
tq(){ printf 'BEGIN;\n%s;\nROLLBACK;\n' "$1" | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "${2:-$DB}" 2>/dev/null; }
# works SQL / rejects SQL - the statement succeeds / fails (always rolled back)
works(){ tq "$1" >/dev/null; }
rejects(){ ! works "$1"; }
# run FILE DB - run a saved query inside a transaction that is rolled back, so
#               checking never changes anything
run(){ { echo 'BEGIN;'; cat "$1"; printf '\n;\n'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# same_rows FILE REFSQL [DB]    - FILE returns the same rows as the reference query
#                                 (any order). Default DB: the untouched copy.
same_rows(){ local d="${3:-$REF}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d" | sort) <(sort <<<"$want") >/dev/null; }
# same_ordered FILE REFSQL [DB] - ... and in the same order (ORDER BY tasks)
same_ordered(){ local d="${3:-$REF}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d") <(cat <<<"$want") >/dev/null; }

echo "Tier 1 - Schemas and the search path"
[[ "$(q "SELECT count(*) FROM pg_namespace WHERE nspname IN ('engineering', 'data_science')")" == 2 ]] \
  && ok "1.1 the engineering and data_science schemas exist" \
  || no "1.1 create the schemas engineering and data_science (CREATE SCHEMA ...)"

[[ "$(q "SELECT string_agg(name, ',' ORDER BY name) FROM engineering.deployment")" == "backend,frontend" ]] \
  && [[ "$(q "SELECT column_default FROM information_schema.columns WHERE table_schema = 'engineering' AND table_name = 'deployment' AND column_name = 'id'")" == nextval* ]] \
  && [[ "$(q "SELECT string_agg(name, ',') FROM public.deployment")" == "legacy-cron" ]] \
  && ok "1.2 engineering.deployment holds backend and frontend (public.deployment untouched)" \
  || no "1.2 create engineering.deployment (id BIGSERIAL PRIMARY KEY, name VARCHAR(100)) with exactly backend + frontend - and leave public.deployment alone"

# Run the script against the live database: with engineering first in the path the
# unqualified table is engineering.deployment (public.deployment would give legacy-cron).
f="$SB/1.4.sql"
if [[ -s "$f" ]] && grep -qi 'search_path' "$f" && ! grep -Eqi 'engineering"?[[:space:]]*\.[[:space:]]*"?deployment' "$f" \
   && [[ "$(run "$f" "$DB" | sort | paste -sd, -)" == "backend,frontend" ]]; then
  ok "1.4 1.4.sql sets the search_path and finds engineering.deployment without a prefix"
else
  no "1.4 1.4.sql must SET search_path (engineering before public) \\; then SELECT name FROM deployment (no schema prefix) - one line, saved with \\w 1.4.sql"
fi

echo "Tier 2 - Advanced data types"
[[ "$(q "SELECT start_value || ',' || increment_by || ',' || last_value FROM pg_sequences WHERE sequencename = 'ticket_seq'")" == "100,10,130" ]] \
  && ok "2.1 ticket_seq starts at 100, steps by 10 and last handed out 130" \
  || no "2.1 create ticket_seq (START WITH 100 INCREMENT BY 10 MINVALUE 100) and call nextval until the last value is 130"

[[ "$(q "SELECT string_agg(name || '=' || array_to_string(emails, ';'), ' ' ORDER BY id) FROM customer")" == \
   "John=john@gmail.com Kai=kai@cool.com Jamila=jamila@amigoscode.com;jamila@gmail.com Ola=ola@amigoscode.com;ola@yahoo.com;ola.n@gmail.com" ]] \
  && ok "2.2 Jamila gained jamila@gmail.com, John lost j@hotmail.com, nobody else changed" \
  || no "2.2 array_append jamila@gmail.com to Jamila only, array_remove j@hotmail.com from John only (use WHERE)"

same_rows "$SB/2.3.sql" "SELECT name, emails[1] FROM customer" \
  && ok "2.3 2.3.sql lists every customer's name and first email" \
  || no "2.3 2.3.sql must list name and the FIRST email (emails[1] - arrays start at 1) of every customer"

same_rows "$SB/2.4.sql" "SELECT name, attributes->>'ram' FROM product WHERE attributes @> '{\"water_resistant\": true}'" \
  && ok "2.4 2.4.sql lists the water-resistant products and their ram as text" \
  || no "2.4 2.4.sql must list name and attributes->>'ram' (text, ->> not ->) of products where attributes @> '{\"water_resistant\": true}'"

if [[ "$(q "SELECT string_agg(enumlabel, ',' ORDER BY enumsortorder) FROM pg_enum WHERE enumtypid = 'priority'::regtype")" == "LOW,MEDIUM,HIGH,URGENT,SUPER_URGENT" ]] \
   && [[ "$(q "SELECT udt_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'todo' AND column_name = 'priority'")" == priority ]] \
   && works "INSERT INTO todo (task, priority) VALUES ('ship it', 'SUPER_URGENT')" \
   && rejects "INSERT INTO todo (task, priority) VALUES ('ship it', 'CRITICAL')"; then
  ok "2.5 priority is LOW..URGENT, SUPER_URGENT and todo.priority only accepts those values"
else
  no "2.5 CREATE TYPE priority AS ENUM ('LOW','MEDIUM','HIGH','URGENT'), table todo(id, task, priority priority), then ALTER TYPE priority ADD VALUE 'SUPER_URGENT' AFTER 'URGENT'"
fi

if [[ "$(q "SELECT count(*) FROM pg_extension WHERE extname = 'uuid-ossp'")" == 1 ]] \
   && [[ "$(q "SELECT data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'transaction' AND column_name = 'id'")" == uuid ]] \
   && [[ "$(q "SELECT count(*) FROM pg_constraint WHERE conrelid = 'public.transaction'::regclass AND contype = 'p'")" == 1 ]] \
   && [[ "$(q "SELECT count(DISTINCT id) FROM transaction WHERE description IN ('Smash burger', 'Birthday cake')")" == 2 ]] \
   && [[ "$(tq "INSERT INTO transaction (description) VALUES ('grader'); SELECT count(*) FROM transaction WHERE description = 'grader' AND id IS NOT NULL")" == 1 ]]; then
  ok "2.6 uuid-ossp is on and transaction gets a random UUID id by default"
else
  no "2.6 CREATE EXTENSION \"uuid-ossp\", table transaction (id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), description TEXT), insert 'Smash burger' and 'Birthday cake'"
fi

echo "Tier 3 - Working with dates"
same_rows "$SB/3.1.sql" "SELECT customer, (started_at + duration)::date FROM subscription WHERE EXTRACT(YEAR FROM started_at + duration) = 2025" \
  && ok "3.1 3.1.sql lists the subscriptions ending in 2025 with their end date" \
  || no "3.1 3.1.sql must list customer and (started_at + duration) as a DATE (::date) for subscriptions that end in 2025"

same_ordered "$SB/3.2.sql" "SELECT first_name, EXTRACT(YEAR FROM age(dob)) FROM person WHERE dob < '1990-01-01' ORDER BY dob" \
  && ok "3.2 3.2.sql lists people born before 1990 with their age in years, oldest first" \
  || no "3.2 3.2.sql must list first_name and EXTRACT(YEAR FROM age(dob)) for dob before 1990, oldest first (ORDER BY dob)"

[[ "$(q "SELECT data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'signup' AND column_name = 'signed_up_on'")" == date ]] \
  && [[ "$(q "SELECT string_agg(id || '=' || signed_up_on, ' ' ORDER BY id) FROM signup")" == \
     "1=2024-01-31 2=2024-03-05 3=2023-11-12 4=2024-02-29 5=2024-12-01" ]] \
  && ok "3.3 signup.signed_up_on is a DATE and every row kept its real date" \
  || no "3.3 ALTER TABLE signup ALTER COLUMN signed_up_on TYPE DATE USING to_date(signed_up_on, 'DD/MM/YYYY') - every row must keep its date"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Schemas & Data Types complete."
