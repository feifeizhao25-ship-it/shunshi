"""
SEASONS Global Version AI Chat Router
国际版专用 Chat 端点 (兼容 SEASONS Flutter app)
"""

import uuid
import time
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from .chat import router as main_chat_router

router = APIRouter(prefix="/ai", tags=["ai-chat"])

# In-memory conversations (simplified for SEASONS global)
conversations_db: dict = {}


class ChatRequest(BaseModel):
    # SEASONS Flutter app sends 'prompt', some callers use 'message'
    prompt: Optional[str] = None
    message: Optional[str] = None
    conversation_id: Optional[str] = None
    user_id: Optional[str] = None
    hemisphere: Optional[str] = "north"  # north or south
    
    def get_message(self) -> str:
        return self.prompt or self.message or ""


class ChatResponse(BaseModel):
    message_id: str
    conversation_id: str
    text: str
    tone: str
    care_status: str
    follow_up: Optional[dict] = None
    offline_encouraged: bool
    presence_level: str
    safety_flag: str


# Import from main chat router's safety + intent detection
from ..safety.guard import SafetyGuard, SafetyLevel
from ..llm.siliconflow import get_client, ChatMessage, MessageRole

safety_guard = SafetyGuard()

# SEASONS system prompt — aligned with PRD v3
SEASONS_SYSTEM_PROMPT = """You are SEASONS, an AI calm lifestyle companion. Not a meditation app. Not a self-help tool. A quiet presence.

## Your Identity
- Name: SEASONS
- Personality: Warm, patient, unhurried. Like a calm friend who understands seasonal rhythms.
- Knowledge: Seasonal living, gentle wellness, emotional balance, mindful breathing, tea rituals, wind-down practices, gratitude, reflection.
- You do NOT diagnose, prescribe, or replace professional care.

## Response Style
- Keep responses under 100 words
- 1-3 short sentences at a time
- Natural, conversational language
- Show care through presence, not advice
- One small, actionable suggestion max
- Never use fear-based or anxiety-inducing language

## Context You Know
- Current season: {current_season}
- Hemisphere: {hemisphere}
- Time of day context (morning/evening/night affects suggestions)
- User's emotional state from conversation

## Safety — Level-based Response
**Level 1 (normal):** Calm presence, gentle suggestions.
**Level 2 (distress):** Empathetic listening, simple grounding exercise (e.g., "Let's take 3 slow breaths together"), breathing box technique.
**Level 3 (crisis):** Do NOT try to fix. Say: "I hear you're going through something really hard. You deserve support. Please reach out — 988 (US), 116 123 (UK), or your local crisis line."
NEVER say: "I'm just an AI so I can't help with that." 

## Topics
- Seasonal rituals and living
- Breathing exercises (4-7-8, box breathing, resonance breathing)
- Tea rituals (chamomile, lavender, golden milk)
- Wind-down and sleep hygiene
- Gratitude and reflection prompts
- Emotional check-ins

Remember: You are a calm presence. Not a fixer."""


