#!/usr/bin/env bash
# Runs INSIDE the container. Grades your normalized tables in the "normalization"
# database (structure, behaviour, and that no data was lost in the split) and the
# queries you saved in ~/sandbox/<task>.sql.
set -uo pipefail
SB="$HOME/sandbox"; DB=normalization; REF="${DB}_ref"   # REF: untouched copy made by seed.sh
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# run FILE DB - run a saved query inside a transaction that is rolled back (the extra
#               ';' lets a query saved without its semicolon still run)
run(){ { echo 'BEGIN;'; cat "$1"; echo; echo ';'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# same_rows FILE REFSQL [DB] - FILE returns the same rows as the reference query (any
#                              order). Default DB: the untouched copy.
same_rows(){ local d="${3:-$REF}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d" | sort) <(sort <<<"$want") >/dev/null; }
# same_data SQL REFSQL - SQL on your database returns exactly the rows REFSQL returns on
#                        the untouched copy (your split tables still hold all the data)
same_data(){ local want got; want="$(q "$2" "$REF")"; got="$(q "$1")"
  [[ -n "$want" ]] && diff <(sort <<<"$got") <(sort <<<"$want") >/dev/null; }
# cols TABLE "name:type" ... - every listed column exists with that data type
cols(){ local tb="$1" c; shift; for c in "$@"; do
  [[ "$(q "SELECT data_type FROM information_schema.columns WHERE table_schema = 'public'
          AND table_name = '$tb' AND column_name = '${c%%:*}'")" == "${c#*:}" ]] || return 1; done; }
# gone TABLE COL - the column no longer exists (the table still does)
gone(){ [[ "$(q "SELECT to_regclass('$1') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'public' AND table_name = '$1' AND column_name = '$2')")" == t ]]; }

# --- behaviour-test helpers --------------------------------------------------------
# Every test runs inside ONE transaction that is rolled back, so checking never
# changes your database. The helpers below live in pg_temp (gone when the test ends).
#   pg_temp.ins(table, vals)    insert a row, return its primary key. vals is JSON:
#                               {"column": value} or {"referenced_table": id} (fills
#                               whatever column is the foreign key to that table).
#                               Required columns you didn't pass get simple values
#                               (text 'u1@x.io', numbers 1, dates now()); a required
#                               foreign key reuses an existing row of that table.
#   pg_temp.no_ins(table, vals) true if that insert is REJECTED
#   pg_temp.ghost(table, vals)  the id of a row that no longer exists (insert + delete)
#   pg_temp.has_fk(t, ref, nn)  t has a foreign key to ref (nn: true NOT NULL / false nullable)
#   pg_temp.cnt(table, conds)   how many rows match conds (same JSON keys as ins; a
#                               referenced table matches ANY foreign key to it; a JSON
#                               number compares as a number; "*" matches a row with
#                               that value in any column)
#   pg_temp.pick(table, conds)  the primary key of a matching row (error if none)
#   pg_temp.expect(bool, what)  stop the test (= ❌) unless bool is true
HELPERS=$(cat <<'SQL'
CREATE TEMP SEQUENCE g;
CREATE FUNCTION pg_temp.expect(b boolean, what text DEFAULT 'check') RETURNS void LANGUAGE plpgsql AS $f$
BEGIN IF b IS NOT TRUE THEN RAISE EXCEPTION 'expected: %', what; END IF; END $f$;
CREATE FUNCTION pg_temp.pkcol(t regclass) RETURNS name LANGUAGE sql AS $f$
  SELECT a.attname FROM pg_constraint c JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
  WHERE c.conrelid = t AND c.contype = 'p' $f$;
CREATE FUNCTION pg_temp.pkcols(t regclass) RETURNS text LANGUAGE sql AS $f$
  SELECT string_agg(a.attname, ',' ORDER BY a.attname) FROM pg_constraint c
  JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
  WHERE c.conrelid = t AND c.contype = 'p' $f$;
CREATE FUNCTION pg_temp.has_pk(t regclass) RETURNS boolean LANGUAGE sql AS $f$
  SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = t AND contype = 'p') $f$;
