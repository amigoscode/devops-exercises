#!/usr/bin/env bash
# Runs INSIDE the container. Grades your Tick Trade design in the "ticktrade" database
# by the RULES of the brief, not one exact schema: the right tables exist with primary
# keys, foreign keys point at the right tables, and test rows that must go in do while
# rows that break a rule are rejected. Your column names are free (foreign keys are
# found by what they reference) except the ones a task names.
set -uo pipefail
SB="$HOME/sandbox"; DB=ticktrade
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# run FILE DB - run a saved query inside a transaction that is rolled back (the extra
#               ';' lets a query saved without its semicolon still run)
run(){ { echo 'BEGIN;'; cat "$1"; echo; echo ';'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# fkcols TABLE REF - the columns of TABLE that are foreign keys to REF; pkcol TABLE
fkcols(){ q "SELECT a.attname FROM pg_constraint c JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
             WHERE c.contype = 'f' AND cardinality(c.conkey) = 1 AND c.conrelid = to_regclass('$1') AND c.confrelid = to_regclass('$2')"; }
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
# a product for user :'u' with a given stripe id (status/price/stock always valid)
P="jsonb_build_object('application_user', :'u', 'status', 'LISTED', 'price', 10, 'stock_level', 1, 'stripe_id'"

echo "Tier 1 - Users and products"
t "
SELECT pg_temp.expect(pg_temp.has_pk('application_user'), 'primary key');
SELECT pg_temp.expect(pg_temp.notnull('application_user', 'email'), 'email required');
SELECT pg_temp.ins('application_user', '{\"email\": \"zz-a@ticktrade.io\"}');
SELECT pg_temp.ins('application_user', '{\"email\": \"zz-b@ticktrade.io\"}');
SELECT pg_temp.expect(pg_temp.no_ins('application_user', '{\"email\": \"zz-a@ticktrade.io\"}'), 'duplicate email rejected');
" && ok "1.2 application_user: primary key, email required and unique" \
  || no "1.2 application_user needs a primary key and email NOT NULL UNIQUE"

t "
SELECT pg_temp.expect(pg_temp.has_pk('product'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('product', 'application_user', true), 'NOT NULL FK to application_user');
SELECT pg_temp.expect(pg_temp.notnull('product', 'name') AND pg_temp.notnull('product', 'price')
  AND pg_temp.notnull('product', 'stock_level') AND pg_temp.notnull('product', 'status'), 'required columns');
SELECT pg_temp.expect(pg_temp.has_col('product', 'stripe_id'), 'stripe_id column');
SELECT pg_temp.ins('application_user') AS u \gset
SELECT pg_temp.ins('product', $P, 'zz-s1'));
SELECT pg_temp.ins('product', $P, 'zz-s2') || jsonb_build_object('status', 'DRAFT'));
SELECT pg_temp.ins('product', $P, 'zz-s3') || jsonb_build_object('status', 'ARCHIVED', 'price', 0, 'stock_level', 0));
SELECT pg_temp.expect(pg_temp.no_ins('product', $P, 'zz-s1')), 'duplicate stripe_id rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product', $P, 'zz-s4') || jsonb_build_object('price', -1)), 'negative price rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product', $P, 'zz-s5') || jsonb_build_object('stock_level', -1)), 'negative stock rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product', $P, 'zz-s6') || jsonb_build_object('status', 'SOLD')), 'unknown status rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product', $P, 'zz-s7') || jsonb_build_object('application_user', null)), 'no seller rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product', $P, 'zz-s8') || jsonb_build_object('application_user', pg_temp.ghost('application_user'))), 'missing seller rejected');
" && ok "1.3 product: one seller, many products each; price/stock never negative, status DRAFT/LISTED/ARCHIVED, unique stripe_id" \
  || no "1.3 product needs a NOT NULL FK to application_user, name/price/stock_level/status NOT NULL, CHECKs (price >= 0, stock_level >= 0, status in DRAFT/LISTED/ARCHIVED), stripe_id UNIQUE"

echo "Tier 2 - Images, stars and reviews"
t "
SELECT pg_temp.expect(pg_temp.has_pk('product_image'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('product_image', 'product', true), 'NOT NULL FK to product');
SELECT pg_temp.expect(EXISTS (SELECT 1 FROM pg_attribute a JOIN pg_type ty ON ty.oid = a.atttypid
  WHERE a.attrelid = 'product_image'::regclass AND a.attnum > 0 AND NOT a.attisdropped AND a.attnotnull
    AND ty.typcategory = 'S' AND NOT EXISTS (SELECT 1 FROM pg_constraint c WHERE c.conrelid = a.attrelid
    AND c.contype IN ('p', 'f') AND a.attnum = ANY (c.conkey))), 'required URL column');
SELECT pg_temp.ins('application_user') AS u \gset
SELECT pg_temp.ins('product', $P, 'zz-s1')) AS p \gset
SELECT pg_temp.ins('product_image', jsonb_build_object('product', :'p'));
SELECT pg_temp.ins('product_image', jsonb_build_object('product', :'p'));
SELECT pg_temp.ins('product_image', jsonb_build_object('product', :'p'));
SELECT pg_temp.expect(pg_temp.no_ins('product_image', jsonb_build_object('product', null)), 'image without product rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product_image', jsonb_build_object('product', pg_temp.ghost('product', $P, 'zz-s2')))), 'missing product rejected');
" && ok "2.1 product_image: many images per product, each with a real product and a URL" \
  || no "2.1 product_image needs a primary key, a NOT NULL FK to product and a NOT NULL text column for the URL"

