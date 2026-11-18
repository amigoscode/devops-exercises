#!/usr/bin/env bash
# Runs INSIDE the container. Grades your functions, procedure and triggers in the
# "platform" database by calling them. Every test runs in a transaction that is rolled
# back, so checking never changes your data.
set -uo pipefail
SB="$HOME/sandbox"; DB=platform
[[ -d "$SB" ]] || { echo "No sandbox. Open this section in the Academy (./academy.sh) and press enter first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
# q SQL - run SQL, bare output
q(){ psql -X -A -t -q -d "$DB" -c "$1" 2>/dev/null; }
# tx SQL - run statements in a transaction that is rolled back; non-zero exit on the first error
tx(){ { echo 'BEGIN;'; printf '%s\n' "$1"; echo 'ROLLBACK;'; } | psql -X -A -t -q -v ON_ERROR_STOP=1 -d "$DB" 2>/dev/null; }
# routine NAME KIND - how many routines of that name and kind (f = function, p = procedure)
routine(){ q "SELECT count(*) FROM pg_proc WHERE proname = '$1' AND prokind = '$2' AND pronamespace = 'public'::regnamespace"; }

echo "Tier 1 - Functions"
if [[ "$(routine add_numbers f)" == 1 ]] \
   && [[ "$(q "SELECT l.lanname || '|' || pg_get_function_result(p.oid) FROM pg_proc p JOIN pg_language l ON l.oid = p.prolang WHERE p.proname = 'add_numbers'")" == 'plpgsql|integer' ]] \
   && [[ "$(q 'SELECT add_numbers(10, 7)')" == 17 && "$(q 'SELECT add_numbers(-4, 4)')" == 0 && "$(q 'SELECT add_numbers(1000, 234)')" == 1234 ]]; then
  ok "1.1 add_numbers(10, 7) returns 17 (PL/pgSQL, RETURNS integer)"
else
  no "1.1 CREATE FUNCTION add_numbers(n1 INTEGER, n2 INTEGER) RETURNS INTEGER ... RETURN n1 + n2; ... LANGUAGE plpgsql"
fi

if [[ "$(routine account_balance f)" == 1 ]] \
   && [[ "$(q 'SELECT bool_and(account_balance(id) = balance) FROM account')" == t ]] \
   && [[ "$(tx "UPDATE account SET balance = 12.34 WHERE id = 2; SELECT account_balance(2);")" == 12.34 ]] \
   && [[ "$(q 'SELECT account_balance(999) IS NULL')" == t ]]; then
  ok "1.2 account_balance(id) returns that account's balance (NULL for an unknown account)"
else
  no "1.2 CREATE FUNCTION account_balance(acc_id INTEGER) RETURNS NUMERIC: SELECT balance INTO ... FROM account WHERE id = acc_id; RETURN it"
fi

echo "Tier 2 - Stored procedures and your first trigger"
RESET="UPDATE account SET balance = 100 WHERE id IN (1, 2);"
if [[ "$(routine transfer_funds p)" -ge 1 ]] \
   && [[ "$(tx "$RESET CALL transfer_funds(1, 2, 30); SELECT string_agg(balance::text, ' ' ORDER BY id) FROM account WHERE id IN (1, 2);")" == '70.00 130.00' ]]; then
  ok "2.1 CALL transfer_funds(1, 2, 30) moves 30.00 from account 1 to account 2"
else
  no "2.1 CREATE PROCEDURE transfer_funds(from_acc INT, to_acc INT, amount NUMERIC): debit from_acc, credit to_acc (run it with CALL)"
fi

if [[ "$(routine transfer_funds p)" -ge 1 ]] \
   && [[ "$(tx "$RESET CALL transfer_funds(1, 2, 100); SELECT string_agg(balance::text, ' ' ORDER BY id) FROM account WHERE id IN (1, 2);")" == '0.00 200.00' ]] \
   && ! tx "$RESET CALL transfer_funds(99, 2, 10);" >/dev/null \
   && ! tx "$RESET CALL transfer_funds(1, 2, 100.01);" >/dev/null \
   && ! tx "$RESET CALL transfer_funds(1, 99, 10);" >/dev/null; then
  ok "2.2 transfer_funds raises an error for an unknown sender, insufficient funds or an unknown receiver"
else
  no "2.2 make transfer_funds RAISE EXCEPTION when the sender doesn't exist (IF NOT FOUND), would go below 0, or the receiver doesn't exist"
fi

if [[ "$(tx "INSERT INTO app_user (email, full_name) VALUES ('t1@example.com', 'Test One');
             INSERT INTO app_user (email, full_name, signup_role) VALUES ('t2@example.com', 'Test Two', 'instructor');
             SELECT string_agg(r.role::text, ' ' ORDER BY u.email) FROM user_role r JOIN app_user u ON u.id = r.user_id
             WHERE u.email IN ('t1@example.com', 't2@example.com');")" == 'student instructor' ]]; then
  ok "2.3 a new app_user automatically gets a user_role row (their signup_role, or 'student')"
else
  no "2.3 add an AFTER INSERT trigger on app_user that inserts (NEW.id, COALESCE(NEW.signup_role, 'student')) into user_role"
fi

echo "Tier 3 - Triggers the platform relies on"
CERT="SELECT count(*) FROM certificate WHERE student_id = %s AND course_id = %s"
if [[ "$(tx "UPDATE course_enrollment SET progress = 100 WHERE id = 2;
             UPDATE course_enrollment SET progress = 100 WHERE id = 2;
             UPDATE course_enrollment SET progress = 80 WHERE id = 3;
             UPDATE course_enrollment SET progress = 100 WHERE id = 1;
             SELECT ($(printf "$CERT" 1 2)) || '|' || ($(printf "$CERT" 2 1)) || '|' || ($(printf "$CERT" 1 1));")" == '1|0|1' ]]; then
  ok "3.1 reaching 100% progress issues exactly one certificate (no duplicates, none below 100)"
else
  no "3.1 AFTER UPDATE trigger on course_enrollment: when NEW.progress = 100 and no certificate exists yet, insert one"
fi

AUD="SELECT count(*) || '|' || coalesce(string_agg(account_id || ':' || old_balance || '>' || new_balance, ' ' ORDER BY id), '') FROM account_audit"
if [[ "$(tx "DELETE FROM account_audit; UPDATE account SET balance = 100 WHERE id = 1; DELETE FROM account_audit;
             UPDATE account SET balance = balance - 10 WHERE id = 1;
             UPDATE account SET owner = 'Ana B' WHERE id = 1;
             UPDATE account SET balance = balance;
             $AUD;")" == '1|1:100.00>90.00' ]]; then
  ok "3.2 every balance change is logged in account_audit (old and new), and nothing else is"
else
  no "3.2 trigger on account: log (account_id, old_balance, new_balance) to account_audit only when the balance actually changes"
fi

if [[ "$(routine account_history f)" == 1 ]] \
   && [[ "$(tx "DELETE FROM account_audit;
             INSERT INTO account_audit (account_id, old_balance, new_balance, changed_at) VALUES
               (1, 100, 90, '2024-01-02'), (2, 5, 6, '2024-01-01'), (1, 90, 95, '2024-01-03'), (1, 50, 100, '2024-01-01');
             SELECT string_agg(old_balance || '>' || new_balance, ' ') FROM account_history(1);")" == '50.00>100.00 100.00>90.00 90.00>95.00' ]] \
   && [[ "$(tx "DELETE FROM account_audit; SELECT count(*) FROM account_history(1);")" == 0 ]]; then
  ok "3.3 account_history(1) returns that account's changes, oldest first"
else
  no "3.3 CREATE FUNCTION account_history(acc_id INT) RETURNS TABLE (changed_at, old_balance, new_balance) ... ORDER BY changed_at"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Functions, procedures and triggers done - logic that lives next to the data."
