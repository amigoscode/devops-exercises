#!/usr/bin/env bash
# Runs INSIDE the container. Grades your video tables in the "youtube" database by the
# RULES of the requirement, not one exact schema: the right tables exist with primary
# keys, foreign keys point at the right tables, and test rows that must go in do while
# rows that break a rule are rejected. Your column names are free (foreign keys are
# found by what they reference) except the ones a task names.
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
# fkcol TABLE REF - the column of TABLE that is a foreign key to REF; pkcol TABLE
fkcol(){ q "SELECT a.attname FROM pg_constraint c JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
            WHERE c.contype = 'f' AND c.conrelid = to_regclass('$1') AND c.confrelid = to_regclass('$2') LIMIT 1"; }
pkcol(){ q "SELECT a.attname FROM pg_constraint c JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
            WHERE c.contype = 'p' AND c.conrelid = to_regclass('$1')"; }

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
# a required text column that isn't a key (the comment's text)
TEXTCOL="SELECT pg_temp.expect(EXISTS (SELECT 1 FROM pg_attribute a JOIN pg_type ty ON ty.oid = a.atttypid
  WHERE a.attrelid = 'video_comment'::regclass AND a.attnum > 0 AND NOT a.attisdropped AND a.attnotnull
    AND ty.typcategory = 'S' AND NOT EXISTS (SELECT 1 FROM pg_constraint c WHERE c.conrelid = a.attrelid
    AND c.contype IN ('p', 'f') AND a.attnum = ANY (c.conkey))), 'required text column');"

