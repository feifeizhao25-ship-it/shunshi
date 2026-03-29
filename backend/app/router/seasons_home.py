"""
SEASONS Global Version - Home Dashboard & User Profile API
"""

import uuid
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons-home"])

# In-memory user profiles
user_profiles_db: dict = {}

# Hemisphere-aware season logic
def _get_season_for_hemisphere(month: int, hemisphere: str = "north") -> str:
    """Get season name based on month and hemisphere"""
    # Northern hemisphere default
    if month in [3, 4, 5]:
        season = "spring"
    elif month in [6, 7, 8]:
        season = "summer"
    elif month in [9, 10, 11]:
        season = "autumn"
    else:
        season = "winter"
    
    # Southern hemisphere is opposite
    if hemisphere == "south":
        opposite = {"spring": "autumn", "summer": "winter", "autumn": "spring", "winter": "summer"}
        season = opposite.get(season, season)
    
    return season


def _get_season_phase(month: int) -> str:
    """Get early/mid/late phase within season"""
    phase_map = {
        3: "early", 4: "mid", 5: "late",      # spring
        6: "early", 7: "mid", 8: "late",      # summer
        9: "early", 10: "mid", 11: "late",     # autumn
        12: "early", 1: "mid", 2: "late"      # winter
    }
    return phase_map.get(month, "early")


def _get_current_season_full(hemisphere: str = "north") -> dict:
    """Get complete season data including phase"""
    now = datetime.now()
    month = now.month
    season = _get_season_for_hemisphere(month, hemisphere)
    phase = _get_season_phase(month)
    return {"season": season, "phase": phase, "hemisphere": hemisphere}


# Daily insights database
DAILY_INSIGHTS = {
    "spring": [
        "Spring energy is building inside you. Today is a wonderful day to start something small — a new route, a new recipe, a new breath.",
        "Like the earth after winter, this is your time to plant seeds. Not big changes — just one small thing that feels meaningful.",
        "The longer days are an invitation to move a little more, eat a little lighter, and open yourself to what the world is offering.",
    ],
    "summer": [
        "The warmth of summer invites you to move your body and soak in the light. Stay hydrated. Make time for what makes you come alive.",
        "Long days can be energizing or exhausting. Notice which it is for you today, and adjust accordingly.",
        "Summer is fleeting. Take a moment today to really notice the warmth on your skin — these days won't last forever.",
    ],
    "autumn": [
        "Autumn whispers: slow down. As the leaves let go, you too can release what you've been carrying. One small thing. Just let it go.",
        "This is the season of transition. Whatever you're in between right now — let it be okay. Not everything needs to be resolved today.",
        "The season is changing whether you rush it or not. Instead of fighting the shift, what if you let it guide your evening routine tonight?",
    ],
    "winter": [
        "Winter is not emptiness — it's depth. Beneath the quiet surface, roots are growing. Give yourself permission to rest deeply today.",
        "The shorter days are not a punishment — they're an invitation inward. What does your inner landscape need right now?",
        "Stillness is productive too. Even five quiet minutes of doing nothing is a practice in a world that never stops.",
    ],
}