CREATE FUNCTION pg_temp.has_fk(t regclass, ref regclass, nn boolean DEFAULT NULL) RETURNS boolean LANGUAGE sql AS $f$
  SELECT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
    WHERE c.contype = 'f' AND c.conrelid = t AND c.confrelid = ref AND cardinality(c.conkey) = 1
      AND (nn IS NULL OR a.attnotnull = nn)) $f$;
CREATE FUNCTION pg_temp.has_col(t regclass, col name) RETURNS boolean LANGUAGE sql AS $f$
  SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = t AND attname = col AND attnum > 0 AND NOT attisdropped) $f$;
CREATE FUNCTION pg_temp.notnull(t regclass, col name) RETURNS boolean LANGUAGE sql AS $f$
  SELECT coalesce((SELECT attnotnull FROM pg_attribute WHERE attrelid = t AND attname = col AND attnum > 0 AND NOT attisdropped), false) $f$;
CREATE FUNCTION pg_temp.ins(t regclass, vals jsonb DEFAULT '{}', depth int DEFAULT 0) RETURNS text LANGUAGE plpgsql AS $f$
DECLARE r record; cols text[] := '{}'; exprs text[] := '{}'; v text; res text; pk name;
BEGIN
  IF depth > 4 THEN RAISE EXCEPTION 'foreign keys nest too deep'; END IF;
  FOR r IN
    SELECT a.attname, a.attnotnull, a.atthasdef, a.attidentity, a.attgenerated, a.atttypid,
           ty.typtype, ty.typcategory, format_type(a.atttypid, NULL) AS ftype, fk.ref, fk.refcol,
           EXISTS (SELECT 1 FROM pg_constraint u WHERE u.conrelid = t AND u.contype IN ('u','p') AND a.attnum = ANY (u.conkey)) AS uniq
    FROM pg_attribute a JOIN pg_type ty ON ty.oid = a.atttypid
    LEFT JOIN LATERAL (SELECT c.confrelid::regclass AS ref, ra.attname AS refcol FROM pg_constraint c
                       JOIN pg_attribute ra ON ra.attrelid = c.confrelid AND ra.attnum = c.confkey[1]
                       WHERE c.contype = 'f' AND c.conrelid = t AND c.conkey = ARRAY[a.attnum] LIMIT 1) fk ON true
    WHERE a.attrelid = t AND a.attnum > 0 AND NOT a.attisdropped ORDER BY a.attnum
  LOOP
    v := NULL;
    IF vals ? r.attname THEN
      v := CASE WHEN jsonb_typeof(vals -> r.attname) = 'null' THEN 'NULL' ELSE quote_literal(vals ->> r.attname) END;
    ELSIF r.ref IS NOT NULL AND vals ? r.ref::text THEN
      v := CASE WHEN jsonb_typeof(vals -> r.ref::text) = 'null' THEN 'NULL' ELSE quote_literal(vals ->> r.ref::text) END;
    ELSIF r.attnotnull AND NOT r.atthasdef AND r.attidentity = '' AND r.attgenerated = '' THEN
      IF r.ref IS NOT NULL THEN
        EXECUTE format('SELECT %I::text FROM %s LIMIT 1', r.refcol, r.ref) INTO v;
        IF v IS NULL THEN v := pg_temp.ins(r.ref, '{}', depth + 1); END IF;
        v := quote_literal(v);
      ELSIF r.typtype = 'e' THEN
        v := quote_literal((SELECT enumlabel FROM pg_enum WHERE enumtypid = r.atttypid ORDER BY enumsortorder LIMIT 1));
      ELSIF r.ftype = 'uuid' THEN v := 'gen_random_uuid()';
      ELSIF r.ftype IN ('json', 'jsonb') THEN v := quote_literal('{}');
      ELSIF r.typcategory = 'S' THEN v := quote_literal('u' || nextval('g') || '@x.io');
      ELSIF r.typcategory = 'N' THEN v := CASE WHEN r.uniq THEN (1000 + nextval('g'))::text ELSE '1' END;
      ELSIF r.typcategory = 'D' THEN v := 'now()';
      ELSIF r.typcategory = 'B' THEN v := 'false';
      ELSIF r.typcategory = 'A' THEN v := quote_literal('{}');
      END IF;
    END IF;
    IF v IS NOT NULL THEN cols := cols || quote_ident(r.attname); exprs := exprs || v; END IF;
  END LOOP;
  pk := pg_temp.pkcol(t);
  IF cardinality(cols) = 0 THEN
    EXECUTE format('INSERT INTO %s DEFAULT VALUES RETURNING %s::text', t, coalesce(quote_ident(pk), 'NULL')) INTO res;
  ELSE
    EXECUTE format('INSERT INTO %s (%s) VALUES (%s) RETURNING %s::text', t, array_to_string(cols, ', '),
                   array_to_string(exprs, ', '), coalesce(quote_ident(pk), 'NULL')) INTO res;
  END IF;
  RETURN res;
