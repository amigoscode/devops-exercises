#!/usr/bin/env bash
# Runs INSIDE the container. Grades the query and the connection proofs you saved in
# ~/sandbox, and the password on your role.
set -uo pipefail
SB="$HOME/sandbox"; DB=student
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# run FILE DB - run a saved query inside a transaction that is rolled back, so
#               checking never changes anything
run(){ { echo 'BEGIN;'; cat "$1"; echo; echo ';'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# same_rows FILE REFSQL DB - FILE returns the same rows as the reference query (any order)
same_rows(){ local want; want="$(q "$2" "$3")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$3" | sort) <(sort <<<"$want") >/dev/null; }
# has FILE PATTERN... - the file exists and contains every (extended regex) pattern
has(){ local f="$1"; shift; [[ -s "$f" ]] || return 1
  for p in "$@"; do grep -Eq -- "$p" "$f" || return 1; done; }

echo "Tier 1 - What we have so far"
# Run where you'd expect it to change: the answer must follow the connection.
if [[ -s "$SB/1.2.sql" && "$(run "$SB/1.2.sql" student)" == "student|student|5432" \
      && "$(run "$SB/1.2.sql" postgres)" == "postgres|student|5432" ]]; then
  ok "1.2 1.2.sql returns the database, user and port you're connected to"
else
  no "1.2 save a query returning current_database(), current_user and current_setting('port'), in that order, with \\w 1.2.sql"
fi

echo "Tier 2 - Connecting to the server"
has "$SB/2.2.txt" '\bpostgres\b' '\bstudent\b' '\b5432\b' \
  && ok "2.2 2.2.txt: connected to the postgres database as student, port 5432" \
  || no "2.2 \\c postgres, then \\o 2.2.txt, \\i 1.2.sql, \\o"
if has "$SB/2.3.txt" '\bpostgres\b' '\bstudent\b' '(127\.0\.0\.1|::1)' '\b5432\b' \
   && [[ "$(q "SELECT rolpassword IS NOT NULL FROM pg_authid WHERE rolname = 'student'")" == t ]]; then
  ok "2.3 2.3.txt: connected over localhost:5432 to postgres as student, with a password"
else
  no "2.3 \\password, \\c postgres student localhost 5432, then send the query's result to 2.3.txt (\\o 2.3.txt ... \\o)"
fi

echo "Tier 3 - A second server"
same_rows "$SB/3.1.sql" "SELECT name, setting FROM pg_settings WHERE name IN ('port', 'data_directory', 'config_file', 'hba_file')" "$DB" \
  && ok "3.1 3.1.sql returns the name and setting of port, data_directory, config_file and hba_file" \
  || no "3.1 save a query on pg_settings returning name and setting of port, data_directory, config_file and hba_file as 3.1.sql"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You know what you're connected to - and how to connect to anything else."
