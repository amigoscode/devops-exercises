#!/usr/bin/env bash
# Runs INSIDE the container. Grades the queries you saved in ~/sandbox with \w.
set -uo pipefail
SB="$HOME/sandbox"; DB=student; REF="${DB}_ref"   # REF: untouched copy made by seed.sh
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# run FILE DB - run a saved query inside a transaction that is rolled back, so
#               checking never changes anything
run(){ { echo 'BEGIN;'; cat "$1"; echo; echo ';'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# same_rows FILE REFSQL [DB]    - FILE returns the same rows as the reference query
#                                 (any order). Default DB: the untouched copy.
same_rows(){ local d="${3:-$REF}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d" | sort) <(sort <<<"$want") >/dev/null; }

echo "Tier 1 - PostgreSQL is installed"
same_rows "$SB/1.2.sql" "SELECT version()" \
  && ok "1.2 1.2.sql asks the server for its version" \
  || no "1.2 run SELECT version(); then save it with \\w 1.2.sql"

echo "Tier 2 - Talk to the server"
same_rows "$SB/2.1.sql" "SHOW port" \
  && ok "2.1 2.1.sql returns the port the server listens on (5432)" \
  || no "2.1 save a query that returns the server's port as 2.1.sql (hint: SHOW port;)"
same_rows "$SB/2.2.sql" "SELECT pg_postmaster_start_time()" \
  && ok "2.2 2.2.sql returns when the server started" \
  || no "2.2 save a query that returns when the server started as 2.2.sql (pg_postmaster_start_time())"
same_rows "$SB/2.3.sql" "SELECT * FROM customers" \
  && ok "2.3 2.3.sql selects every column of every customer" \
  || no "2.3 save a query selecting all columns (*) of every row in customers as 2.3.sql"

echo "Tier 3 - Inside your installation"
same_rows "$SB/3.1.sql" "SHOW data_directory" \
  && ok "3.1 3.1.sql returns the server's data directory" \
  || no "3.1 save a query that returns the data directory as 3.1.sql (hint: SHOW)"
same_rows "$SB/3.2.sql" "SHOW config_file" \
  && ok "3.2 3.2.sql returns where postgresql.conf is" \
  || no "3.2 save a query that returns the configuration file's location as 3.2.sql (hint: SHOW)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 PostgreSQL is installed, running and answering your SQL."