END $f$;
CREATE FUNCTION pg_temp.no_ins(t regclass, vals jsonb DEFAULT '{}') RETURNS boolean LANGUAGE plpgsql AS $f$
BEGIN PERFORM pg_temp.ins(t, vals); RETURN false; EXCEPTION WHEN OTHERS THEN RETURN true; END $f$;
CREATE FUNCTION pg_temp.ghost(t regclass, vals jsonb DEFAULT '{}') RETURNS text LANGUAGE plpgsql AS $f$
DECLARE id text;
BEGIN id := pg_temp.ins(t, vals);
  EXECUTE format('DELETE FROM %s WHERE %I::text = %L', t, pg_temp.pkcol(t), id); RETURN id; END $f$;
CREATE FUNCTION pg_temp.where_sql(t regclass, conds jsonb) RETURNS text LANGUAGE plpgsql AS $f$
DECLARE k text; w text[] := '{}'; parts text[];
BEGIN
  FOR k IN SELECT jsonb_object_keys(conds) LOOP
    IF k = '*' THEN
      w := w || format('EXISTS (SELECT 1 FROM jsonb_each_text(to_jsonb(x)) e WHERE e.value = %L)', conds ->> k);
      CONTINUE;
    ELSIF EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = t AND attname = k AND attnum > 0 AND NOT attisdropped) THEN
      parts := ARRAY['x.' || quote_ident(k)];
    ELSE
      SELECT array_agg('x.' || quote_ident(a.attname)) INTO parts FROM pg_constraint co
      JOIN pg_attribute a ON a.attrelid = co.conrelid AND a.attnum = co.conkey[1]
      WHERE co.contype = 'f' AND co.conrelid = t AND cardinality(co.conkey) = 1 AND co.confrelid::regclass::text = k;
      IF parts IS NULL THEN RAISE EXCEPTION '% has no column or foreign key for %', t, k; END IF;
    END IF;
    IF jsonb_typeof(conds -> k) = 'null' THEN
      w := w || ('(' || (SELECT string_agg(c || ' IS NULL', ' AND ') FROM unnest(parts) c) || ')');
    ELSIF jsonb_typeof(conds -> k) = 'number' THEN
      w := w || ('(' || (SELECT string_agg(c || ' = ' || (conds ->> k)::numeric, ' OR ') FROM unnest(parts) c) || ')');
    ELSE
      w := w || ('(' || (SELECT string_agg(c || '::text = ' || quote_literal(conds ->> k), ' OR ') FROM unnest(parts) c) || ')');
    END IF;
  END LOOP;
  RETURN coalesce(array_to_string(w, ' AND '), 'true');