PAIR="
SELECT pg_temp.ins('application_user') AS u \gset
SELECT pg_temp.ins('application_user') AS u2 \gset
SELECT pg_temp.ins('product', $P, 'zz-s1')) AS p1 \gset
SELECT pg_temp.ins('product', $P, 'zz-s2')) AS p2 \gset"
t "
SELECT pg_temp.expect(pg_temp.has_pk('product_star'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('product_star', 'product', true) AND pg_temp.has_fk('product_star', 'application_user', true), 'NOT NULL FKs');
$PAIR
SELECT pg_temp.ins('product_star', jsonb_build_object('application_user', :'u', 'product', :'p1'));
SELECT pg_temp.ins('product_star', jsonb_build_object('application_user', :'u', 'product', :'p2'));
SELECT pg_temp.ins('product_star', jsonb_build_object('application_user', :'u2', 'product', :'p1'));
SELECT pg_temp.expect(pg_temp.no_ins('product_star', jsonb_build_object('application_user', :'u', 'product', :'p1')), 'second star rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product_star', jsonb_build_object('application_user', null, 'product', :'p2')), 'star without user rejected');
" && ok "2.2 product_star: many users x many products, each pair only once" \
  || no "2.2 product_star needs NOT NULL FKs to application_user and product and a composite PRIMARY KEY (or UNIQUE) on the pair"

t "
SELECT pg_temp.expect(pg_temp.has_pk('product_review'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('product_review', 'product', true) AND pg_temp.has_fk('product_review', 'application_user', true), 'NOT NULL FKs');
SELECT pg_temp.expect(pg_temp.notnull('product_review', 'rating'), 'rating required');
$PAIR
SELECT pg_temp.ins('application_user') AS u3 \gset
SELECT pg_temp.ins('product_review', jsonb_build_object('application_user', :'u', 'product', :'p1', 'rating', 5));
SELECT pg_temp.ins('product_review', jsonb_build_object('application_user', :'u', 'product', :'p2', 'rating', 1));
SELECT pg_temp.ins('product_review', jsonb_build_object('application_user', :'u2', 'product', :'p1', 'rating', 4));
SELECT pg_temp.expect(pg_temp.no_ins('product_review', jsonb_build_object('application_user', :'u3', 'product', :'p1', 'rating', 6)), 'rating 6 rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product_review', jsonb_build_object('application_user', :'u3', 'product', :'p1', 'rating', 0)), 'rating 0 rejected');
SELECT pg_temp.ins('product_review', jsonb_build_object('application_user', :'u3', 'product', :'p1', 'rating', 3));
SELECT pg_temp.expect(pg_temp.no_ins('product_review', jsonb_build_object('application_user', :'u', 'product', :'p1', 'rating', 2)), 'second review rejected');
" && ok "2.3 product_review: rating 1-5 required, one review per user per product" \
  || no "2.3 product_review needs NOT NULL FKs to application_user and product, rating NOT NULL CHECK (rating BETWEEN 1 AND 5), UNIQUE on the user+product pair"

echo "Tier 3 - Buying and selling"
ORDER="jsonb_build_object('application_user', :'u2', 'product', :'p1', 'quantity'"
t "
SELECT pg_temp.expect(pg_temp.has_pk('product_order'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('product_order', 'product', true) AND pg_temp.has_fk('product_order', 'application_user', true), 'NOT NULL FKs');
SELECT pg_temp.expect(pg_temp.notnull('product_order', 'quantity'), 'quantity required');
$PAIR
SELECT pg_temp.ins('product_order', $ORDER, 1));
SELECT pg_temp.ins('product_order', $ORDER, 1));
SELECT pg_temp.ins('product_order', $ORDER, 3));
SELECT pg_temp.expect(pg_temp.no_ins('product_order', $ORDER, 0)), 'quantity 0 rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product_order', $ORDER, 1) || jsonb_build_object('application_user', null)), 'no buyer rejected');
SELECT pg_temp.expect(pg_temp.no_ins('product_order', $ORDER, 1) || jsonb_build_object('product', pg_temp.ghost('product', $P, 'zz-s9')))), 'missing product rejected');
" && ok "3.1 product_order: buyer + product required, quantity > 0, repeat purchases allowed" \
  || no "3.1 product_order needs its own primary key, NOT NULL FKs to application_user (buyer) and product, quantity NOT NULL CHECK (quantity > 0)"

