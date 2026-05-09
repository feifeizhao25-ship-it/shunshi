"""
顺时 — 习惯养成 API (shunshi-habit-builder)
建立健康养生习惯、追踪习惯打卡 (PostgreSQL backed)
"""
import uuid
from datetime import datetime, date, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import Habit, HabitCheckin

router = APIRouter(prefix="/api/v1/habits", tags=["habits"])

_TEMPLATES = [
    {"id": "morning_baduanjin", "name": "晨练八段锦", "category": "exercise",
     "frequency": "daily", "target_days": 21, "description": "每天早晨练习八段锦，调和气血"},
    {"id": "water_2000", "name": "每日喝水2000ml", "category": "health",
     "frequency": "daily", "target_days": 21, "description": "养成科学补水习惯"},
    {"id": "sleep_2230", "name": "22:30前入睡", "category": "sleep",
     "frequency": "daily", "target_days": 30, "description": "子时前入睡，养护肝胆"},
    {"id": "gratitude_journal", "name": "感恩日记", "category": "emotion",
     "frequency": "daily", "target_days": 21, "description": "每日记录三件感恩的事"},
    {"id": "no_phone_bed", "name": "睡前不刷手机", "category": "sleep",
     "frequency": "daily", "target_days": 21, "description": "睡前1小时远离电子屏幕"},
    {"id": "seasonal_food", "name": "吃应季食材", "category": "diet",
     "frequency": "daily", "target_days": 30, "description": "顺应节气选择当季食材"},
    {"id": "acupoint_massage", "name": "穴位按摩", "category": "health",
     "frequency": "daily", "target_days": 21, "description": "每天按摩足三里、合谷等保健穴位"},
    {"id": "meditation_10min", "name": "冥想10分钟", "category": "emotion",
     "frequency": "daily", "target_days": 21, "description": "每天静坐冥想，调养心神"},
]

_CATEGORIES = [
    {"id": "exercise", "name": "运动功法"},
    {"id": "diet", "name": "饮食调养"},
    {"id": "sleep", "name": "睡眠管理"},
    {"id": "health", "name": "日常保健"},
    {"id": "emotion", "name": "情志养生"},
]


class HabitIn(BaseModel):
    user_id: str
    name: str = Field(..., min_length=2, max_length=100)
    category: str = "health"
    frequency: str = "daily"
    target_days: int = Field(default=21, ge=1, le=365)


class CheckinIn(BaseModel):
    user_id: str
    note: Optional[str] = None


def _compute_streak(db: Session, habit_id: uuid.UUID) -> int:
    today = date.today()
    streak = 0
    check_date = today - timedelta(days=1)  # count days before today
    while True:
        exists = db.query(HabitCheckin).filter(
            HabitCheckin.habit_id == habit_id,
            HabitCheckin.check_date == check_date,
        ).first()
        if not exists:
            break
        streak += 1
        check_date -= timedelta(days=1)
    return streak


@router.get("/templates", summary="习惯模板")
def list_templates(category: Optional[str] = Query(None)):
    templates = [t for t in _TEMPLATES if not category or t["category"] == category]
    return {"success": True, "data": {"templates": templates, "total": len(templates)}}


@router.post("/", summary="创建习惯")
def create_habit(body: HabitIn, db: Session = Depends(get_db)):
    habit = Habit(
        id=uuid.uuid4(),
        user_id=body.user_id,
        name=body.name,
        category=body.category,
        frequency=body.frequency,
        target_days=body.target_days,
        current_streak=0,
        longest_streak=0,
        total_checkins=0,
        is_active=True,
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )
    db.add(habit)
    db.commit()
    db.refresh(habit)
    return {
        "success": True,
        "data": {
            "habit_id": str(habit.id),
            "name": habit.name,
            "category": habit.category,
            "frequency": habit.frequency,
            "target_days": habit.target_days,
            "created_at": habit.created_at.isoformat(),
        }
    }