# Personalized insights based on feeling + season + help_goal
PERSONALIZED_INSIGHTS = {
    # feeling=calm
    ("calm", "sleep"): ["A calm mind is the best sleep companion. Tonight, let stillness be your practice."],
    ("calm", "unwind"): ["Your calm is a gift you give yourself. Savor it with a gentle evening ritual."],
    ("calm", "calm"): ["Your calm is a quiet strength. Nurture it like a still pond that reflects clearly."],
    ("calm", "ritual"): ["With a calm heart, even simple rituals become sacred. What small ceremony calls to you today?"],
    ("calm", "reflect"): ["A calm mind is perfect for reflection. What have you been quietly knowing?"],
    # feeling=stressed
    ("stressed", "sleep"): ["Stress melts when you exhale. Take three slow breaths now — your sleep will thank you."],
    ("stressed", "unwind"): ["Your shoulders carry so much. Tonight, let them drop. You've done enough today."],
    ("stressed", "calm"): ["The stress is temporary, but your inner calm is always there, like sky behind clouds."],
    ("stressed", "ritual"): ["A small ritual can be an anchor in storm. What one thing can you return to?"],
    ("stressed", "reflect"): ["When stress clouds the mind, writing helps. One sentence about today is enough."],
    # feeling=tired
    ("tired", "sleep"): ["Your tiredness is your body asking for rest. Tonight, give it what it truly needs."],
    ("tired", "unwind"): ["Tiredness is not laziness — it's your body whispering for gentleness."],
    ("tired", "calm"): ["Even the river rests. Your tiredness is calling you toward stillness."],
    ("tired", "ritual"): ["When tired, the simplest ritual is enough. A warm drink, a quiet moment."],
    ("tired", "reflect"): ["Tiredness often holds wisdom. What is your tiredness trying to tell you?"],
    # feeling=overwhelmed
    ("overwhelmed", "sleep"): ["One breath at a time. That's all tonight asks of you."],
    ("overwhelmed", "unwind"): ["When everything feels like too much, step back. One thing. Just one."],
    ("overwhelmed", "calm"): ["The storm passes. Right now, you're safe inside your own calm center."],
    ("overwhelmed", "ritual"): ["Rituals bring order from chaos. One small anchor — a breath, a cup, a moment."],
    ("overwhelmed", "reflect"): ["Overwhelm shrinks when we name it. One word: how do you feel right now?"],
    # feeling=curious
    ("curious", "sleep"): ["Even your dreams are exploring tonight. Let curiosity guide you to gentle rest."],
    ("curious", "unwind"): ["Your curiosity is alive! Let it wander — but toward rest, not more stimulation."],
    ("curious", "calm"): ["Curiosity and calm coexist beautifully. You can be both interested and at peace."],
    ("curious", "ritual"): ["What ritual speaks to your curiosity? Something old, something new — explore."],
    ("curious", "reflect"): ["Your curiosity is a compass. What is it pointing you toward today?"],
}


def _generate_daily_insight(season: str, feeling: str = None, help_goal: str = None) -> str:
    """Get a deterministic daily insight based on date + season (+ feeling + help_goal if available)"""
    import hashlib
    today = datetime.now().strftime("%Y-%m-%d")
    
    # Try personalized insight first
    if feeling and help_goal:
        key = (feeling.lower(), help_goal.lower())
        if key in PERSONALIZED_INSIGHTS:
            pool = PERSONALIZED_INSIGHTS[key]
            hash_val = int(hashlib.md5(f"{today}-{feeling}-{help_goal}".encode()).hexdigest()[:8], 16)
            base_insight = pool[hash_val % len(pool)]
            # Append season-specific note
            season_note = _get_season_personalization_note(season)
            return f"{base_insight} {season_note}"
    
    # Fall back to season-based insight
    key = f"{today}-{season}"
    hash_val = int(hashlib.md5(key.encode()).hexdigest()[:8], 16)
    insights = DAILY_INSIGHTS.get(season, DAILY_INSIGHTS["spring"])
    return insights[hash_val % len(insights)]


def _get_season_personalization_note(season: str) -> str:
    """Get a short seasonal note to append to personalized insights"""
    notes = {
        "spring": "🌱 Spring is stirring — let yourself begin again.",
        "summer": "☀️ The warmth is with you — stay hydrated, stay present.",
        "autumn": "🍂 Autumn is release — let what no longer serves you fall away.",
        "winter": "❄️ Winter is rest — give yourself permission to slow down.",
    }
    return notes.get(season, "")


# Gentle suggestions database
GENTLE_SUGGESTIONS = {
    "morning": [
        {"icon": "🌅", "text": "Take three slower breaths before checking your phone", "duration": "1 min", "category": "breathing"},
        {"icon": "☕", "text": "Make a warm drink and just hold it for a moment", "duration": "2 min", "category": "ritual"},
        {"icon": "🚶", "text": "Step outside, even for 60 seconds", "duration": "1 min", "category": "movement"},
    ],
    "afternoon": [
        {"icon": "🌿", "text": "Pause and take 5 deep breaths", "duration": "1 min", "category": "breathing"},
        {"icon": "💧", "text": "Drink a full glass of water", "duration": "1 min", "category": "wellness"},
        {"icon": "👀", "text": "Look away from your screen for 2 minutes", "duration": "2 min", "category": "awareness"},
    ],
    "evening": [
        {"icon": "🍵", "text": "Make a cup of caffeine-free tea", "duration": "5 min", "category": "ritual"},
        {"icon": "📖", "text": "Read something that has nothing to do with work", "duration": "10 min", "category": "unwind"},
        {"icon": "🌙", "text": "Dim the lights 20 minutes earlier tonight", "duration": "1 min", "category": "sleep"},
    ],
    "any": [
        {"icon": "🫁", "text": "Breathe slowly: 4 in, 7 hold, 8 out", "duration": "2 min", "category": "breathing"},
        {"icon": "💜", "text": "Stretch your shoulders and neck gently", "duration": "3 min", "category": "movement"},
        {"icon": "📝", "text": "Write one sentence about how you feel", "duration": "2 min", "category": "reflection"},
    ],
}


