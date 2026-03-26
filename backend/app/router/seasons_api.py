"""
SEASONS Global Version - Additional API Endpoints
Reflections, Seasons, User management
"""

import uuid
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons-global"])

# In-memory storage
reflections_db: dict = {}
seasons_db: dict = {}
users_db: dict = {}

# Default seasons data
SEASONS_DATA = {
    "spring": {
        "name": "Spring",
        "emoji": "🌱",
        "insight": "Today, consider starting something new — even something small. Spring is for beginnings.",
        "phase": "early",
        "color_start": "#C8DCC5",
        "color_end": "#F2F5F0",
        "food_suggestions": ["Leafy greens", "Sprouts", "Asparagus", "Peas", "Lemon", "Ginger", "Honey"],
        "stretch_routines": ["Morning Wake-Up Stretch", "Sun Salutation", "Gentle Yoga"],
        "sleep_rituals": ["Wind-down routine", "Early wake time", "Fresh air"],
    },
    "summer": {
        "name": "Summer",
        "emoji": "☀️",
        "insight": "Let the warmth of the day guide you toward connection and joy. What brings you sunlight?",
        "phase": "mid",
        "color_start": "#E8D4B8",
        "color_end": "#FAF5EF",
        "food_suggestions": ["Berries", "Yogurt", "Fresh salads", "Hydrating fruits", "Light soups"],
        "stretch_routines": ["Evening Walk", "Swimming stretches", "Desk Worker Relief"],
        "sleep_rituals": ["Cool environment", "Relaxation", "Shorter sleep latency"],
    },
    "autumn": {
        "name": "Autumn",
        "emoji": "🍂",
        "insight": "As things naturally let go, consider what you might release. Rest is also productivity.",
        "phase": "mid",
        "color_start": "#DDD4C6",
        "color_end": "#F8F4EE",
        "food_suggestions": ["Root vegetables", "Pears", "Apples", "Ginger", "Warm teas", "Soups"],
        "stretch_routines": ["Evening Walk", "Tai Chi", "Bedtime Yoga"],
        "sleep_rituals": ["Warm drink", "Earlier bedtime", "Layered clothing"],
    },
    "winter": {
        "name": "Winter",
        "emoji": "❄️",
        "insight": "Turn inward. What does your body need right now? Warmth, slowness, and gentle care.",
        "phase": "late",
        "color_start": "#C0D4E0",
        "color_end": "#F0F5FA",
        "food_suggestions": ["Warming foods", "Soups", "Hot teas", "Root vegetables", "Nourishing grains"],
        "stretch_routines": ["Morning Wake-Up", "Indoor Yoga", "Gentle Movement"],
        "sleep_rituals": ["Earlier bedtime", "Warm environment", "Wind-down routine"],
    },
}


def _get_current_season() -> str:
    """Determine current season from northern hemisphere"""
    month = datetime.now().month
    if month in [3, 4, 5]:
        return "spring"
    elif month in [6, 7, 8]:
        return "summer"
    elif month in [9, 10, 11]:
        return "autumn"
    else:
        return "winter"


# ==================== Reflections ====================

class ReflectionSubmit(BaseModel):
    user_id: str
    mood: str
    energy: str
    sleep: str
    notes: Optional[str] = None


class WeeklyReflectionRequest(BaseModel):
    user_id: str
    week_start: str
    week_end: str


@router.post("/reflection/submit")
async def submit_reflection(body: ReflectionSubmit):
    """Submit a daily reflection"""
    ref_id = str(uuid.uuid4())
    reflection = {
        "id": ref_id,
        "user_id": body.user_id,
        "mood": body.mood,
        "energy": body.energy,
        "sleep": body.sleep,
        "notes": body.notes,
        "date": datetime.now().isoformat(),
    }
    reflections_db[ref_id] = reflection
    
    # Update user streak
    user_id = body.user_id
    if user_id not in users_db:
        users_db[user_id] = {"id": user_id, "streak": 0, "last_reflection": None, "reflections_count": 0}
    
    last_ref = users_db[user_id].get("last_reflection")
    if last_ref:
        last_date = datetime.fromisoformat(last_ref)
        if (datetime.now() - last_date).days == 1:
            users_db[user_id]["streak"] = users_db[user_id].get("streak", 0) + 1
        elif (datetime.now() - last_date).days > 1:
            users_db[user_id]["streak"] = 1
    else:
        users_db[user_id]["streak"] = 1
    
    users_db[user_id]["last_reflection"] = datetime.now().isoformat()
    users_db[user_id]["reflections_count"] = users_db[user_id].get("reflections_count", 0) + 1
    
    return {"id": ref_id, "success": True}