END $f$;
CREATE FUNCTION pg_temp.cnt(t regclass, conds jsonb DEFAULT '{}') RETURNS bigint LANGUAGE plpgsql AS $f$
DECLARE n bigint;
BEGIN EXECUTE format('SELECT count(*) FROM %s x WHERE %s', t, pg_temp.where_sql(t, conds)) INTO n; RETURN n; END $f$;
CREATE FUNCTION pg_temp.pick(t regclass, conds jsonb DEFAULT '{}') RETURNS text LANGUAGE plpgsql AS $f$
DECLARE v text;
BEGIN EXECUTE format('SELECT x.%I::text FROM %s x WHERE %s LIMIT 1', pg_temp.pkcol(t), t, pg_temp.where_sql(t, conds)) INTO v;
  IF v IS NULL THEN RAISE EXCEPTION 'no % row matching %', t, conds; END IF; RETURN v; END $f$;
SQL
)
# t SCRIPT - run a behaviour test (SQL using the helpers) in a rolled-back transaction;
#            true only if every statement succeeds. DEBUG=1 bash verify.sh shows errors.
ERR=/dev/null; [[ -n "${DEBUG:-}" ]] && ERR=/dev/stderr
t(){ { echo 'BEGIN;'; echo "$HELPERS"; echo "$1"; echo "SELECT 'ok';"; echo 'ROLLBACK;'; } \
     | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>"$ERR" | tail -1 | grep -qx ok; }

echo "Tier 1 - First normal form (1NF)"
same_rows "$SB/1.1.sql" "SELECT id, first_name, phone_numbers FROM user_profile WHERE phone_numbers LIKE '%,%'" \
  && ok "1.1 1.1.sql lists the users whose phone_numbers holds more than one number" \
  || no "1.1 1.1.sql: id, first_name, phone_numbers of users with MORE THAN ONE number (hint: they contain a comma)"

cols phone_number id:bigint user_profile_id:bigint phone_number:text && t "
SELECT pg_temp.expect(pg_temp.pkcols('phone_number') = 'id', 'id is the primary key');
SELECT pg_temp.expect(pg_temp.has_fk('phone_number', 'user_profile', true), 'NOT NULL FK to user_profile');
SELECT pg_temp.expect(pg_temp.notnull('phone_number', 'phone_number'), 'phone_number required');
SELECT pg_temp.ins('phone_number', '{\"user_profile_id\": 6, \"phone_number\": \"zz-555-0001\"}');
SELECT pg_temp.ins('phone_number', '{\"user_profile_id\": 6, \"phone_number\": \"zz-555-0002\"}');
SELECT pg_temp.expect(pg_temp.no_ins('phone_number', '{\"user_profile_id\": 5, \"phone_number\": \"zz-555-0001\"}'), 'duplicate number rejected');
SELECT pg_temp.expect(pg_temp.no_ins('phone_number', '{\"user_profile_id\": 999999, \"phone_number\": \"zz-555-0003\"}'), 'missing user rejected');
" && ok "1.2 phone_number: id PK, user_profile_id NOT NULL FK, phone_number unique - many numbers per user" \
  || no "1.2 create phone_number (id BIGSERIAL PRIMARY KEY, user_profile_id BIGINT NOT NULL REFERENCES user_profile (id), phone_number TEXT NOT NULL UNIQUE)"

gone user_profile phone_numbers && same_data \
  "SELECT u.email, p.phone_number FROM user_profile u JOIN phone_number p ON p.user_profile_id = u.id" \
  "SELECT email, trim(n) FROM user_profile, unnest(string_to_array(phone_numbers, ',')) AS n" \
  && ok "1.3 every number is its own row in phone_number and phone_numbers is gone - 1NF" \
  || no "1.3 copy each number into phone_number (one row per number, linked to its user), then DROP COLUMN phone_numbers"

echo "Tier 2 - Second normal form (2NF)"
gone user_profile address && gone user_profile postcode \
  && cols address id:bigint user_profile_id:bigint address:text postcode:text \
  && t "SELECT pg_temp.expect(pg_temp.pkcols('address') = 'id', 'id is the primary key');
        SELECT pg_temp.expect(pg_temp.has_fk('address', 'user_profile', true), 'NOT NULL FK to user_profile');
        SELECT pg_temp.expect(pg_temp.notnull('address', 'address') AND pg_temp.notnull('address', 'postcode'), 'required');" \
  && same_data "SELECT u.email, a.address, a.postcode FROM user_profile u JOIN address a ON a.user_profile_id = u.id" \
               "SELECT email, address, postcode FROM user_profile" \
  && ok "2.1 address + postcode live in their own address table, linked to the user" \
  || no "2.1 create address (id PK, user_profile_id NOT NULL FK, address, postcode NOT NULL), copy the data, drop both columns from user_profile"

