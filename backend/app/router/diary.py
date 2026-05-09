"""
顺时 — 日记 API（Diary）
Flutter 端调用 /api/v1/diary/* 端点，本路由桥接到 DiaryEntry 模型。
"""

from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func, and_

from app.db.database import get_db
from app.models.diary import DiaryEntry
from fastapi import Depends

router = APIRouter(prefix="/api/v1/diary", tags=["diary"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求模型
# ─────────────────────────────────────────────────────────────────────────────

class DiarySaveRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    entry_date: Optional[str] = Field(None, description="日期 (YYYY-MM-DD)，默认今天")
    mood: Optional[int] = Field(None, ge=1, le=5, description="心情评分 1-5")
    sleep_quality: Optional[int] = Field(None, ge=1, le=5, description="睡眠质量 1-5")
    sleep_hours: Optional[float] = Field(None, ge=0, le=24, description="睡眠时长")
    diet: Optional[str] = Field(None, max_length=2000, description="饮食记录")
    water_glasses: Optional[int] = Field(None, ge=0, le=30, description="饮水杯数")
    exercise: Optional[str] = Field(None, max_length=2000, description="运动记录")
    exercise_minutes: Optional[int] = Field(None, ge=0, description="运动时长（分钟）")
    notes: Optional[str] = Field(None, max_length=5000, description="备注")


class DiaryEntryRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    date: Optional[str] = Field(None, description="日期 (YYYY-MM-DD)")
    mood: Optional[int] = Field(None, ge=1, le=5)
    sleep_quality: Optional[int] = Field(None, ge=1, le=5)
    sleep_hours: Optional[float] = Field(None, ge=0, le=24)
    notes: Optional[str] = Field(None, max_length=1000)
    tags: Optional[List[str]] = Field(None, description="标签列表")
    constitution_type: Optional[str] = Field(None, description="体质类型")


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/list")
async def list_diary_entries(
    user_id: str = Query(..., description="用户ID"),
    limit: int = Query(7, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """获取日记列表"""
    entries = (
        db.query(DiaryEntry)
        .filter(DiaryEntry.user_id == user_id)
        .order_by(DiaryEntry.entry_date.desc())
        .limit(limit)
        .all()
    )
    return {
        "entries": [
            {
                "id": str(e.id),
                "user_id": e.user_id,
                "entry_date": str(e.entry_date),
                "mood": e.mood,
                "sleep_quality": e.sleep_quality,
                "sleep_hours": e.sleep_hours,
                "diet": e.diet,
                "water_glasses": e.water_glasses,
                "exercise": e.exercise,
                "exercise_minutes": e.exercise_minutes,
                "notes": e.notes,
                "ai_comment": e.ai_comment,
                "created_at": str(e.created_at) if hasattr(e, "created_at") else None,
            }
            for e in entries
        ],
        "total": len(entries),
    }


@router.get("/entries")
async def get_diary_entries(
    user_id: str = Query(..., description="用户ID"),
    db: Session = Depends(get_db),
):
    """获取用户所有日记条目"""
    entries = (
        db.query(DiaryEntry)
        .filter(DiaryEntry.user_id == user_id)
        .order_by(DiaryEntry.entry_date.desc())
        .all()
    )
    return {
        "entries": [
            {
                "id": str(e.id),
                "user_id": e.user_id,
                "entry_date": str(e.entry_date),
                "mood": e.mood,
                "sleep_quality": e.sleep_quality,
                "sleep_hours": e.sleep_hours,
                "diet": e.diet,
                "water_glasses": e.water_glasses,
                "exercise": e.exercise,
                "exercise_minutes": e.exercise_minutes,
                "notes": e.notes,
                "ai_comment": e.ai_comment,
            }
            for e in entries
        ]
    }


@router.get("/trends")
async def get_diary_trends(
    user_id: str = Query(..., description="用户ID"),
    days: int = Query(30, ge=7, le=90),
    db: Session = Depends(get_db),
):
    """获取日记趋势数据"""
    since = date.today() - timedelta(days=days)
    entries = (
        db.query(DiaryEntry)
        .filter(
            DiaryEntry.user_id == user_id,
            DiaryEntry.entry_date >= since,
        )
        .order_by(DiaryEntry.entry_date)
        .all()
    )
    if not entries:
        return {"trends": [], "summary": {"avg_mood": None, "avg_sleep_quality": None, "total_entries": 0}}

    mood_vals = [e.mood for e in entries if e.mood is not None]
    sleep_vals = [e.sleep_quality for e in entries if e.sleep_quality is not None]

    return {
        "trends": [
            {
                "date": str(e.entry_date),
                "mood": e.mood,
                "sleep_quality": e.sleep_quality,
                "sleep_hours": e.sleep_hours,
                "water_glasses": e.water_glasses,
                "exercise_minutes": e.exercise_minutes,
            }
            for e in entries
        ],
        "summary": {
            "avg_mood": round(sum(mood_vals) / len(mood_vals), 1) if mood_vals else None,
            "avg_sleep_quality": round(sum(sleep_vals) / len(sleep_vals), 1) if sleep_vals else None,
            "total_entries": len(entries),
        },
    }


@router.post("/entry")
async def create_diary_entry(
    request: DiaryEntryRequest,
    db: Session = Depends(get_db),
):
    """创建日记条目（/entry 端点）"""
    entry_date = date.today()
    if request.date:
        try:
            entry_date = date.fromisoformat(request.date)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format, use YYYY-MM-DD")

    entry = DiaryEntry(
        user_id=request.user_id,
        entry_date=entry_date,
        mood=request.mood,
        sleep_quality=request.sleep_quality,
        sleep_hours=request.sleep_hours,
        notes=request.notes,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)

    return {
        "id": str(entry.id),
        "user_id": entry.user_id,
        "entry_date": str(entry.entry_date),
        "mood": entry.mood,
        "sleep_quality": entry.sleep_quality,
        "message": "日记创建成功",
    }


@router.post("/save")
async def save_diary_entry(
    request: DiarySaveRequest,
    db: Session = Depends(get_db),
):
    """保存日记条目（/save 端点，含完整字段）"""
    entry_date = date.today()
    if request.entry_date:
        try:
            entry_date = date.fromisoformat(request.entry_date)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format, use YYYY-MM-DD")

    entry = DiaryEntry(
        user_id=request.user_id,
        entry_date=entry_date,
        mood=request.mood,
        sleep_quality=request.sleep_quality,
        sleep_hours=request.sleep_hours,
        diet=request.diet,
        water_glasses=request.water_glasses,
        exercise=request.exercise,
        exercise_minutes=request.exercise_minutes,
        notes=request.notes,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)

    return {
        "id": str(entry.id),
        "user_id": entry.user_id,
        "entry_date": str(entry.entry_date),
        "message": "日记保存成功",
    }
