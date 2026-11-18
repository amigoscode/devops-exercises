#!/usr/bin/env bash
# Runs INSIDE the container. Gives you a clean place to write your scripts.
set -euo pipefail
SB="$HOME/sandbox"
rm -rf "$SB"; mkdir -p "$SB"
echo "Sandbox ready at ~/sandbox. Write your .sh scripts here."
echo "Reminder: start with a shebang (#!/bin/bash), chmod +x, run with ./name.sh"
