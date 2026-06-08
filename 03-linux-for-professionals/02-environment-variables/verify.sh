#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Environment Variables exercises.
# Values are read from a fresh interactive bash, so they must be PERSISTED in
# ~/.bashrc (not just set in your current session).
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=02-environment-variables' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
val(){ bash -ic "printf '%s' \"\$$1\"" 2>/dev/null; }     # value of $VAR from a fresh interactive shell

echo "Tier 1 - Persistent environment variables"
if [[ "$(val GREETING)" == "hello world" ]]; then
  ok "1.1 GREETING persists as 'hello world'"
else
  no "1.1 add  export GREETING=\"hello world\"  to ~/.bashrc"
fi
if [[ "$(val APP_ENV)" == "production" ]]; then
  ok "1.2 APP_ENV persists as 'production'"
else
  no "1.2 add  export APP_ENV=production  to ~/.bashrc"
fi

echo "Tier 2 - Aliases & PATH"
if bash -ic 'alias ll' 2>/dev/null | grep -q 'ls -lah'; then
  ok "2.1 'll' alias persists and resolves"
else
  no "2.1 add  alias ll='ls -lah'  to ~/.bashrc"
fi
if [[ -d "$HOME/bin" ]] && bash -ic 'printf %s "$PATH"' 2>/dev/null | tr ':' '\n' | grep -qx "$HOME/bin"; then
  ok "2.2 ~/bin exists and is on PATH"
else
  no "2.2 mkdir ~/bin and add  export PATH=\"\$HOME/bin:\$PATH\"  to ~/.bashrc"
fi

echo "Tier 3 - Make your own command on PATH"
if [[ -x "$HOME/bin/greet" ]] && [[ "$(bash -ic 'greet' 2>/dev/null)" == "ready to deploy" ]]; then
  ok "3.1 ~/bin/greet is executable and runs as a command -> 'ready to deploy'"
else
  no "3.1 create executable ~/bin/greet that echoes 'ready to deploy', then run it by name"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You understand env vars, PATH, and how Linux finds your commands."