@router.get("/user/{user_id}", summary="用户习惯列表")
def user_habits(user_id: str, db: Session = Depends(get_db)):
    habits = db.query(Habit).filter(
        Habit.user_id == user_id,
        Habit.is_active == True,  # noqa: E712
    ).order_by(Habit.created_at.desc()).all()
    return {
        "success": True,
        "data": {
            "habits": [
                {
                    "habit_id": str(h.id),
                    "name": h.name,
                    "category": h.category,
                    "frequency": h.frequency,
                    "target_days": h.target_days,
                    "current_streak": h.current_streak,
                    "longest_streak": h.longest_streak,
                    "total_checkins": h.total_checkins,
                    "progress_pct": round(min(h.total_checkins / h.target_days * 100, 100), 1),
                }
                for h in habits
            ],
            "total": len(habits),
        }
    }


@router.post("/{habit_id}/checkin", summary="习惯打卡")
def checkin(habit_id: str, body: CheckinIn, db: Session = Depends(get_db)):
    try:
        hid = uuid.UUID(habit_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="习惯不存在")
    habit = db.query(Habit).filter(
        Habit.id == hid, Habit.user_id == body.user_id
    ).first()
    if not habit:
        raise HTTPException(status_code=404, detail="习惯不存在")

    today = date.today()
    already = db.query(HabitCheckin).filter(
        HabitCheckin.habit_id == hid,
        HabitCheckin.check_date == today,
    ).first()
    if already:
        return {
            "success": True,
            "data": {
                "habit_id": habit_id,
                "already_checked": True,
                "current_streak": habit.current_streak,
                "message": "今日已打卡",
            }
        }

    entry = HabitCheckin(
        id=uuid.uuid4(),
        habit_id=hid,
        user_id=body.user_id,
        check_date=today,
        note=body.note,
        logged_at=datetime.now(),
    )
    db.add(entry)
    habit.total_checkins += 1
    streak = _compute_streak(db, hid) + 1
    habit.current_streak = streak
    if streak > habit.longest_streak:
        habit.longest_streak = streak
    habit.updated_at = datetime.now()
    db.commit()

    return {
        "success": True,
        "data": {
            "habit_id": habit_id,
            "habit_name": habit.name,
            "check_date": today.isoformat(),
            "current_streak": streak,
            "longest_streak": habit.longest_streak,
            "total_checkins": habit.total_checkins,
            "progress_pct": round(min(habit.total_checkins / habit.target_days * 100, 100), 1),
            "message": f"打卡成功！连续 {streak} 天 🌟",
        }
    }


@router.get("/{habit_id}/progress", summary="习惯进度")
def habit_progress(habit_id: str, db: Session = Depends(get_db)):
    try:
        hid = uuid.UUID(habit_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="习惯不存在")
    habit = db.query(Habit).filter(Habit.id == hid).first()
    if not habit:
        raise HTTPException(status_code=404, detail="习惯不存在")

    today = date.today()
    since = today - timedelta(days=29)
    checkins = db.query(HabitCheckin).filter(
        HabitCheckin.habit_id == hid,
        HabitCheckin.check_date >= since,
    ).all()
    checked_dates = {c.check_date.isoformat() for c in checkins}
    calendar = [
        {"date": (since + timedelta(days=i)).isoformat(),
         "checked": (since + timedelta(days=i)).isoformat() in checked_dates}
        for i in range(30)
    ]
    return {
        "success": True,
        "data": {
            "habit_id": habit_id,
            "name": habit.name,
            "target_days": habit.target_days,
            "total_checkins": habit.total_checkins,
            "current_streak": habit.current_streak,
            "longest_streak": habit.longest_streak,
            "progress_pct": round(min(habit.total_checkins / habit.target_days * 100, 100), 1),
            "calendar_30d": calendar,
        }
    }


@router.get("/categories/list", summary="习惯分类")
def list_categories():
    return {"success": True, "data": {"categories": _CATEGORIES}}
