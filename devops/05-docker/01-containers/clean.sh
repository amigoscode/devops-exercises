#!/usr/bin/env bash
# Removes only the containers this section uses. Your other containers are untouched.
docker rm -f web game scratch old-web >/dev/null 2>&1 || true
