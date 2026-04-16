# API Backend (FastAPI) - Run using: uvicorn main:app --host 0.0.0.0 --port 8000
from fastapi import FastAPI, Form
from fastapi.middleware.cors import CORSMiddleware
import google.generativeai as genai
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

# Gemini API Key setup (Render environment variables se lega)
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
else:
    print("Warning: GEMINI_API_KEY environment variable not found.")

# Gemini model set karna ('gemini-1.5-flash' fast aur reliable hai)
model = genai.GenerativeModel('gemini-1.5-flash')

@app.post("/api/chat")
async def chat_with_ai(
    userText: str = Form(...),
    userName: str = Form("User"),
    userContext: str = Form(""),
    extractedText: str = Form("") # Phone OCR karke text yahan bhejega
):
    try:
        # AI ko uska role samjhane ke liye Prompt banana
        prompt = (
            f"Tum ek friendly aur expert health assistant ho. User ka naam {userName} hai. "
            f"User ka context aur medical background: {userContext}. "
            f"Tumhe user ke sawal ka asaan Hinglish (Hindi+English) mein jawab dena hai.\n"
        )
        
        # Agar phone ne kisi image/PDF se text nikal kar bheja hai toh usko prompt mein jorna
        if extractedText.strip():
            prompt += (
                f"\nUser ne ek medical document/report attach ki hai, jiska text ye raha:\n"
                f"'''{extractedText}'''\n"
                f"Is report ko dhyan se analyze karo aur user ko asaan bhasha mein samjhao.\n"
            )
            
        prompt += f"\nUser ka sawal: {userText}"

        # Gemini model se response generate karna
        response = model.generate_content(prompt)

        return {"status": "success", "reply": response.text}

    except Exception as e:
        return {"status": "error", "message": str(e)}
