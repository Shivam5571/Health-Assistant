# API Backend (FastAPI) - Run using: uvicorn main:app --host 0.0.0.0 --port 8000
from fastapi import FastAPI, Form
from fastapi.middleware.cors import CORSMiddleware
import requests
import os

app = FastAPI()

# CORS allow karne ke liye (Taki mobile app/frontend se request aa sake)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Gemini API Key setup
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

@app.post("/api/chat")
async def chat_with_ai(
    userText: str = Form(...),
    userName: str = Form("User"),
    userContext: str = Form(""),
    extractedText: str = Form("") # Phone OCR karke text yahan bhejega
):
    try:
        if not GEMINI_API_KEY:
            return {"status": "error", "message": "API Key missing in Render Environment!"}

        # Prompt banana
        prompt = (
            f"Tum ek friendly aur expert health assistant ho. User ka naam {userName} hai. "
            f"User ka context aur medical background: {userContext}. "
            f"Tumhe user ke sawal ka asaan Hinglish (Hindi+English) mein jawab dena hai.\n"
        )
        
        if extractedText.strip():
            prompt += (
                f"\nUser ne ek medical document/report attach ki hai, jiska text ye raha:\n"
                f"'''{extractedText}'''\n"
                f"Is report ko dhyan se analyze karo aur user ko asaan bhasha mein samjhao.\n"
            )
            
        prompt += f"\nUser ka sawal: {userText}"

        # Google Generative AI SDK ke bina Direct API Call (Ye kabhi version error nahi dega)
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={GEMINI_API_KEY}"
        
        payload = {
            "contents": [{"parts": [{"text": prompt}]}]
        }
        
        headers = {"Content-Type": "application/json"}

        # API Request bhejna
        response = requests.post(url, json=payload, headers=headers)
        data = response.json()

        # Agar API se error aaye (jaise invalid key)
        if response.status_code != 200:
            return {"status": "error", "message": f"Google API Error: {data.get('error', {}).get('message', 'Unknown error')}"}

        # Reply nikalna
        reply_text = data['candidates'][0]['content']['parts'][0]['text']

        return {"status": "success", "reply": reply_text}

    except Exception as e:
        return {"status": "error", "message": str(e)}