gone channel_subscriber youtube_channel_category && same_data \
  "SELECT s.youtube_account_id, s.youtube_channel_id, c.category FROM channel_subscriber s JOIN youtube_channel c ON c.id = s.youtube_channel_id" \
  "SELECT youtube_account_id, youtube_channel_id, youtube_channel_category FROM channel_subscriber" \
  && ok "2.2 each channel's category is stored once on youtube_channel - no partial dependency left" \
  || no "2.2 add youtube_channel.category, fill it from channel_subscriber, then drop youtube_channel_category"

echo "Tier 3 - Third normal form (3NF)"
# Al Fredrickson's date may already be corrected by 3.3, so it's compared separately
gone tournament_winner winner_date_of_birth && cols winner name:text date_of_birth:date && t "
SELECT pg_temp.expect(pg_temp.pkcols('winner') = 'name', 'name is the primary key');
SELECT pg_temp.expect(pg_temp.notnull('winner', 'date_of_birth'), 'date_of_birth required');
SELECT pg_temp.expect(pg_temp.has_fk('tournament_winner', 'winner', true), 'winner is a FK');
SELECT pg_temp.expect(pg_temp.no_ins('tournament_winner', '{\"tournament\": \"Zz Open\", \"year\": 2001, \"winner\": \"Nobody Known\"}'), 'unknown winner rejected');
SELECT pg_temp.ins('tournament_winner', '{\"tournament\": \"Zz Open\", \"year\": 2001, \"winner\": \"Bob Albertson\"}');
SELECT pg_temp.expect((SELECT date_of_birth FROM winner WHERE name = 'Al Fredrickson') IN ('1975-07-21', '1975-07-12'), 'Al kept');
" && same_data "SELECT t.tournament, t.year, t.winner, CASE WHEN t.winner = 'Al Fredrickson' THEN NULL ELSE w.date_of_birth END
                FROM tournament_winner t JOIN winner w ON w.name = t.winner" \
               "SELECT tournament, year, winner, CASE WHEN winner = 'Al Fredrickson' THEN NULL ELSE winner_date_of_birth END
                FROM tournament_winner" \
  && ok "3.1 winner (name PK, date_of_birth) + tournament_winner.winner as FK - each date of birth stored once" \
  || no "3.1 create winner (name TEXT PRIMARY KEY, date_of_birth DATE NOT NULL), make tournament_winner.winner a FK to it, drop winner_date_of_birth"

gone tournament_winner winner_date_of_birth && same_rows "$SB/3.2.sql" \
  "SELECT t.tournament, t.year, t.winner, w.date_of_birth FROM tournament_winner t JOIN winner w ON w.name = t.winner" "$DB" \
  && ok "3.2 3.2.sql rebuilds tournament, year, winner, date of birth with a JOIN" \
  || no "3.2 after 3.1, 3.2.sql must JOIN tournament_winner to winner: tournament, year, winner, date_of_birth"

[[ "$(q "SELECT string_agg(name || '=' || date_of_birth, ',' ORDER BY name) FROM winner")" == \
   "Al Fredrickson=1975-07-12,Bob Albertson=1968-09-28,Chip Masterson=1977-03-14,Dana Whitfield=1980-11-02" ]] \
  && ok "3.3 Al Fredrickson's date of birth is 1975-07-12 - fixed in one row, everyone else unchanged" \
  || no "3.3 in the winner table, set Al Fredrickson's date_of_birth to 1975-07-12 (and change nothing else)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 1NF, 2NF and 3NF: every fact stored once, and not a row of data lost."
