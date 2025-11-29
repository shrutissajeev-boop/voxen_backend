# Voxen Backend - Automated Setup Script for Windows
# This script sets up a complete development environment for the FastAPI speech-to-speech backend

$ErrorActionPreference = "Stop"

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

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

# Start setup
Write-Header "Voxen Backend Setup for Windows"

# Step 1: Check Python installation
Write-Header "Step 1: Checking Python Installation"

try {
    $pythonVersion = python --version 2>&1
    Write-Success "Python found: $pythonVersion"
} catch {
    Write-Error-Custom "Python is not installed or not in PATH"
    Write-Info "Please install Python 3.8+ from https://www.python.org/downloads/"
    exit 1
}

# Step 2: Create virtual environment
Write-Header "Step 2: Creating Virtual Environment"

if (Test-Path ".env") {
    Write-Info "Virtual environment already exists at .\.env"
} else {
    Write-Info "Creating virtual environment at .\.env..."
    python -m venv .env
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Virtual environment created"
    } else {
        Write-Error-Custom "Failed to create virtual environment"
        exit 1
    }
}

# Step 3: Activate virtual environment
Write-Header "Step 3: Activating Virtual Environment"

& ".\.env\Scripts\Activate.ps1"
Write-Success "Virtual environment activated"

# Step 4: Upgrade pip and setuptools
Write-Header "Step 4: Upgrading pip and setuptools"

Write-Info "Upgrading pip..."
python -m pip install --upgrade pip 2>&1 | Out-Null
Write-Success "pip upgraded"

Write-Info "Pinning setuptools to <81..."
python -m pip install "setuptools<81" 2>&1 | Out-Null
Write-Success "setuptools pinned"

Write-Info "Installing wheel and build..."
python -m pip install wheel build 2>&1 | Out-Null
Write-Success "wheel and build installed"

# Step 5: Check and install FFmpeg
Write-Header "Step 5: Installing FFmpeg (Required for Whisper)"

$ffmpegTest = ffmpeg -version 2>&1 | Select-Object -First 1
if ($ffmpegTest -like "ffmpeg*") {
    Write-Success "FFmpeg is already installed"
} else {
    Write-Info "FFmpeg not found. Attempting installation via winget..."
    
    try {
        $wingetVersion = winget --version 2>&1
        Write-Info "Installing FFmpeg with winget..."
        winget install -e --id Gyan.FFmpeg --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "FFmpeg installed successfully"
        } else {
            Write-Info "FFmpeg installation had issues - continuing anyway"
        }
    } catch {
        Write-Info "winget not available - you can install FFmpeg manually from https://ffmpeg.org/download.html"
    }
}

# Step 6: Install PyAudio
Write-Header "Step 6: Installing PyAudio (Audio Input/Output)"

Write-Info "Installing PyAudio via pip..."
pip install pyaudio 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Success "PyAudio installed successfully"
} else {
    Write-Info "PyAudio pip installation had issues - trying alternative method"
    pip install pipwin 2>&1 | Out-Null
    pipwin install pyaudio 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "PyAudio installed via pipwin"
    } else {
        Write-Info "PyAudio installation had issues - you may need to install manually"
    }
}

# Step 7: Install Python dependencies
Write-Header "Step 7: Installing Python Dependencies from requirements.txt"

if (-not (Test-Path "requirements.txt")) {
    Write-Error-Custom "requirements.txt not found"
    exit 1
}

Write-Info "Installing all packages..."
Write-Info "First installing build essentials..."
pip install --upgrade setuptools wheel build 2>&1 | Out-Null

Write-Info "Installing packages from requirements.txt..."
$ErrorActionPreference = "Continue"
pip install -r requirements.txt --no-cache-dir 2>&1 | Out-Null
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

# Step 9: Validate installation
Write-Header "Step 9: Validating Installation"

Write-Info "Checking critical packages..."

$packagesToCheck = @("fastapi", "uvicorn", "pydantic", "requests")
$criticalOk = $true

foreach ($package in $packagesToCheck) {
    python -c "import $package" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$package is installed"
    } else {
        Write-Error-Custom "$package is NOT installed"
        $criticalOk = $false
    }
}

Write-Info "Checking optional/heavy packages..."
$optionalPackages = @("whisper", "torch")
foreach ($package in $optionalPackages) {
    python -c "import $package" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$package is installed"
    } else {
        Write-Info "$package not yet installed (may need manual setup)"
    }
}

if (-not $criticalOk) {
    Write-Error-Custom "Critical packages are missing!"
    exit 1
}

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
