# test_tts.py
import pyttsx3

def test_voices():
    engine = pyttsx3.init()
    voices = engine.getProperty("voices")

    print("🔊 Available voices:")
    for i, v in enumerate(voices):
        print(f"{i}: {v.name} ({v.id})")

    # Test first voice
    if voices:
        print(f"\n🧪 Testing first voice: {voices[0].name}")
        engine.setProperty("voice", voices[0].id)
        engine.say("Hello Shruti, I am the first available voice.")
        engine.runAndWait()

    # Test last voice
    if len(voices) > 1:
        print(f"\n🧪 Testing last voice: {voices[-1].name}")
        engine.setProperty("voice", voices[-1].id)
        engine.say("Hello Shruti, I am the last available voice.")
        engine.runAndWait()

if __name__ == "__main__":
    test_voices()
