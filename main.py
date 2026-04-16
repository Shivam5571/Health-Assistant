# API Backend (FastAPI) - Run using: uvicorn main:app --host 0.0.0.0 --port 8000
from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
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

# OpenAI API Key setup (Render environment variables se lega)
# Ensure you add OPENAI_API_KEY in your Render dashboard
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")

# Initialize OpenAI client
client = OpenAI(api_key=OPENAI_API_KEY)

@app.post("/api/chat")
async def chat_with_ai(
    userText: str = Form(...),
    userName: str = Form("User"),
    userContext: str = Form(""),
    extractedText: str = Form("") # Phone OCR karke text yahan bhejega
):
    try:
        # System prompt: AI ko uska role aur context batane ke liye
        system_prompt = (
            f"Tum ek friendly aur expert health assistant ho. User ka naam {userName} hai. "
            f"User ka context aur medical background: {userContext}. "
            f"Tumhe user ke sawal ka asaan Hinglish (Hindi+English) mein jawab dena hai."
        )
        
        # User message construct karna
        user_message = ""
        
        # Agar phone ne kisi image/PDF se text nikal kar bheja hai
        if extractedText.strip():
            user_message += f"User ne ek medical document/report attach ki hai, jiska text ye raha:\n'''{extractedText}'''\nIs report ko dhyan se analyze karo aur user ko asaan bhasha mein samjhao.\n\n"
            
        user_message += f"User ka sawal: {userText}"

        # OpenAI (ChatGPT) model se response generate karna (gpt-4o-mini is fast & cost-effective)
        response = client.chat.completions.create(
            model="gpt-4o-mini", # Aap "gpt-3.5-turbo" bhi use kar sakte hain
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ]
        )

        # ChatGPT ka reply nikalna
        reply = response.choices[0].message.content

        return {"status": "success", "reply": reply}

    except Exception as e:
        return {"status": "error", "message": str(e)}
    	
