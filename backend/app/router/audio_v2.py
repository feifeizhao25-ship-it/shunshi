"""
SEASONS Audio API v2 — Frontend-compatible routes
Provides /api/v1/audio/* endpoints expected by AudioContentService in the Flutter app.
Delegates to existing AUDIO_LIBRARY data from seasons_audio.py.
"""

import logging
from typing import Optional, List
from fastapi import APIRouter, Query, Path
from pydantic import BaseModel

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/audio", tags=["audio-v2"])

# Re-use the audio library from seasons_audio
from .seasons_audio import AUDIO_LIBRARY


def _all_items() -> list:
    result = []
    for items in AUDIO_LIBRARY.values():
        result.extend(items)
    return result


def _hemisphere_season(hemisphere: str) -> Optional[str]:
    """Map current month to season string based on hemisphere."""
    from datetime import datetime
    month = datetime.utcnow().month
    if hemisphere == "south":
        if month in (9, 10, 11): return "spring"
        if month in (12, 1, 2):  return "summer"
        if month in (3, 4, 5):   return "autumn"
        return "winter"
    else:
        if month in (3, 4, 5):   return "spring"
        if month in (6, 7, 8):   return "summer"
        if month in (9, 10, 11): return "autumn"
        return "winter"


@router.get("/library")
async def get_audio_library(
    hemisphere: str = Query("north"),
    season: Optional[str] = Query(None),
):
    """
    Fetch full audio library grouped by category.
    Returned as {breathing: [...], windDown: [...], soundscapes: [...], seasonal: [...]}
    """
    effective_season = season or _hemisphere_season(hemisphere)

    # Seasonal items filtered to current season
    seasonal_items = [
        item for item in AUDIO_LIBRARY.get("seasonal", [])
        if effective_season in item.get("tags", [])
    ] or AUDIO_LIBRARY.get("seasonal", [])  # fallback: all seasonal

    return {
        "breathing":   AUDIO_LIBRARY.get("breathing", []),
        "windDown":    AUDIO_LIBRARY.get("wind_down", []),
        "soundscapes": AUDIO_LIBRARY.get("soundscapes", []),
        "seasonal":    seasonal_items,
        "hemisphere":  hemisphere,
        "season":      effective_season,
    }


@router.get("/recommended")
async def get_recommended_audio(
    user_id: Optional[str] = Query(None),
    hemisphere: str = Query("north"),
    season: Optional[str] = Query(None),
    time_of_day: Optional[str] = Query(None),  # morning/afternoon/evening/night
    duration_minutes: Optional[int] = Query(None),
    categories: Optional[str] = Query(None),
    limit: int = Query(10),
):
    """
    Return personalized audio recommendations based on time of day, hemisphere, etc.
    """
    all_items = _all_items()
    effective_season = season or _hemisphere_season(hemisphere)

    # Filter by time of day
    if time_of_day:
        filtered = [
            i for i in all_items
            if i.get("best_time") in (time_of_day, "any")
        ]
        if not filtered:
            filtered = all_items
    else:
        filtered = all_items

    # Filter by duration if specified
    if duration_minutes:
        filtered = [i for i in filtered if i.get("duration_minutes") == duration_minutes] or filtered

    # Filter by categories
    if categories:
        requested = set(categories.lower().split(","))
        cat_map = {
            "breathing": "breathing",
            "winddown": "wind_down",
            "soundscape": "soundscapes",
            "seasonal": "seasonal",
        }
        matched_keys = {cat_map.get(c.strip(), c.strip()) for c in requested}
        filtered_by_cat = [
            i for i in filtered
            if any(tag in i.get("tags", []) or i.get("type") in matched_keys for tag in requested)
        ]
        if filtered_by_cat:
            filtered = filtered_by_cat

    # Boost free items first for non-premium users
    filtered.sort(key=lambda x: (1 if x.get("is_premium") else 0))

    return {
        "items": filtered[:limit],
        "total": len(filtered),
        "hemisphere": hemisphere,
        "season": effective_season,
    }


@router.get("/contents")
async def get_audio_contents(
    duration_minutes: Optional[int] = Query(None),
    hemisphere: str = Query("north"),
    season: Optional[str] = Query(None),
    limit: int = Query(20),
):
    """
    Fetch audio items filtered by duration and hemisphere/season.
    Used by AudioContentService.fetchByDuration().
    """
    all_items = _all_items()
    effective_season = season or _hemisphere_season(hemisphere)

    if duration_minutes:
        items = [i for i in all_items if i.get("duration_minutes") == duration_minutes]
        if not items:
            # Fallback: items close to requested duration (±2 min)
            items = [
                i for i in all_items
                if abs(i.get("duration_minutes", 0) - duration_minutes) <= 2
            ]
    else:
        items = all_items

    return {
        "items": items[:limit],
        "total": len(items),
        "hemisphere": hemisphere,
        "season": effective_season,
    }


@router.get("/{audio_item_id}/stream")
async def get_audio_stream_url(
    audio_item_id: str = Path(...),
):
    """
    Return a stream URL for a given audio item.
    In production: generate a signed CDN URL here.
    """
    # Find item
    all_items = _all_items()
    item = next((i for i in all_items if i.get("id") == audio_item_id), None)

    if not item:
        return {"url": None, "error": "Audio item not found"}

    return {
        "url": item.get("audio_url"),
        "expires_at": None,  # In production: signed URL expiry
    }


class AudioPlayEvent(BaseModel):
    user_id: str
    audio_item_id: str
    duration_played_seconds: int
    completed: bool
    played_at: Optional[str] = None


@router.post("/plays")
async def record_audio_play(event: AudioPlayEvent):
    """
    Record an audio play event for analytics.
    """
    logger.info(
        "[AudioPlay] user=%s item=%s duration=%ds completed=%s",
        event.user_id,
        event.audio_item_id,
        event.duration_played_seconds,
        event.completed,
    )
    # In production: persist to analytics store
    return {"status": "ok"}
