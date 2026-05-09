"""
顺时 — 感恩日记 API (shunshi-gratitude)
每日感恩记录、正念练习、积极心理培养 (PostgreSQL backed)
"""
import uuid
from datetime import datetime, date, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.database import get_db
from app.models.wellness_tracking import GratitudeEntry

router = APIRouter(prefix="/api/v1/gratitude", tags=["gratitude"])

_DAILY_PROMPTS = [
    "今天有什么让你感到温暖的小事？",
    "谁帮助过你，让你心存感激？",
    "今天的身体给你带来了哪些便利？",
    "你生活中哪些平凡的事情值得感谢？",
    "今天有什么让你微笑的瞬间？",
    "你感激自己今天做到的一件事是什么？",
    "大自然今天给了你什么礼物？",
]

_INSIGHTS = [
    "研究表明，每天记录3件感恩的事能显著提升幸福感",
    "中医认为积极情绪有助于肝气疏泄，改善气血运行",
    "感恩练习能降低皮质醇水平，减少压力对身体的伤害",
    "长期感恩练习者睡眠质量更好，免疫力更强",
]


class GratitudeIn(BaseModel):
    user_id: str
    content: str = Field(..., min_length=2)
    items: List[str] = []
    mood: str = "neutral"


@router.post("/log", summary="记录感恩日记")
def log_gratitude(body: GratitudeIn, db: Session = Depends(get_db)):
    today = date.today()
    entry = GratitudeEntry(
        id=uuid.uuid4(),
        user_id=body.user_id,
        content=body.content,
        items=body.items,
        mood=body.mood,
        date=today,
        logged_at=datetime.now(),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)

    # Calculate streak
    streak = _calc_streak(db, body.user_id)
    return {
        "success": True,
        "data": {
            "entry_id": str(entry.id),
            "date": today.isoformat(),
            "streak_days": streak,
            "message": "感恩日记已记录，继续保持！",
        }
    }


@router.get("/history/{user_id}", summary="感恩日记历史")
def get_history(
    user_id: str,
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    rows = db.query(GratitudeEntry).filter(
        GratitudeEntry.user_id == user_id
    ).order_by(GratitudeEntry.logged_at.desc()).limit(limit).all()
    return {
        "success": True,
        "data": {
            "entries": [
                {
                    "entry_id": str(r.id),
                    "content": r.content,
                    "items": r.items,
                    "mood": r.mood,
                    "date": r.date.isoformat(),
                    "logged_at": r.logged_at.isoformat(),
                }
                for r in rows
            ],
            "total": len(rows),
        }
    }


@router.get("/streak/{user_id}", summary="连续记录天数")
def get_streak(user_id: str, db: Session = Depends(get_db)):
    streak = _calc_streak(db, user_id)
    total = db.query(func.count(GratitudeEntry.id)).filter(
        GratitudeEntry.user_id == user_id
    ).scalar() or 0
    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "streak_days": streak,
            "total_entries": total,
            "achievement": _streak_badge(streak),
        }
    }


@router.get("/prompts/daily", summary="今日感恩提示")
def daily_prompt():
    import hashlib
    day_index = int(hashlib.md5(date.today().isoformat().encode()).hexdigest(), 16) % len(_DAILY_PROMPTS)
    return {
        "success": True,
        "data": {
            "prompt": _DAILY_PROMPTS[day_index],
            "date": date.today().isoformat(),
        }
    }


@router.get("/insights", summary="感恩练习的益处")
def get_insights():
    return {
        "success": True,
        "data": {
            "insights": _INSIGHTS,
            "tcm_view": "中医情志养生强调「喜则气和志达」，感恩之心有助于心气调达、百病消散。",
        }
    }


# ─── Helpers ────────────────────────────────────────────────────────────────

def _calc_streak(db: Session, user_id: str) -> int:
    """Count consecutive days with at least one entry ending today or yesterday."""
    today = date.today()
    streak = 0
    check_date = today
    while True:
        exists = db.query(GratitudeEntry).filter(
            GratitudeEntry.user_id == user_id,
            GratitudeEntry.date == check_date,
        ).first()
        if not exists:
            if check_date == today:
                # Allow yesterday start
                check_date = today - timedelta(days=1)
                exists2 = db.query(GratitudeEntry).filter(
                    GratitudeEntry.user_id == user_id,
                    GratitudeEntry.date == check_date,
                ).first()
                if not exists2:
                    break
                streak += 1
                check_date -= timedelta(days=1)
            else:
                break
        else:
            streak += 1
            check_date -= timedelta(days=1)
    return streak


def _streak_badge(streak: int) -> str:
    if streak >= 365:
        return "🏆 感恩大师"
    if streak >= 100:
        return "🌟 百日感恩"
    if streak >= 30:
        return "🌙 月度坚持"
    if streak >= 7:
        return "🌱 一周坚持"
    return "🌸 初心感恩"
