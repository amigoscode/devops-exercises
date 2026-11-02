#!/usr/bin/env bash
# Runs INSIDE the container. Grades the constraints you added by trying good and bad
# rows against them, always inside a transaction that is rolled back.
set -uo pipefail
SB="$HOME/sandbox"; DB=my_db
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL  - run SQL against the student's database, bare output
q(){ psql -X -A -t -q -d "$DB" -c "$1" 2>/dev/null; }
# tq SQL - run SQL inside a transaction that is rolled back (nothing changes)
tq(){ printf 'BEGIN;\n%s;\nROLLBACK;\n' "$1" | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>/dev/null; }
# works SQL / rejects SQL - the statement succeeds / is refused (always rolled back)
works(){ tq "$1" >/dev/null; }
rejects(){ ! works "$1"; }
# has NAME TABLE TYPE - a constraint with that name and type (p, u, f, c) is on TABLE
has(){ [[ "$(q "SELECT count(*) FROM pg_constraint WHERE conname = '$1' AND conrelid = to_regclass('$2') AND contype = '$3'")" == 1 ]]; }
# fk_restricts TABLE COL REFTABLE - a foreign key TABLE(COL) -> REFTABLE without cascade
fk_restricts(){ [[ "$(q "SELECT count(*) FROM pg_constraint c JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ALL (c.conkey)
  WHERE c.contype = 'f' AND c.conrelid = to_regclass('$1') AND a.attname = '$2' AND c.confrelid = to_regclass('$3') AND c.confdeltype IN ('a', 'r')")" == 1 ]]; }
P="INSERT INTO person (id, first_name, last_name, gender, dob, phone_number, country_of_origin) VALUES"

echo "Tier 1 - Constraints on an existing table"
if has pk_person_id person p \
   && [[ "$(q "SELECT a.attname FROM pg_constraint c JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey) WHERE c.conname = 'pk_person_id'")" == id ]] \
   && rejects "$P (1, 'Dup', 'Licate', 'M', '1990-01-01', NULL, 'UK')" \
   && rejects "$P (NULL, 'No', 'Id', 'M', '1990-01-01', NULL, 'UK')"; then
  ok "1.1 pk_person_id makes person.id required and unique"
else
  no "1.1 ALTER TABLE person ADD CONSTRAINT pk_person_id PRIMARY KEY (id)"
fi

if [[ "$(q "SELECT string_agg(column_name || '=' || is_nullable, ',' ORDER BY column_name) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'person' AND column_name <> 'id'")" == \
     "country_of_origin=NO,dob=NO,first_name=NO,gender=NO,last_name=NO,phone_number=YES" ]] \
   && has unique_phone_number person u \
   && rejects "$P (100, NULL, 'Name', 'M', '1990-01-01', NULL, 'UK')" \
   && works "$P (100, 'No', 'Phone', 'M', '1990-01-01', NULL, 'UK'); $P (101, 'Also', 'None', 'F', '1990-01-01', NULL, 'UK')" \
   && rejects "$P (100, 'Same', 'Phone', 'M', '1990-01-01', '+447700900001', 'UK')"; then
  ok "1.2 the five required columns are NOT NULL and phone numbers are unique (but optional)"
else
  no "1.2 SET NOT NULL on first_name, last_name, gender, dob, country_of_origin (not phone_number) + ADD CONSTRAINT unique_phone_number UNIQUE (phone_number)"
fi

if ! has check_country_of_origin person c \
   && works "$P (100, 'Ana', 'Silva', 'F', '1990-01-01', NULL, 'Brazil')"; then
  ok "1.3 check_country_of_origin is gone - Brazil is a valid country"
else
  no "1.3 ALTER TABLE person DROP CONSTRAINT check_country_of_origin"
fi

echo "Tier 2 - Constraints on car and the foreign key"
C="INSERT INTO car (id, brand, model, price, mileage) VALUES"
if [[ "$(q "SELECT count(*) FROM pg_constraint c JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ALL (c.conkey) WHERE c.conrelid = to_regclass('car') AND c.contype = 'p' AND a.attname = 'id'")" == 1 ]] \
   && has check_price car c && has check_mileage car c \
   && [[ "$(tq "INSERT INTO car (id, brand, model) VALUES (100, 'Test', 'X'); SELECT price = 0 AND mileage = 0 AND is_electric = false FROM car WHERE id = 100")" == t ]] \
   && rejects "INSERT INTO car (id, brand, model) VALUES (1, 'Dup', 'Id')" \
   && rejects "INSERT INTO car (id, brand, model) VALUES (100, NULL, 'X')" \
   && rejects "INSERT INTO car (id, brand, model) VALUES (100, 'Test', NULL)" \
   && rejects "$C (100, 'Test', 'X', -1, 0)" \
   && rejects "$C (100, 'Test', 'X', 10, -5)" \
   && works "$C (100, 'Test', 'X', 0, 0)"; then
  ok "2.1 car has its primary key, required brand/model, defaults and both checks"
else
  no "2.1 car needs: PRIMARY KEY (id), brand/model NOT NULL, price DEFAULT 0.0 + check_price (>= 0), mileage DEFAULT 0 + check_mileage (>= 0), is_electric DEFAULT false"
