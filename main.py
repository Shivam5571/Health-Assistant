from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
import os
from dotenv import load_dotenv
from openai import OpenAI

# ---------------- LOAD ENV ----------------
load_dotenv()

# ---------------- APP INIT ----------------
app = FastAPI(title="HealthFly Backend")

# ---------------- OPENAI CLIENT ----------------
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ---------------- MODELS ----------------
class UserInput(BaseModel):
    age: int
    height: float
    weight: float
    goal: str
    condition: str


class IngredientInput(BaseModel):
    ingredients: List[str]


class ChatInput(BaseModel):
    message: str


# ---------------- UTILS ----------------
def calculate_bmi(weight, height_cm):
    h = height_cm / 100
    return round(weight / (h * h), 2)


# ---------------- FOOD RECOMMENDATION ----------------
def recommend_food(goal):
    if goal == "weight_loss":
        return ["Oats", "Salad", "Fruits"]
    elif goal == "weight_gain":
        return ["Rice", "Milk", "Banana"]
    else:
        return ["Balanced Diet"]


# ---------------- INGREDIENT RULES ----------------
INGREDIENT_RULES = {
    "sugar": {"status": "Avoid ❌", "reason": "High blood sugar spike"},
    "palm oil": {"status": "Limit ⚠️", "reason": "High saturated fat"},
    "maida": {"status": "Avoid ❌", "reason": "Low nutrition, high GI"},
    "oats": {"status": "Safe ✅", "reason": "High fiber, good for digestion"},
    "olive oil": {"status": "Safe ✅", "reason": "Healthy fats"},
}

# ---------------- ROUTES ----------------

@app.get("/")
def root():
    return {"status": "Backend running"}


# -------- BMI + FOOD RECOMMENDATION --------
@app.post("/recommend")
def recommend(user: UserInput):
    bmi = calculate_bmi(user.weight, user.height)
    foods = recommend_food(user.goal)

    return {
        "bmi": bmi,
        "recommended_food": foods
    }


# -------- INGREDIENT CHECKER --------
@app.post("/check-ingredients")
def check_ingredients(data: IngredientInput):
    results = []

    for item in data.ingredients:
        key = item.lower().strip()
        if key in INGREDIENT_RULES:
            rule = INGREDIENT_RULES[key]
            results.append({
                "ingredient": item,
                "status": rule["status"],
                "reason": rule["reason"]
            })
        else:
            results.append({
                "ingredient": item,
                "status": "Unknown",
                "reason": "No data available"
            })

    return {"results": results}


# -------- AI CHAT (LLM + FALLBACK) --------
@app.post("/chat")
def chat(data: ChatInput):
    user_message = data.message.lower()

    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a friendly AI health assistant. "
                        "Give food and lifestyle advice only. "
                        "Do not provide medical diagnosis or medicines."
                    )
                },
                {
                    "role": "user",
                    "content": user_message
                }
            ],
            max_tokens=120,
            temperature=0.6,
        )

        reply = response.choices[0].message.content

    except Exception as e:
        print("LLM ERROR (fallback used):", e)

        # 🔥 SMART FALLBACK LOGIC
        if "weight loss" in user_message:
            reply = (
                "For weight loss, focus on portion control, "
                "eat more vegetables, and include daily physical activity."
            )
        elif "weight gain" in user_message:
            reply = (
                "For weight gain, eat calorie-dense healthy foods "
                "like nuts, milk, bananas, and strength training."
            )
        elif "diabetes" in user_message:
            reply = (
                "For diabetes, avoid sugar and refined carbs, "
                "and prefer high-fiber foods like oats and vegetables."
            )
        elif "exercise" in user_message:
            reply = (
                "Regular walking, yoga, and light strength exercises "
                "are beneficial for overall health."
            )
        else:
            reply = (
                "Maintaining a balanced diet, staying hydrated, "
                "and regular exercise are key to good health."
            )

    return {"reply": reply}