t "
SELECT pg_temp.expect(pg_temp.has_pk('invoice'), 'primary key');
SELECT pg_temp.expect(pg_temp.has_fk('invoice', 'product_order', true), 'NOT NULL FK to product_order');
$PAIR
SELECT pg_temp.ins('product_order', $ORDER, 1)) AS o1 \gset
SELECT pg_temp.ins('product_order', $ORDER, 1)) AS o2 \gset
SELECT pg_temp.ins('invoice', jsonb_build_object('product_order', :'o1'));
SELECT pg_temp.ins('invoice', jsonb_build_object('product_order', :'o2'));
SELECT pg_temp.expect(pg_temp.no_ins('invoice', jsonb_build_object('product_order', :'o1')), 'second invoice rejected');
SELECT pg_temp.expect(pg_temp.no_ins('invoice', jsonb_build_object('product_order', null)), 'invoice without order rejected');
SELECT pg_temp.expect(pg_temp.no_ins('invoice', jsonb_build_object('product_order', pg_temp.ghost('product_order', $ORDER, 1)))), 'missing order rejected');
" && ok "3.2 invoice: one-to-one with product_order - every invoice has an order, an order has at most one" \
  || no "3.2 invoice needs a NOT NULL foreign key to product_order that is also UNIQUE (or is the primary key itself)"

t "
SELECT pg_temp.pick('application_user', '{\"email\": \"ama@ticktrade.io\"}') AS ama \gset
SELECT pg_temp.pick('application_user', '{\"email\": \"kofi@ticktrade.io\"}') AS kofi \gset
SELECT pg_temp.pick('application_user', '{\"email\": \"zola@ticktrade.io\"}') AS zola \gset
SELECT pg_temp.pick('product', jsonb_build_object('application_user', :'ama', 'name', 'Mechanical Keyboard',
  'price', 89.99, 'stock_level', 5, 'status', 'LISTED')) AS kb \gset
SELECT pg_temp.pick('product', jsonb_build_object('application_user', :'ama', 'name', 'USB-C Hub',
  'price', 34.50, 'stock_level', 10, 'status', 'LISTED')) AS hub \gset
SELECT pg_temp.expect(pg_temp.cnt('product_image', jsonb_build_object('product', :'kb')) = 2, 'two keyboard images');
SELECT pg_temp.expect(pg_temp.cnt('product_star', jsonb_build_object('product', :'kb', 'application_user', :'kofi')) = 1, 'Kofi stars it');
SELECT pg_temp.expect(pg_temp.cnt('product_review', jsonb_build_object('product', :'kb', 'application_user', :'kofi', 'rating', 5)) = 1, 'Kofi rates it 5');
SELECT pg_temp.pick('product_order', jsonb_build_object('product', :'kb', 'application_user', :'kofi', 'quantity', 1)) AS o1 \gset
SELECT pg_temp.pick('product_order', jsonb_build_object('product', :'hub', 'application_user', :'kofi', 'quantity', 2)) AS o2 \gset
SELECT pg_temp.pick('product_order', jsonb_build_object('product', :'hub', 'application_user', :'zola', 'quantity', 1)) AS o3 \gset
SELECT pg_temp.expect(pg_temp.cnt('invoice', jsonb_build_object('product_order', :'o1')) = 1
  AND pg_temp.cnt('invoice', jsonb_build_object('product_order', :'o2')) = 1
  AND pg_temp.cnt('invoice', jsonb_build_object('product_order', :'o3')) = 1, 'every order invoiced');
" && ok "3.3 Ama's two listings, the keyboard's images/star/review, three invoiced orders by Kofi and Zola" \
  || no "3.3 add the 3 users, Ama's 2 LISTED products (+2 keyboard images), Kofi's star, 5-star review and 2 orders, Zola's order, and an invoice per order"

ppk="$(pkcol product)"; upk="$(pkcol application_user)"; opk="$(fkcols product_order product | head -1)"
ou="$(fkcols product_order application_user | sed "s/.*/u.\"$upk\" = o.\"&\"/" | paste -sd'|' - | sed 's/|/ OR /g')"
want=""
[[ -n "$ppk" && -n "$upk" && -n "$opk" && -n "$ou" ]] && want="$(q "SELECT p.name, p.price, o.quantity FROM product_order o
    JOIN product p ON p.\"$ppk\" = o.\"$opk\" JOIN application_user u ON ($ou) WHERE u.email = 'kofi@ticktrade.io'")"
[[ -s "$SB/3.4.sql" && -n "$want" ]] && diff <(run "$SB/3.4.sql" "$DB" | sort) <(sort <<<"$want") >/dev/null \
  && ok "3.4 3.4.sql lists Kofi's purchases: product name, price and quantity per order" \
  || no "3.4 after 3.3, 3.4.sql: name, price, quantity of every order placed by kofi@ticktrade.io (orders JOIN products JOIN users)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 A marketplace schema from a blank page: every rule of the brief enforced by the database."
