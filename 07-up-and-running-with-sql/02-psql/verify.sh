#!/usr/bin/env bash
# Runs INSIDE the container. Grades the psql output you saved in ~/sandbox and the
# table you created in the "student" database.
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

echo "Tier 1 - Getting around psql"
has "$SB/roles.txt" 'List of roles' '\bpostgres\b' '\bstudent\b' 'Superuser' \
  && ok "1.3 roles.txt holds the \\du list of roles (postgres, student)" \
  || no "1.3 save the output of \\du in roles.txt (\\o roles.txt, \\du, \\o)"

echo "Tier 2 - Meta-commands that list things"
has "$SB/databases.txt" 'List of databases' '\btemplate0\b' '\btemplate1\b' '\bpostgres\b' '\bstudent\b' \
  && ok "2.1 databases.txt holds the list of databases" \
  || no "2.1 save the list of databases (\\l) in databases.txt"
has "$SB/schemas.txt" 'List of schemas' '\bpublic\b' \
  && ok "2.2 schemas.txt holds the list of schemas" \
  || no "2.2 save the list of schemas (\\dn) in schemas.txt"
if [[ "$(q "SELECT count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'foo'")" == 1 ]] \
   && [[ "$(q "SELECT count(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'foo'")" == 0 ]] \
   && has "$SB/tables.txt" 'List of (relations|tables)' '\bfoo\b' '\btable\b'; then
  ok "2.3 table foo exists (no columns) and tables.txt lists it"
else
  no "2.3 CREATE TABLE foo (); in the student database, keep it, and save \\dt in tables.txt"
fi

echo "Tier 3 - Run a script"
has "$SB/report.txt" 'RECORD 1' '^connected_as +\| student' '^server_version +\| 16' '^port +\| 5432' \
  && ok "3.1 report.txt holds report.sql's result in expanded display" \
  || no "3.1 run report.sql with \\i, expanded display on (\\x), output sent to report.txt (\\o)"

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can find your way around psql - help, meta-commands, files and all."