fi

if has fk_car_owner_id car f && fk_restricts car owner_id person \
   && rejects "UPDATE car SET owner_id = 9999 WHERE id = 1" \
   && works "UPDATE car SET owner_id = NULL WHERE id = 1" \
   && rejects "DELETE FROM person WHERE id = 2"; then
  ok "2.2 fk_car_owner_id only accepts real people and blocks deleting an owner"
else
  no "2.2 ALTER TABLE car ADD CONSTRAINT fk_car_owner_id FOREIGN KEY (owner_id) REFERENCES person(id) - no ON DELETE CASCADE"
fi

[[ "$(q "SELECT string_agg(p.first_name || ' ' || p.last_name, ',') FROM car c JOIN person p ON p.id = c.owner_id WHERE c.brand = 'Tesla' AND c.model = 'Cybertruck'")" == "Jamila Bob" ]] \
  && [[ "$(q "SELECT count(*) FROM car WHERE owner_id = (SELECT id FROM person WHERE first_name = 'Jamila' AND last_name = 'Bob')")" == 1 ]] \
  && ok "2.3 the Tesla Cybertruck now belongs to Jamila Bob" \
  || no "2.3 UPDATE car SET owner_id = <Jamila's id> WHERE <the Cybertruck> - only that car"

echo "Tier 3 - Real-world constraint work"
if [[ "$(q "SELECT string_agg(id::text, ',' ORDER BY id) FROM passport")" == "1,2,3,4,5,9" ]] \
   && fk_restricts passport person_id person \
   && works "INSERT INTO passport (person_id, passport_number, country) VALUES (1, 'NEW0000001', 'UK')" \
   && rejects "INSERT INTO passport (person_id, passport_number, country) VALUES (1, 'UK1234567', 'UK')" \
   && rejects "INSERT INTO passport (person_id, passport_number, country) VALUES (9999, 'NEW0000002', 'UK')"; then
  ok "3.1 passport is clean (lowest-id copies kept, orphans gone), passport_number unique, person_id a foreign key"
else
  no "3.1 delete the later duplicate passports and the orphans (only those), then add UNIQUE (passport_number) and FOREIGN KEY (person_id) REFERENCES person(id)"
fi

I="INSERT INTO insurance_policy (policy_number, car_id, premium, start_date, end_date) VALUES"
if has pk_insurance_policy_id insurance_policy p && has fk_insurance_policy_car_id insurance_policy f \
   && fk_restricts insurance_policy car_id car \
   && works "$I ('POL-1', 1, 500, '2025-01-01', '2026-01-01'); $I ('POL-2', 1, 99.99, '2025-01-01', '2025-01-02')" \
   && rejects "$I ('POL-1', 1, 500, '2025-01-01', '2026-01-01'); $I ('POL-1', 2, 500, '2025-01-01', '2026-01-01')" \
   && rejects "$I (NULL, 1, 500, '2025-01-01', '2026-01-01')" \
   && rejects "$I ('POL-1', 9999, 500, '2025-01-01', '2026-01-01')" \
   && rejects "$I ('POL-1', NULL, 500, '2025-01-01', '2026-01-01')" \
   && rejects "$I ('POL-1', 1, 0, '2025-01-01', '2026-01-01')" \
   && rejects "$I ('POL-1', 1, NULL, '2025-01-01', '2026-01-01')" \
   && rejects "$I ('POL-1', 1, 500, '2025-01-01', '2025-01-01')" \
   && rejects "$I ('POL-1', 1, 500, NULL, '2026-01-01')" \
   && rejects "$I ('POL-1', 1, 500, '2025-01-01', NULL)" \
   && rejects "$I ('POL-1', 1, 500, '2025-01-01', '2026-01-01'); DELETE FROM car WHERE id = 1"; then
  ok "3.2 insurance_policy enforces every rule with named pk/fk constraints"
else
  no "3.2 insurance_policy: pk_insurance_policy_id, unique NOT NULL policy_number, NOT NULL car_id with fk_insurance_policy_car_id (no cascade), premium > 0, NOT NULL dates with end_date > start_date"
fi

if fk_restricts car_listing dealership_id dealership \
   && [[ "$(q "SELECT count(*) FROM pg_constraint WHERE conrelid = to_regclass('car_listing') AND contype = 'f'")" == 1 ]] \
   && [[ "$(q "SELECT count(*) FROM car_listing")" == 5 ]] \
   && rejects "DELETE FROM dealership WHERE id = 1" \
   && works "DELETE FROM dealership WHERE id = 3" \
   && rejects "INSERT INTO car_listing (dealership_id, title, price) VALUES (999, 'Ghost', 1)"; then
  ok "3.3 deleting a dealership with listings is refused and all 5 listings are still there"
else
  no "3.3 DROP CONSTRAINT fk_car_listing_dealership_id, then ADD it again (FOREIGN KEY (dealership_id) REFERENCES dealership(id)) without ON DELETE CASCADE - keep all 5 listings"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Constraints & Foreign Keys complete."
