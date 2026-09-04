#!/usr/bin/env bash
# Exercise runner for "Docker for Professionals".
#
# You normally do not call this directly - use the launcher for your machine:
#   macOS / Linux / WSL / Git Bash / Codespaces : ./course.sh  verify 01-containers
#   Windows (PowerShell or cmd)                 : course.cmd   verify 01-containers
#
# Launchers sit in the repo root and in 06-docker/, and `install` puts a `course`
# command on your PATH so any folder works. Nothing here depends on where you cd to.
#
# Docker itself is the subject of this course, so there is no container to drop
# into. You run `docker ...` commands in your own terminal and this runner grades
# the real Docker state your commands produced.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Base images the exercises build on. Pulled on demand by each seed, or all at once
# by `setup`.
IMAGES="nginx:alpine python:3-alpine python:3-slim redis:alpine postgres:16-alpine amigoscode/2048"

sections() { (cd "$HERE" && ls -d [0-9]*-*/ 2>/dev/null | sed 's#/$##'); }

usage() {
  cat <<USAGE
Docker for Professionals - exercise runner

  $LAUNCHER setup                  (optional) pre-pull the images the course uses
  $LAUNCHER start   <section>      seed the scenario, then run docker in your terminal
  $LAUNCHER verify  <section>      grade your work against the real Docker daemon
  $LAUNCHER reset   <section>      remove this section's artifacts and re-seed
  $LAUNCHER stop    <section>      clean up this section completely
  $LAUNCHER list                   show the sections
  $LAUNCHER install                add a 'course' command to your PATH (run from anywhere)
  $LAUNCHER uninstall              remove it again

<section> can be the full name or just enough to identify it:
  $LAUNCHER verify 01-containers
  $LAUNCHER verify containers
  $LAUNCHER verify 1

Inside a section folder you can leave it out entirely - the section is taken from
the folder you are standing in:
  cd 06-docker/03-volumes && $LAUNCHER verify

Sections:
$(sections | sed 's/^/  /')
USAGE
}

need_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed. Install Docker Desktop (Mac/Windows) or Docker Engine (Linux)."
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Docker is installed but not running. Start Docker and try again."
    exit 1
  fi
}

# Accepts "03-volumes", "volumes", "3" or "03" and prints the real section name.
resolve() {
  local want="${1%/}" hits n
  if [ -d "$HERE/$want" ]; then echo "$want"; return 0; fi
  hits="$(sections | grep -iE "^0*${want}-|${want}" || true)"
  n="$(printf '%s' "$hits" | grep -c . || true)"
  if [ "$n" = "1" ]; then
    echo "$hits"; return 0
  elif [ "$n" = "0" ]; then
    echo "No such section: $want" >&2
  else
    echo "'$want' matches more than one section:" >&2
    echo "$hits" | sed 's/^/  /' >&2
  fi
  echo "Sections:" >&2
  sections | sed 's/^/  /' >&2
  return 1
}

# Works out the section from the folder you are standing in, so that
#   cd 06-docker/03-volumes && course verify
# and
#   cd 06-docker/sandbox/03-volumes/site && course verify
# both know which section you mean. Prints nothing if we are not inside one.
from_cwd() {
  local cwd="${COURSE_CWD:-$PWD}" rel first
  case "$cwd" in
    "$HERE") return 1 ;;
    "$HERE"/*) rel="${cwd#"$HERE"/}" ;;
    *) return 1 ;;
  esac
  rel="${rel#sandbox/}"
  first="${rel%%/*}"
  [ -d "$HERE/$first" ] && [ -f "$HERE/$first/verify.sh" ] && { echo "$first"; return 0; }
  return 1
}

# Sets S, SRC and SB for the requested section.
pick() {
  local want="${1:-}"
  if [ -z "$want" ]; then
    want="$(from_cwd)" || {
      echo "Which section? e.g. $LAUNCHER $CMD 01-containers"
      echo "(or cd into a section folder and run '$LAUNCHER $CMD' with no arguments)"
      exit 1
    }
    echo "Section: $want  (from the folder you are in)"
  fi
  S="$(resolve "$want")" || exit 1
  SRC="$HERE/$S"
  SB="$HERE/sandbox/$S"
  export SB SRC
}

LAUNCHER="${COURSE_LAUNCHER:-./course.sh}"
CMD="${1:-help}"
shift || true

case "$CMD" in
  setup)
    need_docker
    for img in $IMAGES; do
      echo "pulling $img"
      docker pull -q "$img" >/dev/null
    done
    echo "Base images ready."
    ;;

  start)
    need_docker; pick "${1:-}"
    mkdir -p "$SB"
    bash "$SRC/seed.sh"
    echo
    echo "Seeded $S. Your working files (if any) are in: 06-docker/sandbox/$S"
    echo "Now run the docker commands from the README in this terminal, then:"
    echo "  $LAUNCHER verify $S"
    ;;

  verify)
    need_docker; pick "${1:-}"
    bash "$SRC/verify.sh"
    ;;

  reset)
    need_docker; pick "${1:-}"
    bash "$SRC/clean.sh" >/dev/null 2>&1 || true
    rm -rf "$SB"; mkdir -p "$SB"
    bash "$SRC/seed.sh"
    echo "Re-seeded $S. Fresh start."
    ;;

  stop)
    need_docker; pick "${1:-}"
    bash "$SRC/clean.sh" >/dev/null 2>&1 || true
    rm -rf "$SB"
    echo "Cleaned up $S (containers, images, volumes and networks it created)."
    ;;

  list)
    sections
    ;;

  install)
    # Drops a tiny `course` wrapper on your PATH so the command works in any folder,
    # inside this repo or outside it. It only ever points back at this checkout.
    BIN="${COURSE_BIN_DIR:-$HOME/.local/bin}"
    mkdir -p "$BIN" || { echo "Could not create $BIN"; exit 1; }
    cat > "$BIN/course" <<SHIM
#!/usr/bin/env bash
# Installed by '$LAUNCHER install'. Delete this file to remove it.
exec bash "$HERE/runner.sh" "\$@"
SHIM
    chmod +x "$BIN/course"
    echo "Installed: $BIN/course"
    if command -v course >/dev/null 2>&1 && [ "$(command -v course)" = "$BIN/course" ]; then
      echo
      echo "You can now run 'course' from any folder:"
      echo "  course verify 01-containers"
      echo "  cd 06-docker/03-volumes && course verify"
    else
      echo
      echo "$BIN is not on your PATH yet. Add it, then reopen your terminal:"
      case "${SHELL:-}" in
        *zsh)  echo "  echo 'export PATH=\"$BIN:\$PATH\"' >> ~/.zshrc" ;;
        *bash) echo "  echo 'export PATH=\"$BIN:\$PATH\"' >> ~/.bashrc" ;;
        *)     echo "  export PATH=\"$BIN:\$PATH\"" ;;
      esac
    fi
    ;;

  uninstall)
    BIN="${COURSE_BIN_DIR:-$HOME/.local/bin}"
    if [ -f "$BIN/course" ]; then
      rm -f "$BIN/course"
      echo "Removed: $BIN/course"
    else
      echo "Nothing to remove (no $BIN/course)."
    fi
    ;;

  help|-h|--help)
    usage
    ;;

  *)
    echo "Unknown command: $CMD"
    echo
    usage
    exit 1
    ;;
esac
