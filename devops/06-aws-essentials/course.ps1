#!/usr/bin/env pwsh
# Launcher for Windows. Docker is the only thing you need installed.
#
# There is no bash on a stock Windows machine, so this runs the same runner
# script inside a tiny Alpine container that is wired to YOUR Docker daemon. The
# runner then starts the AWS CLI container that checks your AWS account.
#
#   .\course.ps1 login
#   .\course.ps1 start  01-account-safety
#   .\course.ps1 verify 01-account-safety
#
# If PowerShell blocks the script, use course.cmd instead - same thing, no
# execution-policy change needed.

$ErrorActionPreference = 'Continue'
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$image = 'devops-exercises/aws-course-runner'

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

# Tell the runner which folder you are standing in, so `course.cmd verify` with no
# section can work it out. Paths inside the container are rooted at /course.
$cwd = (Get-Location).Path
if ($cwd.ToLower().StartsWith($here.ToLower())) {
    $rel = $cwd.Substring($here.Length).TrimStart('\', '/')
    if ($rel) { $courseCwd = '/course/' + ($rel -replace '\\', '/') } else { $courseCwd = '/course' }
} else {
    $courseCwd = '/'
}

# `login` needs a real terminal to paste the sign-in code into.
$tty = @('-i')
if (-not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) { $tty = @('-it') }

docker run --rm @tty `
    -e COURSE_LAUNCHER=course.cmd `
    -e "COURSE_CWD=$courseCwd" `
    -v /var/run/docker.sock:/var/run/docker.sock `
    -v "${here}:/course" `
    -w /course `
    $image @args

exit $LASTEXITCODE
