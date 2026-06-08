#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Linux Commands exercises.
set -uo pipefail
SB="$HOME/sandbox"
ZRC="$HOME/.zshrc"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=03-linux-commands' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
resolves(){ zsh -ic "alias $1" 2>/dev/null | grep -q "$2"; }

echo "Tier 1 - Commands have structure"
if [[ -f "$SB/hidden.txt" ]] && grep -q '\.secret' "$SB/hidden.txt"; then
  ok "1.1 found the hidden-files flag (.secret is listed)"
else
  no "1.1 hidden.txt should list the hidden .secret file - find the flag via 'ls --help' or 'man ls'"
fi
if [[ -f "$SB/today.txt" ]] && [[ "$(cat "$SB/today.txt" 2>/dev/null)" == "$(date +%F)" ]]; then
  ok "1.2 formatted today's date as YYYY-MM-DD"
else
  no "1.2 today.txt must hold today's date as YYYY-MM-DD (read 'date --help')"
fi

echo "Tier 2 - The art of finding help"
if [[ -f "$SB/apropos-space.txt" ]] && grep -qE '^du' "$SB/apropos-space.txt"; then
  ok "2.1 apropos surfaced 'du' from a description search"
else
  no "2.1 apropos-space.txt should contain the 'du' line (try: apropos 'space usage')"
fi
if [[ -f "$SB/where-is-du.txt" ]] && grep -qE '/bin/du' "$SB/where-is-du.txt"; then
  ok "2.2 located the du program with which"
else
  no "2.2 where-is-du.txt should hold du's path (try: which du > ~/sandbox/where-is-du.txt)"
fi
if [[ -f "$SB/long.txt" ]] && grep -qE '[-d][rwx-]{9}' "$SB/long.txt"; then
  ok "2.3 used the man-found flag for a long listing (permissions shown)"
else
  no "2.3 long.txt should be a long listing of ~/sandbox/files (use 'man ls' to find the flag)"
fi

echo "Tier 3 - Build your toolkit + on-call discovery"
kit_ok=true
resolves gl  "git log"     || kit_ok=false
resolves dps "docker ps"   || kit_ok=false
resolves kgp "kubectl get" || kit_ok=false
if $kit_ok; then
  ok "3.1 custom aliases (gl, dps, kgp) load and resolve in zsh"
else
  no "3.1 add gl/dps/kgp aliases to ~/.zshrc so they resolve (see README)"
fi
if [[ -f "$SB/disk-report.txt" ]] \
   && grep -qE '[0-9]+(\.[0-9]+)?[KMG]?\b' "$SB/disk-report.txt" \
   && grep -q 'files' "$SB/disk-report.txt"; then
  ok "3.2 produced a human-readable disk-usage report of ~/sandbox/files"
else
  no "3.2 disk-report.txt should hold a human-readable size for ~/sandbox/files (du -sh)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 You can find any command and its flags without memorising a thing."
