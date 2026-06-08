#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Working with Directories exercises.
set -uo pipefail
SB="$HOME/sandbox"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=06-working-with-directories' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }
empty_dir(){ [[ -d "$1" ]] && [[ -z "$(ls -A "$1" 2>/dev/null)" ]]; }

echo "Tier 1 - Create dirs"
if [[ -d "$SB/builds" ]] && [[ -d "$SB/app/src/main" ]]; then
  ok "1.1 made a dir and a nested tree with mkdir -p"
else
  no "1.1 need ~/sandbox/builds and the nested ~/sandbox/app/src/main (mkdir -p)"
fi
if [[ ! -e "$SB/old-empty" ]] && [[ -d "$SB/has-stuff" ]]; then
  ok "1.2 rmdir removed the empty dir; left the non-empty one alone"
else
  no "1.2 rmdir ~/sandbox/old-empty (and leave has-stuff - rmdir refuses non-empty dirs)"
fi

echo "Tier 2 - Remove dirs (and respect the danger)"
if [[ ! -e "$SB/temp-build" ]]; then
  ok "2.1 rm -rf deleted temp-build and all its contents"
else
  no "2.1 rm -rf ~/sandbox/temp-build"
fi
if empty_dir "$SB/cache"; then
  ok "2.2 emptied cache/ but kept the folder"
else
  no "2.2 delete cache's contents but keep the folder (rm -rf ~/sandbox/cache/*)"
fi
if [[ -f "$SB/danger.txt" ]] && grep -q 'rm -rf /' "$SB/danger.txt"; then
  ok "2.3 named the command you must NEVER run"
else
  no "2.3 write the system-wiping command into ~/sandbox/danger.txt (the rm -rf / one)"
fi

echo "Tier 3 - Structure & archive a release"
if [[ -d "$SB/release/v2/bin" && -d "$SB/release/v2/config" && -d "$SB/release/v2/logs" ]] \
   && [[ -f "$SB/release/v2/VERSION" ]]; then
  ok "3.1 built release/v2/{bin,config,logs} + a VERSION file"
else
  no "3.1 mkdir -p release/v2/bin, .../config, .../logs and add a VERSION file inside v2"
fi
if [[ -f "$SB/release-v2.zip" ]] \
   && unzip -l "$SB/release-v2.zip" 2>/dev/null | grep -q 'VERSION' \
   && unzip -l "$SB/release-v2.zip" 2>/dev/null | grep -q 'release/v2'; then
  ok "3.2 zip -r archived the whole release directory"
else
  no "3.2 zip -r the release folder into ~/sandbox/release-v2.zip"
fi
if [[ ! -e "$SB/old releases" ]] && [[ -d "$SB/archived-releases" ]]; then
  ok "3.3 handled the space in the name and renamed the folder"
else
  no "3.3 rename 'old releases' (with a space) to archived-releases"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Directories: created, cleaned, archived - and you know the one command never to run."
