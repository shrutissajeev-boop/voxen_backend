<<<<<<< HEAD
import whisper
import pyttsx3
import speech_recognition as sr
import os
import json
import atexit
import requests
import uuid
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from main import listen_and_transcribe
import base64

# ----------------------------
# Setup
# ----------------------------
print("🔄 Loading Whisper model (base)...")
model = whisper.load_model("base")

engine = pyttsx3.init()
engine.setProperty("rate", 170)
engine.setProperty("volume", 1.0)

def cleanup_tts():
    try:
        if 'engine' in globals() and engine is not None:
            engine.stop()
            del globals()['engine']
    except Exception:
        pass

atexit.register(cleanup_tts)

recognizer = sr.Recognizer()
mic = sr.Microphone()

# ----------------------------
# Load OpenRouter config
# ----------------------------
config_path = "config.json"
if not os.path.exists(config_path):
    raise RuntimeError(f"❌ Config file not found at {config_path}")

with open(config_path, "r") as f:
    config = json.load(f)

provider = config.get("default_provider", "openrouter")
provider_config = config.get("providers", {}).get(provider)

if not provider_config:
    raise RuntimeError(f"❌ No provider settings found for '{provider}' in config.json")

API_KEY = provider_config.get("api_key")
BASE_URL = provider_config.get("base_url", "https://openrouter.ai/api/v1/chat/completions")
MODEL_NAME = provider_config.get("default_model", "deepseek/deepseek-chat-v3.1:free")

if not API_KEY:
    raise RuntimeError("❌ No API key found in config.json for OpenRouter")

# ----------------------------
# FastAPI App
# ----------------------------
app = FastAPI()

# Allow frontend running on 5500
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5500"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------
# Request Models
# ----------------------------
class ChatIn(BaseModel):
    message: str

class ChatOut(BaseModel):
    reply: str
    audio_base64: str

