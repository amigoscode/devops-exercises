#!/usr/bin/env bash
# Runs INSIDE the container. Grades the "bank" database and the transaction scripts
# you saved with \w (in ~/sandbox). Each script runs, like \i would run it, on a FRESH copy of
# the original data (bank_ref), so your experiments in the live database don't count.
set -uo pipefail
SB="$HOME/sandbox"; DB=bank; REF="${DB}_ref"; CHK="${DB}_check"
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL [DB] - run SQL, bare output
q(){ psql -X -A -t -q -d "${2:-$DB}" -c "$1" 2>/dev/null; }
# fresh [SQL] - a new scratch copy of the original data, then optional SQL to set a scene
fresh(){ dropdb --if-exists "$CHK" 2>/dev/null; createdb -T "$REF" "$CHK" 2>/dev/null && { [[ -z "${1:-}" ]] || q "$1" "$CHK" >/dev/null; }; }
# script FILE - run a saved script on the scratch copy the way \i does (keeps going after
#               an error), printing the server's replies: BEGIN, UPDATE 1, ROLLBACK, ERROR...
script(){ psql -X -d "$CHK" -f "$1" </dev/null 2>&1; }
# bal [DB] - every balance, e.g. "1:100.00 2:100.00 ..."
bal(){ q "SELECT string_agg(id || ':' || balance, ' ' ORDER BY id) FROM account" "${1:-$CHK}"; }
ORIG='1:100.00 2:100.00 3:250.00 4:40.00 5:0.00'
has(){ grep -q -- "$2" <<<"$1"; }
last_tag(){ grep -E '^(BEGIN|COMMIT|ROLLBACK|START TRANSACTION|END|ABORT)$' <<<"$1" | tail -1; }

echo "Tier 1 - BEGIN, COMMIT and ROLLBACK"
if [[ "$(q 'SELECT balance FROM account WHERE id = 1')" == 95.00 && "$(q 'SELECT balance FROM account WHERE id = 2')" == 105.00 ]]; then
  ok "1.1 5.00 moved from Ana (1) to Ben (2): 95.00 / 105.00"
else
  no "1.1 in the live database: BEGIN; take 5.00 from account 1; add 5.00 to account 2; COMMIT; (1 = 95.00, 2 = 105.00)"
fi

f="$SB/1.3.sql"
if [[ -s "$f" ]] && fresh && out="$(script "$f")" && has "$out" 'UPDATE 1' && has "$out" 'UPDATE 0' \
   && [[ "$(last_tag "$out")" == ROLLBACK || "$(last_tag "$out")" == ABORT ]] && ! has "$out" 'no transaction in progress' \
   && [[ "$(bal)" == "$ORIG" ]]; then
  ok "1.3 1.3.sql debits account 1, finds no account 99, and rolls the whole thing back"
else
  no "1.3 1.3.sql: BEGIN; take 5.00 from account 1 (UPDATE 1); add it to account 99 (UPDATE 0); ROLLBACK; - nothing may change"
fi

echo "Tier 2 - Savepoints and isolation levels"
f="$SB/2.1.sql"
if [[ -s "$f" ]] && fresh && out="$(script "$f")" && has "$out" 'SAVEPOINT' && has "$out" 'UPDATE 6' \
   && [[ "$(q "SELECT count(*) || '|' || coalesce(max(balance)::text, '') FROM account WHERE owner = 'Fay'" "$CHK")" == '1|500.00' ]] \
   && [[ "$(q "SELECT string_agg(id || ':' || balance, ' ' ORDER BY id) FROM account WHERE owner <> 'Fay'" "$CHK")" == "$ORIG" ]]; then
  ok "2.1 2.1.sql keeps Fay's new account and undoes the 'everyone to 0' mistake with a savepoint"
else
  no "2.1 2.1.sql: BEGIN; add Fay (500.00); SAVEPOINT; set EVERY balance to 0; ROLLBACK TO SAVEPOINT; COMMIT;"
fi

f="$SB/2.2.sql"
if [[ -s "$f" ]] && fresh && out="$(script "$f")" && grep -Eq '^ *(repeatable read|serializable) *$' <<<"$out" \
   && has "$out" '490.00' && [[ "$(bal)" == "$ORIG" ]]; then
  ok "2.2 2.2.sql runs the balance report inside a REPEATABLE READ (or SERIALIZABLE) transaction"
else
  no "2.2 2.2.sql: BEGIN; SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; SHOW transaction_isolation; total of all balances; COMMIT;"
fi

echo "Tier 3 - Payments that can't lose money"
f="$SB/3.1.sql"
FAULT="CREATE FUNCTION fail_dev() RETURNS trigger AS \$\$ BEGIN IF NEW.id = 4 THEN RAISE EXCEPTION 'network down'; END IF; RETURN NEW; END \$\$ LANGUAGE plpgsql;
       CREATE TRIGGER fail_dev BEFORE UPDATE ON account FOR EACH ROW EXECUTE FUNCTION fail_dev();"
if [[ -s "$f" ]] \
   && fresh && script "$f" >/dev/null && [[ "$(bal)" == '1:100.00 2:100.00 3:220.00 4:70.00 5:0.00' ]] \
   && fresh "$FAULT" && script "$f" >/dev/null && [[ "$(bal)" == "$ORIG" ]] \
   && fresh "UPDATE account SET balance = 10 WHERE id = 3" && script "$f" >/dev/null \
   && [[ "$(bal)" == '1:100.00 2:100.00 3:10.00 4:40.00 5:0.00' ]]; then
  ok "3.1 3.1.sql moves 30.00 Carla -> Dev, and changes nothing when either step fails"
else
  no "3.1 3.1.sql must move 30.00 from 3 to 4 as ONE unit: if the credit or the debit fails, neither may happen"
fi

f="$SB/3.2.sql"
if [[ -s "$f" ]] && fresh && out="$(script "$f")" && has "$out" 'violates check constraint' \
   && [[ "$(bal)" == '1:100.00 2:100.00 3:230.00 4:60.00 5:0.00' ]]; then
  ok "3.2 3.2.sql keeps Carla's 20.00 to Dev after the failed 500.00 to Eve"
else
  no "3.2 3.2.sql: pay 20.00 3 -> 4, SAVEPOINT, try 500.00 3 -> 5 (it fails), ROLLBACK TO SAVEPOINT, COMMIT"
fi
dropdb --if-exists "$CHK" 2>/dev/null

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Transactions done - all or nothing, and checkpoints when you need them."
