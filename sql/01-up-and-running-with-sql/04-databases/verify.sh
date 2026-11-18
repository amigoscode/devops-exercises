#!/usr/bin/env bash
# Runs INSIDE the container. Grades the databases on the server and the query and
# connection proof you saved in ~/sandbox.
set -uo pipefail
SB="$HOME/sandbox"; DB=student
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# has FILE PATTERN... - the file exists and contains every (extended regex) pattern
has(){ local f="$1"; shift; [[ -s "$f" ]] || return 1
  for p in "$@"; do grep -Eq -- "$p" "$f" || return 1; done; }
# run FILE DB - run a saved query inside a transaction that is rolled back
run(){ { echo 'BEGIN;'; cat "$1"; echo; echo ';'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# same_rows FILE REFSQL [DB] - FILE returns the same rows as the reference query (any order)
same_rows(){ local d="${3:-$DB}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d" | sort) <(sort <<<"$want") >/dev/null; }
# db NAME - the database exists
db(){ [[ "$(q "SELECT count(*) FROM pg_database WHERE datname = '$1'")" == 1 ]]; }
# rows DB TABLE - number of rows in a table of that database (empty if it isn't there)
rows(){ q "SELECT count(*) FROM $2" "$1"; }
# user_tables DB - number of tables you created in that database
user_tables(){ q "SELECT count(*) FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema')" "$1"; }

echo "Tier 1 - Create and connect"
db my_db \
  && ok "1.2 the my_db database exists" \
  || no "1.2 create a database called my_db (CREATE DATABASE my_db;)"
has "$SB/1.3.txt" '\bmy_db\b' '\bstudent\b' \
  && ok "1.3 1.3.txt: connected to my_db" \
  || no "1.3 \\c my_db, then \\o 1.3.txt, SELECT current_database(), current_user;, \\o"
same_rows "$SB/1.4.sql" "SELECT datname, datallowconn FROM pg_database WHERE datname = 'template0'" \
  && ok "1.4 1.4.sql: template0 does not allow connections (datallowconn = f)" \
  || no "1.4 save a query returning datname and datallowconn of template0 (from pg_database) as 1.4.sql"

echo "Tier 2 - Rename and drop"
if db test_db && ! db tset_db && [[ "$(rows test_db notes)" == 3 ]]; then
  ok "2.1 tset_db was renamed to test_db (notes table and its rows kept)"
else
  no "2.1 rename tset_db to test_db (ALTER DATABASE tset_db RENAME TO test_db;) - don't drop it"
fi
# "nothing else": the other seeded databases (renamed or not) still hold their data
if ! db old_app && db student && db postgres \
   && { [[ "$(rows test_db notes)" == 3 ]] || [[ "$(rows tset_db notes)" == 3 ]]; } \
   && { [[ "$(rows staging orders)" == 4 ]] || [[ "$(rows staging_old orders)" == 4 ]]; }; then
  ok "2.2 old_app is gone (and the other databases are still there)"
else
  no "2.2 drop the old_app database (DROP DATABASE old_app;) - only that one"
fi

echo "Tier 3 - Rename the database you're in"
if db staging_old && [[ "$(rows staging_old orders)" == 4 ]] && db staging && [[ "$(user_tables staging)" == 0 ]]; then
  ok "3.1 staging_old keeps the old data and staging is a fresh, empty database"
else
  no "3.1 rename staging to staging_old (connect to another database first), then create a new empty staging"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can create, connect to, rename and (carefully) drop databases."