@router.get("/reflection/list")
async def get_reflections(user_id: str = Query(...)):
    """Get reflection history for a user"""
    user_reflections = [r for r in reflections_db.values() if r["user_id"] == user_id]
    user_reflections.sort(key=lambda x: x["date"], reverse=True)
    return user_reflections[:30]


@router.post("/reflection/weekly")
async def get_weekly_reflection(body: WeeklyReflectionRequest):
    """Get weekly reflection summary"""
    user_reflections = [
        r for r in reflections_db.values()
        if r["user_id"] == body.user_id
    ]
    
    week_start = datetime.fromisoformat(body.week_start)
    week_end = datetime.fromisoformat(body.week_end)
    
    week_refs = [
        r for r in user_reflections
        if week_start <= datetime.fromisoformat(r["date"]) <= week_end
    ]
    
    if not week_refs:
        return {
            "ai_summary": "No reflections this week. Starting fresh is always a good time.",
            "ai_insight": "Consider taking a moment each day to check in with yourself.",
            "mood_trend": [],
            "average_energy": "medium",
            "average_sleep": "good",
            "streak_days": users_db.get(body.user_id, {}).get("streak", 0),
        }
    
    moods = [r["mood"] for r in week_refs]
    most_common_mood = max(set(moods), key=moods.count) if moods else "neutral"
    
    return {
        "ai_summary": f"You reflected {len(week_refs)} times this week. Your emotional landscape shows {most_common_mood} as the dominant mood.",
        "ai_insight": "Taking time to reflect is a practice of self-care. Notice what patterns emerge across your weeks.",
        "mood_trend": moods,
        "average_energy": "medium",
        "average_sleep": "good",
        "streak_days": users_db.get(body.user_id, {}).get("streak", 0),
    }


# ==================== Seasons ====================

@router.get("/season/current")
async def get_current_season_api(
    user_id: str = Query("seasons-user"),
    hemisphere: str = Query("north"),
):
    """Get current season info"""
    from datetime import datetime
    month = datetime.now().month
    
    # Northern hemisphere
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
    
    season_data = SEASONS_DATA[season]
    return {
        "name": season_data["name"],
        "insight": season_data["insight"],
        "food_suggestions": season_data["food_suggestions"],
        "stretch_routines": season_data["stretch_routines"],
        "sleep_rituals": season_data["sleep_rituals"],
    }


@router.get("/season/list")
async def list_seasons():
    """List all seasons"""
    return [
        {
            "name": data["name"],
            "emoji": data["emoji"],
            "insight": data["insight"],
            "phase": data["phase"],
        }
        for key, data in SEASONS_DATA.items()
    ]


# ==================== User ====================

class UserUpdate(BaseModel):
    name: Optional[str] = None
    avatar_url: Optional[str] = None
    country: Optional[str] = None
    subscription: Optional[str] = None


@router.get("/user/{user_id}")
async def get_user(user_id: str):
    """Get user profile"""
    if user_id not in users_db:
        users_db[user_id] = {
            "id": user_id,
            "email": f"{user_id}@seasons.app",
            "name": None,
            "avatar_url": None,
            "country": "US",
            "subscription": "free",
            "created_at": datetime.now().isoformat(),
            "streak": 0,
            "reflections_count": 0,
        }
    return users_db[user_id]


@router.put("/user/{user_id}")
async def update_user(user_id: str, body: UserUpdate):
    """Update user profile"""
    if user_id not in users_db:
        users_db[user_id] = {"id": user_id}
    
    user = users_db[user_id]
    if body.name is not None:
        user["name"] = body.name
    if body.avatar_url is not None:
        user["avatar_url"] = body.avatar_url
    if body.country is not None:
        user["country"] = body.country
    if body.subscription is not None:
        user["subscription"] = body.subscription
    
    return {"success": True, "user": user}


# ==================== Content Library ====================

