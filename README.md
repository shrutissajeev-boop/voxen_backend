<<<<<<< HEAD
# voxen_backend
it contains the whisper and piper code
=======
# Voxen Backend - Speech-to-Speech AI Assistant

A FastAPI-based speech-to-speech AI assistant that uses Whisper for speech recognition, OpenRouter for AI responses, and pyttsx3 for text-to-speech synthesis.

## 🚀 Features

- **Speech Recognition**: Uses OpenAI Whisper model for accurate speech-to-text transcription
- **AI Responses**: Integrates with OpenRouter API for intelligent conversational responses
- **Text-to-Speech**: Converts AI responses to natural-sounding speech using pyttsx3
- **FastAPI Backend**: RESTful API endpoints for chat and voice interactions
- **CORS Enabled**: Ready for frontend integration

## 📋 Prerequisites

- Python 3.8 or higher
- Microphone for voice input
- OpenRouter API key (get one at [openrouter.ai](https://openrouter.ai))

## 🔧 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/shrutissajeev-boop/voxen_backend.git
   cd voxen_backend
   ```

2. **Create a virtual environment**
   ```bash
   python -m venv .venv
   .venv\Scripts\activate  # On Windows
   # source .venv/bin/activate  # On macOS/Linux
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure API settings**
   
   Create a `config.json` file in the root directory:
   ```json
   {
     "providers": {
       "openrouter": {
         "base_url": "https://openrouter.ai/api/v1/chat/completions",
         "api_key": "your-openrouter-api-key-here",
         "default_model": "deepseek/deepseek-r1-0528-qwen3-8b:free"
       }
     },
     "default_provider": "openrouter"
   }
   ```

## 🎯 Usage

### Running the Server

Start the FastAPI server:
```bash
uvicorn server:app --reload --port 8000
```

The server will be available at `http://localhost:8000`

### API Endpoints

#### 1. Chat Endpoint
**POST** `/api/chat`

Send a text message and receive an AI response with audio.

**Request Body:**
```json
{
  "message": "Hello, how are you?"
}
```

**Response:**
```json
{
  "reply": "I'm doing well, thank you for asking!",
  "audio_base64": "base64_encoded_audio_data"
}
```

#### 2. Listen Endpoint
**GET** `/api/listen`

Capture voice input from the microphone and transcribe it.

**Response:**
```json
{
  "message": "transcribed text from microphone"
}
```

#### 3. Profile Endpoint
**GET** `/api/profile`

Get user profile information.

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

## 📁 Project Structure

```
voxen_backend/
├── server.py              # Main FastAPI application
├── main.py                # Core speech recognition and TTS functions
├── config.json            # API configuration (not in git)
├── requirements.txt       # Python dependencies
├── .env.example          # Environment variables template
├── .gitignore            # Git ignore rules
├── test_model.py         # Model testing utilities
├── test_tts.py           # TTS testing utilities
├── check_env.py          # Environment checker
└── README.md             # This file
```

## 🔐 Security Notes

- **Never commit your `config.json`** with real API keys
- The `config.json` file is gitignored by default
- Use environment variables for production deployments
- Keep your OpenRouter API key secure

## 🛠️ Dependencies

- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `openai-whisper` - Speech recognition
- `pyttsx3` - Text-to-speech
- `speechrecognition` - Audio capture
- `pyaudio` - Audio I/O
- `requests` - HTTP client
- `python-dotenv` - Environment management

## 🐛 Troubleshooting

### PyAudio Installation Issues
If you encounter issues installing PyAudio on Windows:
```bash
pip install pipwin
pipwin install pyaudio
```

### Microphone Not Working
- Check microphone permissions in system settings
- Ensure no other application is using the microphone
- Test with `test_tts.py` to verify audio setup

### OpenRouter API Errors
- Verify your API key is correct in `config.json`
- Check your OpenRouter account has sufficient credits
- Enable "Free model publication" in OpenRouter privacy settings for free models

## 📝 License

This project is open source and available under the MIT License.

## 👤 Author

**Shruti S Sajeev**
- GitHub: [@shrutissajeev-boop](https://github.com/shrutissajeev-boop)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## ⭐ Show your support

Give a ⭐️ if this project helped you!
>>>>>>> ef90493 (Add FastAPI server, comprehensive README, and updated dependencies)
