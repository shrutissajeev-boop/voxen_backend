# Voxen Backend - Automated Setup Script for Windows
# This script sets up a complete development environment for the FastAPI speech-to-speech backend
# Production-ready, idempotent, fully automated setup for Windows PowerShell 5.1+

param(
    [switch]$InstallCritical,
    [switch]$InstallOptional,
    [switch]$UpgradePip,
    [switch]$ClearPipCache,
    [switch]$RecreateVenv,
    [string]$ManualPackage
)

$ErrorActionPreference = "Stop"

# ============================================================
# Colored Output Functions
# ============================================================

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Magenta
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

# ============================================================
# Script Execution Begins
# ============================================================

Write-Header "Voxen Backend Setup for Windows"
Write-Info "This script will set up a complete Python environment in .\.env"
Write-Info "All package operations use ONLY the virtual environment's pip"

# Step 1: Check Python installation
Write-Header "Step 1: Checking System Python Installation"

try {
    $pythonVersion = python --version 2>&1
    Write-Success "System Python found: $pythonVersion"
} catch {
    Write-Error-Custom "Python is not installed or not in PATH"
    Write-Info "Please install Python 3.8+ from https://www.python.org/downloads/"
    exit 1
}

# Step 2: Create virtual environment
Write-Header "Step 2: Creating Virtual Environment at .\.env"

if (Test-Path ".\.env\Scripts\python.exe") {
    Write-Success "Virtual environment already exists at .\.env"
} else {
    Write-Info "Creating virtual environment at .\.env..."
    python -m venv .env
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to create virtual environment"
        exit 1
    }
    Write-Success "Virtual environment created successfully"
}

# Step 3: Verify virtual environment executables
Write-Header "Step 3: Verifying Virtual Environment Executables"

$pythonExe = ".\.env\Scripts\python.exe"
$pipExe = ".\.env\Scripts\pip.exe"

if (-not (Test-Path $pythonExe)) {
    Write-Error-Custom "Virtual environment python.exe not found at $pythonExe"
    exit 1
}
Write-Success "Virtual environment python.exe found"

if (-not (Test-Path $pipExe)) {
    Write-Error-Custom "Virtual environment pip.exe not found at $pipExe"
    exit 1
}
Write-Success "Virtual environment pip.exe found"

# Step 4: Upgrade pip, setuptools, wheel, and build
Write-Header "Step 4: Upgrading Core Tools in Virtual Environment"
Write-Info "Upgrading pip to latest version..."

# Temporarily relax error action for external pip commands in this section
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"

& $pipExe install --upgrade pip 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning-Custom "pip upgrade had issues, but continuing..."
}
Write-Success "pip upgraded"

Write-Info "Upgrading setuptools (pinning to <81)..."
& $pipExe install "setuptools<81" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning-Custom "setuptools install had issues, but continuing..."
}
Write-Success "setuptools pinned to <81"

Write-Info "Installing wheel and build tools..."
& $pipExe install wheel build 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning-Custom "wheel/build install had issues, but continuing..."
}
Write-Success "wheel and build tools installed"

# Restore previous ErrorActionPreference
$ErrorActionPreference = $prevEAP

# Step 5: Install FFmpeg (optional, required for Whisper)
Write-Header "Step 5: Checking FFmpeg Installation (Optional, Required for Whisper)"

$ffmpegTest = ffmpeg -version 2>&1 | Select-Object -First 1
if ($ffmpegTest -like "ffmpeg*") {
    Write-Success "FFmpeg is already installed"
} else {
    Write-Warning-Custom "FFmpeg not found on system. Attempting installation via winget..."
    
    try {
        $wingetVersion = winget --version 2>&1
        Write-Info "Installing FFmpeg with winget..."
        winget install -e --id Gyan.FFmpeg --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "FFmpeg installed successfully"
        } else {
            Write-Warning-Custom "FFmpeg installation via winget had issues"
            Write-Info "You can install FFmpeg manually from: https://ffmpeg.org/download.html"
        }
    } catch {
        Write-Warning-Custom "winget not available on this system"
        Write-Info "You can install FFmpeg manually from: https://ffmpeg.org/download.html"
    }
}

# Step 6: Install PyAudio
Write-Header "Step 6: Installing PyAudio (Audio Input/Output)"

Write-Info "Installing PyAudio via pip..."
## Relax error preference for pip operations in this block so they don't terminate the script
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"

& $pipExe install pyaudio 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Success "PyAudio installed successfully"
} else {
    Write-Info "PyAudio pip installation had issues - trying alternative method"
    & $pipExe install pipwin 2>&1 | Out-Null
    & $pipExe install pyaudio 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "PyAudio installed via pipwin"
    } else {
        Write-Warning-Custom "PyAudio installation had issues - you may need to install manually"
    }
}

# Restore previous ErrorActionPreference
$ErrorActionPreference = $prevEAP

# Step 7: Install Python dependencies
Write-Header "Step 7: Installing Python Dependencies from requirements.txt"

if (-not (Test-Path "requirements.txt")) {
    Write-Error-Custom "requirements.txt not found"
    exit 1
}

Write-Info "Installing all packages..."
Write-Info "First installing build essentials..."
## Temporarily relax error handling for this pip invocation
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& $pipExe install --upgrade setuptools wheel build 2>&1 | Out-Null
$ErrorActionPreference = $prevEAP

Write-Info "Installing packages from requirements.txt..."
$ErrorActionPreference = "Continue"
& $pipExe install -r requirements.txt --no-cache-dir 2>&1 | Out-Null
$ErrorActionPreference = "Stop"

if ($LASTEXITCODE -eq 0) {
    Write-Success "All Python packages installed"
} else {
    Write-Info "Some packages had issues during installation"
    Write-Info "This may be expected for packages with C dependencies"
    Write-Info "Validating installed packages..."
}

