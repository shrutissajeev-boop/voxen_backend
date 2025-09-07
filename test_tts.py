#!/usr/bin/env python3
"""
Simple TTS test script to verify pyttsx3 is working correctly
"""
import pyttsx3
import atexit

def cleanup_tts():
    """Clean up TTS engine properly"""
    try:
        if 'engine' in globals() and engine:
            engine.stop()
    except:
        pass

# Initialize TTS engine
engine = pyttsx3.init()
engine.setProperty("rate", 170)
engine.setProperty("volume", 1.0)

# Register cleanup function
atexit.register(cleanup_tts)

def test_tts():
    """Test TTS functionality"""
    print("🔊 Testing TTS...")
    engine.say("Hello! This is a test of the text to speech system.")
    engine.runAndWait()
    print("✅ TTS test completed successfully!")

if __name__ == "__main__":
    test_tts()
