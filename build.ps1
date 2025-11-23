$ErrorActionPreference = "Stop"

if (-not $IsWindows) {
    throw "Deze build-stap is bedoeld voor Windows; voer het script op Windows uit om een .exe te maken."
}

$DesiredMajor = 3
$DesiredMinor = 12
$DesiredPatch = 6
$DesiredVersion = "{0}.{1}.{2}" -f $DesiredMajor, $DesiredMinor, $DesiredPatch
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
print(json.dumps({"major": sys.version_info.major, "minor": sys.version_info.minor, "micro": sys.version_info.micro, "executable": sys.executable}))
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
        $candidates += { & py -3.12 -c "import sys,json;print(json.dumps({'major':sys.version_info.major,'minor':sys.version_info.minor,'micro':sys.version_info.micro,'executable':sys.executable}))" }
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
        & $winget install --id Python.Python.3.12 -e --source winget --accept-package-agreements --accept-source-agreements -h
        return
    }

    $installerUrl = "https://www.python.org/ftp/python/$DesiredVersion/python-$DesiredVersion-amd64.exe"
    $installerPath = Join-Path $env:TEMP "python-$DesiredVersion-amd64.exe"

    Write-Host "Download Python $DesiredVersion installer..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    Write-Host "Start stille installatie van Python $DesiredVersion..." -ForegroundColor Yellow
    & $installerPath /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1 Include_test=0
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
    Write-Host "Maak geïsoleerde build-omgeving (.venv-build)..." -ForegroundColor Yellow
    & $python312 -m venv $venvPath
}

Write-Host "Installeer/actualiseer build dependencies..." -ForegroundColor Yellow
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r requirements.txt

Write-Host "Start PyInstaller-build..." -ForegroundColor Yellow
& $venvPython build_exe.py

$exePath = Join-Path $RepoRoot "dist/poster-splitter.exe"
if (Test-Path $exePath) {
    Write-Host "Klaar! Uitvoer: $exePath" -ForegroundColor Green
} else {
    Write-Host "Build voltooid, maar \"$exePath\" werd niet gevonden. Controleer de PyInstaller-uitvoer voor details." -ForegroundColor Red
}
