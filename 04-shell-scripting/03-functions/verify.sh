#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Functions scripts by running them.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=03-functions' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
runq(){ bash "$SB/$1" "${@:2}" 2>/dev/null; }

echo "Tier 1 - Define & call a function"
if [[ -f "$SB/hello-fn.sh" ]] && [[ "$(runq hello-fn.sh)" == *"Hello from a function"* ]]; then
  ok "1.1 hello-fn.sh: defines a function and calls it"
else
  no "1.1 hello-fn.sh should define a function that echoes 'Hello from a function', then call it"
fi

echo "Tier 2 - Functions with parameters"
if [[ -f "$SB/square.sh" ]] && [[ "$(runq square.sh 6)" == *36* ]] && [[ "$(runq square.sh 5)" == *25* ]]; then
  ok "2.1 square.sh: a function squares the number passed to the script"
else
  no "2.1 square.sh should pass \$1 to a function that prints its square (6 -> 36)"
fi
if [[ -f "$SB/greet-fn.sh" ]] && [[ "$(runq greet-fn.sh Sam)" == *"Hi, Sam"* ]] && [[ "$(runq greet-fn.sh Ada)" == *"Hi, Ada"* ]]; then
  ok "2.2 greet-fn.sh: a function greets the name passed in"
else
  no "2.2 greet-fn.sh should pass \$1 to a function that prints 'Hi, <name>'"
fi

echo "Tier 3 - A function with its own logic"
if [[ -f "$SB/maxof.sh" ]] && [[ "$(runq maxof.sh 3 8)" == *8* ]] && [[ "$(runq maxof.sh 10 2)" == *10* ]]; then
  ok "3.1 maxof.sh: a function returns the larger of two numbers"
else
  no "3.1 maxof.sh should pass \$1 and \$2 to a 'max' function that prints the bigger one (if/else inside)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can package logic into reusable functions."
