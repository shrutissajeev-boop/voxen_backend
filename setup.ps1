# Voxen Backend - Automated Setup Script for Windows
# This script sets up a complete development environment for the FastAPI speech-to-speech backend
# with all system and Python dependencies including FFmpeg, PortAudio, and PyAudio.

# Set error handling
$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Message)
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $Message" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

# Start setup
Write-Header "Voxen Backend Setup"

# ============================================================================
# Step 1: Check Python installation
# ============================================================================
Write-Header "Step 1: Checking Python Installation"

try {
    $pythonVersion = python --version 2>&1
    Write-Success "Python found: $pythonVersion"
} catch {
    Write-Error-Custom "Python is not installed or not in PATH"
    Write-Info "Please install Python 3.8+ from https://www.python.org/downloads/"
    exit 1
}

# ============================================================================
# Step 2: Create virtual environment
# ============================================================================
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

# ============================================================================
# Step 3: Activate virtual environment
# ============================================================================
Write-Header "Step 3: Activating Virtual Environment"

& ".\.env\Scripts\Activate.ps1"
if ($LASTEXITCODE -eq 0) {
    Write-Success "Virtual environment activated"
} else {
    Write-Error-Custom "Failed to activate virtual environment"
    exit 1
}

# ============================================================================
# Step 4: Upgrade pip and setuptools
# ============================================================================
Write-Header "Step 4: Upgrading pip and setuptools"

Write-Info "Upgrading pip..."
python -m pip install --upgrade pip
Write-Success "pip upgraded"

Write-Info "Pinning setuptools to <81..."
python -m pip install "setuptools<81"
Write-Success "setuptools pinned"

Write-Info "Installing wheel and build..."
python -m pip install wheel build
Write-Success "wheel and build installed"

# ============================================================================
# Step 5: Check and install FFmpeg via winget
# ============================================================================
Write-Header "Step 5: Installing FFmpeg (Required for Whisper)"

$ffmpegCheck = ffmpeg -version 2>&1 | Select-Object -First 1
if ($ffmpegCheck -like "ffmpeg*") {
    Write-Success "FFmpeg is already installed"
} else {
    Write-Info "FFmpeg not found. Attempting installation via winget..."
    
    # Check if winget is available
    try {
        $wingetVersion = winget --version 2>&1
        Write-Success "winget found: $wingetVersion"
        
        Write-Info "Installing FFmpeg..."
        winget install -e --id Gyan.FFmpeg --silent --accept-source-agreements --accept-package-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "FFmpeg installed successfully"
            Write-Info "You may need to restart PowerShell for FFmpeg to be in PATH"
        } else {
            Write-Info "winget installation had issues. Attempting manual installation..."
            # Continue anyway - user may have FFmpeg in PATH or can install manually
        }
    } catch {
        Write-Info "winget not available on this system"
        Write-Info "FFmpeg can be installed manually from: https://ffmpeg.org/download.html"
        Write-Info "Or via Chocolatey: choco install ffmpeg"
        Write-Info "Setup will continue - Whisper will download FFmpeg as needed"
    }
}

# ============================================================================
# Step 6: Install PyAudio wheel for Windows
# ============================================================================
Write-Header "Step 6: Installing PyAudio (Audio Input/Output)"

Write-Info "Checking Python version for PyAudio .whl file..."
$pythonVersion = python -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor}')"
$pythonArch = python -c "import struct; print('win_amd64' if struct.calcsize('P') == 8 else 'win32')"

Write-Info "Python version code: $pythonVersion, Architecture: $pythonArch"

