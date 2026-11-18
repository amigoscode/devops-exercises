#!/usr/bin/env bash
# Runs INSIDE the container. Grades the tables you built in the "youtube" database by
# their structure AND their behaviour (valid rows go in, rows that break a rule are
# rejected), plus the queries you saved in ~/sandbox/<task>.sql.
set -uo pipefail
SB="$HOME/sandbox"; DB=youtube
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
# order). Here both run on YOUR database: the tables are yours, the names are fixed.
same_rows(){ local d="${3:-$DB}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d" | sort) <(sort <<<"$want") >/dev/null; }
# cols TABLE "name:type" ... - every listed column exists with that data type
cols(){ local tb="$1" c; shift; for c in "$@"; do
  [[ "$(q "SELECT data_type FROM information_schema.columns WHERE table_schema = 'public'
          AND table_name = '$tb' AND column_name = '${c%%:*}'")" == "${c#*:}" ]] || return 1; done; }
# serial TABLE - the id fills itself in (BIGSERIAL, or an identity column)
serial(){ [[ "$(q "SELECT column_default LIKE 'nextval%' OR is_identity = 'YES' FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_name = '$1' AND column_name = 'id'")" == t ]]; }
TS="timestamp without time zone"

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

echo "Tier 1 - Entities, attributes and keys"
cols user_profile id:bigint first_name:text last_name:text email:text gender:text "created_at:$TS" \
  && serial user_profile \
  && t "SELECT pg_temp.expect(pg_temp.pkcols('user_profile') = 'id', 'id is the primary key');" \
  && ok "1.2 user_profile has id BIGSERIAL PRIMARY KEY, first_name, last_name, email, gender (TEXT), created_at (TIMESTAMP)" \
  || no "1.2 create user_profile: id BIGSERIAL PRIMARY KEY, first_name/last_name/email/gender TEXT, created_at TIMESTAMP"

t "
SELECT pg_temp.expect((SELECT count(*) FROM information_schema.columns WHERE table_schema = 'public'
  AND table_name = 'user_profile' AND is_nullable = 'NO'
  AND column_name IN ('id','first_name','last_name','email','gender','created_at')) = 6, 'all NOT NULL');
SELECT pg_temp.ins('user_profile', '{\"email\": \"bond@mi6.uk\", \"gender\": \"MALE\"}');
SELECT pg_temp.expect(pg_temp.no_ins('user_profile', '{\"email\": \"bond@mi6.uk\", \"gender\": \"MALE\"}'), 'duplicate email rejected');
SELECT pg_temp.ins('user_profile', '{\"gender\": \"FEMALE\"}');
SELECT pg_temp.expect(pg_temp.no_ins('user_profile', '{\"gender\": \"OTHER\"}'), 'gender OTHER rejected');
" && ok "1.3 email is unique, gender is only MALE/FEMALE, and no column accepts NULL" \
  || no "1.3 user_profile needs: UNIQUE email, CHECK (gender IN ('MALE', 'FEMALE')), NOT NULL on every column"

echo "Tier 2 - Relationships"
# a fresh profile can get ONE account; a second one, or one for a missing profile, fails
cols youtube_account id:bigint "created_at:$TS" && t "
SELECT pg_temp.expect(pg_temp.pkcols('youtube_account') = 'id', 'id is the primary key');
SELECT pg_temp.expect(pg_temp.has_fk('youtube_account', 'user_profile', true), 'FK to user_profile');
SELECT pg_temp.expect(pg_temp.notnull('youtube_account', 'created_at'), 'created_at required');
SELECT pg_temp.ins('user_profile', '{\"gender\": \"MALE\"}') AS p \gset
SELECT pg_temp.ins('youtube_account', jsonb_build_object('id', :'p'));
SELECT pg_temp.expect(pg_temp.no_ins('youtube_account', jsonb_build_object('id', :'p')), 'second account rejected');
SELECT pg_temp.expect(pg_temp.no_ins('youtube_account',
  jsonb_build_object('id', pg_temp.ghost('user_profile', '{\"gender\": \"MALE\"}'))), 'missing profile rejected');
" && ok "2.1 youtube_account: id is PK + FK to user_profile - one account per profile, none for a missing profile" \
  || no "2.1 youtube_account needs id BIGINT PRIMARY KEY REFERENCES user_profile (id) and created_at TIMESTAMP NOT NULL"

cols youtube_channel id:bigint youtube_account_id:bigint channel_name:text "created_at:$TS" && serial youtube_channel && t "
SELECT pg_temp.expect(pg_temp.pkcols('youtube_channel') = 'id', 'id is the primary key');
SELECT pg_temp.expect(pg_temp.has_fk('youtube_channel', 'youtube_account', true), 'NOT NULL FK to youtube_account');
SELECT pg_temp.expect(pg_temp.notnull('youtube_channel', 'channel_name') AND pg_temp.notnull('youtube_channel', 'created_at'), 'required columns');
SELECT pg_temp.ins('user_profile', '{\"gender\": \"MALE\"}') AS p \gset
SELECT pg_temp.ins('youtube_account', jsonb_build_object('id', :'p')) AS a \gset
SELECT pg_temp.ins('youtube_channel', jsonb_build_object('youtube_account_id', :'a', 'channel_name', 'zz-one'));
SELECT pg_temp.ins('youtube_channel', jsonb_build_object('youtube_account_id', :'a', 'channel_name', 'zz-two'));
SELECT pg_temp.expect(pg_temp.no_ins('youtube_channel', jsonb_build_object('youtube_account_id', :'a', 'channel_name', 'zz-one')), 'duplicate name rejected');
SELECT pg_temp.expect(pg_temp.no_ins('youtube_channel', jsonb_build_object('youtube_account_id', null, 'channel_name', 'zz-three')), 'no account rejected');
SELECT pg_temp.expect(pg_temp.no_ins('youtube_channel', jsonb_build_object('youtube_account_id',
  pg_temp.ghost('user_profile', '{\"gender\": \"MALE\"}'), 'channel_name', 'zz-four')), 'missing account rejected');
