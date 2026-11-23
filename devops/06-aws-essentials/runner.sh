#!/usr/bin/env bash
# Exercise runner for "AWS Essentials".
#
# You normally do not call this directly - use the launcher for your machine:
#   macOS / Linux / WSL / Git Bash / Codespaces : ./course.sh  verify 01-account-safety
#   Windows (PowerShell or cmd)                 : course.cmd   verify 01-account-safety
#
# You build everything by clicking in the AWS console. This runner only CHECKS your
# work: it reads your real AWS account with the official AWS CLI, which runs in a
# Docker container, so Docker stays the only thing you install.
#
# `login` signs that CLI in to your account with `aws login`: you sign in in the
# browser with your normal console username and password, and the CLI gets
# short-lived credentials. No access keys, ever. The sign-in is kept in a Docker
# volume (not in this repo), so it can never end up in a commit.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The official AWS CLI, pinned so every student runs the same one, plus an SSH
# client (for checks that look inside a server you launched). Built locally from
# the official image on first use - nothing to download from us.
BASE_IMAGE="amazon/aws-cli:2.39.3"
IMAGE="devops-exercises/aws-checker:2.39.3"
SESSION_VOLUME="amigoscode-aws-session"
REGION="us-east-1"

sections() { (cd "$HERE" && ls -d [0-9]*-*/ 2>/dev/null | sed 's#/$##'); }

usage() {
  cat <<USAGE
AWS Essentials - exercise runner

  $LAUNCHER login                  sign the checker in to your AWS account (browser sign-in)
  $LAUNCHER whoami                 show which account and user the checker is signed in as
  $LAUNCHER logout                 forget the sign-in
  $LAUNCHER start   <section>      set up what the section needs, then build it in the console
  $LAUNCHER verify  <section>      check your work against your real AWS account
  $LAUNCHER reset   <section>      delete what the section created and set it up again
  $LAUNCHER stop    <section>      delete everything the section created
  $LAUNCHER list                   show the sections

<section> can be the full name or just enough to identify it:
  $LAUNCHER verify 01-account-safety
  $LAUNCHER verify account
  $LAUNCHER verify 1

Every check runs in region $REGION (US East, N. Virginia) - build your work there.

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
  if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Getting the AWS CLI (first time only, about a minute)..."
    # Built from stdin with no folder sent to Docker, so it works the same on every
    # OS and from inside the Academy's own container.
    printf 'FROM %s\nRUN dnf install -y -q openssh-clients && dnf clean all\n' "$BASE_IMAGE" \
      | docker build -q -t "$IMAGE" - >/dev/null \
      || { echo "Could not build the AWS checker from $BASE_IMAGE. Are you online?"; exit 1; }
  fi
}

# The AWS CLI, in its container, with the saved sign-in. Extra docker flags first,
# then a lone "--", then the aws arguments.
cli() {
  local flags=()
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do flags+=("$1"); shift; done
  [ "${1:-}" = "--" ] && shift
  docker run --rm -i ${flags[@]+"${flags[@]}"} \
    -v "$SESSION_VOLUME:/aws" -e HOME=/aws \
    -e AWS_REGION="$REGION" -e AWS_PAGER="" \
    "$IMAGE" "$@"
}

# Runs one of the section scripts (verify.sh, seed.sh, clean.sh) inside the CLI
# container. The script is streamed in on stdin together with lib/aws.sh, so no
# folder has to be mounted - this works the same on every OS and inside the Academy.
run_script() {
  cat "$HERE/lib/aws.sh" "$1" | docker run --rm -i \
    -v "$SESSION_VOLUME:/aws" -e HOME=/aws \
    -e AWS_REGION="$REGION" -e AWS_PAGER="" -e SECTION="$S" -e LAUNCHER="$LAUNCHER" \
    --entrypoint bash "$IMAGE" -s
}

signed_in() { cli -- sts get-caller-identity >/dev/null 2>&1; }

need_login() {
  signed_in && return 0
  echo "The checker is not signed in to your AWS account (or the sign-in expired)."
  echo "Sign in first:  $LAUNCHER login"
  exit 1
}