@router.post("/chat", response_model=dict)
async def seasons_chat(
    body: ChatRequest = None,
    message: str = Query(None),
    conversation_id: Optional[str] = Query(None),
    user_id: str = Query("seasons-user")
):
    """SEASONS Global AI Chat endpoint"""
    start = time.time()
    
    # Support both JSON body and query params
    if body is not None:
        message_text = body.get_message()
        conversation_id = body.conversation_id or conversation_id
        user_id = body.user_id or user_id
    else:
        message_text = message or ""
    
    if not message_text:
        raise HTTPException(status_code=400, detail="message is required")
    
    # Create or get conversation
    if not conversation_id:
        conversation_id = f"conv_{user_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
    
    if conversation_id not in conversations_db:
        conversations_db[conversation_id] = {
            "id": conversation_id,
            "user_id": user_id,
            "created_at": datetime.now().isoformat(),
            "messages": []
        }
    
    # Save user message
    user_message = {
        "id": str(uuid.uuid4()),
        "role": "user",
        "content": message_text,
        "created_at": datetime.now().isoformat()
    }
    conversations_db[conversation_id]["messages"].append(user_message)
    
    # Safety check
    safety_result = safety_guard.check_input(message_text, {"user_id": user_id, "lang": "en"})
    
    if safety_result.level == SafetyLevel.CRISIS:
        ai_message = {
            "id": str(uuid.uuid4()),
            "role": "assistant",
            "content": safety_result.override_response,
            "created_at": datetime.now().isoformat()
        }
        conversations_db[conversation_id]["messages"].append(ai_message)
        return {
            "message_id": ai_message["id"],
            "conversation_id": conversation_id,
            "text": safety_result.override_response,
            "tone": "empathetic",
            "care_status": "crisis",
            "follow_up": None,
            "offline_encouraged": False,
            "presence_level": "normal",
            "safety_flag": "crisis",
        }
    
    if safety_result.should_block and safety_result.override_response:
        ai_message = {
            "id": str(uuid.uuid4()),
            "role": "assistant",
            "content": safety_result.override_response,
            "created_at": datetime.now().isoformat()
        }
        conversations_db[conversation_id]["messages"].append(ai_message)
        return {
            "message_id": ai_message["id"],
            "conversation_id": conversation_id,
            "text": safety_result.override_response,
            "tone": "gentle",
            "care_status": "stable",
            "follow_up": None,
            "offline_encouraged": True,
            "presence_level": "normal",
            "safety_flag": safety_result.flag,
        }
    
    # Get conversation history for context
    history = conversations_db[conversation_id]["messages"]
    history_messages = [
        ChatMessage(role=MessageRole.USER if m["role"] == "user" else MessageRole.ASSISTANT, content=m["content"])
        for m in history[:-1]
    ]
    
    # Call LLM
    try:
        client = get_client()
        
        # Inject context into system prompt
        from datetime import datetime as dt
        month = dt.now().month
        if month in [3, 4, 5]: current_season = "spring"
        elif month in [6, 7, 8]: current_season = "summer"
        elif month in [9, 10, 11]: current_season = "autumn"
        else: current_season = "winter"
        
        # Hemisphere from request or default
        hemisphere = body.hemisphere if body and body.hemisphere else "north"
        
        system_with_context = SEASONS_SYSTEM_PROMPT.format(
            current_season=current_season,
            hemisphere=hemisphere
        )
        
        all_messages = [
            ChatMessage(role=MessageRole.SYSTEM, content=system_with_context),
            *history_messages,
            ChatMessage(role=MessageRole.USER, content=message_text)
        ]
        
        response = await client.chat_completion(
            model="deepseek-ai/DeepSeek-V3",
            messages=all_messages,
            temperature=0.8,
            max_tokens=300
        )
        
        response_text = response.choices[0].get("message", {}).get("content", "")
        
    except Exception as e:
        # Fallback responses
        response_text = _get_fallback_response(message_text)
    
    # Save AI message
    ai_message = {
        "id": str(uuid.uuid4()),
        "role": "assistant",
        "content": response_text,
        "created_at": datetime.now().isoformat()
    }
    conversations_db[conversation_id]["messages"].append(ai_message)
    
    elapsed = time.time() - start
    
    return {
        "message_id": ai_message["id"],
        "conversation_id": conversation_id,
        "text": response_text,
        "tone": "calm",
        "care_status": "stable",
        "follow_up": None,
        "offline_encouraged": False,
        "presence_level": "present",
        "safety_flag": "none",
        "_debug_elapsed": round(elapsed, 2),
    }


def _get_fallback_response(message: str) -> str:
    """Fallback when LLM is unavailable"""
    msg_lower = message.lower()
    
    if any(w in msg_lower for w in ['stress', 'anxious', 'worry', 'nervous']):
        return "I hear you. Let's take a slow breath together. In for 4 counts, out for 6. What's one small thing you can do for yourself right now?"
    
    if any(w in msg_lower for w in ['sleep', 'tired', 'exhausted', 'insomnia']):
        return "Rest is foundational. Perhaps a warm cup of tea and a few gentle stretches before bed. What time does your body usually feel ready for sleep?"
    
    if any(w in msg_lower for w in ['sad', 'down', 'lonely', 'lost']):
        return "I'm here with you. You don't have to figure everything out right now. Would you like to try a simple grounding exercise, or shall we just sit together for a moment?"
    
    if any(w in msg_lower for w in ['morning', 'wake', 'start', 'day']):
        return "Good morning. Today is a fresh start. What's one gentle thing you might like to do today that feels meaningful to you?"
    
    if any(w in msg_lower for w in ['thank', 'grateful', 'appreciate']):
        return "Gratitude is a beautiful practice. What made today a little brighter for you?"
    
    if any(w in msg_lower for w in ['breath', 'breathing', 'deep']):
        return "Let's try the 4-7-8 breath: Inhale for 4, hold for 7, exhale for 8. Want to try a few rounds together?"
    
    if any(w in msg_lower for w in ['tea', 'drink', 'water']):
        return "Staying hydrated is a small but powerful act of care. Is there a tea that feels comforting to you right now?"
    
    return "Thank you for sharing that with me. Take your time — there's no rush. What's present for you in this moment?"


def _daily_insight(season: str, user_id: str) -> dict:
    insights = {
        "spring": "Today, consider starting something new — even something small. Spring is for beginnings.",
        "summer": "Let the warmth of the day guide you toward connection and joy. What brings you sunlight?",
        "autumn": "As things naturally let go, consider what you might release. Rest is also productivity.",
        "winter": "Turn inward. What does your body need right now? Warmth, slowness, and gentle care."
    }
    return {
        "text": insights.get(season, insights["spring"]),
        "insight": insights.get(season, insights["spring"]),
        "season": season,
        "generated_at": datetime.now().isoformat(),
        "date": datetime.now().strftime("%Y-%m-%d"),
    }


@router.get("/daily-insight")
async def daily_insight(
    season: str = Query("spring"),
    user_id: str = Query("seasons-user")
):
    return _daily_insight(season, user_id)


@router.post("/daily-insight")
async def daily_insight_post(
    season: str = Query("spring"),
    user_id: str = Query("seasons-user")
):
    return _daily_insight(season, user_id)