echo "Tier 1 - Videos"
t "
SELECT pg_temp.expect(pg_temp.has_pk('video'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('video', 'youtube_channel', true), 'NOT NULL FK to youtube_channel');
SELECT pg_temp.expect(pg_temp.notnull('video', 'title') AND pg_temp.notnull('video', 'url'), 'title + url required');
SELECT pg_temp.ins('video', '{\"youtube_channel\": 1, \"url\": \"zz-url-1\"}');
SELECT pg_temp.ins('video', '{\"youtube_channel\": 1, \"url\": \"zz-url-2\"}');
SELECT pg_temp.expect(pg_temp.no_ins('video', '{\"youtube_channel\": 2, \"url\": \"zz-url-1\"}'), 'duplicate url rejected');
SELECT pg_temp.expect(pg_temp.no_ins('video', '{\"youtube_channel\": null, \"url\": \"zz-url-3\"}'), 'video without a channel rejected');
SELECT pg_temp.expect(pg_temp.no_ins('video', jsonb_build_object('url', 'zz-url-4',
  'youtube_channel', pg_temp.ghost('youtube_channel', '{\"youtube_account_id\": 1}'))), 'missing channel rejected');
" && ok "1.2 video: one channel has many videos, every video has a real channel, title + unique url required" \
  || no "1.2 video needs a primary key, a NOT NULL foreign key to youtube_channel, title NOT NULL and url NOT NULL UNIQUE"

echo "Tier 2 - Views and likes"
t "
SELECT pg_temp.expect(pg_temp.has_pk('video_view'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('video_view', 'video', true), 'NOT NULL FK to video');
SELECT pg_temp.expect(pg_temp.has_fk('video_view', 'youtube_account', false), 'NULLABLE FK to youtube_account');
SELECT pg_temp.ins('video', '{\"youtube_channel\": 1}') AS v \gset
SELECT pg_temp.ins('video_view', jsonb_build_object('video', :'v', 'youtube_account', null));
SELECT pg_temp.ins('video_view', jsonb_build_object('video', :'v', 'youtube_account', null));
SELECT pg_temp.ins('video_view', jsonb_build_object('video', :'v', 'youtube_account', 1));
SELECT pg_temp.ins('video_view', jsonb_build_object('video', :'v', 'youtube_account', 1));
SELECT pg_temp.expect(pg_temp.no_ins('video_view', jsonb_build_object('video', :'v', 'youtube_account', 3)), 'missing account rejected');
SELECT pg_temp.expect(pg_temp.no_ins('video_view', jsonb_build_object('youtube_account', 1,
  'video', pg_temp.ghost('video', '{\"youtube_channel\": 1}'))), 'missing video rejected');
" && ok "2.1 video_view: anonymous views allowed, repeat views allowed, real video (and account, when given) enforced" \
  || no "2.1 video_view needs a primary key, a NOT NULL FK to video and a NULLABLE FK to youtube_account - with no unique pair (repeat views count)"

t "
SELECT pg_temp.expect(pg_temp.has_pk('video_like'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('video_like', 'video', true) AND pg_temp.has_fk('video_like', 'youtube_account', true), 'NOT NULL FKs');
SELECT pg_temp.ins('video', '{\"youtube_channel\": 1}') AS v1 \gset
SELECT pg_temp.ins('video', '{\"youtube_channel\": 2}') AS v2 \gset
SELECT pg_temp.ins('video_like', jsonb_build_object('video', :'v1', 'youtube_account', 1));
SELECT pg_temp.ins('video_like', jsonb_build_object('video', :'v2', 'youtube_account', 1));
SELECT pg_temp.ins('video_like', jsonb_build_object('video', :'v1', 'youtube_account', 2));
SELECT pg_temp.expect(pg_temp.no_ins('video_like', jsonb_build_object('video', :'v1', 'youtube_account', 1)), 'second like rejected');
SELECT pg_temp.expect(pg_temp.no_ins('video_like', jsonb_build_object('video', :'v2', 'youtube_account', null)), 'like without account rejected');
SELECT pg_temp.expect(pg_temp.no_ins('video_like', jsonb_build_object('video', :'v2', 'youtube_account', 3)), 'missing account rejected');
" && ok "2.2 video_like: many accounts x many videos, an account is required, and each pair only once" \
  || no "2.2 video_like needs NOT NULL FKs to video and youtube_account and a composite PRIMARY KEY (or UNIQUE) on the pair"

echo "Tier 3 - Comments, then real data"
t "
SELECT pg_temp.expect(pg_temp.has_pk('video_comment'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('video_comment', 'video', true) AND pg_temp.has_fk('video_comment', 'youtube_account', true), 'NOT NULL FKs');
$TEXTCOL
SELECT pg_temp.ins('video', '{\"youtube_channel\": 1}') AS v \gset
SELECT pg_temp.ins('video_comment', jsonb_build_object('video', :'v', 'youtube_account', 1));
SELECT pg_temp.ins('video_comment', jsonb_build_object('video', :'v', 'youtube_account', 1));
SELECT pg_temp.expect(pg_temp.no_ins('video_comment', jsonb_build_object('video', :'v', 'youtube_account', null)), 'comment without account rejected');
SELECT pg_temp.expect(pg_temp.no_ins('video_comment', jsonb_build_object('youtube_account', 1,
  'video', pg_temp.ghost('video', '{\"youtube_channel\": 1}'))), 'missing video rejected');
" && ok "3.1 video_comment: account + video required, text required, many comments per account per video" \
  || no "3.1 video_comment needs a primary key, NOT NULL FKs to video and youtube_account, a NOT NULL text column, and no unique pair"

t "
SELECT pg_temp.expect(pg_temp.has_pk('video_comment_like'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('video_comment_like', 'video_comment', true) AND pg_temp.has_fk('video_comment_like', 'youtube_account', true), 'NOT NULL FKs');
SELECT pg_temp.ins('video', '{\"youtube_channel\": 1}') AS v \gset
SELECT pg_temp.ins('video_comment', jsonb_build_object('video', :'v', 'youtube_account', 4)) AS c1 \gset
SELECT pg_temp.ins('video_comment', jsonb_build_object('video', :'v', 'youtube_account', 4)) AS c2 \gset
SELECT pg_temp.ins('video_comment_like', jsonb_build_object('video_comment', :'c1', 'youtube_account', 1));
SELECT pg_temp.ins('video_comment_like', jsonb_build_object('video_comment', :'c2', 'youtube_account', 1));
SELECT pg_temp.ins('video_comment_like', jsonb_build_object('video_comment', :'c1', 'youtube_account', 2));
SELECT pg_temp.expect(pg_temp.no_ins('video_comment_like', jsonb_build_object('video_comment', :'c1', 'youtube_account', 1)), 'second like rejected');
SELECT pg_temp.expect(pg_temp.no_ins('video_comment_like', jsonb_build_object('video_comment', :'c2', 'youtube_account', null)), 'like without account rejected');
" && ok "3.2 video_comment_like: an account likes a comment only once" \
  || no "3.2 video_comment_like needs NOT NULL FKs to video_comment and youtube_account and a composite PRIMARY KEY (or UNIQUE) on the pair"

t "
SELECT pg_temp.pick('video', '{\"url\": \"https://youtube.com/432423k\", \"youtube_channel\": 2, \"title\": \"Macbook Air M1 Unboxing\"}') AS v \gset
SELECT pg_temp.expect(pg_temp.cnt('video_like', jsonb_build_object('video', :'v')) = 2
  AND pg_temp.cnt('video_like', jsonb_build_object('video', :'v', 'youtube_account', 1)) = 1
  AND pg_temp.cnt('video_like', jsonb_build_object('video', :'v', 'youtube_account', 4)) = 1, 'liked by 1 and 4');
SELECT pg_temp.expect(pg_temp.cnt('video_view', jsonb_build_object('video', :'v', 'youtube_account', null)) = 2, 'two anonymous views');
SELECT pg_temp.pick('video_comment', jsonb_build_object('video', :'v', 'youtube_account', 4, '*', 'Nice video')) AS c \gset
SELECT pg_temp.expect(pg_temp.cnt('video_comment_like', jsonb_build_object('video_comment', :'c', 'youtube_account', 2)) = 1, 'Joe likes the comment');
SELECT pg_temp.expect(pg_temp.cnt('video', '{\"url\": \"https://youtube.com/932898233\", \"youtube_channel\": 3, \"title\": \"Database Design\"}') = 1, 'second video');
" && ok "3.3 the unboxing video with its 2 likes, 2 anonymous views, Alex's comment and Joe's like - plus Database Design" \
  || no "3.3 add the two videos, the two likes (accounts 1, 4), two anonymous views, Alex's 'Nice video' comment and Joe's like on it"

vpk="$(pkcol video)"; lfk="$(fkcol video_like video)"; want=""
[[ -n "$vpk" && -n "$lfk" ]] && want="$(q "SELECT v.title, count(l.\"$lfk\") FROM video v
    LEFT JOIN video_like l ON l.\"$lfk\" = v.\"$vpk\" GROUP BY v.\"$vpk\", v.title")"
# there must be a video with 0 likes (3.3's Database Design) so the LEFT JOIN matters
[[ -s "$SB/3.4.sql" && "$want" == *"|0"* ]] && diff <(run "$SB/3.4.sql" "$DB" | sort) <(sort <<<"$want") >/dev/null \
  && ok "3.4 3.4.sql lists every video's title with its number of likes (0 included)" \
  || no "3.4 after 3.3, 3.4.sql: title + number of likes for EVERY video - LEFT JOIN video_like + GROUP BY, so a video without likes shows 0"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You extended a real design: one-to-many, many-to-many, optional foreign keys - all enforced by the database."
