"""
SEASONS Global Version - Audio Content System v2
Real audio files hosted at: http://116.62.32.43/static/audio/{lang}/
"""

from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Query, Body
from .seasons_audio_content import AUDIO_LIBRARY, serialize_item

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons-audio"])


@router.get("/audio/list")
async def get_audio_list(
    type: Optional[str] = Query(None),
    best_time: Optional[str] = Query(None),
    season: Optional[str] = Query(None),
    lang: Optional[str] = Query("en", description="Language: en or zh"),
    page: int = Query(1),
    limit: int = Query(20),
):
    """Get audio content list with language-appropriate URLs."""
    items = []
    types_to_search = [type] if type else list(AUDIO_LIBRARY.keys())
    
    for t in types_to_search:
        if t in AUDIO_LIBRARY:
            for item in AUDIO_LIBRARY[t]:
                items.append(serialize_item(item, lang))
    
    # Filter by time
    if best_time:
        items = [i for i in items if i["best_time"] == best_time or i["best_time"] == "any"]
    
    # Filter by season tag
    if season:
        items = [i for i in items if season.lower() in [t.lower() for t in i.get("tags", [])]]
    
    start = (page - 1) * limit
    end = start + limit
    total = len(items)
    return {"items": items[start:end], "total": total, "lang": lang}


@router.get("/audio/recommended")
async def get_recommended_audio(
    time_of_day: str = Query("evening"),
    season: str = Query("spring"),
    lang: str = Query("en"),
    limit: int = Query(3),
):
    """Get recommended audio based on context."""
    all_items = []
    for items in AUDIO_LIBRARY.values():
        for item in items:
            all_items.append((item, serialize_item(item, lang)))
    
    # Score by time/season match
    scored = []
    for item, ser_item in all_items:
        score = 0
        if ser_item["best_time"] == time_of_day:
            score = 10
        elif ser_item["best_time"] == "any":
            score = 5
        if season.lower() in [t.lower() for t in ser_item.get("tags", [])]:
            score += 3
        if not ser_item["is_premium"]:
            score += 2
        scored.append((score, ser_item))
    
    scored.sort(key=lambda x: x[0], reverse=True)
    return [item for _, item in scored[:limit]]


@router.get("/audio/{audio_id}")
async def get_audio_detail(audio_id: str, lang: str = Query("en")):
    """Get audio detail with language-appropriate URL."""
    for items in AUDIO_LIBRARY.values():
        for item in items:
            if item["id"] == audio_id:
                return serialize_item(item, lang)
    from fastapi import HTTPException
    raise HTTPException(status_code=404, detail="Audio not found")


@router.post("/audio/progress")
async def update_audio_progress(
    audio_id: str = Body(...),
    user_id: str = Body(...),
    progress_seconds: int = Body(...),
    completed: bool = Body(False),
):
    """Track user's listening progress for an audio item."""
    now = datetime.utcnow().isoformat()
    print(f"[AUDIO PROGRESS] user={user_id} audio={audio_id} "
          f"progress={progress_seconds}s completed={completed} at={now}")
    return {"saved": True, "audio_id": audio_id, "completed": completed}
