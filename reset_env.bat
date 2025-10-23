@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Reset + Reinstall (STT+TTS)

rem —————————— CONFIG (edit if needed) ——————————
rem cpu | cu121 | cu118  (set cu121/cu118 if using NVIDIA CUDA wheels)
set "TORCH_DEVICE=cpu"
rem auto = use requirements.txt if present, yes = always use, no = always ignore
set "USE_REQUIREMENTS=auto"
rem extra flags to pass to pip install -r (e.g., --no-cache-dir)
set "PIP_EXTRA="
rem ————————————————————————————————————————————————

cd /d "%~dp0"

echo [1/7] Deleting existing .venv (if any)…
if exist ".venv" rmdir /s /q ".venv"

echo [2/7] Locating Python…
set "PYLAUNCHER="
where py >nul 2>&1 && set "PYLAUNCHER=py -3"
if "%PYLAUNCHER%"=="" where python >nul 2>&1 && set "PYLAUNCHER=python"
if "%PYLAUNCHER%"=="" (
  echo ERROR: Python 3.x not found in PATH. Install Python and try again.
  pause & exit /b 1
)

echo [3/7] Creating new virtual environment…
%PYLAUNCHER% -m venv ".venv" || (echo Failed to create venv.& pause & exit /b 1)

set "PY=.venv\Scripts\python.exe"
set "PIP=.venv\Scripts\pip.exe"

echo [4/7] Upgrading pip/setuptools/wheel…
"%PY%" -m pip install --upgrade pip setuptools wheel || (echo pip upgrade failed.& pause & exit /b 1)

rem Optional: ensure FFmpeg (needed by Whisper). This tries to install if available.
where ffmpeg >nul 2>&1 || (
  echo [Info] FFmpeg not found in PATH. Attempting install via Chocolatey/Scoop (if present)…
  where choco >nul 2>&1 && choco install -y ffmpeg
  where scoop >nul 2>&1 && scoop install ffmpeg
)

rem Use requirements.txt if requested/present
if /i "%USE_REQUIREMENTS%"=="yes" goto :use_req
if /i "%USE_REQUIREMENTS%"=="auto" if exist "requirements.txt" goto :use_req

echo [5/7] Installing PyTorch (%TORCH_DEVICE%)…
if /i "%TORCH_DEVICE%"=="cpu" (
  "%PIP%" install --upgrade --extra-index-url https://download.pytorch.org/whl/cpu torch torchvision torchaudio || (echo PyTorch install failed.& pause & exit /b 1)
) else if /i "%TORCH_DEVICE%"=="cu121" (
  "%PIP%" install --upgrade --index-url https://download.pytorch.org/whl/cu121 torch torchvision torchaudio || (echo PyTorch CUDA 12.1 install failed.& pause & exit /b 1)
) else if /i "%TORCH_DEVICE%"=="cu118" (
  "%PIP%" install --upgrade --index-url https://download.pytorch.org/whl/cu118 torch torchvision torchaudio || (echo PyTorch CUDA 11.8 install failed.& pause & exit /b 1)
) else (
  echo Unknown TORCH_DEVICE "%TORCH_DEVICE%". Falling back to CPU wheels…
  "%PIP%" install --upgrade --extra-index-url https://download.pytorch.org/whl/cpu torch torchvision torchaudio || (echo PyTorch install failed.& pause & exit /b 1)
)

echo [6/7] Installing Whisper, Piper, and audio stack…
"%PIP%" install --upgrade ^
  openai-whisper ^
  piper-tts ^
  sounddevice ^
  pydub ^
  numpy ^
  SpeechRecognition ^
  audioop-lts || (echo Package install failed.& pause & exit /b 1)

goto :verify

:use_req
echo [5/7] Installing from requirements.txt…
"%PIP%" install -r requirements.txt %PIP_EXTRA% || (echo requirements install failed.& pause & exit /b 1)

:verify
echo [7/7] Verifying imports (torch, whisper, sounddevice)…
"%PY%" -c "import importlib; [importlib.import_module(m) for m in ['torch','whisper','sounddevice']]" || (
  echo One or more imports failed. See errors above.
  echo If FFmpeg is missing, install it (e.g., via Chocolatey or Scoop) and re-run.
  pause & exit /b 1
)

echo.
echo Done! Activate the environment with:
echo     .venv\Scripts\activate
echo Then run:
echo     python main.py
echo.
pause
exit /b 0

