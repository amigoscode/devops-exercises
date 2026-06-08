#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Error Handling scripts by running them.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=04-error-handling' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }

echo "Tier 1 - Exit codes"
bash "$SB/status.sh" >/dev/null 2>&1; rc=$?
if [[ -f "$SB/status.sh" ]] && [[ "$rc" == "42" ]]; then
  ok "1.1 status.sh: exits with code 42"
else
  no "1.1 status.sh should finish with exit code 42 (use 'exit 42')"
fi

echo "Tier 2 - Strict mode & \$?"
has_e=false; has_u=false; has_pf=false
if [[ -f "$SB/safe.sh" ]]; then
  grep -Eq 'set +-[a-z]*e'   "$SB/safe.sh" && has_e=true
  grep -Eq 'set +-[a-z]*u'   "$SB/safe.sh" && has_u=true
  grep -q  'pipefail'        "$SB/safe.sh" && has_pf=true
fi
if $has_e && $has_u && $has_pf && [[ "$(bash "$SB/safe.sh" 2>/dev/null)" == *"running safely"* ]]; then
  ok "2.1 safe.sh: enables strict mode (set -e, -u, -o pipefail) and runs"
else
  no "2.1 safe.sh should start with strict mode (set -e, -u, -o pipefail) then echo 'running safely'"
fi
if [[ -f "$SB/report.sh" ]] && [[ "$(bash "$SB/report.sh" 2>/dev/null)" == *"exit code: 2"* ]]; then
  ok "2.2 report.sh: runs a failing command and reports its exit code via \$?"
else
  no "2.2 report.sh: run a failing command (e.g. ls /nonexistent), then echo \"exit code: \$?\" (it's 2)"
fi

echo "Tier 3 - Validate input like a real script"
bash "$SB/deploy.sh" >/dev/null 2>&1; norc=$?
witharg="$(bash "$SB/deploy.sh" v1 2>/dev/null)"
if [[ -f "$SB/deploy.sh" ]] && [[ "$norc" -ne 0 ]] && [[ "$witharg" == *"deploying v1"* ]]; then
  ok "3.1 deploy.sh: errors out (non-zero) with no arg, deploys with one"
else
  no "3.1 deploy.sh: with no argument exit non-zero; with an argument print 'deploying <arg>'"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Your scripts fail loudly and safely - the mark of production-grade automation."