whoami_report() {
  local arn acct plan
  arn="$(cli -- sts get-caller-identity --query Arn --output text 2>/dev/null)" || {
    echo "Not signed in. Run: $LAUNCHER login"; return 1; }
  acct="$(cli -- sts get-caller-identity --query Account --output text 2>/dev/null)"
  echo "Account : $acct"
  case "$arn" in
    *:root) echo "Signed in as : the root user" ;;
    *)      echo "Signed in as : ${arn##*/}  ($arn)" ;;
  esac
  echo "Region  : $REGION"
  plan="$(cli -- freetier get-account-plan-state \
    --query '[accountPlanType, accountPlanRemainingCredits.amount, accountPlanExpirationDate]' \
    --output text 2>/dev/null || true)"
  # shellcheck disable=SC2086
  set -- $plan
  if [ "${1:-}" = FREE ]; then
    echo "Plan    : Free plan - \$${2:-?} credits left, ends ${3%%T*}"
  else
    echo "Plan    : not the Free plan - anything left running is billed to your card"
  fi
}

# Accepts "01-account-safety", "account" or "1" and prints the real section name.
resolve() {
  local want="${1%/}" hits n
  if [ -d "$HERE/$want" ]; then echo "$want"; return 0; fi
  # A number means the section with that number ("3" is 03-iam, never 04-s3);
  # anything else is a part of the name ("s3", "account").
  case "$want" in
    *[!0-9]*|"") hits="$(sections | grep -iF -- "$want" || true)" ;;
    *)           hits="$(sections | grep -E "^0*${want}-" || true)" ;;
  esac
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

# Works out the section from the folder you are standing in. Prints nothing if we
# are not inside one.
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

# Sets S and SRC for the requested section.
pick() {
  local want="${1:-}"
  if [ -z "$want" ]; then
    want="$(from_cwd)" || {
      echo "Which section? e.g. $LAUNCHER $CMD 01-account-safety"
      echo "(or cd into a section folder and run '$LAUNCHER $CMD' with no arguments)"
      exit 1
    }
    echo "Section: $want  (from the folder you are in)"
  fi
  S="$(resolve "$want")" || exit 1
  SRC="$HERE/$S"
}

# A section's seed.sh creates what earlier sections would have built (a role, a
# VPC...), so every section can be done on its own. Sections without one need nothing.
seed() {
  [ -f "$SRC/seed.sh" ] || return 0
  need_login
  run_script "$SRC/seed.sh" || { echo "Setting up $S failed (see above)."; return 1; }
}

clean() {
  [ -f "$SRC/clean.sh" ] || return 0
  need_login
  run_script "$SRC/clean.sh"
}

LAUNCHER="${COURSE_LAUNCHER:-./course.sh}"
CMD="${1:-help}"
shift || true

case "$CMD" in
  login)
    need_docker
    tty=(); [ -t 0 ] && [ -t 1 ] && tty=(-t)
    cli -- configure set region "$REGION" >/dev/null
    echo "Signing the checker in to your AWS account."
    echo
    echo "  1. Open the link below in your browser and sign in to AWS as usual."
    echo "  2. AWS then shows you a code. Copy it, paste it here and press Enter."
    echo
    cli ${tty[@]+"${tty[@]}"} -- login --remote || { echo; echo "Sign-in did not finish. Run '$LAUNCHER login' to try again."; exit 1; }
    echo
    whoami_report
    ;;

  whoami)
    need_docker
    whoami_report || exit 1
    ;;

  logout)
    need_docker
    docker volume rm "$SESSION_VOLUME" >/dev/null 2>&1 || true
    echo "Signed out. The checker no longer has access to your AWS account."
    ;;

  start)
    need_docker; pick "${1:-}"
    mkdir -p "$HERE/sandbox/$S"
    seed || exit 1
    echo
    echo "Ready: $S. Build it in the AWS console (region $REGION), then:"
    if [ "$LAUNCHER" = academy ]; then echo "  check"; else echo "  $LAUNCHER verify $S"; fi
    ;;

  verify)
    need_docker; pick "${1:-}"
    run_script "$SRC/verify.sh"
    ;;

  reset)
    need_docker; pick "${1:-}"
    clean || true
    mkdir -p "$HERE/sandbox/$S"
    seed || exit 1
    echo "Reset $S. Fresh start."
    ;;

  stop)
    need_docker; pick "${1:-}"
    clean || true
    rm -rf "${HERE:?}/sandbox/$S"
    echo "Cleaned up $S."
    ;;

  list)
    sections
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
