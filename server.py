import whisper
import pyttsx3
import speech_recognition as sr
from openai import OpenAI
import os
from dotenv import load_dotenv
import atexit
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

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

# Load API key
load_dotenv('.env_file')
api_key = os.getenv("api-key")
if not api_key:
    raise RuntimeError("❌ No API key found in .env_file")

client = OpenAI(api_key=api_key, timeout=30.0)

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
# AI Functions
# ----------------------------
def ask_ai(prompt: str) -> str:
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a helpful assistant named ShrutiBot."},
                {"role": "user", "content": prompt}
            ]
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"⚠️ OpenAI API Error: {e}")
        return "⚠️ AI service is not available right now."

# ----------------------------
# API Routes
# ----------------------------
@app.post("/api/chat", response_model=ChatOut)
def chat(req: ChatIn):
    reply = ask_ai(req.message)
    return {"reply": reply}

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
