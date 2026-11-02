#!/usr/bin/env bash
# Runs INSIDE the container. Grades the tables in the "my_db" database and the
# description you saved in ~/sandbox.
set -uo pipefail
SB="$HOME/sandbox"; DB=my_db
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# has FILE PATTERN... - the file exists and contains every (extended regex) pattern
has(){ local f="$1"; shift; [[ -s "$f" ]] || return 1
  for p in "$@"; do grep -Eq -- "$p" "$f" || return 1; done; }
# table NAME - the table exists in the public schema
table(){ [[ "$(q "SELECT count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = '$1'")" == 1 ]]; }
# cols NAME - the table's columns as name:type:length, sorted by name
cols(){ q "SELECT string_agg(column_name || ':' || data_type || ':' || coalesce(character_maximum_length::text, ''), ',' ORDER BY column_name)
           FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '$1'"; }

echo "Tier 1 - Create, rename and drop tables"
if table car && [[ -z "$(cols car)" ]]; then
  ok "1.2 table car exists, with no columns yet"
else
  no "1.2 create a table called car with no columns (CREATE TABLE car ();)"
fi
if table customer && ! table custmer && [[ "$(q "SELECT count(*) FROM customer")" == 3 ]]; then
  ok "1.3 custmer was renamed to customer (rows kept)"
else
  no "1.3 rename custmer to customer (ALTER TABLE custmer RENAME TO customer;) - don't drop it"
fi
if ! table temp_import && { [[ "$(q "SELECT count(*) FROM customer")" == 3 ]] || [[ "$(q "SELECT count(*) FROM custmer")" == 3 ]]; }; then
  ok "1.4 temp_import is gone (and the customer table is still there)"
else
  no "1.4 drop the temp_import table (DROP TABLE temp_import;) - only that one"
fi

echo "Tier 2 - Columns and data types"
want="country_of_origin:character varying:50,date_of_birth:date:,first_name:character varying:50,gender:character:1,id:integer:,last_name:character varying:50,phone_number:character varying:15"
if table person && [[ "$(cols person)" == "$want" ]]; then
  ok "2.1 person has the 7 columns with the right types"
else
  no "2.1 create person with id INTEGER, first_name/last_name VARCHAR(50), gender CHAR(1), date_of_birth DATE, phone_number VARCHAR(15), country_of_origin VARCHAR(50)"
fi
t=customer; table customer || t=custmer
c="$(cols "$t")"
if [[ "$c" == *"email:character varying:100"* && "$c" != *emial* ]] \
   && [[ "$(q "SELECT count(*) FROM $t WHERE email LIKE '%@example.com'")" == 3 ]]; then
  ok "2.2 the emial column is now email (data kept)"
else
  no "2.2 rename the column: ALTER TABLE customer RENAME COLUMN emial TO email;"
fi
has "$SB/person.txt" 'Table "public\.person"' 'phone_number' 'character varying\(15\)' 'date_of_birth' \
  && ok "2.3 person.txt holds the \\d person description" \
  || no "2.3 save the output of \\d person in person.txt (\\o person.txt, \\d person, \\o)"

echo "Tier 3 - Design a table"
c="$(cols course)"
c="${c/id:bigint:/id:integer:}"; c="${c/id:smallint:/id:integer:}"   # any whole-number type
if table course && [[ "$c" == "description:text:,id:integer:,level:character:1,published_on:date:,title:character varying:100" ]]; then
  ok "3.1 course has id, title VARCHAR(100), description TEXT, level CHAR(1), published_on DATE"
else
  no "3.1 create course: id (whole number), title (max 100 chars), description (any length), level (1 char), published_on (date) - and nothing else"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can design, create, describe, rename and drop tables."
