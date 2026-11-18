#!/usr/bin/env bash
# Repo-root launcher for the Docker course exercise runner.
# Works from here; from inside devops/05-docker/ use ./course.sh there, or run
# `./course.sh install` once to get a `course` command that works in any folder.
#
#   ./course.sh start  01-containers
#   ./course.sh verify 01-containers
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_LAUNCHER="./course.sh" exec bash "$HERE/devops/05-docker/runner.sh" "$@"
