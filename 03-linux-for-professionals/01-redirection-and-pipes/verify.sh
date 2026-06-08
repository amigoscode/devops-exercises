#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Redirection & Pipes exercises.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=01-redirection-and-pipes' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
lines(){ wc -l < "$1" 2>/dev/null | tr -d ' '; }

echo "Tier 1 - Redirect streams"
if [[ -f "$SB/etc.txt" ]] && grep -q 'passwd' "$SB/etc.txt"; then
  ok "1.1 redirected ls /etc into etc.txt ( > )"
else
  no "1.1 ls /etc > ~/sandbox/etc.txt"
fi
if [[ -f "$SB/deploy.log" ]] && grep -q 'Deploy started' "$SB/deploy.log" && grep -q 'Deploy finished' "$SB/deploy.log"; then
  ok "1.2 wrote then appended to deploy.log ( > then >> )"
else
  no "1.2 echo 'Deploy started' > deploy.log, then echo 'Deploy finished' >> deploy.log"
fi
if [[ -f "$SB/err.txt" ]] && grep -qi 'no such file' "$SB/err.txt"; then
  ok "1.3 captured an error stream into err.txt ( 2> )"
else
  no "1.3 redirect a failing command's error, e.g. ls /nope 2> ~/sandbox/err.txt"
fi

echo "Tier 2 - Pipe & filter"
if [[ -f "$SB/errors.txt" ]] && [[ "$(lines "$SB/errors.txt")" == "2" ]] && ! grep -qv 'ERROR' "$SB/errors.txt"; then
  ok "2.1 piped access.log through grep to keep only ERROR lines"
else
  no "2.1 cat access.log | grep ERROR > ~/sandbox/errors.txt (exactly the 2 ERROR lines)"
fi
if [[ -f "$SB/get-count.txt" ]] && grep -q '5' "$SB/get-count.txt"; then
  ok "2.2 counted the GET requests with grep | wc -l (5)"
else
  no "2.2 grep GET access.log | wc -l > ~/sandbox/get-count.txt (should be 5)"
fi
if [[ -f "$SB/sorted.txt" ]] && [[ "$(head -1 "$SB/sorted.txt")" == "alice" ]] && [[ "$(tail -1 "$SB/sorted.txt")" == "charlie" ]]; then
  ok "2.3 sorted names.txt via stdin redirection ( < )"
else
  no "2.3 sort < ~/sandbox/names.txt > ~/sandbox/sorted.txt (alice first, charlie last)"
fi

echo "Tier 3 - find + pipeline log triage"
if [[ -f "$SB/found.txt" ]] && grep -q 'app.log' "$SB/found.txt" && grep -q 'db.log' "$SB/found.txt" && grep -q 'web.log' "$SB/found.txt"; then
  ok "3.1 found all .log files with find"
else
  no "3.1 find ~/sandbox/logs -name '*.log' > ~/sandbox/found.txt"
fi
if [[ -f "$SB/error-count.txt" ]] && grep -q '3' "$SB/error-count.txt"; then
  ok "3.2 counted ERROR lines across all logs (3)"
else
  no "3.2 cat ~/sandbox/logs/*.log | grep ERROR | wc -l > ~/sandbox/error-count.txt (should be 3)"
fi
if [[ -f "$SB/errors-sorted.txt" ]] && [[ "$(lines "$SB/errors-sorted.txt")" == "3" ]] \
   && grep -q 'disk full' "$SB/errors-sorted.txt" && grep -q 'timeout' "$SB/errors-sorted.txt" \
   && [[ "$(head -1 "$SB/errors-sorted.txt")" == "ERROR disk full" ]]; then
  ok "3.3 saved all ERROR lines, sorted, to errors-sorted.txt"
else
  no "3.3 grep -h ERROR ~/sandbox/logs/*.log | sort > ~/sandbox/errors-sorted.txt"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can redirect, pipe and filter like a pro - the heart of Linux power-use."