CONTENT_LIBRARY = {
    "breathing": [
        {"id": "breathing_1", "title": "4-7-8 Breathing", "description": "A calming breath technique to reduce anxiety and promote sleep.", "type": "breathing", "duration_seconds": 300, "tags": ["anxiety", "sleep", "calm"]},
        {"id": "breathing_2", "title": "Box Breathing", "description": "Equal-count breathing for focus and emotional balance.", "type": "breathing", "duration_seconds": 240, "tags": ["focus", "balance"]},
        {"id": "breathing_3", "title": "Diaphragmatic Breathing", "description": "Deep belly breathing to activate the parasympathetic nervous system.", "type": "breathing", "duration_seconds": 360, "tags": ["relaxation", "stress"]},
        {"id": "breathing_4", "title": "Alternate Nostril Breathing", "description": "Balancing breath practice from yoga tradition.", "type": "breathing", "duration_seconds": 300, "tags": ["balance", "focus"]},
        {"id": "breathing_5", "title": "Lion's Breath", "description": "Releasing tension and stress with expressive exhaling.", "type": "breathing", "duration_seconds": 180, "tags": ["stress", "release"]},
        {"id": "breathing_6", "title": "Ocean Breath", "description": "Rhythmic breathing inspired by ocean waves.", "type": "breathing", "duration_seconds": 420, "tags": ["calm", "mindfulness"]},
        {"id": "breathing_7", "title": "Resonance Breathing", "description": "5 breaths per minute for heart rate variability improvement.", "type": "breathing", "duration_seconds": 600, "tags": ["HRV", "calm"]},
    ],
    "stretch": [
        {"id": "stretch_1", "title": "Morning Wake-Up Stretch", "description": "Gentle stretches to greet the day with ease.", "type": "stretch", "duration_seconds": 480, "tags": ["morning", "energy"]},
        {"id": "stretch_2", "title": "Evening Walk", "description": "A mindful walk to transition from day to night.", "type": "stretch", "duration_seconds": 1800, "tags": ["evening", "mindfulness"]},
        {"id": "stretch_3", "title": "Desk Worker Relief", "description": "Stretches for neck, shoulders, and wrists.", "type": "stretch", "duration_seconds": 600, "tags": ["work", "tension"]},
        {"id": "stretch_4", "title": "Sun Salutation", "description": "Classic yoga flow to energize body and mind.", "type": "stretch", "duration_seconds": 900, "tags": ["energy", "yoga"]},
        {"id": "stretch_5", "title": "Bedtime Yoga", "description": "Gentle poses to prepare the body for rest.", "type": "stretch", "duration_seconds": 900, "tags": ["sleep", "relaxation"]},
        {"id": "stretch_6", "title": "Tai Chi", "description": "Slow, flowing movements for balance and calm.", "type": "stretch", "duration_seconds": 1200, "tags": ["balance", "calm"]},
        {"id": "stretch_7", "title": "Energy Boost", "description": "Quick movements to increase alertness.", "type": "stretch", "duration_seconds": 300, "tags": ["energy", "alertness"]},
    ],
    "tea": [
        {"id": "tea_1", "title": "Chamomile Sunset", "description": "Calming chamomile blend for evening relaxation.", "type": "tea", "duration_seconds": 600, "tags": ["calm", "sleep"]},
        {"id": "tea_2", "title": "Peppermint Clarity", "description": "Refreshing mint tea for afternoon focus.", "type": "tea", "duration_seconds": 420, "tags": ["focus", "refresh"]},
        {"id": "tea_3", "title": "Ginger Lemon", "description": "Warming blend to support digestion and immunity.", "type": "tea", "duration_seconds": 600, "tags": ["immunity", "warm"]},
        {"id": "tea_4", "title": "Matcha", "description": "Gentle energy from ceremonial grade matcha.", "type": "tea", "duration_seconds": 300, "tags": ["energy", "focus"]},
        {"id": "tea_5", "title": "Lavender Honey", "description": "Floral and sweet for deep relaxation.", "type": "tea", "duration_seconds": 480, "tags": ["relaxation", "calm"]},
        {"id": "tea_6", "title": "Golden Milk", "description": "Warming turmeric blend for evening wind-down.", "type": "tea", "duration_seconds": 600, "tags": ["warm", "sleep"]},
        {"id": "tea_7", "title": "Jasmine", "description": "Fragrant green tea with jasmine for mindfulness.", "type": "tea", "duration_seconds": 480, "tags": ["mindfulness", "calm"]},
    ],
    "sleep": [
        {"id": "sleep_1", "title": "Sleep Hygiene", "description": "Foundation practices for quality rest.", "type": "sleep", "duration_seconds": 600, "tags": ["foundation", "habit"]},
        {"id": "sleep_2", "title": "Progressive Muscle Relaxation", "description": "Systematic tension and release for deep calm.", "type": "sleep", "duration_seconds": 900, "tags": ["relaxation", "tension"]},
        {"id": "sleep_3", "title": "Wind-Down Routine", "description": "30-minute ritual to prepare for sleep.", "type": "sleep", "duration_seconds": 1800, "tags": ["routine", "habit"]},
        {"id": "sleep_4", "title": "Body Scan Meditation", "description": "Guided awareness practice for physical relaxation.", "type": "sleep", "duration_seconds": 1200, "tags": ["meditation", "relaxation"]},
        {"id": "sleep_5", "title": "Rain Sounds", "description": "Nature soundscape for falling asleep.", "type": "sleep", "duration_seconds": 3600, "tags": ["soundscape", "sleep"]},
        {"id": "sleep_6", "title": "Counting Breath", "description": "Simple technique to quiet a busy mind.", "type": "sleep", "duration_seconds": 300, "tags": ["technique", "focus"]},
        {"id": "sleep_7", "title": "Gratitude Practice", "description": "Shift to positive mindset before sleep.", "type": "sleep", "duration_seconds": 300, "tags": ["gratitude", "mindset"]},
    ],
    "meditation": [
        {"id": "meditation_1", "title": "Body Scan", "description": "Systematic awareness of physical sensations.", "type": "meditation", "duration_seconds": 900, "tags": ["awareness", "relaxation"]},
        {"id": "meditation_2", "title": "Loving-Kindness", "description": "Cultivating compassion for self and others.", "type": "meditation", "duration_seconds": 600, "tags": ["compassion", "connection"]},
        {"id": "meditation_3", "title": "Nature Visualization", "description": "Guided imagery of natural peaceful settings.", "type": "meditation", "duration_seconds": 600, "tags": ["visualization", "calm"]},
        {"id": "meditation_4", "title": "Breath Anchor", "description": "Simple breath awareness for present moment.", "type": "meditation", "duration_seconds": 300, "tags": ["breath", "presence"]},
        {"id": "meditation_5", "title": "Walking Meditation", "description": "Mindful movement in daily life.", "type": "meditation", "duration_seconds": 900, "tags": ["movement", "mindfulness"]},
        {"id": "meditation_6", "title": "Gratitude Meditation", "description": "Focus on appreciation and abundance.", "type": "meditation", "duration_seconds": 480, "tags": ["gratitude"]},
        {"id": "meditation_7", "title": "Mountain Visualization", "description": "Finding stillness and stability within.", "type": "meditation", "duration_seconds": 600, "tags": ["stability", "calm"]},
    ],
    "reflection": [
        {"id": "reflection_1", "title": "Gratitude Check-In", "description": "What are three things you're grateful for today?", "type": "reflection", "duration_seconds": 300, "tags": ["gratitude", "daily"]},
        {"id": "reflection_2", "title": "Mood Check-In", "description": "How are you really feeling right now?", "type": "reflection", "duration_seconds": 180, "tags": ["emotion", "awareness"]},
        {"id": "reflection_3", "title": "Weekly Review", "description": "Reflect on the past week with kindness.", "type": "reflection", "duration_seconds": 600, "tags": ["review", "weekly"]},
        {"id": "reflection_4", "title": "Letting Go", "description": "What can you release today?", "type": "reflection", "duration_seconds": 300, "tags": ["release", "acceptance"]},
        {"id": "reflection_5", "title": "Intention Setting", "description": "What's one intention for today?", "type": "reflection", "duration_seconds": 180, "tags": ["intention", "daily"]},
        {"id": "reflection_6", "title": "Future Letter", "description": "Write a letter to your future self.", "type": "reflection", "duration_seconds": 900, "tags": ["connection", "creativity"]},
        {"id": "reflection_7", "title": "Mindful Moments", "description": "What moments brought you peace today?", "type": "reflection", "duration_seconds": 300, "tags": ["mindfulness", "awareness"]},
    ],
}


@router.get("/content/list")
async def get_content_list(
    type: Optional[str] = Query(None),
    season: Optional[str] = Query(None),
    page: int = Query(1),
    limit: int = Query(20),
):
    """Get content library items"""
    items = []
    types_to_search = [type] if type else list(CONTENT_LIBRARY.keys())
    
    for t in types_to_search:
        if t in CONTENT_LIBRARY:
            items.extend(CONTENT_LIBRARY[t])
    
    # Filter by season tag if provided
    if season:
        season_keywords = season.lower()
        items = [i for i in items if any(season_keywords in str(t).lower() for t in i.get("tags", []))]
    
    # Paginate
    start = (page - 1) * limit
    end = start + limit
    return items[start:end]


@router.get("/content/{content_id}")
async def get_content_detail(content_id: str):
    """Get content detail"""
    for items in CONTENT_LIBRARY.values():
        for item in items:
            if item["id"] == content_id:
                return item
    raise HTTPException(status_code=404, detail="Content not found")

