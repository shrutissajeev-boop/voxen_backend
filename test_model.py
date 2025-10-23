import requests
import json

def load_config(path="config.json"):
    with open(path, "r") as f:
        config = json.load(f)

    provider = config["providers"]["openrouter"]

    if not provider["api_key"]:
        raise ValueError("❌ No OpenRouter API key found in config.json.")

    return provider

def chat_with_model(settings, messages):
    """Send messages to the model and get response"""
    url = settings["base_url"]
    headers = {
        "Authorization": f"Bearer {settings['api_key']}",
        "HTTP-Referer": "http://localhost",
        "X-Title": "NVIDIA-Chat-App",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": settings["default_model"],
        "messages": messages,
        "max_tokens": 500,  # More tokens for longer responses
        "temperature": 0.7,
        "stream": False
    }

    try:
        response = requests.post(url, headers=headers, json=data)
        
        if response.status_code == 200:
            result = response.json()
            message_obj = result["choices"][0]["message"]
            
            # Handle both content and reasoning fields
            content = message_obj.get("content", "")
            reasoning = message_obj.get("reasoning", "")
            
            # Use content if available, otherwise use reasoning
            final_response = content if content.strip() else reasoning
            
            return final_response.strip()
        else:
            return f"❌ Error {response.status_code}: {response.text}"
            
    except Exception as e:
        return f"❌ Connection error: {e}"

def main():
    print("🚀 Starting Interactive Chat with NVIDIA Model")
    print("Type 'quit', 'exit', or 'bye' to end the conversation")
    print("=" * 50)
    
    try:
        settings = load_config()
        print(f"🔑 Using model: {settings['default_model']}")
        print("=" * 50)
        
        # Initialize conversation with system message
        messages = [
            {"role": "system", "content": "You are a helpful assistant. Give direct, conversational responses without showing your reasoning process."}
        ]
        
        while True:
            # Get user input
            user_input = input("\n👤 You: ").strip()
            
            # Check for exit commands
            if user_input.lower() in ['quit', 'exit', 'bye', 'q']:
                print("\n👋 Goodbye!")
                break
            
            if not user_input:
                print("Please type something or 'quit' to exit.")
                continue
            
            # Add user message to conversation
            messages.append({"role": "user", "content": user_input})
            
            # Get response from model
            print("\n🤖 Assistant: ", end="", flush=True)
            response = chat_with_model(settings, messages)
            print(response)
            
            # Add assistant response to conversation history
            if not response.startswith("❌"):
                messages.append({"role": "assistant", "content": response})
            
            # Keep conversation history manageable (last 10 messages)
            if len(messages) > 11:  # 1 system + 10 conversation messages
                messages = messages[:1] + messages[-10:]
                
    except KeyboardInterrupt:
        print("\n\n👋 Chat interrupted. Goodbye!")
    except Exception as e:
        print(f"\n❌ Error starting chat: {e}")

if __name__ == "__main__":
    main()