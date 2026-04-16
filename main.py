# API Backend (FastAPI) - Run using: uvicorn backend:app --host 0.0.0.0 --port 8000
from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
import google.generativeai as genai
import os

app = FastAPI()

# CORS allow karne ke liye (Taki mobile app se request aa sake)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Gemini API Key setup (Render environment variables se lega)
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "YOUR_GEMINI_API_KEY_HERE")
genai.configure(api_key=GEMINI_API_KEY)

# Gemini 1.5 Flash model text aur image/PDF dono ke liye best hai
model = genai.GenerativeModel('gemini-1.5-flash')

@app.post("/api/chat")
async def chat_with_ai(
    userText: str = Form(...),
    userName: str = Form("User"),
    userContext: str = Form(""),
    extractedText: str = Form("") # Naya field: Phone OCR karke text yahan bhejegaa
):
    try:
        # Prompt banana
        prompt = (
            f"Tum ek friendly aur expert health assistant ho. User ka naam {userName} hai. "
            f"User ka context aur medical background: {userContext}. "
            f"Tumhe user ke sawal ka asaan Hinglish (Hindi+English) mein jawab dena hai. "
        )
        
        # Agar phone ne kisi image/PDF se text nikal kar bheja hai
        if extractedText.strip():
            prompt += f"\n\nUser ne ek medical document/report attach ki hai, jiska text ye raha:\n'''{extractedText}'''\nIs report ko dhyan se analyze karo aur user ko asaan bhasha mein samjhao."
            
        prompt += f"\n\nUser ka sawal: {userText}"

        # Gemini model se response generate karna (Ab sirf text prompt jaayega)
        response = model.generate_content(prompt)

        return {"status": "success", "reply": response.text}

    except Exception as e:
        return {"status": "error", "message": str(e)}