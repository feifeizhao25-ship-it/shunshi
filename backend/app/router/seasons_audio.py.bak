"""
SEASONS Global Version - Audio Content System
"""

from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Query, Body

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons-audio"])

# Audio content library
# audio_url uses the pattern: https://audio.seasons.app/{category}/{id}.mp3
# These are CDN URLs — replace with real hosted audio files when available.
AUDIO_LIBRARY = {
    "breathing": [
        {"id": "audio_breathe_1", "title": "4-7-8 Breathing", "subtitle": "A calming breath to ease anxiety", "use_case": "Before sleep or during stressful moments", "duration_minutes": 5, "best_time": "evening", "type": "guided", "tags": ["anxiety", "sleep", "calm"], "is_premium": False, "audio_url": "https://audio.seasons.app/breathing/audio_breathe_1.mp3"},
        {"id": "audio_breathe_2", "title": "Box Breathing", "subtitle": "Equal counts for emotional balance", "use_case": "When you need to center yourself", "duration_minutes": 4, "best_time": "any", "type": "guided", "tags": ["focus", "balance"], "is_premium": False, "audio_url": "https://audio.seasons.app/breathing/audio_breathe_2.mp3"},
        {"id": "audio_breathe_3", "title": "Morning Breath Reset", "subtitle": "Start the day with intention", "use_case": "First thing in the morning", "duration_minutes": 3, "best_time": "morning", "type": "guided", "tags": ["morning", "energy"], "is_premium": False, "audio_url": "https://audio.seasons.app/breathing/audio_breathe_3.mp3"},
        {"id": "audio_breathe_4", "title": "Deep Belly Breathing", "subtitle": "Activate your rest system", "use_case": "When feeling overwhelmed", "duration_minutes": 6, "best_time": "afternoon", "type": "guided", "tags": ["relaxation", "stress"], "is_premium": True, "audio_url": "https://audio.seasons.app/breathing/audio_breathe_4.mp3"},
        {"id": "audio_breathe_5", "title": "Alternate Nostril Breathing", "subtitle": "Balancing breath from yoga", "use_case": "Transition between tasks", "duration_minutes": 5, "best_time": "any", "type": "guided", "tags": ["balance", "focus"], "is_premium": True, "audio_url": "https://audio.seasons.app/breathing/audio_breathe_5.mp3"},
    ],
    "wind_down": [
        {"id": "audio_wind_1", "title": "Evening Wind-Down", "subtitle": "A gentle transition from day to night", "use_case": "30-60 minutes before bed", "duration_minutes": 8, "best_time": "evening", "type": "guided", "tags": ["sleep", "evening"], "is_premium": False, "audio_url": "https://audio.seasons.app/wind_down/audio_wind_1.mp3"},
        {"id": "audio_wind_2", "title": "Body Scan for Sleep", "subtitle": "Release tension from head to toe", "use_case": "In bed, lights off", "duration_minutes": 10, "best_time": "evening", "type": "guided", "tags": ["sleep", "relaxation"], "is_premium": True, "audio_url": "https://audio.seasons.app/wind_down/audio_wind_2.mp3"},
        {"id": "audio_wind_3", "title": "Gratitude Reflection", "subtitle": "End the day with appreciation", "use_case": "Evening journaling companion", "duration_minutes": 5, "best_time": "evening", "type": "guided", "tags": ["reflection", "gratitude"], "is_premium": False, "audio_url": "https://audio.seasons.app/wind_down/audio_wind_3.mp3"},
        {"id": "audio_wind_4", "title": "Progressive Relaxation", "subtitle": "Tense and release for deep calm", "use_case": "When you can't fall asleep", "duration_minutes": 12, "best_time": "evening", "type": "guided", "tags": ["sleep", "tension"], "is_premium": True, "audio_url": "https://audio.seasons.app/wind_down/audio_wind_4.mp3"},
    ],
    "soundscapes": [
        {"id": "audio_sound_1", "title": "Gentle Rain", "subtitle": "Steady rainfall for focus or sleep", "use_case": "Background while working or sleeping", "duration_minutes": 60, "best_time": "any", "type": "soundscape", "tags": ["focus", "sleep"], "is_premium": False, "audio_url": "https://audio.seasons.app/soundscapes/audio_sound_1.mp3"},
        {"id": "audio_sound_2", "title": "Forest Morning", "subtitle": "Birds and gentle breeze", "use_case": "Morning routine or meditation", "duration_minutes": 30, "best_time": "morning", "type": "soundscape", "tags": ["nature", "morning"], "is_premium": False, "audio_url": "https://audio.seasons.app/soundscapes/audio_sound_2.mp3"},
        {"id": "audio_sound_3", "title": "Ocean Waves", "subtitle": "Rhythmic waves for deep relaxation", "use_case": "Sleep or deep work", "duration_minutes": 90, "best_time": "any", "type": "soundscape", "tags": ["sleep", "relaxation"], "is_premium": True, "audio_url": "https://audio.seasons.app/soundscapes/audio_sound_3.mp3"},
        {"id": "audio_sound_4", "title": "Crackling Fire", "subtitle": "Cozy warmth by the fire", "use_case": "Autumn/winter evenings", "duration_minutes": 45, "best_time": "evening", "type": "soundscape", "tags": ["cozy", "evening"], "is_premium": True, "audio_url": "https://audio.seasons.app/soundscapes/audio_sound_4.mp3"},
    ],
    "seasonal": [
        {"id": "audio_season_spring", "title": "Spring Renewal", "subtitle": "Embrace the season of new beginnings", "use_case": "Spring mornings", "duration_minutes": 8, "best_time": "morning", "type": "guided", "tags": ["spring", "renewal"], "is_premium": True, "audio_url": "https://audio.seasons.app/seasonal/audio_season_spring.mp3"},
        {"id": "audio_season_summer", "title": "Summer Energy", "subtitle": "Stay cool and centered in the heat", "use_case": "Summer afternoons", "duration_minutes": 6, "best_time": "afternoon", "type": "guided", "tags": ["summer", "balance"], "is_premium": True, "audio_url": "https://audio.seasons.app/seasonal/audio_season_summer.mp3"},
        {"id": "audio_season_autumn", "title": "Autumn Letting Go", "subtitle": "A meditation for the season of release", "use_case": "Autumn evenings", "duration_minutes": 10, "best_time": "evening", "type": "guided", "tags": ["autumn", "release"], "is_premium": True, "audio_url": "https://audio.seasons.app/seasonal/audio_season_autumn.mp3"},
        {"id": "audio_season_winter", "title": "Winter Stillness", "subtitle": "Find warmth in the quiet", "use_case": "Winter nights", "duration_minutes": 12, "best_time": "evening", "type": "guided", "tags": ["winter", "stillness"], "is_premium": True, "audio_url": "https://audio.seasons.app/seasonal/audio_season_winter.mp3"},
    ],
}


