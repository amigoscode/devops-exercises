#!/usr/bin/env bash
# Launcher for macOS, Linux, WSL, Git Bash and GitHub Codespaces.
# Windows users without bash: run course.cmd instead.
#
#   ./course.sh setup
#   ./course.sh start  01-containers
#   ./course.sh verify 01-containers
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_LAUNCHER="./course.sh" exec bash "$HERE/runner.sh" "$@"