# Pre-built PyAudio wheels for common Python versions
$pyaudioUrl = ""
if ($pythonVersion -eq "310" -and $pythonArch -eq "win_amd64") {
    $pyaudioUrl = "https://files.pythonhosted.org/packages/b0/42/9836e1a6b78cac3eef1b1841bdfaa5c55588353ceeb6d5a8c73387f7a826/PyAudio-0.2.13-cp310-cp310-win_amd64.whl"
} elseif ($pythonVersion -eq "311" -and $pythonArch -eq "win_amd64") {
    $pyaudioUrl = "https://files.pythonhosted.org/packages/42/b8/8549e5c1b6e0c00a9eaf1221ac25d6cc6f35a20795ef15177f5c4b2ceee/PyAudio-0.2.13-cp311-cp311-win_amd64.whl"
} elseif ($pythonVersion -eq "312" -and $pythonArch -eq "win_amd64") {
    $pyaudioUrl = "https://files.pythonhosted.org/packages/e6/00/58bbe16d34b7a88b7329a4be3b86f22dcb77f5be7c882f9a1db2639b7a7a/PyAudio-0.2.13-cp312-cp312-win_amd64.whl"
} else {
    Write-Info "PyAudio wheel not pre-configured for Python $pythonVersion ($pythonArch)"
    Write-Info "Installation will attempt via pip (may require PortAudio development files)"
}

if ($pyaudioUrl) {
    Write-Info "Downloading PyAudio wheel for Python $pythonVersion..."
    pip install $pyaudioUrl
    if ($LASTEXITCODE -eq 0) {
        Write-Success "PyAudio installed from wheel"
    } else {
        Write-Error-Custom "Failed to install PyAudio wheel. Attempting pip fallback..."
        pip install pyaudio
    }
} else {
    Write-Info "Installing PyAudio via pip..."
    pip install pyaudio 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "PyAudio installed"
    } else {
        Write-Info "PyAudio installation encountered issues"
        Write-Info "You may need to install PortAudio development files manually"
    }
}

# ============================================================================
# Step 7: Install Python dependencies from requirements.txt
# ============================================================================
Write-Header "Step 7: Installing Python Dependencies"

if (-not (Test-Path "requirements.txt")) {
    Write-Error-Custom "requirements.txt not found in current directory"
    exit 1
}

Write-Info "Installing packages from requirements.txt..."
pip install -r requirements.txt

if ($LASTEXITCODE -eq 0) {
    Write-Success "All Python packages installed successfully"
} else {
    Write-Error-Custom "Some packages failed to install"
    Write-Info "Please check the error messages above and try installing manually"
    exit 1
}

# ============================================================================
# Step 8: Create necessary directories
# ============================================================================
Write-Header "Step 8: Creating Project Directories"

$directories = @("models", "logs", "temp")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Success "Created directory: $dir"
    } else {
        Write-Info "Directory already exists: $dir"
    }
}

# ============================================================================
# Step 9: Validate setup
# ============================================================================
Write-Header "Step 9: Validating Installation"

Write-Info "Checking critical packages..."

$packagesToCheck = @("fastapi", "uvicorn", "whisper", "pydantic", "requests")
$allOk = $true

foreach ($package in $packagesToCheck) {
    try {
        python -c "import $package" 2>&1 | Out-Null
        Write-Success "$package is installed"
    } catch {
        Write-Error-Custom "$package is NOT installed"
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Error-Custom "Some critical packages are missing"
    Write-Info "Try running: pip install -r requirements.txt"
    exit 1
}

# ============================================================================
# Success!
# ============================================================================
Write-Header "Setup Complete! ✅"

Write-Info "Your environment is ready to use!"
Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Activate the virtual environment (if not already active):"
Write-Host "      .\.env\Scripts\Activate" -ForegroundColor Yellow
Write-Host "`n   2. Configure your API keys in config.json"
Write-Host "      - Set OPENROUTER_API_KEY for OpenRouter"
Write-Host "      - Or install Ollama locally for free local inference"
Write-Host "      - Or set OPENAI_API_KEY for OpenAI"
Write-Host "`n   3. Run the backend server:"
Write-Host "      python -m uvicorn server:app --reload" -ForegroundColor Yellow
Write-Host "      Server will be available at: http://127.0.0.1:8000"
Write-Host "`n   4. Test the API:"
Write-Host "      curl http://127.0.0.1:8000/api/profile" -ForegroundColor Yellow
Write-Host "`n📚 Documentation:" -ForegroundColor Cyan
Write-Host "   - Full README: Check README.md"
Write-Host "   - API Docs: http://127.0.0.1:8000/docs (when server is running)"
Write-Host "   - Whisper info: https://github.com/openai/whisper"
Write-Host "   - Ollama setup: https://ollama.ai"
Write-Host ""
