import whisper
import pyttsx3
import speech_recognition as sr
from openai import OpenAI
import os
from dotenv import load_dotenv
import atexit

# ----------------------------
# Setup
# ----------------------------
print("🔄 Loading Whisper model (base)...")
model = whisper.load_model("base")

engine = pyttsx3.init()
engine.setProperty("rate", 170)
engine.setProperty("volume", 1.0)

# Register cleanup function to properly close TTS engine
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

# Load environment variables from .env_file
load_dotenv('.env_file')

# Fetch API key
api_key = os.getenv("api-key")

if not api_key:
    print("⚠️ Warning: OPENAI_API_KEY not found in .env_file.")
    print("Using fallback hardcoded key (not recommended).")
    api_key = "api-key"  # replace with your actual key if needed

# Initialize OpenAI client
try:
    client = OpenAI(api_key=api_key, timeout=30.0)
except Exception as e:
    print(f"⚠️ Error initializing OpenAI client: {e}")
    client = None

# ----------------------------
# Function: Speak text
# ----------------------------
def speak(text):
    print("🗣️ Assistant:", text)
    engine.say(text)
    engine.runAndWait()

# ----------------------------
# Function: Listen & Transcribe
# ----------------------------
def listen_and_transcribe():
    with mic as source:
        print("🎤 Say something...")
        recognizer.adjust_for_ambient_noise(source)
        audio = recognizer.listen(source)

    with open("temp.wav", "wb") as f:
        f.write(audio.get_wav_data())

    print("🔎 Transcribing with Whisper...")
    result = model.transcribe("temp.wav")
    text = result["text"].strip()
    print("👤 You said:", text)
    return text

# ----------------------------
# Function: Get AI Response
# ----------------------------
def ask_ai(prompt):
    if client is None:
        return "AI service is not available. Please check your OpenAI configuration."
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",  # fast + cheap model
            messages=[
                {"role": "system", "content": "You are a helpful assistant named ShrutiBot."},
                {"role": "user", "content": prompt}
            ]
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"⚠️ OpenAI API Error: {e}")
        return "I'm having trouble connecting to my AI service right now. Please check your API key configuration."

# ----------------------------
# Main Loop
# ----------------------------
if __name__ == "__main__":
    speak("Hello, I am ready to listen to you!")

    while True:
        try:
            user_text = listen_and_transcribe()

            if user_text.lower() in ["quit", "exit", "stop"]:
                speak("Okay, goodbye!")
                break

            ai_response = ask_ai(user_text)
            speak(ai_response)

        except Exception as e:
            print("⚠️ Error:", e)
            speak("Sorry, I didn't catch that.")
