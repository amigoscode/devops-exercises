@echo off
rem Launcher for Windows (works in both cmd.exe and PowerShell).
rem Bypasses the PowerShell execution policy so students never have to change it.
rem
rem   course.cmd login
rem   course.cmd start  01-account-safety
rem   course.cmd verify 01-account-safety
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0course.ps1" %*