def _get_suggestions_for_time(time_of_day: str, limit: int = 3) -> List[dict]:
    """Get contextual suggestions"""
    primary = GENTLE_SUGGESTIONS.get(time_of_day, GENTLE_SUGGESTIONS["any"])
    any_suggestions = GENTLE_SUGGESTIONS["any"]
    
    suggestions = primary[:min(2, len(primary))]
    if len(suggestions) < limit:
        for s in any_suggestions:
            if s not in suggestions:
                suggestions.append(s)
            if len(suggestions) >= limit:
                break
    
    return suggestions[:limit]


# ==================== Request/Response Models ====================

class UserProfileCreate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    hemisphere: Optional[str] = "north"
    timezone: Optional[str] = "UTC"
    country: Optional[str] = "US"
    locale: Optional[str] = "en"
    preferences: Optional[dict] = None


class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    hemisphere: Optional[str] = None
    timezone: Optional[str] = None
    country: Optional[str] = None
    locale: Optional[str] = None
    preferences: Optional[dict] = None
    memory_enabled: Optional[bool] = True
    notifications_enabled: Optional[bool] = True
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None


class OnboardingData(BaseModel):
    feeling: Optional[str] = None       # calm/stressed/tired/overwhelmed/curious
    help_goal: Optional[str] = None     # sleep/unwind/calm/ritual/reflect
    life_stage: Optional[str] = None    # student/professional/parent/midlife/retired
    support_time: Optional[str] = None  # morning/afternoon/evening
    style_preference: Optional[str] = None  # minimal/gentle/active
    hemisphere: Optional[str] = "north"
    timezone: Optional[str] = "UTC"
    country: Optional[str] = "US"


# ==================== Onboarding ====================

@router.post("/onboarding/complete")
async def complete_onboarding(body: OnboardingData):
    """Save onboarding data and return first dashboard data"""
    user_id = f"seasons-{uuid.uuid4().hex[:8]}"
    
    now = datetime.now()
    hemisphere = body.hemisphere or "north"
    season_data = _get_current_season_full(hemisphere)
    season = season_data["season"]
    support_time = body.support_time or "evening"
    
    # Create user profile
    profile = {
        "id": user_id,
        "created_at": now.isoformat(),
        "feeling": body.feeling,
        "help_goal": body.help_goal,
        "life_stage": body.life_stage,
        "support_time": support_time,
        "style_preference": body.style_preference,
        "hemisphere": hemisphere,
        "timezone": body.timezone or "UTC",
        "country": body.country or "US",
        "locale": "en",
        "memory_enabled": True,
        "notifications_enabled": True,
        "subscription": "free",
        "streak": 0,
        "reflections_count": 0,
        "first_insight_generated": True,
    }
    user_profiles_db[user_id] = profile
    
    # Generate first personalized insight
    first_insight = _generate_daily_insight(season, feeling=body.feeling, help_goal=body.help_goal)
    suggestions = _get_suggestions_for_time(support_time, limit=3)
    
    return {
        "user_id": user_id,
        "onboarding_completed": True,
        "dashboard": {
            "greeting": _get_greeting(now.hour),
            "daily_insight": {
                "id": f"insight-{uuid.uuid4().hex[:8]}",
                "text": first_insight,
                "season": season,
                "generated_at": now.isoformat(),
            },
            "suggestions": suggestions,
            "season_card": {
                "name": season.capitalize(),
                "phase": season_data["phase"],
                "insight": first_insight,
                "emoji": _get_season_emoji(season),
            },
        },
    }


def _get_season_emoji(season: str) -> str:
    return {"spring": "🌱", "summer": "☀️", "autumn": "🍂", "winter": "❄️"}.get(season, "🌿")


# ==================== Home Dashboard ====================

@router.get("/home/dashboard")
async def get_home_dashboard(
    user_id: str = Query(...),
    hemisphere: str = Query("north"),
):
    """Get personalized home dashboard"""
    now = datetime.now()
    season_data = _get_current_season_full(hemisphere)
    season = season_data["season"]
    
    # Get user profile if exists
    profile = user_profiles_db.get(user_id, {})
    support_time = profile.get("support_time", "evening")
    
    # Generate insight
    daily_insight = _generate_daily_insight(season)
    
    # Get suggestions based on user preference
    suggestions = _get_suggestions_for_time(support_time, limit=3)
    
    return {
        "greeting": _get_greeting(now.hour, profile.get("name")),
        "daily_insight": {
            "id": f"insight-{uuid.uuid4().hex[:8]}",
            "text": daily_insight,
            "season": season,
            "phase": season_data["phase"],
            "generated_at": now.isoformat(),
        },
        "suggestions": suggestions,
        "season_card": {
            "name": season.capitalize(),
            "phase": season_data["phase"],
            "insight": daily_insight,
            "emoji": _get_season_emoji(season),
            "hemisphere": hemisphere,
        },
        "user": {
            "streak": profile.get("streak", 0),
            "subscription": profile.get("subscription", "free"),
        },
    }


