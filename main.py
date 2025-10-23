import whisper
import speech_recognition as sr
import atexit
from llm_client import LLMClient
import pyttsx3

# ----------------------------
# Setup Whisper
# ----------------------------
print("🔄 Loading Whisper model (base)...")
model = whisper.load_model("base")

recognizer = sr.Recognizer()
mic = sr.Microphone()
recognizer.energy_threshold = 300
recognizer.dynamic_energy_threshold = True

# ----------------------------
# Setup AI Client (OpenRouter from config.json)
# ----------------------------
client = LLMClient(provider_name=None, config_path="config.json")

# ----------------------------
# Speak Function (fixed for Windows SAPI5 issue)
# ----------------------------
def speak(text):
    if not text or not isinstance(text, str):
        print("⚠️ No valid text to speak")
        return

    print(f"🗣️ Assistant says: {text}")

    # Re-init pyttsx3 each time to avoid engine freeze
    engine = pyttsx3.init()
    engine.setProperty("rate", 170)
    engine.setProperty("volume", 1.0)

    voices = engine.getProperty("voices")
    if voices:
        engine.setProperty("voice", voices[0].id)

    engine.say(text)
    engine.runAndWait()
    engine.stop()
    del engine  # force cleanup

# ----------------------------
# Listen & Transcribe
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
<<<<<<< HEAD
=======
# Get AI Response
# ----------------------------
# ----------------------------
>>>>>>> ef90493 (Add FastAPI server, comprehensive README, and updated dependencies)
# Get AI Response with Fallback
# ----------------------------
def ask_ai(prompt):
    messages = [
        {"role": "system", "content": "You are a helpful assistant named ShrutiBot."},
        {"role": "user", "content": prompt}
    ]

    primary_model = "deepseek/deepseek-chat-v3.1:free"
    fallback_model = "mistralai/mistral-7b-instruct:free"

    try:
        print(f"🔹 Trying primary model: {primary_model}")
        reply = client.chat(
            model=primary_model,
            messages=messages
        )
        if not reply or not isinstance(reply, str):
            print("⚠️ AI returned invalid reply from primary:", reply)
            raise Exception("Primary model gave invalid reply")
        return reply.strip()

    except Exception as e:
        print(f"❌ Primary model failed: {e}")
        print(f"🔄 Falling back to: {fallback_model}")
        try:
            reply = client.chat(
                model=fallback_model,
                messages=messages
            )
            if not reply or not isinstance(reply, str):
                print("⚠️ AI returned invalid reply from fallback:", reply)
                return "Sorry, I didn’t get that."
            return reply.strip()
        except Exception as e2:
            print(f"❌ Fallback model also failed: {e2}")
            return "I'm having trouble connecting to my AI service right now."

# ----------------------------
# Main Loop
# ----------------------------
if __name__ == "__main__":
    speak("Hello, I am ready to listen to you!")

    while True:
        try:
            user_text = listen_and_transcribe().lower().strip()

            if user_text in ["quit", "exit", "stop"]:
                speak("Okay, goodbye!")
                break

            ai_response = ask_ai(user_text)
            print("DEBUG AI Response:", ai_response)

            # Always speak something (fallback if empty)
            if not ai_response:
                speak("I didn’t understand that.")
            else:
                speak(ai_response)

        except Exception as e:
            print("⚠️ Error:", e)
            speak("Sorry, I didn’t catch that.")
