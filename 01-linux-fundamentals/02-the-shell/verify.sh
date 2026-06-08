#!/usr/bin/env bash
# Runs INSIDE the container. Grades the Shell exercises.
set -uo pipefail
SB="$HOME/sandbox"
ZRC="$HOME/.zshrc"
[[ -d "$SB" ]] || { echo "No sandbox. Run 'make start S=02-the-shell' first."; exit 1; }

pass=0; fail=0
ok(){ printf '  ✅ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ❌ %s\n' "$1"; fail=$((fail+1)); }

# Does an alias actually resolve in an interactive zsh (proves .zshrc loads it)?
resolves(){ zsh -ic "alias $1" 2>/dev/null | grep -q "$2"; }

echo "Tier 1 - Discover the shells"
if [[ -f "$SB/shells.txt" ]] && grep -qi bash "$SB/shells.txt" && grep -qi zsh "$SB/shells.txt"; then
  ok "1.1 shells.txt lists the available shells (incl. bash & zsh)"
else
  no "1.1 shells.txt missing - run: cat /etc/shells > ~/sandbox/shells.txt"
fi

echo "Tier 2 - Configure your shell"
login_shell="$(getent passwd "$(whoami)" | cut -d: -f7)"
if [[ "$login_shell" == *zsh ]]; then
  ok "2.1 default login shell is now zsh"
else
  no "2.1 default shell is still '$login_shell' - use: sudo chsh -s \"\$(which zsh)\" \$USER"
fi
if [[ -f "$ZRC" ]] && grep -q "alias ll=" "$ZRC" && resolves ll "ls -lah"; then
  ok "2.2 ~/.zshrc defines a working 'll' alias"
else
  no "2.2 ~/.zshrc must define alias ll='ls -lah' (and it must load in zsh)"
fi
if [[ -f "$ZRC" ]] && grep -Eq '^[[:space:]]*ZSH_THEME=' "$ZRC"; then
  ok "2.3 ~/.zshrc sets a ZSH_THEME"
else
  no "2.3 add a theme line to ~/.zshrc, e.g. ZSH_THEME=\"agnoster\""
fi

echo "Tier 3 - Provision a productive shell"
team_ok=true
resolves gs "git status"        || team_ok=false
resolves k  "kubectl get pods"  || team_ok=false
resolves dc "docker compose"    || team_ok=false
if $team_ok; then
  ok "3.1 all team aliases (gs, k, dc) load and resolve in zsh"
else
  no "3.1 add gs/k/dc aliases to ~/.zshrc so they resolve (see README)"
fi
if [[ -f "$ZRC" ]] && grep -Eq '^[[:space:]]*plugins=\(.*\bgit\b.*\)' "$ZRC"; then
  ok "3.2 git plugin enabled in ~/.zshrc"
else
  no "3.2 enable the git plugin: a line like  plugins=(git)"
fi

echo
echo "Score: $pass passed, $fail failed."
[[ $fail -eq 0 ]] && echo "🎉 Fresh box, fully yours - zsh default, aliases live, theme set."
