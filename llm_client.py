import json
import requests

class LLMClient:
    def __init__(self, provider_name=None, config_path="config.json"):
        # Load provider settings from JSON
        with open(config_path, "r") as f:
            config = json.load(f)

        # If provider not passed, use default from config.json
        if not provider_name:
            provider_name = config.get("default_provider")

        providers = config.get("providers", {})
        if provider_name not in providers:
            raise ValueError(f"❌ Provider '{provider_name}' not found in config.json")

        provider = providers[provider_name]

        # Read provider details
        self.provider_name = provider_name
        self.base_url = provider["base_url"]
        self.model = provider.get("default_model")
        self.api_key = provider["api_key"]

        # Setup headers
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        # Log startup message
        print(f"✅ Connected to provider: {self.provider_name} | model: {self.model}")

    def chat(self, messages, model=None):
        """
        messages = [{"role": "user", "content": "Hello!"}]
        """
        data = {
            "model": model or self.model,
            "messages": messages
        }

        # Debug request payload
        print("DEBUG Request Payload:", json.dumps(data, indent=2))

        # Make API request
        response = requests.post(self.base_url, headers=self.headers, json=data)

        if response.status_code != 200:
            print("❌ API returned:", response.text)
            response.raise_for_status()

        try:
            reply = response.json()["choices"][0]["message"]["content"]
            return reply.strip()
        except Exception as e:
            print("⚠️ Parse Error:", e, "| Raw response:", response.text)
            return "⚠️ AI did not return a valid response."
