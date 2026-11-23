#!/usr/bin/env bash
# Launcher for macOS, Linux, WSL, Git Bash and GitHub Codespaces.
# Windows users without bash: run course.cmd instead.
#
#   ./course.sh login
#   ./course.sh start  01-account-safety
#   ./course.sh verify 01-account-safety
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_LAUNCHER="./course.sh" exec bash "$HERE/runner.sh" "$@"
