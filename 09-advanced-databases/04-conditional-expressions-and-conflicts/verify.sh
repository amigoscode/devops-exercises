#!/usr/bin/env bash
# Runs INSIDE the container. Grades the queries you saved in ~/sandbox/<task>.sql,
# runs your conflict scripts twice (then rolls back) and inspects the data.
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
# twice FILE SETUP CHECK - in one rolled-back transaction: SETUP, the script, the
#                          script again, then CHECK; prints CHECK's result (empty on error)
twice(){ [[ -s "$1" ]] || return 0
  { echo 'BEGIN;'; echo "$2"; cat "$1"; printf '\n;\n'; cat "$1"; printf '\n;\n'; echo "$3"; echo 'ROLLBACK;'; } \
    | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>/dev/null | tail -n 1; }

echo "Tier 1 - COALESCE, NULLIF and CASE"
same_rows "$SB/1.2.sql" "SELECT first_name, last_name, COALESCE(phone_number, 'Unknown') FROM person" \
  && ok "1.2 1.2.sql lists everyone with their phone number or 'Unknown'" \
  || no "1.2 1.2.sql must list first_name, last_name, COALESCE(phone_number, 'Unknown') for every person"

same_rows "$SB/1.3.sql" "SELECT name, COALESCE(clicks * 100 / NULLIF(impressions, 0), 0) FROM campaign" \
  && ok "1.3 1.3.sql shows each campaign's click-through rate, 0 where there are no impressions" \
  || no "1.3 1.3.sql must list name and COALESCE(clicks * 100 / NULLIF(impressions, 0), 0) for every campaign"

same_rows "$SB/1.4.sql" "SELECT first_name, last_name, CASE WHEN gender = 'M' THEN 'MALE' WHEN gender = 'F' THEN 'FEMALE' ELSE gender END FROM person" \
  && ok "1.4 1.4.sql spells out M and F as MALE and FEMALE" \
  || no "1.4 1.4.sql must list first_name, last_name and CASE WHEN gender = 'M' THEN 'MALE' WHEN gender = 'F' THEN 'FEMALE' ELSE gender END"

same_rows "$SB/1.5.sql" "SELECT COUNT(CASE WHEN gender IN ('MALE', 'M') THEN 1 END), COUNT(CASE WHEN gender IN ('FEMALE', 'F') THEN 1 END) FROM person" \
  && ok "1.5 1.5.sql counts men and women (M and F included) in one row" \
  || no "1.5 1.5.sql must return one row: COUNT(CASE WHEN gender IN ('MALE','M') THEN 1 END), then the same for FEMALE/F"

[[ "$(q "SELECT string_agg(id || '=' || gender, ' ' ORDER BY id) FROM person WHERE id <= 10")" == \
   "1=MALE 2=MALE 3=FEMALE 4=MALE 5=MALE 6=FEMALE 7=FEMALE 8=MALE 9=FEMALE 10=MALE" ]] \
  && ok "1.6 every M is now MALE and every F is now FEMALE" \
  || no "1.6 UPDATE person SET gender = CASE WHEN gender = 'M' THEN 'MALE' WHEN gender = 'F' THEN 'FEMALE' ELSE gender END;"

echo "Tier 2 - Dealing with conflicts"
# Put rows 3, 11 and 12 back as seeded first, so earlier experiments don't matter.
RESET_PEOPLE="UPDATE person SET first_name = 'Mark', last_name = 'Barajas', phone_number = '001-308-674-9013x649' WHERE id = 3;
DELETE FROM person WHERE id IN (11, 12);"
[[ "$(twice "$SB/2.1.sql" "$RESET_PEOPLE" \
     "SELECT string_agg(id || '=' || first_name, ' ' ORDER BY id) FROM person WHERE id IN (3, 11);")" == "3=Mark 11=Ada" ]] \
  && ok "2.1 2.1.sql inserts Ada, ignores the existing row 3 and can run again without failing" \
  || no "2.1 2.1.sql: INSERT INTO person (...) VALUES (3, 'Marcus', ...), (11, 'Ada', ...) ON CONFLICT (id) DO NOTHING; - it must survive running twice"

