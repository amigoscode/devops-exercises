#!/usr/bin/env bash
# Starts PostgreSQL, waits until it accepts connections, then runs the command
# (your shell). Used as the image's entrypoint.
sudo service postgresql start >/dev/null 2>&1
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done
exec "$@"