# ----------------------------
# AI Functions (OpenRouter)
# ----------------------------
def ask_ai(prompt: str) -> str:
    try:
        headers = {
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json"
        }

        payload = {
            "model": MODEL_NAME,
            "messages": [
                {"role": "system", "content": "You are a helpful assistant named ShrutiBot."},
                {"role": "user", "content": prompt}
            ]
        }

        response = requests.post(BASE_URL, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        data = response.json()

        return data["choices"][0]["message"]["content"].strip()

    except Exception as e:
        print(f"⚠️ OpenRouter API Error: {e}")
        return "I'm sorry, I could not process that request right now."

# ----------------------------
# TTS Helper
# ----------------------------
def generate_tts_audio(text: str) -> str:
    """Always returns a valid audio filename with spoken text"""
    if not text or not text.strip():
        text = "I'm sorry, I didn't catch that."

    filename = f"response_{uuid.uuid4().hex}.wav"

    try:
        engine = pyttsx3.init()
        engine.setProperty("rate", 170)
        engine.setProperty("volume", 1.0)
        engine.save_to_file(text, filename)
        engine.runAndWait()
        engine.stop()
    except Exception as e:
        print(f"⚠️ TTS Error: {e}")
        # fallback speech
        fallback_text = "Sorry, I could not generate audio right now."
        engine = pyttsx3.init()
        engine.save_to_file(fallback_text, filename)
        engine.runAndWait()
        engine.stop()
        text = fallback_text

    return filename, text

# ----------------------------
# API Routes
# ----------------------------
@app.post("/api/chat", response_model=ChatOut)
def chat(req: ChatIn):
    print(f"📩 User: {req.message}")
    reply = ask_ai(req.message).strip()
    filename, reply = generate_tts_audio(reply)

    with open(filename, "rb") as f:
        audio_base64 = base64.b64encode(f.read()).decode("utf-8")

    print(f"✅ Assistant: {reply}")
    return JSONResponse(content={"reply": reply, "audio_base64": audio_base64})


@app.get("/api/listen")
def listen_endpoint():
    try:
        text = listen_and_transcribe()  # calls main.py microphone function
        return JSONResponse(content={"message": text})
    except Exception as e:
        return JSONResponse(content={"message": ""}, status_code=500)


@app.get("/api/profile")
def profile():
    return {
        "user": {
            "id": "123",
            "username": "shruti",
            "full_name": "Shruti S Sajeev",
            "profile_picture": ""  # You can put a URL if available
        }
    }
=======
import whisper
import pyttsx3
import speech_recognition as sr
import os
import json
import atexit
import requests
import uuid
import tempfile
import base64
from fastapi import FastAPI
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from main import listen_and_transcribe

# ----------------------------
# Setup
# ----------------------------
print("🔄 Loading Whisper model (base)...")
model = whisper.load_model("base")

# Global TTS engine
engine = pyttsx3.init()
engine.setProperty("rate", 170)
engine.setProperty("volume", 1.0)

def cleanup_tts():
    try:
        if 'engine' in globals() and engine is not None:
            engine.stop()
            del globals()['engine']
    except Exception:
        pass

atexit.register(cleanup_tts)

recognizer = sr.Recognizer()
mic = sr.Microphone()

# ----------------------------
# Load OpenRouter config
# ----------------------------
config_path = "config.json"
if not os.path.exists(config_path):
    raise RuntimeError(f"❌ Config file not found at {config_path}")

with open(config_path, "r") as f:
    config = json.load(f)

provider = config.get("default_provider", "openrouter")
provider_config = config.get("providers", {}).get(provider)

if not provider_config:
    raise RuntimeError(f"❌ No provider settings found for '{provider}' in config.json")

API_KEY = provider_config.get("api_key")
BASE_URL = provider_config.get("base_url", "https://openrouter.ai/api/v1/chat/completions")
MODEL_NAME = provider_config.get("default_model", "deepseek/deepseek-chat-v3.1:free")

if not API_KEY:
    raise RuntimeError("❌ No API key found in config.json for OpenRouter")

# ----------------------------
# FastAPI App
# ----------------------------
app = FastAPI()

# Allow frontend running on 5500
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5500"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------
# Request Models
# ----------------------------
class ChatIn(BaseModel):
    message: str

class ChatOut(BaseModel):
    reply: str

# ----------------------------
# AI Functions (OpenRouter)
# ----------------------------
def ask_ai(prompt: str) -> str:
    try:
        headers = {
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json"
        }

        payload = {
            "model": MODEL_NAME,
            "messages": [
                {"role": "system", "content": "You are a helpful assistant named ShrutiBot."},
                {"role": "user", "content": prompt}
            ]
        }

        response = requests.post(BASE_URL, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        data = response.json()

        return data["choices"][0]["message"]["content"].strip()

    except Exception as e:
        print(f"⚠️ OpenRouter API Error: {e}")
        return ""  # return empty string for fallback

# ----------------------------
# API Routes
# ----------------------------
@app.post("/api/chat", response_model=ChatOut)
def chat(req: ChatIn):
    try:
        print(f"📩 User: {req.message}")
        reply = ask_ai(req.message)

        # Ensure reply is never empty
        if not reply:
            reply = "I’m sorry, I didn’t get that."

        print(f"✅ Assistant: {reply}")

        # Use temporary file for TTS
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmpfile:
            filename = tmpfile.name
            tmpfile.close()

            try:
                engine.save_to_file(reply, filename)
                engine.runAndWait()
            except Exception as e:
                print(f"⚠️ TTS Error: {e}")
                # fallback: generate silent audio if TTS fails
                with open(filename, "wb") as f:
                    f.write(b"")

            # Convert audio to base64
            with open(filename, "rb") as f:
                audio_base64 = base64.b64encode(f.read()).decode("utf-8")

        return JSONResponse(content={"reply": reply, "audio_base64": audio_base64})

    except Exception as e:
        print(f"⚠️ Chat Endpoint Error: {e}")
        # Always return fallback
        fallback_reply = "I’m sorry, I didn’t get that."
        return JSONResponse(content={"reply": fallback_reply, "audio_base64": ""})


@app.get("/api/listen")
def listen_endpoint():
    try:
        text = listen_and_transcribe()  # calls main.py microphone function
        if not text:
            text = ""  # Ensure we return empty string, not None
        return JSONResponse(content={"message": text})
    except Exception as e:
        print(f"⚠️ Listen Endpoint Error: {e}")
        return JSONResponse(content={"message": ""}, status_code=500)


@app.get("/api/profile")
def profile():
    return {
        "user": {
            "id": "123",
            "username": "shruti",
            "full_name": "Shruti S Sajeev",
            "profile_picture": ""  # You can put a URL if available
        }
    }
>>>>>>> ef90493 (Add FastAPI server, comprehensive README, and updated dependencies)
