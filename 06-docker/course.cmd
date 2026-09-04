@echo off
rem Launcher for Windows (works in both cmd.exe and PowerShell).
rem Bypasses the PowerShell execution policy so students never have to change it.
rem
rem   course.cmd setup
rem   course.cmd start  01-containers
rem   course.cmd verify 01-containers
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0course.ps1" %*