@router.get("/audio/list")
async def get_audio_list(
    type: Optional[str] = Query(None),
    best_time: Optional[str] = Query(None),
    season: Optional[str] = Query(None),
    page: int = Query(1),
    limit: int = Query(20),
):
    """Get audio content list"""
    items = []
    types_to_search = [type] if type else list(AUDIO_LIBRARY.keys())
    
    for t in types_to_search:
        if t in AUDIO_LIBRARY:
            items.extend(AUDIO_LIBRARY[t])
    
    # Filter by time
    if best_time:
        items = [i for i in items if i["best_time"] == best_time or i["best_time"] == "any"]
    
    # Filter by season tag
    if season:
        items = [i for i in items if season.lower() in [t.lower() for t in i.get("tags", [])]]
    
    start = (page - 1) * limit
    end = start + limit
    return items[start:end]


# NOTE: /audio/recommended must be before /audio/{audio_id} for FastAPI route matching
@router.get("/audio/recommended")
async def get_recommended_audio(
    time_of_day: str = Query("evening"),
    season: str = Query("spring"),
    limit: int = Query(3),
):
    """Get recommended audio based on context"""
    all_items = []
    for items in AUDIO_LIBRARY.values():
        all_items.extend(items)
    
    # Prioritize by time match
    scored = []
    for item in all_items:
        score = 0
        if item["best_time"] == time_of_day:
            score = 10
        elif item["best_time"] == "any":
            score = 5
        if season.lower() in [t.lower() for t in item.get("tags", [])]:
            score += 3
        if not item["is_premium"]:
            score += 2
        scored.append((score, item))
    
    scored.sort(key=lambda x: x[0], reverse=True)
    return [item for _, item in scored[:limit]]


@router.get("/audio/{audio_id}")
async def get_audio_detail(audio_id: str):
    """Get audio detail"""
    for items in AUDIO_LIBRARY.values():
        for item in items:
            if item["id"] == audio_id:
                return item
    from fastapi import HTTPException
    raise HTTPException(status_code=404, detail="Audio not found")


@router.post("/audio/progress")
async def update_audio_progress(
    audio_id: str = Body(...),
    user_id: str = Body(...),
    progress_seconds: int = Body(...),
    completed: bool = Body(False),
):
    """
    Track user's listening progress for an audio item.
    Called by the frontend audio player during playback and on completion.
    """
    # In production: store in DB table user_audio_progress
    # For now: log and return success
    now = datetime.utcnow().isoformat()
    print(f"[AUDIO PROGRESS] user={user_id} audio={audio_id} "
          f"progress={progress_seconds}s completed={completed} at={now}")
    return {"saved": True, "audio_id": audio_id, "completed": completed}
