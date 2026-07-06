#!/usr/bin/env bash
# Removes only the tags/images this section uses. Base images (nginx:alpine) are kept.
docker rmi -f dashboard:1 dashboard:2 dashboard:latest httpd:alpine busybox:1.36 >/dev/null 2>&1 || true
