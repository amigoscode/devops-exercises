#!/usr/bin/env pwsh
# Amigoscode Academy for Windows. Docker Desktop is the only thing you need.
#
#   .\academy.ps1     (or academy.cmd, which needs no execution-policy change)
#
# The first run builds a small image (about a minute); after that it starts instantly
# and only rebuilds when the academy's code changes.

$ErrorActionPreference = 'Continue'
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$image = 'amigoscode/academy:local'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker is not installed. Install Docker Desktop from https://docs.docker.com/get-docker/"
    exit 1
}
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is installed but not running. Start Docker Desktop and try again."
    exit 1
}

# Fingerprint the academy source; rebuild only when it changes.
$src = Join-Path $here 'academy'
$files = Get-ChildItem $src -File | Where-Object { $_.Name -match '\.(go|mod|sum)$' -or $_.Name -eq 'Dockerfile' } | Sort-Object Name
$joined = ($files | ForEach-Object { (Get-FileHash $_.FullName -Algorithm SHA256).Hash }) -join ''
$sha = [Security.Cryptography.SHA256]::Create()
$hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($joined))) -replace '-', '').Substring(0, 16).ToLower()

$current = docker image inspect -f '{{ index .Config.Labels "academy.hash" }}' $image 2> $null
if ($current -ne $hash) {
    Write-Host "Building the Amigoscode Academy (first run only, about a minute)..."
    docker build -q --label "academy.hash=$hash" -t $image $src *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Could not build the academy. Check that Docker is running and you are online."
        exit 1
    }
}

docker run --rm -it `
    -v /var/run/docker.sock:/var/run/docker.sock `
    -v "${here}:/course" `
    -w /course `
    -e ACADEMY_REPO=/course `
    -e COLORTERM=truecolor `
    --add-host host.docker.internal:host-gateway `
    $image @args

exit $LASTEXITCODE