" && ok "2.2 youtube_channel: one account owns many channels, every channel has a real account, names are unique" \
  || no "2.2 youtube_channel needs id BIGSERIAL PK, youtube_account_id BIGINT NOT NULL REFERENCES youtube_account (id), channel_name TEXT NOT NULL UNIQUE, created_at"

cols channel_subscriber youtube_account_id:bigint youtube_channel_id:bigint "created_at:$TS" && t "
SELECT pg_temp.expect(pg_temp.pkcols('channel_subscriber') = 'youtube_account_id,youtube_channel_id', 'composite PK');
SELECT pg_temp.expect(pg_temp.has_fk('channel_subscriber', 'youtube_account') AND pg_temp.has_fk('channel_subscriber', 'youtube_channel'), 'both FKs');
SELECT pg_temp.expect(pg_temp.notnull('channel_subscriber', 'created_at'), 'created_at required');
SELECT pg_temp.ins('user_profile', '{\"gender\": \"MALE\"}') AS p1 \gset
SELECT pg_temp.ins('user_profile', '{\"gender\": \"FEMALE\"}') AS p2 \gset
SELECT pg_temp.ins('youtube_account', jsonb_build_object('id', :'p1')) AS a \gset
SELECT pg_temp.ins('youtube_account', jsonb_build_object('id', :'p2')) AS b \gset
SELECT pg_temp.ins('youtube_channel', jsonb_build_object('youtube_account_id', :'a')) AS x \gset
SELECT pg_temp.ins('youtube_channel', jsonb_build_object('youtube_account_id', :'a')) AS y \gset
SELECT pg_temp.ins('channel_subscriber', jsonb_build_object('youtube_account_id', :'a', 'youtube_channel_id', :'x'));
SELECT pg_temp.ins('channel_subscriber', jsonb_build_object('youtube_account_id', :'a', 'youtube_channel_id', :'y'));
SELECT pg_temp.ins('channel_subscriber', jsonb_build_object('youtube_account_id', :'b', 'youtube_channel_id', :'x'));
SELECT pg_temp.expect(pg_temp.no_ins('channel_subscriber', jsonb_build_object('youtube_account_id', :'a', 'youtube_channel_id', :'x')), 'second subscription rejected');
SELECT pg_temp.expect(pg_temp.no_ins('channel_subscriber', jsonb_build_object('youtube_account_id', :'b',
  'youtube_channel_id', pg_temp.ghost('youtube_channel', jsonb_build_object('youtube_account_id', :'a')))), 'missing channel rejected');
SELECT pg_temp.expect(pg_temp.no_ins('channel_subscriber', jsonb_build_object('youtube_channel_id', :'y',
  'youtube_account_id', pg_temp.ghost('user_profile', '{\"gender\": \"MALE\"}'))), 'missing account rejected');
" && ok "2.3 channel_subscriber: many accounts x many channels, each pair only once (composite PK)" \
  || no "2.3 channel_subscriber needs youtube_account_id + youtube_channel_id (FKs), created_at, PRIMARY KEY (youtube_account_id, youtube_channel_id)"

echo "Tier 3 - Put the design to work"
[[ "$(q "SELECT (SELECT count(*) FROM user_profile WHERE email IN ('m.ali@gmail.com', 'j.james@gmail.com',
          'jamila@gmail.com', 'alex2000@gmail.com', 'bobbill@gmail.com')) = 5
     AND (SELECT count(*) FROM youtube_account WHERE id IN (1, 2, 4)) = 3
     AND (SELECT count(*) FROM youtube_channel WHERE (id, youtube_account_id, channel_name) IN
          ((1, 1, 'MariamBeauty'), (4, 1, 'MariamBeautyTutorials'), (2, 2, 'JoeTech'), (3, 4, 'AlexTutorials'))) = 4
     AND (SELECT count(*) FROM channel_subscriber WHERE (youtube_account_id, youtube_channel_id) IN
          ((1, 2), (1, 3), (4, 1), (2, 1))) = 4")" == t ]] \
  && ok "3.1 the sample data is loaded: 5 profiles, 3 accounts, 4 channels, 4 subscriptions" \
  || no "3.1 load the sample data into your tables: \\i sample-data.sql - every row must go in"

same_rows "$SB/3.2.sql" "SELECT c.channel_name, count(s.youtube_account_id) FROM youtube_channel c
    LEFT JOIN channel_subscriber s ON s.youtube_channel_id = c.id GROUP BY c.id, c.channel_name" \
  && ok "3.2 3.2.sql lists every channel with its subscriber count (0 included)" \
  || no "3.2 3.2.sql: channel_name + number of subscribers for EVERY channel - LEFT JOIN + GROUP BY so unsubscribed channels show 0"

same_rows "$SB/3.3.sql" "SELECT p.first_name, p.last_name FROM user_profile p
    JOIN channel_subscriber s ON s.youtube_account_id = p.id
    JOIN youtube_channel c ON c.id = s.youtube_channel_id WHERE c.channel_name = 'MariamBeauty'" \
  && ok "3.3 3.3.sql lists the first and last names of MariamBeauty's subscribers" \
  || no "3.3 3.3.sql: first_name, last_name of every subscriber of MariamBeauty (channel -> channel_subscriber -> account id = profile id)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 From ERD to enforced schema: one-to-one, one-to-many and many-to-many, all guarded by the database."
