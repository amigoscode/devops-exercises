#!/usr/bin/env bash
# Runs INSIDE the container. Grades your indexes by asking the planner (EXPLAIN) whether
# it uses them, plus the query and the plans you saved in the sandbox folder.
set -uo pipefail
SB="$HOME/sandbox"; DB=my_db
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB]  - run SQL (default: the student's database), bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# tq SQL - run SQL inside a transaction that is rolled back (nothing changes)
tq(){ printf 'BEGIN;\n%s;\nROLLBACK;\n' "$1" | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>/dev/null; }
rejects(){ ! tq "$1" >/dev/null; }
# run FILE DB - run a saved query inside a transaction that is rolled back
run(){ { echo 'BEGIN;'; cat "$1"; printf '\n;\n'; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$2" 2>/dev/null; }
# same_rows FILE REFSQL [DB] - FILE returns the same rows as the reference query (any order)
same_rows(){ local d="${3:-$DB}" want; want="$(q "$2" "$d")"
  [[ -s "$1" && -n "$want" ]] && diff <(run "$1" "$d" | sort) <(sort <<<"$want") >/dev/null; }
# indexes COLS [extra SQL condition] - names of employee indexes on exactly COLS (in order)
indexes(){ q "SELECT string_agg(c.relname, ' ') FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
  WHERE i.indrelid = 'employee'::regclass ${2:-} AND (SELECT string_agg(a.attname, ',' ORDER BY k.n)
    FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, n)
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum) = '$1'"; }
# planner_uses "INDEX NAMES" QUERY - EXPLAIN QUERY scans one of these indexes
planner_uses(){ local plan n; plan="$(q "EXPLAIN $2")"; [[ -n "$1" ]] || return 1
  for n in $1; do grep -Eq "(using|on) $n( |$)" <<<"$plan" && return 0; done; return 1; }

echo "Tier 1 - Indexes in action"
idx="$(indexes name "AND i.indpred IS NULL")"
planner_uses "$idx" "SELECT * FROM employee WHERE name = 'c4ca4238a0b923820dcc509a6f75849b'" \
  && ok "1.2 there's an index on employee(name) and the planner uses it ($idx)" \
  || no "1.2 CREATE INDEX idx_employee_name ON employee (name); then EXPLAIN a WHERE name = ... query"

[[ -z "$(q "SELECT 1 FROM pg_class WHERE relname = 'idx_employee_is_manager'")" ]] \
  && [[ "$(q "SELECT count(*) FROM pg_constraint WHERE conrelid = 'employee'::regclass AND contype = 'p'")" == 1 ]] \
  && ok "1.3 idx_employee_is_manager is gone (the primary key is still there)" \
  || no "1.3 DROP INDEX idx_employee_is_manager; - and keep the primary key"

same_rows "$SB/1.4.sql" "SELECT indexrelname, pg_size_pretty(pg_relation_size(indexrelid)) FROM pg_stat_user_indexes WHERE relname = 'employee'" \
  && ok "1.4 1.4.sql lists every employee index with its pretty size" \
  || no "1.4 1.4.sql must list indexrelname and pg_size_pretty(pg_relation_size(indexrelid)) FROM pg_stat_user_indexes WHERE relname = 'employee'"

echo "Tier 2 - Partial and multi-column indexes, reading plans"
idx="$(indexes termination_date "AND pg_get_expr(i.indpred, i.indrelid) = '(termination_date IS NOT NULL)'")"
planner_uses "$idx" "SELECT count(*) FROM employee WHERE termination_date IS NOT NULL" \
  && ok "2.1 a partial index on termination_date (WHERE termination_date IS NOT NULL) serves the leavers count" \
  || no "2.1 CREATE INDEX idx_terminated_employee ON employee (termination_date) WHERE termination_date IS NOT NULL;"

idx="$(indexes department,hire_date "AND i.indpred IS NULL")"
planner_uses "$idx" "SELECT count(*) FROM employee WHERE department = 'SALES' AND hire_date > '2020-01-01'" \
  && ok "2.2 a (department, hire_date) index serves both filters - department first, so department-only queries can use it too" \
  || no "2.2 CREATE INDEX idx_department_hire_date ON employee (department, hire_date); - department must come first"

f="$SB/plan-by-id.txt"
[[ -s "$f" ]] && grep -q 'Index Scan using employee_pkey' "$f" && grep -q 'actual time' "$f" && grep -q 'Execution Time' "$f" \
  && ok "2.3 plan-by-id.txt holds an EXPLAIN ANALYZE plan using the primary key" \
  || no "2.3 \\o plan-by-id.txt, then EXPLAIN ANALYZE SELECT * FROM employee WHERE id = 4242; then \\o"

echo "Tier 3 - Make the login query fast"
f="$SB/before.txt"
[[ -s "$f" ]] && grep -q 'Seq Scan on employee' "$f" && grep -q "Filter: (email = 'employee4242@amigoscode.com'" "$f" && grep -q 'Execution Time' "$f" \
  && ok "3.1 before.txt shows the login query doing a full table scan (EXPLAIN ANALYZE)" \
  || no "3.1 before indexing: \\o before.txt, EXPLAIN ANALYZE the login query (WHERE email = 'employee4242@amigoscode.com'), \\o"

uidx="$(indexes email "AND i.indisunique AND i.indpred IS NULL")"
if [[ "$(q "SELECT count(*) || ',' || count(DISTINCT email) || ',' || max(id) FROM employee")" == "200000,200000,200000" ]] \
   && planner_uses "$uidx" "SELECT id, name FROM employee WHERE email = 'employee4242@amigoscode.com'" \
   && rejects "INSERT INTO employee (name, department, hire_date, email) VALUES ('dup', 'HR', '2024-01-01', 'employee4242@amigoscode.com')"; then
  ok "3.2 the 50 later duplicates are gone and a unique index on email serves the login query"
else
  no "3.2 delete only the duplicate rows with the higher ids (200,000 must remain), then CREATE UNIQUE INDEX ... ON employee (email);"
fi

f="$SB/after.txt"
if [[ -s "$f" ]] && [[ -n "$uidx" ]] && grep -q 'Execution Time' "$f" \
   && grep -Eq "Index (Only )?Scan using ($(tr ' ' '|' <<<"$uidx")) on employee" "$f"; then
  ok "3.3 after.txt shows the login query using the unique email index"
else
  no "3.3 after 3.2: \\o after.txt, EXPLAIN ANALYZE the same login query, \\o - it must show an Index Scan on your email index"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Indexes & Query Analysis complete."
