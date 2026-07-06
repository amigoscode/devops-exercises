#!/usr/bin/env bash
# Removes only this section's container.
docker rm -f buggy >/dev/null 2>&1 || true
