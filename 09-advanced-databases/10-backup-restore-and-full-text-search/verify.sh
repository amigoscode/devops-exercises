#!/usr/bin/env bash
# Runs INSIDE the container. Grades your backups by restoring them into scratch
# databases, your CSV exports by comparing them with the table, and your full-text
# search by running it. Saved queries run in a transaction that is rolled back.
set -uo pipefail
SB="$HOME/sandbox"; BK="$SB/backups"; DB=my_db; CHK=my_db_check
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB] - run SQL, bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# tx SQL - run statements in a rolled-back transaction; non-zero exit on the first error
tx(){ { echo 'BEGIN;'; printf '%s\n' "$1"; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>/dev/null; }
# run FILE - run a saved query in a rolled-back transaction
run(){ { echo 'BEGIN;'; cat "$1"; echo; echo ';'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>/dev/null; }
same_rows(){ local want; want="$(q "$2")"; [[ -s "$1" && -n "$want" ]] && diff <(run "$1" | sort) <(sort <<<"$want") >/dev/null; }
same_ordered(){ local want; want="$(q "$2")"; [[ -s "$1" && -n "$want" ]] && diff <(run "$1") <(cat <<<"$want") >/dev/null; }
scratch(){ dropdb --if-exists "$CHK" 2>/dev/null; createdb "$CHK" 2>/dev/null; }
# restored DB - the cars and articles made it into DB (counts from the original data)
restored(){ [[ "$(q 'SELECT count(*) FROM car' "$1")" == 15 && "$(q 'SELECT count(*) >= 30 FROM article' "$1")" == t ]]; }
DOC="to_tsvector('english', coalesce(title, '') || ' ' || coalesce(body, ''))"

echo "Tier 1 - Back up and restore"
f="$BK/backup.sql"
if [[ -s "$f" ]] && head -c 400 "$f" | grep -q 'PostgreSQL database dump' \
   && scratch && psql -X -q -d "$CHK" -f "$f" >/dev/null 2>&1 && restored "$CHK"; then
  ok "1.1 backup.sql is a plain-SQL dump of my_db that restores with psql"
else
  no "1.1 \\! pg_dump -d my_db -f backups/backup.sql (plain SQL; it must restore my_db's tables)"
fi

f="$BK/backup.tar"
if [[ -s "$f" ]] && pg_restore -l "$f" 2>/dev/null | grep -q 'Format: TAR' \
   && grep -q 'dbname: my_db$' <(pg_restore -l "$f" 2>/dev/null) \
   && scratch && { pg_restore -d "$CHK" "$f" >/dev/null 2>&1; restored "$CHK"; }; then
  ok "1.2 backup.tar is a tar-format dump of my_db that pg_restore can restore"
else
  no "1.2 \\! pg_dump -F t -d my_db -f backups/backup.tar"
fi

if restored my_db_from_dump \
   && [[ "$(q "SELECT count(*) FROM pg_constraint WHERE conrelid = 'car'::regclass AND contype = 'p'" my_db_from_dump)" == 1 ]]; then
  ok "1.3 my_db_from_dump holds the restored tables (data and constraints)"
else
  no "1.3 create the database my_db_from_dump and pg_restore backup.tar into it (\\! pg_restore -d my_db_from_dump backups/backup.tar)"
fi

f="$BK/all-dbs.sql"
if [[ -s "$f" ]] && head -c 400 "$f" | grep -q 'PostgreSQL database cluster dump' \
   && grep -q '^\\connect.* my_db$' "$f" && grep -q '^CREATE ROLE student;' "$f"; then
  ok "1.4 all-dbs.sql is a pg_dumpall of the whole server (roles + every database)"
else
  no "1.4 \\! pg_dumpall -f backups/all-dbs.sql"
fi

echo "Tier 2 - COPY and full-text search"
f="$BK/car.csv"
if [[ -s "$f" ]] && diff <(tr -d '\r' < "$f") <(q 'COPY car TO STDOUT WITH (FORMAT csv, HEADER)') >/dev/null; then
  ok "2.1 car.csv has a header row and every car"
else
  no "2.1 \\copy car TO 'backups/car.csv' DELIMITER ',' CSV HEADER"
fi

f="$BK/car2.csv"
want="$(q 'COPY (SELECT id, brand FROM car) TO STDOUT WITH (FORMAT csv, HEADER)')"
if [[ -s "$f" ]] && [[ "$(head -1 "$f" | tr -d '\r')" == "id,brand" ]] \
   && diff <(tail -n +2 "$f" | tr -d '\r' | sort) <(tail -n +2 <<<"$want" | sort) >/dev/null; then
  ok "2.2 car2.csv has just id and brand, with a header"
else
  no "2.2 \\copy (SELECT id, brand FROM car) TO 'backups/car2.csv' DELIMITER ',' CSV HEADER"
fi

same_rows "$SB/2.3.sql" "SELECT id, title FROM article WHERE $DOC @@ to_tsquery('english', 'postgresql & index')" \
  && ok "2.3 2.3.sql finds the articles about PostgreSQL AND indexes" \
  || no "2.3 2.3.sql: id, title WHERE to_tsvector('english', title || ' ' || body) @@ to_tsquery('english', 'postgresql & index')"

same_rows "$SB/2.4.sql" "SELECT id, title FROM article WHERE $DOC @@ phraseto_tsquery('english', 'full text search')" \
  && ok "2.4 2.4.sql finds the exact phrase 'full text search'" \
  || no "2.4 2.4.sql: id, title of articles with the phrase 'full text search' (phraseto_tsquery - the words together, in order)"

same_rows "$SB/2.5.sql" "SELECT id, title FROM article WHERE $DOC @@ to_tsquery('english', 'data:* & !mysql')" \
  && ok "2.5 2.5.sql finds words starting with 'data', minus anything about MySQL" \
  || no "2.5 2.5.sql: id, title of articles with a word starting with 'data' (data:*) that don't mention MySQL (!)"

echo "Tier 3 - Ship search, survive an accident"
MISMATCH="SELECT count(*) FROM article a, (VALUES ('postgresql'), ('index'), ('data:*'), ('phone'), ('full <-> text <-> search')) v(t)
          WHERE (a.search_vector @@ to_tsquery('english', v.t)) IS DISTINCT FROM
                (to_tsvector('english', coalesce(a.title, '') || ' ' || coalesce(a.body, '')) @@ to_tsquery('english', v.t))"
if [[ "$(q 'SELECT count(*) FROM article WHERE search_vector IS NULL')" == 0 && "$(q "$MISMATCH")" == 0 ]] \
   && [[ "$(q "SELECT count(*) FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid JOIN pg_am am ON am.oid = c.relam
              JOIN pg_attribute att ON att.attrelid = i.indrelid AND att.attnum = i.indkey[0]
              WHERE i.indrelid = 'article'::regclass AND am.amname = 'gin' AND att.attname = 'search_vector'")" -ge 1 ]] \
   && tx "SET LOCAL enable_seqscan = off; EXPLAIN SELECT id FROM article WHERE search_vector @@ to_tsquery('english', 'postgresql');" \
        | grep -q 'Index Scan'; then
  ok "3.1 every article has a search_vector (title + body), backed by a GIN index the planner uses"
else
  no "3.1 fill search_vector = to_tsvector('english', title || ' ' || body) for every row, then CREATE INDEX ... USING GIN (search_vector)"
fi

if [[ "$(tx "INSERT INTO article (title, body) VALUES ('Home brewing', 'A short guide to zymurgy.');
             UPDATE article SET title = title || ' (quokka edition)' WHERE id = 2;
             UPDATE article SET body = body || ' Wombats approve.' WHERE id = 4;
             SELECT (SELECT count(*) FROM article WHERE search_vector @@ to_tsquery('english', 'zymurgy')) || '|' ||
                    (SELECT count(*) FROM article WHERE search_vector @@ to_tsquery('english', 'quokka')) || '|' ||
                    (SELECT count(*) FROM article WHERE search_vector @@ to_tsquery('english', 'wombat'));")" == '1|1|1' ]]; then
  ok "3.2 search_vector stays in sync when articles are inserted or updated"
else
  no "3.2 add a BEFORE INSERT OR UPDATE trigger on article that sets NEW.search_vector from NEW.title and NEW.body"
fi

same_ordered "$SB/3.3.sql" "SELECT id, title FROM article WHERE $DOC @@ to_tsquery('english', 'postgresql & performance')
                            ORDER BY ts_rank($DOC, to_tsquery('english', 'postgresql & performance')) DESC, id" \
  && ok "3.3 3.3.sql lists the PostgreSQL performance articles, most relevant first" \
  || no "3.3 3.3.sql: id, title of articles matching 'postgresql & performance', ORDER BY ts_rank(search_vector, query) DESC"

if [[ "$(q "SELECT count(*) || '|' || md5(string_agg(id || '|' || article_id || '|' || author || '|' || body || '|' || created_at, E'\n' ORDER BY id)) FROM comment")" == '20|e12f54549e89286ee656f26c4b0161f4' ]] \
   && [[ "$(q 'SELECT count(*) FROM car')" == 15 ]]; then
  ok "3.4 all 20 comments are back from nightly.tar (and nothing else was overwritten)"
else
  no "3.4 restore ONLY the comment table's data from backups/nightly.tar into my_db (\\! pg_restore --data-only -t comment -d my_db backups/nightly.tar)"
fi
dropdb --if-exists "$CHK" 2>/dev/null

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Backups that restore and search that ranks - two things production can't live without."