# Step 8: Create project directories
Write-Header "Step 8: Creating Project Directories"

$directories = @("models", "logs", "temp")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "Created directory: $dir"
    } else {
        Write-Info "Directory already exists: $dir"
    }
}

# Step 9: Force-install and validate critical packages
Write-Header "Step 9: Force-Installing Critical Packages"

$criticalPackages = @("fastapi", "uvicorn", "pydantic", "requests")

Write-Info "Force-installing critical packages with --upgrade --force-reinstall..."
Write-Info "Note: This step may take several minutes and requires disk space"

$ErrorActionPreference = "Continue"

foreach ($package in $criticalPackages) {
    Write-Info "Force-installing: $package"
    & $pipExe install --upgrade --force-reinstall $package 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to install $package (see error above)"
    } else {
        Write-Success "Force-installed $package"
    }
}

$ErrorActionPreference = "Stop"

# Step 10: Validate critical packages using pip show
Write-Header "Step 10: Validating Critical Packages"

Write-Info "Validating critical packages..."
$missingCritical = @()

$ErrorActionPreference = "Continue"

foreach ($package in $criticalPackages) {
    Write-Info "Checking: $package"
    & $pipExe show $package 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$package is installed and verified"
    } else {
        Write-Error-Custom "$package is NOT installed"
        $missingCritical += $package
    }
}

$ErrorActionPreference = "Stop"

if ($missingCritical.Count -gt 0) {
    Write-Error-Custom "Critical packages missing: $($missingCritical -join ', ')"
    Write-Info "Please check disk space, then re-run the script: ./setup.ps1"
    exit 1
}

# Step 11: Check optional packages (warn only, do not fail)
Write-Header "Step 11: Checking Optional Packages"

$optionalPackages = @("whisper", "torch")

Write-Info "Checking optional packages (installation not required)..."
## Allow pip show to fail without terminating the script
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
foreach ($package in $optionalPackages) {
    Write-Info "Checking: $package"
    & $pipExe show $package 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$package is installed"
    } else {
        Write-Warning-Custom "$package is not installed (optional - can be installed manually later)"
    }
}
$ErrorActionPreference = $prevEAP

# Success!
Write-Header "Setup Complete!"

Write-Info "Your environment is ready!"
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Green
Write-Host "  1. Activate environment: .\.env\Scripts\Activate"
Write-Host "  2. Run the server: python -m uvicorn server:app --reload"
Write-Host "  3. Visit: http://127.0.0.1:8000/docs"
Write-Host ""
Write-Host "For more info, see README.md"
Write-Host ""
Write-Header "Manual Installation Helpers (Fallback)"

Write-Info "This script includes helper routines for manual package installation and troubleshooting."
Write-Info "You can invoke the script with switches to perform specific fallback actions, for example:"
Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallCritical" -ForegroundColor Cyan
Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\setup.ps1 -ManualPackage openai-whisper" -ForegroundColor Cyan

# Helper functions (do not run automatically unless corresponding switch is provided)
function Install-ManualPackage {
    param([string]$Package)
    if (-not $Package) {
        Write-Error-Custom "No package name provided to Install-ManualPackage"
        return
    }
    Write-Info "Installing package: $Package"
    & $pythonExe -m pip install $Package
    if ($LASTEXITCODE -eq 0) { Write-Success "$Package installed" } else { Write-Error-Custom "Failed to install $Package" }
}

function Install-CriticalPackages {
    $pkgs = @("fastapi","uvicorn","pydantic","requests")
    foreach ($p in $pkgs) { Install-ManualPackage -Package $p }
}

function Install-OptionalHeavyPackages {
    Write-Info "Installing Whisper (openai-whisper)"
    Install-ManualPackage -Package "openai-whisper"

    Write-Info "Installing CPU-only PyTorch (via PyTorch CPU index)"
    & $pythonExe -m pip install torch --index-url https://download.pytorch.org/whl/cpu
    if ($LASTEXITCODE -eq 0) { Write-Success "torch installed (CPU wheel)" } else { Write-Warning-Custom "torch install failed - check internet or try manually" }
}

function Upgrade-Pip-Helper {
    Write-Info "Upgrading pip in virtual environment"
    & $pythonExe -m pip install --upgrade pip
}

function Clear-Pip-Cache-Helper {
    Write-Info "Clearing pip cache"
    & $pythonExe -m pip cache purge
}

function Install-NoCache {
    param([string]$Package)
    if (-not $Package) { Write-Error-Custom "No package provided to Install-NoCache"; return }
    Write-Info "Installing $Package with no cache (verbose)"
    & $pythonExe -m pip install $Package --no-cache-dir -v
}

function Recreate-Venv-Helper {
    Write-Warning-Custom "This will remove and recreate the .\.env virtual environment."
    Write-Info "Removing .\.env..."
    Remove-Item -Recurse -Force .\.env -ErrorAction SilentlyContinue
    Write-Info "Creating virtual environment..."
    python -m venv .env
    Write-Info "Activating and bootstrapping pip, setuptools, wheel..."
    & ".\.env\Scripts\python.exe" -m pip install --upgrade pip setuptools wheel
    Write-Success ".\.env recreated and basic tools installed"
}

# Handle switches if provided
if ($UpgradePip) { Upgrade-Pip-Helper }
if ($ClearPipCache) { Clear-Pip-Cache-Helper }
if ($RecreateVenv) { Recreate-Venv-Helper }
if ($InstallCritical) { Install-CriticalPackages }
if ($InstallOptional) { Install-OptionalHeavyPackages }
if ($ManualPackage) { Install-ManualPackage -Package $ManualPackage }