def _get_greeting(hour: int, name: Optional[str] = None) -> str:
    if hour < 6:
        greeting = "Good night"
    elif hour < 12:
        greeting = "Good morning"
    elif hour < 18:
        greeting = "Good afternoon"
    else:
        greeting = "Good evening"
    
    if name:
        return f"{greeting}, {name}"
    return f"{greeting}"


# ==================== User Profile CRUD ====================

@router.post("/user")
async def create_user(body: UserProfileCreate):
    """Create a new user profile"""
    user_id = f"seasons-{uuid.uuid4().hex[:8]}"
    now = datetime.now()
    
    profile = {
        "id": user_id,
        "created_at": now.isoformat(),
        "name": body.name,
        "email": body.email,
        "hemisphere": body.hemisphere or "north",
        "timezone": body.timezone or "UTC",
        "country": body.country or "US",
        "locale": body.locale or "en",
        "preferences": body.preferences or {},
        "memory_enabled": True,
        "notifications_enabled": True,
        "subscription": "free",
        "streak": 0,
        "reflections_count": 0,
    }
    user_profiles_db[user_id] = profile
    return {"id": user_id, "profile": profile}


@router.get("/user/{user_id}")
async def get_user(user_id: str):
    """Get user profile"""
    if user_id not in user_profiles_db:
        raise HTTPException(status_code=404, detail="User not found")
    return user_profiles_db[user_id]


@router.put("/user/{user_id}")
async def update_user(user_id: str, body: UserProfileUpdate):
    """Update user profile"""
    if user_id not in user_profiles_db:
        raise HTTPException(status_code=404, detail="User not found")
    
    profile = user_profiles_db[user_id]
    update_data = body.model_dump(exclude_unset=True)
    
    for key, value in update_data.items():
        if value is not None:
            profile[key] = value
    
    user_profiles_db[user_id] = profile
    return {"success": True, "profile": profile}


@router.delete("/user/{user_id}")
async def delete_user(user_id: str):
    """Delete user account (GDPR)"""
    if user_id in user_profiles_db:
        del user_profiles_db[user_id]
    return {"success": True, "message": "Account deleted"}


@router.post("/user/{user_id}/export")
async def export_user_data(user_id: str):
    """Export all user data (GDPR)"""
    profile = user_profiles_db.get(user_id, {})
    
    # Gather all data
    reflections = [r for r in reflections_db if r.get("user_id") == user_id]
    
    return {
        "profile": profile,
        "reflections": reflections,
        "exported_at": datetime.now().isoformat(),
    }


# Import reference for reflections (avoid circular)
reflections_db = {}


# ==================== Recommendations ====================

@router.get("/recommendations")
async def get_recommendations(
    user_id: str = Query(...),
    season: str = Query("spring"),
    time_of_day: str = Query("evening"),
    limit: int = Query(3),
):
    """Get personalized content recommendations"""
    suggestions = _get_suggestions_for_time(time_of_day, limit=limit)
    
    return {
        "suggestions": suggestions,
        "audio_suggestion": {
            "id": f"audio_{time_of_day}",
            "title": _get_audio_suggestion_title(time_of_day),
            "duration": "5 min",
            "type": "guided",
        },
        "reflection_suggestion": {
            "title": _get_reflection_prompt(season),
            "mood": "gentle",
        },
    }


def _get_audio_suggestion_title(time: str) -> str:
    titles = {
        "morning": "Morning Wake-up Breath",
        "afternoon": "Afternoon Reset",
        "evening": "Evening Wind-down",
    }
    return titles.get(time, "Calm Breath")


def _get_reflection_prompt(season: str) -> str:
    prompts = {
        "spring": "What is one small thing you'd like to begin this season?",
        "summer": "What is bringing you sunlight right now?",
        "autumn": "What is one thing you are ready to let go of?",
        "winter": "What does your body need most right now?",
    }
    return prompts.get(season, "How are you feeling in this moment?")
