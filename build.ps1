$ErrorActionPreference = "Stop"

$DesiredMajor = 3
$DesiredMinor = 12
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RepoRoot

function Test-PythonVersion {
    param(
        [string]$ExePath
    )

    if (-not (Test-Path $ExePath)) {
        return $null
    }

    try {
        $versionInfo = & "$ExePath" - <<'PYCODE'
import json
import sys
print(json.dumps({"major": sys.version_info.major, "minor": sys.version_info.minor, "executable": sys.executable}))
PYCODE
        return $versionInfo | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Find-Python312 {
    $candidates = @()

    if (Get-Command py -ErrorAction SilentlyContinue) {
        $candidates += { & py -3.12 -c "import sys,json;print(json.dumps({'major':sys.version_info.major,'minor':sys.version_info.minor,'executable':sys.executable}))" }
    }

    $commonPaths = @(
        "python",
        "C:\\Program Files\\Python312\\python.exe",
        "C:\\Program Files (x86)\\Python312\\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:USERPROFILE\AppData\Local\Programs\Python\Python312\python.exe"
    )

    foreach ($path in $commonPaths) {
        $candidates += { param($p) Test-PythonVersion -ExePath $p } -Args $path
    }

    foreach ($candidate in $candidates) {
        try {
            $result = & $candidate
            if ($result -and $result.major -eq $DesiredMajor -and $result.minor -eq $DesiredMinor) {
                return $result.executable
            }
        }
        catch {
            continue
        }
    }

    return $null
}

function Install-Python312 {
    Write-Host "Python 3.12 niet gevonden; installatie wordt gestart..." -ForegroundColor Yellow

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "Probeer via winget Python 3.12 te installeren..." -ForegroundColor Yellow
        & $winget install --id Python.Python.3.12 -e --source winget -h
    }
    else {
        $version = "3.12.3"
        $installerUrl = "https://www.python.org/ftp/python/$version/python-$version-amd64.exe"
        $installerPath = Join-Path $env:TEMP "python-$version-amd64.exe"

        Write-Host "Download Python $version installer..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        Write-Host "Start stille installatie van Python $version..." -ForegroundColor Yellow
        & $installerPath /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1
    }
}

function Ensure-Python312 {
    $pythonPath = Find-Python312
    if ($pythonPath) {
        return $pythonPath
    }

    Install-Python312
    $pythonPath = Find-Python312
    if (-not $pythonPath) {
        throw "Python 3.12 kon niet automatisch worden gevonden of geïnstalleerd. Installeer handmatig en probeer opnieuw."
    }

    return $pythonPath
}

$python312 = Ensure-Python312
Write-Host "Python gevonden: $python312" -ForegroundColor Green

$venvPath = Join-Path $RepoRoot ".venv-build"
$venvPython = Join-Path $venvPath "Scripts/python.exe"

if (-not (Test-Path $venvPython)) {
    & $python312 -m venv $venvPath
}

& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r requirements.txt
& $venvPython build_exe.py
