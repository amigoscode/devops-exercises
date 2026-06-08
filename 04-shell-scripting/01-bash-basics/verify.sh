#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Bash Basics scripts by running them.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=01-bash-basics' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }

echo "Tier 1 - Your first scripts"
# 1.1 - executable, has a shebang, prints the greeting
if [[ -f "$SB/hello.sh" ]] && head -1 "$SB/hello.sh" | grep -q '^#!' \
   && [[ -x "$SB/hello.sh" ]] && "$SB/hello.sh" 2>/dev/null | grep -q 'Hello, DevOps'; then
  ok "1.1 hello.sh: shebang + executable + prints 'Hello, DevOps'"
else
  no "1.1 hello.sh must start with a shebang, be executable (chmod +x), and echo 'Hello, DevOps'"
fi
# 1.2 - uses a variable
if [[ -f "$SB/count.sh" ]] && [[ "$(bash "$SB/count.sh" 2>/dev/null)" == *"Count is 3"* ]]; then
  ok "1.2 count.sh: stores 3 in a variable and prints 'Count is 3'"
else
  no "1.2 count.sh must set a variable to 3 and echo 'Count is 3' (use \$var interpolation)"
fi

echo "Tier 2 - Parameters & arithmetic"
# 2.1 - first parameter
if [[ -f "$SB/greet.sh" ]] && [[ "$(bash "$SB/greet.sh" Sam 2>/dev/null)" == *"Hello, Sam"* ]] \
   && [[ "$(bash "$SB/greet.sh" Ada 2>/dev/null)" == *"Hello, Ada"* ]]; then
  ok "2.1 greet.sh: greets the name passed as the first parameter"
else
  no "2.1 greet.sh should print 'Hello, <name>' using the first parameter (\$1)"
fi
# 2.2 - arithmetic on two params (20+22=42 proves it's math, not string concat)
if [[ -f "$SB/add.sh" ]] && [[ "$(bash "$SB/add.sh" 20 22 2>/dev/null)" == *"42"* ]] \
   && [[ "$(bash "$SB/add.sh" 3 4 2>/dev/null)" == *"7"* ]]; then
  ok "2.2 add.sh: adds its two number parameters with arithmetic expansion"
else
  no "2.2 add.sh should print the sum of \$1 and \$2 using \$(( ... ))"
fi

echo "Tier 3 - Put it together"
# 3.1 - rectangle area (l*w) and perimeter (2*(l+w)) from params
if [[ -f "$SB/rect.sh" ]]; then
  out="$(bash "$SB/rect.sh" 5 8 2>/dev/null)"
  if [[ "$out" == *"40"* ]] && [[ "$out" == *"26"* ]]; then
    ok "3.1 rect.sh: computes area (40) and perimeter (26) for 5 x 8"
  else
    no "3.1 rect.sh should print the area (length*width) and perimeter (2*(length+width))"
  fi
else
  no "3.1 create rect.sh that takes length and width as parameters"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can write, parameterise and compute in Bash scripts."
