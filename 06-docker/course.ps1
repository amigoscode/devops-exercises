#!/usr/bin/env pwsh
# Launcher for Windows. Docker is the only thing you need installed.
#
# There is no bash on a stock Windows machine, so this runs the same runner
# scripts inside a tiny Alpine container that is wired to YOUR Docker daemon.
# Everything it seeds and grades is the real Docker state on your machine.
#
#   .\course.ps1 setup
#   .\course.ps1 start  01-containers
#   .\course.ps1 verify 01-containers
#   .\course.ps1 install          # get a `course` command that works in any folder
#
# If PowerShell blocks the script, use course.cmd instead - same thing, no
# execution-policy change needed.

$ErrorActionPreference = 'Continue'
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$image = 'devops-exercises/docker-course-runner'
$bin   = Join-Path $env:USERPROFILE '.local\bin'

# --- install / uninstall run on Windows itself, not in the container ----------

if ($args.Count -ge 1 -and $args[0] -eq 'install') {
    New-Item -ItemType Directory -Force -Path $bin | Out-Null
    $shim = Join-Path $bin 'course.cmd'
    @(
        '@echo off',
        'rem Installed by "course.cmd install". Delete this file to remove it.',
        ('powershell -NoProfile -ExecutionPolicy Bypass -File "{0}\course.ps1" %*' -f $here)
    ) | Set-Content -Path $shim -Encoding ASCII
    Write-Host "Installed: $shim"

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$bin*") {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$bin", 'User')
        Write-Host ""
        Write-Host "Added $bin to your PATH. Open a NEW terminal, then:"
    } else {
        Write-Host ""
        Write-Host "You can now run 'course' from any folder:"
    }
    Write-Host "  course verify 01-containers"
    Write-Host "  cd 06-docker\03-volumes; course verify"
    exit 0
}

if ($args.Count -ge 1 -and $args[0] -eq 'uninstall') {
    $shim = Join-Path $bin 'course.cmd'
    if (Test-Path $shim) {
        Remove-Item $shim -Force
        Write-Host "Removed: $shim"
    } else {
        Write-Host "Nothing to remove (no $shim)."
    }
    Write-Host "Left $bin on your PATH - remove it yourself if you want it gone."
    exit 0
}

# --- everything else runs the shared bash runner inside the helper container ---

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker is not installed. Install Docker Desktop from https://docs.docker.com/get-docker/"
    exit 1
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is installed but not running. Start Docker Desktop and try again."
    exit 1
}

docker image inspect $image *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Building the exercise runner (first run only, a few seconds)..."
    docker build -q -t $image "$here" *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Could not build the exercise runner. Check that Docker is running and you are online."
        exit 1
    }
}

# Tell the runner which folder you are standing in, so `course verify` with no
# section can work it out. Paths inside the container are rooted at /course.
$cwd = (Get-Location).Path
if ($cwd.ToLower().StartsWith($here.ToLower())) {
    $rel = $cwd.Substring($here.Length).TrimStart('\', '/')
    if ($rel) { $courseCwd = '/course/' + ($rel -replace '\\', '/') } else { $courseCwd = '/course' }
} else {
    $courseCwd = '/'
}

docker run --rm `
    -e COURSE_LAUNCHER=course.cmd `
    -e "COURSE_CWD=$courseCwd" `
    -v /var/run/docker.sock:/var/run/docker.sock `
    -v "${here}:/course" `
    -w /course `
    --add-host host.docker.internal:host-gateway `
    $image @args

exit $LASTEXITCODE