[[ "$(twice "$SB/2.2.sql" "$RESET_PEOPLE" \
     "SELECT string_agg(id || '=' || first_name || ' ' || last_name || ' ' || phone_number, ', ' ORDER BY id) FROM person WHERE id IN (3, 12);")" == \
   "3=Mark Barajas +44 7700 900123, 12=Grace Hopper +1 202 555 0199" ]] \
  && ok "2.2 2.2.sql inserts Grace and only updates Mark's phone number (twice is safe)" \
  || no "2.2 2.2.sql: INSERT ... VALUES (3, 'MARK', ...), (12, 'Grace', ...) ON CONFLICT (id) DO UPDATE SET phone_number = EXCLUDED.phone_number;"

echo "Tier 3 - An idempotent batch upsert"
uniq_cols="$(q "SELECT string_agg(cols, ' ') FROM (SELECT (SELECT string_agg(a.attname, ',' ORDER BY a.attname)
    FROM unnest(i.indkey::int2[]) AS k(attnum) JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum) AS cols
  FROM pg_index i WHERE i.indrelid = 'lecture_progress'::regclass AND i.indisunique AND i.indpred IS NULL) s")"
if grep -qw 'enrollment_id,lecture_id' <<<"$uniq_cols" \
   && [[ "$(q "SELECT count(*) = count(DISTINCT (enrollment_id, lecture_id)) FROM lecture_progress")" == t ]] \
   && [[ "$(q "SELECT string_agg(enrollment_id || '-' || lecture_id || '=' || completed, ' ' ORDER BY enrollment_id, lecture_id)
          FROM lecture_progress WHERE (enrollment_id, lecture_id) IN ((1,1), (1,2), (1,3), (2,1), (3,1))")" == \
        "1-1=true 1-2=true 1-3="*" 2-1=true 3-1=false" ]]; then
  ok "3.1 one row per (enrollment_id, lecture_id) - the latest one - and a unique constraint keeps it that way"
else
  no "3.1 delete the older duplicates (keep the latest updated_at per pair), then ADD CONSTRAINT ... UNIQUE (enrollment_id, lecture_id)"
fi

# Start from the cleaned-up table and the original batch, apply 3.2.sql twice, compare.
RESET_PROGRESS="DELETE FROM lecture_progress;
INSERT INTO lecture_progress (enrollment_id, lecture_id, completed, updated_at) VALUES
  (1, 1, TRUE, '2024-05-01 10:00+00'), (1, 2, TRUE, '2024-05-03 08:00+00'), (1, 3, FALSE, '2024-05-01 10:10+00'),
  (2, 1, TRUE, '2024-05-02 09:00+00'), (2, 3, TRUE, '2024-05-02 09:30+00'), (3, 1, FALSE, '2024-05-04 12:00+00');
DELETE FROM incoming_progress;
INSERT INTO incoming_progress VALUES
  (1, 3, TRUE, '2024-06-01 10:00+00'), (1, 4, TRUE, '2024-06-01 10:05+00'), (3, 2, TRUE, '2024-06-02 11:00+00'),
  (3, 2, FALSE, '2024-06-02 11:30+00'), (2, 3, FALSE, '2024-04-01 09:00+00'), (2, 2, TRUE, '2024-06-03 08:00+00');"
[[ "$(twice "$SB/3.2.sql" "$RESET_PROGRESS" \
     "SELECT string_agg(enrollment_id || '-' || lecture_id || '=' || completed || '@' || to_char(updated_at AT TIME ZONE 'UTC', 'MM-DD HH24:MI'), ' ' ORDER BY enrollment_id, lecture_id) FROM lecture_progress;")" == \
   "1-1=true@05-01 10:00 1-2=true@05-03 08:00 1-3=true@06-01 10:00 1-4=true@06-01 10:05 2-1=true@05-02 09:00 2-2=true@06-03 08:00 2-3=true@05-02 09:30 3-1=false@05-04 12:00 3-2=false@06-02 11:30" ]] \
  && ok "3.2 3.2.sql applies the batch: new pairs inserted, newer events win, stale ones ignored - and twice is the same as once" \
  || no "3.2 3.2.sql: INSERT ... SELECT DISTINCT ON (enrollment_id, lecture_id) ... ORDER BY ..., event_at DESC ON CONFLICT (enrollment_id, lecture_id) DO UPDATE SET ... WHERE lecture_progress.updated_at < EXCLUDED.updated_at (needs 3.1)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Conditional Expressions & Conflicts complete."
