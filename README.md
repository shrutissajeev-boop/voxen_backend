# 🎙️ Voxen AI - Speech-to-Speech Backend

![Python](https://img.shields.io/badge/python-3.8+-blue.svg)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

A FastAPI-based speech-to-speech AI backend that combines Whisper speech recognition, LLM reasoning (Ollama/OpenRouter/OpenAI), and pyttsx3 text-to-speech synthesis. Fully automated setup on Windows with a single command.

## 🚀 Quick Start

### Windows (Automated Setup - One Command)

```powershell
./setup.ps1
```

This script automatically:
- ✅ Creates a Python virtual environment
- ✅ Installs FFmpeg (required for Whisper)
- ✅ Installs PortAudio and PyAudio
- ✅ Installs all Python dependencies
- ✅ Creates necessary project directories
- ✅ Validates the installation

**After setup completes, activate the environment and run:**
```powershell
.\.env\Scripts\Activate
python -m uvicorn server:app --reload 8000
```

Server runs at: **http://127.0.0.1:8000**

### macOS/Linux (Manual Setup)

```bash
# Clone and navigate
git clone https://github.com/shrutissajeev-boop/voxen_backend.git
cd voxen_backend

# Create virtual environment
python3 -m venv .env
source .env/bin/activate

# Upgrade pip and tools
pip install --upgrade pip
pip install "setuptools<81"
pip install wheel build

# Install system dependencies (macOS)
brew install ffmpeg portaudio

# Install system dependencies (Linux - Ubuntu/Debian)
sudo apt-get install ffmpeg python3-dev portaudio19-dev

# Install Python packages
pip install -r requirements.txt

# Create directories
mkdir -p models logs temp

# Run server
python -m uvicorn server:app --reload
```

---

## 📦 What Gets Installed

### System-Level Dependencies
| Component | Purpose | Installed By |
|-----------|---------|--------------|
| **FFmpeg** | Audio processing for Whisper | setup.ps1 (Windows) |
| **PortAudio** | Audio hardware interface | setup.ps1 (Windows) |

### Python Packages (from requirements.txt)
| Package | Purpose |
|---------|---------|
| **fastapi** | Web framework & API server |
| **uvicorn** | ASGI server |
| **openai-whisper** | Speech-to-text recognition |
| **pyttsx3** | Text-to-speech synthesis |
| **SpeechRecognition** | Microphone input capture |
| **pyaudio** | Audio I/O library |
| **requests** | HTTP client |
| **pydantic** | Data validation |
| **torch** | ML framework (for Whisper) |
| **numpy** | Numerical computing |

---

## 📋 Prerequisites

### Windows
- Python 3.8 or later
- PowerShell 5.0+
- Internet connection (to download FFmpeg, PortAudio, and packages)
- ~2GB disk space for dependencies

### macOS/Linux
- Python 3.8 or later
- Bash shell
- Homebrew (macOS) or apt (Linux)
- Internet connection

---

## 📁 Project Structure

```
voxen_backend/
├── setup.ps1                 # Automated Windows setup script (NEW!)
├── server.py                 # Main FastAPI application
├── llm_client.py             # LLM provider abstraction layer
├── main.py                   # Speech recognition & TTS utilities
├── config.json               # Configuration (providers, models)
├── requirements.txt          # Python dependencies
├── README.md                 # This file
├── .env/                     # Virtual environment (created by setup.ps1)
├── models/                   # Cached Whisper models
├── logs/                     # Application logs
├── temp/                     # Temporary audio files
└── package.json              # Frontend dependencies
```

---

## ⚙️ Configuration

### `config.json` - Provider Setup

```json
{
  "providers": {
    "ollama": {
      "base_url": "http://localhost:11434/api",
      "default_model": "qwen2.5:0.5b",
      "num_gpu": 0,
      "num_ctx": 1024
    },
    "openrouter": {
      "base_url": "https://openrouter.ai/api/v1",
      "api_key": "",
      "default_model": "meta-llama/llama-3.1-70b-instruct"
    },
    "openai": {
      "api_key": "",
      "default_model": "gpt-4o"
    }
  },
  "default_provider": "openrouter",
  "fallback_provider": "ollama",
  "force_cpu": true
}
```

### Option 1: Use Ollama (Recommended for Local Development)

1. **Download Ollama** from [ollama.ai](https://ollama.ai)
2. **Start Ollama service:**
   ```bash
   ollama serve
   ```
3. **Pull a model in another terminal:**
   ```bash
   ollama pull qwen2.5:0.5b
   ```
4. **Server will auto-use Ollama** (free, no API key needed!)

### Option 2: Use OpenRouter (Cloud LLM with Free Models)

1. **Create account** at [openrouter.ai](https://openrouter.ai)
2. **Get API key** (starts with `sk-or-v1-`)
3. **Update config.json:**
   ```json
   "openrouter": {
     "api_key": "sk-or-v1-YOUR-KEY-HERE",
     ...
   }
   ```

### Option 3: Use OpenAI (GPT-4)

1. **Create account** at [openai.com](https://platform.openai.com)
2. **Get API key** (starts with `sk-`)
3. **Update config.json:**
   ```json
   "openai": {
     "api_key": "sk-YOUR-KEY-HERE",
     ...
   }
   ```

### Option 4: Pass API Key at Runtime (Frontend)

```bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "x-api-key: sk-or-v1-YOUR-KEY" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello"}'
```

---

## ▶️ Running the Server

### After Setup is Complete

**Windows (with setup.ps1):**
```powershell
.\.env\Scripts\Activate
python -m uvicorn server:app --reload
```

**macOS/Linux:**
```bash
source .env/bin/activate
python -m uvicorn server:app --reload
```

### Expected Server Output

```
🔄 Loading Whisper model (base)...
✅ Whisper model loaded
✅ Connected to provider: ollama | model: qwen2.5:0.5b
INFO:     Started server process [1234]
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete.
```

### Configuration Options

```bash
# Run on different port
python -m uvicorn server:app --port 9000

# Enable auto-reload on file changes
python -m uvicorn server:app --reload

# Allow external connections (use with caution)
python -m uvicorn server:app --host 0.0.0.0 --port 8000

# View debug logs
python -m uvicorn server:app --log-level debug
```

---

## 🔌 API Endpoints

### `POST /api/chat` - Chat with AI

**Request:**
```bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"What is machine learning?"}'
```

**Response:**
```json
{
  "reply": "Machine learning is a branch of artificial intelligence...",
  "audio_base64": "UklGRi4A...",
  "provider_used": "ollama",
  "model_used": "qwen2.5:0.5b"
}
```

### `GET /api/listen` - Transcribe Microphone

**Request:**
```bash
curl http://127.0.0.1:8000/api/listen
```

**Response:**
```json
{
  "message": "What is the weather today?"
}
```

### `GET /api/profile` - Get User Profile

**Request:**
```bash
curl http://127.0.0.1:8000/api/profile
```

**Response:**
```json
{
  "user": {
    "id": "123",
    "username": "shruti",
    "full_name": "Shruti S Sajeev",
    "profile_picture": ""
  }
}
```

### Interactive API Docs

When the server is running, visit:
- **Swagger UI:** http://127.0.0.1:8000/docs
- **ReDoc:** http://127.0.0.1:8000/redoc

---

## 🔄 Provider Switching

The backend intelligently switches between AI providers:

### Default Behavior
- Uses `default_provider` from config.json
- Falls back to `fallback_provider` if primary fails

### Runtime Override (Frontend)
Send `x-api-key` header to force a specific provider:

```bash
# Forces OpenRouter with your key
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "x-api-key: sk-or-v1-YOUR-KEY" \
  -d '{"message":"Hello"}'
```

### Provider Selection Flow

```
Request with x-api-key header?
    ├─ YES → Use OpenRouter with provided key
    └─ NO → Use default_provider
          ↓
    Primary provider succeeds?
          ├─ YES → Return response
          └─ NO → Try fallback_provider
                ├─ YES → Return response
                └─ NO → Return error
```

---

## 🐛 Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'whisper'"

**Fix:** Reinstall dependencies
```powershell
# Activate environment first
.\.env\Scripts\Activate

# Reinstall
pip install -r requirements.txt
```

---

### Issue: "OSError: [Errno -9997] Invalid number of channels"

**Cause:** PyAudio misconfiguration or no microphone detected

**Fix:** Reinstall PyAudio
```powershell
pip uninstall pyaudio
pip install pipwin
pipwin install pyaudio
```

---

### Issue: "Connection refused" to Ollama

**Fix:** Make sure Ollama is running
```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Verify it's working
curl http://localhost:11434/api/version

# Terminal 3: Verify model is available
ollama list
```

---

### Issue: "FFmpeg not found" when running Whisper

**Fix:** Ensure FFmpeg is in PATH
```powershell
# Verify FFmpeg is installed
ffmpeg -version

# If not found, install via winget
winget install -e --id Gyan.FFmpeg

# May need to restart PowerShell for PATH update
```

---

### Issue: "Port 8000 already in use"

**Fix:** Use a different port
```powershell
python -m uvicorn server:app --port 8001
```

Or find and kill the existing process:
```powershell
# Find process using port 8000
netstat -ano | findstr :8000

# Kill it (replace PID with the number from above)
taskkill /PID <PID> /F
```

---

### Issue: "torch/CUDA version mismatch"

**Fix:** Use CPU-only PyTorch (simpler for most setups)
```powershell
pip uninstall torch
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

---

### Issue: "Whisper model download is slow"

**Cause:** First run downloads ~140MB model (1-2 minutes normal)

**Fix:** Model is cached after first download. Subsequent runs are instant.

Pre-download the model manually:
```python
python -c "import whisper; whisper.load_model('base')"
```

---

### Issue: "LLMClient failed to initialize"

**Fix:** Validate config.json syntax
```powershell
python -c "import json; json.load(open('config.json')); print('✅ Valid!')"
```

---

### Issue: "API key invalid" from OpenRouter

**Cause:** Invalid API key or format

**Fix:**
1. Verify key format starts with `sk-or-v1-`
2. Check key at https://openrouter.ai/account
3. Test the key:
```bash
curl -X POST https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer sk-or-v1-YOUR-KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"meta-llama/llama-3.1-70b-instruct","messages":[{"role":"user","content":"test"}]}'
```

---

## 📝 Example Usage

### Python Client

```python
import requests

BASE_URL = "http://127.0.0.1:8000"

def chat(message: str, api_key: str = None):
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["x-api-key"] = api_key
    
    response = requests.post(
        f"{BASE_URL}/api/chat",
        json={"message": message},
        headers=headers
    )
    
    data = response.json()
    print(f"📍 Provider: {data['provider_used']}")
    print(f"🤖 Model: {data['model_used']}")
    print(f"💬 Reply: {data['reply']}")
    return data

# Use default provider (Ollama or OpenRouter)
chat("What is AI?")

# Force OpenRouter
chat("Explain quantum computing", api_key="sk-or-v1-YOUR-KEY")
```

### JavaScript/TypeScript

```javascript
const BASE_URL = "http://127.0.0.1:8000";

async function chat(message, apiKey = null) {
  const headers = { "Content-Type": "application/json" };
  if (apiKey) {
    headers["x-api-key"] = apiKey;
  }

  const response = await fetch(`${BASE_URL}/api/chat`, {
    method: "POST",
    headers,
    body: JSON.stringify({ message })
  });

  const data = await response.json();
  console.log(`📍 Provider: ${data.provider_used}`);
  console.log(`🤖 Model: ${data.model_used}`);
  console.log(`💬 Reply: ${data.reply}`);
  return data;
}

// Usage
await chat("Hello, how are you?");
```

---

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch:** `git checkout -b feature/my-feature`
3. **Make your changes** and test thoroughly
4. **Commit:** `git commit -m "feat: Add feature description"`
5. **Push:** `git push origin feature/my-feature`
6. **Open a Pull Request**

---

## 📄 License

This project is licensed under the **MIT License**.

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/shrutissajeev-boop/voxen_backend/issues)
- **Email:** shrutissajeev-boop@github.com

---

## 🎓 Learning Resources

- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [OpenAI Whisper GitHub](https://github.com/openai/whisper)
- [Ollama Setup Guide](https://ollama.ai)
- [OpenRouter API Docs](https://openrouter.ai/docs)
- [pyttsx3 Documentation](https://pyttsx3.readthedocs.io/)

---

## ⭐ Quick Reference

```bash
# One-command Windows setup
./setup.ps1

# Activate environment (Windows)
.\.env\Scripts\Activate

# Activate environment (Mac/Linux)
source .env/bin/activate

# Run server
python -m uvicorn server:app --reload

# Run with Ollama
ollama serve  # in separate terminal
python -m uvicorn server:app --reload

# Test API
curl http://127.0.0.1:8000/api/profile

# View interactive docs
# Open: http://127.0.0.1:8000/docs
```

---

**Happy coding! 🚀**
---

## Manual installation for optional packages

If the setup script reports messages like the following while checking optional packages:

```
[INFO] Checking: whisper
[WARN] whisper is not installed (optional - can be installed manually later)
[INFO] Checking: torch
[WARN] torch is not installed (optional - can be installed manually later)
```

You can install those optional packages manually into the virtual environment using these commands:

```powershell
# Install Whisper (speech-to-text)
.\.env\Scripts\python.exe -m pip install openai-whisper

# Install CPU-only PyTorch (recommended for most users without GPU)
.\.env\Scripts\python.exe -m pip install torch --index-url https://download.pytorch.org/whl/cpu
```

Notes:
- If you have a CUDA-capable GPU and want GPU-enabled PyTorch, follow the install instructions at https://pytorch.org and pick the appropriate CUDA wheel.
- Run these commands from the project root so the `.env` path is correct, and ensure the virtual environment exists.

---

