#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Conditions & Loops scripts by running them.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=02-conditions-and-loops' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
runq(){ bash "$SB/$1" "${@:2}" 2>/dev/null; }            # run a script, capture stdout

echo "Tier 1 - Decisions with if"
if [[ -f "$SB/check.sh" ]] \
   && [[ "$(runq check.sh 25)" == *adult* ]] && [[ "$(runq check.sh 10)" == *minor* ]]; then
  ok "1.1 check.sh: 'adult' for >=18, 'minor' otherwise"
else
  no "1.1 check.sh should print 'adult' if \$1 >= 18, else 'minor' (use if/else + a comparison operator)"
fi

echo "Tier 2 - Loops"
out="$(runq countup.sh)"
if [[ -f "$SB/countup.sh" ]] && grep -qw 1 <<<"$out" && grep -qw 2 <<<"$out" \
   && grep -qw 3 <<<"$out" && grep -qw 4 <<<"$out" && grep -qw 5 <<<"$out" && ! grep -qw 6 <<<"$out"; then
  ok "2.1 countup.sh: prints 1 through 5 with a loop"
else
  no "2.1 countup.sh should print the numbers 1 to 5 (use a for or while loop)"
fi
if [[ -f "$SB/sum.sh" ]] && [[ "$(runq sum.sh 5)" == *15* ]] && [[ "$(runq sum.sh 10)" == *55* ]]; then
  ok "2.2 sum.sh: adds up 1..N from a loop (sum 1..5 = 15)"
else
  no "2.2 sum.sh should sum the numbers from 1 to \$1 (loop + arithmetic accumulation)"
fi

echo "Tier 3 - Loop + decision together"
out="$(runq sizes.sh 5)"
small=$(grep -ow small <<<"$out" | wc -l | tr -d ' ')
big=$(grep -ow big <<<"$out" | wc -l | tr -d ' ')
if [[ -f "$SB/sizes.sh" ]] && [[ "$small" == "3" ]] && [[ "$big" == "2" ]]; then
  ok "3.1 sizes.sh: for 1..5 prints 'small' (<=3) or 'big' (>3) -> 3 small, 2 big"
else
  no "3.1 sizes.sh should loop 1..\$1 and print 'small' if the number <=3, else 'big'"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can branch and loop - the control flow behind every real script."
