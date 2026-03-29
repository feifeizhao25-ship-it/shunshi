"""
First Daily Insight Generator
Called after onboarding completion to generate the user's first personalized insight.
"""

import logging
from typing import Optional
from datetime import datetime
from fastapi import APIRouter
from pydantic import BaseModel

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/ai", tags=["ai-insights"])


class FirstInsightRequest(BaseModel):
    hemisphere: str = "north"
    feeling: Optional[str] = "calm"
    goal: Optional[str] = "calm"
    style: Optional[str] = "gentle"
    user_id: Optional[str] = None


def _get_current_season(hemisphere: str) -> str:
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


# Insight templates by season × feeling
_INSIGHT_TEMPLATES = {
    "spring": {
        "calm": "Spring is nature's invitation to begin again. You've arrived here with a calm heart — that's a gift. Let this season be a gentle unfolding.",
        "stressed": "Spring carries the energy of new starts. Even when life feels heavy, the season reminds us: things are growing, even underground.",
        "tired": "You're tired — and spring asks nothing more of you than to rest well. Seeds need darkness before they bloom.",
        "overwhelmed": "When everything feels like too much, come back to one breath. Spring is slow. You can be slow too.",
        "curious": "That curiosity you feel? It's perfectly matched with spring energy. Let it lead you somewhere new today.",
    },
    "summer": {
        "calm": "A calm heart in summer is rare and precious. Let the light in — fully.",
        "stressed": "Summer's brightness can feel like pressure. It's okay to find your shade.",
        "tired": "Even in the longest days, you're allowed to rest. Nourishment matters more than productivity.",
        "overwhelmed": "Too much heat, too many demands. Find water, find stillness, find one thing that cools you.",
        "curious": "Summer is perfect for exploring. Follow your curiosity where it leads.",
    },
    "autumn": {
        "calm": "Calm in autumn is deep and golden. This is the season of gratitude — and you seem ready for it.",
        "stressed": "Autumn reminds us to let go. What if you released just one thing today?",
        "tired": "Your tiredness is the harvest — it means you gave. Now it's time to receive.",
        "overwhelmed": "Autumn asks for release, not addition. What needs to fall away?",
        "curious": "The turning season opens new perspectives. Your curiosity is well-placed here.",
    },
    "winter": {
        "calm": "Winter calm is the deepest kind. You're exactly where you need to be.",
        "stressed": "Winter invites withdrawal — not defeat. Rest is sacred in this season.",
        "tired": "Winter is made for this. Deep rest, inward reflection, warmth.",
        "overwhelmed": "Go quiet. Winter asks for less, not more.",
        "curious": "In winter's stillness, the deepest questions arise. Honor your curiosity.",
    },
}


def _get_insight_text(season: str, feeling: str, goal: str, style: str) -> str:
    season_templates = _INSIGHT_TEMPLATES.get(season, _INSIGHT_TEMPLATES["spring"])
    base = season_templates.get(feeling, season_templates.get("calm", "Welcome to SEASONS. We're glad you're here."))

    # Append goal-specific micro-suggestion
    goal_addons = {
        "sleep":   " Tonight, try going to bed 15 minutes earlier.",
        "unwind":  " Take three slow breaths before your next task.",
        "calm":    " Notice one beautiful thing around you right now.",
        "ritual":  " What's one small thing you can do today, just for yourself?",
        "reflect":  " Set aside 5 minutes this evening to write one sentence about your day.",
    }
    addon = goal_addons.get(goal, "")
    return base + addon


@router.post("/generate-first-insight")
async def generate_first_insight(request: FirstInsightRequest):
    """
    Generate a personalized first insight for a new user after onboarding.
    Returns a short, season-aware, feeling-informed message.
    """
    season = _get_current_season(request.hemisphere)

    insight_text = _get_insight_text(
        season=season,
        feeling=request.feeling or "calm",
        goal=request.goal or "calm",
        style=request.style or "gentle",
    )

    logger.info(
        "[FirstInsight] user=%s hemisphere=%s season=%s feeling=%s",
        request.user_id or "new_user",
        request.hemisphere,
        season,
        request.feeling,
    )

    return {
        "success": True,
        "insight": {
            "text": insight_text,
            "season": season,
            "hemisphere": request.hemisphere,
            "generated_at": datetime.utcnow().isoformat(),
            "tone": request.style or "gentle",
        }
    }
