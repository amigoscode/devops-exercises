@echo off
rem Repo-root launcher for Windows (works in both cmd.exe and PowerShell).
rem
rem   course.cmd start  01-containers
rem   course.cmd verify 01-containers
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp006-docker\course.ps1" %*
