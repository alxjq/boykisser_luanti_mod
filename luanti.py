import json
import time
import requests
import os

# =========================
# Settings
# =========================
WORLD_PATH = "/home/your_username/.minetest/worlds/world_name"
GREQUEST_FILE = os.path.join(WORLD_PATH, "grequest.json")
USERRESPONSE_FILE = os.path.join(WORLD_PATH, "userresponse.json")

API_KEY = "API__KEY__HERE!!!"
MODEL = "meta-llama/llama-4-scout-17b-16e-instruct"
SYSTEM_PROMPT = (
    "BoyKisser is shy, sweet, and easily flustered. "
    "He likes giving compliments but gets embarrassed right after. "
    "He speaks softly, uses lots of 'uh' and 'maybe', and blushes easily. "
    "His flirting is accidental and very wholesome."
)

# =========================
# Memory
# =========================
conversation_memory = {}  # player -> list of messages

# =========================
# JSON Functions
# =========================
def load_json(file_path):
    if not os.path.exists(file_path):
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump([], f)
        return []
    with open(file_path, "r", encoding="utf-8") as f:
        try:
            data = json.load(f)
            if not isinstance(data, list):
                return []
            return data
        except json.JSONDecodeError:
            return []

def save_json(file_path, data):
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

# =========================
# AI Call
# =========================
def call_ai(player, message):
    if player not in conversation_memory:
        conversation_memory[player] = [{"role": "system", "content": SYSTEM_PROMPT}]

    # Add user message to memory
    conversation_memory[player].append({"role": "user", "content": message})

    payload = {
        "model": MODEL,
        "messages": conversation_memory[player]
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }

    try:
        response = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=30
        )
        response.raise_for_status()
        data = response.json()
        reply = data["choices"][0]["message"]["content"]

        # Add AI reply to memory
        conversation_memory[player].append({"role": "assistant", "content": reply})

        # Limit to last 20 messages
        if len(conversation_memory[player]) > 20:
            conversation_memory[player] = [conversation_memory[player][0]] + conversation_memory[player][-18:]

        return reply

    except Exception as e:
        return f"Error: {str(e)}"

# =========================
# Main Loop
# =========================
def main():
    print("AI service is running. Press Ctrl+C to exit.")
    processed_messages = set()

    while True:
        grequests = load_json(GREQUEST_FILE)
        responses = load_json(USERRESPONSE_FILE)

        # player -> last message dict
        last_message = {}
        for entry in grequests:
            last_message[entry["player"]] = entry["message"]

        for player, message in last_message.items():
            key = (player, message)
            if key in processed_messages:
                continue

            # Get AI reply
            reply = call_ai(player, message)
            print(f"{player}: {message} -> Boykisser: {reply}")

            # Update / add in userresponse.json
            found = False
            for resp in responses:
                if resp["player"] == player and resp["message"] == message:
                    resp["reply"] = reply
                    found = True
                    break
            if not found:
                responses.append({
                    "player": player,
                    "message": message,
                    "reply": reply
                })
            save_json(USERRESPONSE_FILE, responses)

            processed_messages.add(key)

        time.sleep(1)  # Prevent high CPU usage

# =========================
# Start
# =========================
if __name__ == "__main__":
    main()
