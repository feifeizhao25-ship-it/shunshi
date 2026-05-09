"""
顺时 — 饮水追踪 API (shunshi-water-tracker)
记录每日饮水量，提供科学补水建议 (PostgreSQL backed)
"""
import uuid
from datetime import datetime, date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.database import get_db
from app.models.wellness_tracking import WaterLog, WaterGoal

router = APIRouter(prefix="/api/v1/water-tracker", tags=["water-tracker"])


class WaterLogIn(BaseModel):
    user_id: str
    amount_ml: int = Field(..., ge=1, le=5000)
    type: str = "water"


class WaterGoalIn(BaseModel):
    user_id: str
    goal_ml: int = Field(..., ge=100, le=10000)


def _get_user_goal(db: Session, user_id: str) -> int:
    row = db.query(WaterGoal).filter(WaterGoal.user_id == user_id).first()
    return row.goal_ml if row else 1700


@router.post("/log", summary="记录饮水")
def log_water(body: WaterLogIn, db: Session = Depends(get_db)):
    today = date.today()
    entry = WaterLog(
        id=uuid.uuid4(),
        user_id=body.user_id,
        amount_ml=body.amount_ml,
        type=body.type,
        logged_at=datetime.now(),
        date=today,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)

    total = db.query(func.sum(WaterLog.amount_ml)).filter(
        WaterLog.user_id == body.user_id,
        WaterLog.date == today,
    ).scalar() or 0
    goal_ml = _get_user_goal(db, body.user_id)
    return {
        "success": True,
        "data": {
            "entry_id": str(entry.id),
            "amount_ml": body.amount_ml,
            "type": body.type,
            "logged_at": entry.logged_at.isoformat(),
            "today_total_ml": total,
            "goal_ml": goal_ml,
            "progress_pct": round(min(total / goal_ml * 100, 100), 1),
        }
    }


@router.get("/today", summary="今日饮水记录")
def today_water(user_id: str = Query(...), db: Session = Depends(get_db)):
    today = date.today()
    logs = db.query(WaterLog).filter(
        WaterLog.user_id == user_id,
        WaterLog.date == today,
    ).order_by(WaterLog.logged_at.desc()).all()
    total = sum(e.amount_ml for e in logs)
    goal_ml = _get_user_goal(db, user_id)
    return {
        "success": True,
        "data": {
            "date": today.isoformat(),
            "entries": [
                {"entry_id": str(e.id), "amount_ml": e.amount_ml,
                 "type": e.type, "logged_at": e.logged_at.isoformat()}
                for e in logs
            ],
            "total_ml": total,
            "goal_ml": goal_ml,
            "progress_pct": round(min(total / goal_ml * 100, 100), 1),
            "remaining_ml": max(goal_ml - total, 0),
        }
    }


@router.post("/goal", summary="设置每日饮水目标")
def set_goal(body: WaterGoalIn, db: Session = Depends(get_db)):
    row = db.query(WaterGoal).filter(WaterGoal.user_id == body.user_id).first()
    if row:
        row.goal_ml = body.goal_ml
        row.updated_at = datetime.now()
    else:
        row = WaterGoal(id=uuid.uuid4(), user_id=body.user_id, goal_ml=body.goal_ml)
        db.add(row)
    db.commit()
    return {
        "success": True,
        "data": {"user_id": body.user_id, "goal_ml": body.goal_ml, "message": "饮水目标已更新"}
    }


@router.get("/recommend", summary="个性化补水建议")
def recommend_water(
    user_id: str = Query(...),
    weight_kg: Optional[float] = Query(None),
    season: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    goal_ml = _get_user_goal(db, user_id)
    today = date.today()
    total_today = db.query(func.sum(WaterLog.amount_ml)).filter(
        WaterLog.user_id == user_id,
        WaterLog.date == today,
    ).scalar() or 0
    mult = {"summer": 1.3, "winter": 0.9}.get(season or "", 1.0)
    recommended_ml = int((weight_kg * 33 if weight_kg else goal_ml) * mult)
    schedule = [
        {"time": "07:00", "amount_ml": 300, "tip": "晨起空腹温水，激活肠胃"},
        {"time": "09:30", "amount_ml": 200, "tip": "上午工作间隙补水"},
        {"time": "12:00", "amount_ml": 200, "tip": "饭前半小时少量饮水"},
        {"time": "14:30", "amount_ml": 200, "tip": "午后提神补水"},
        {"time": "17:00", "amount_ml": 200, "tip": "下午收尾补水"},
        {"time": "19:00", "amount_ml": 200, "tip": "晚餐前适量饮水"},
        {"time": "21:00", "amount_ml": 100, "tip": "睡前少量温水"},
    ]
    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "recommended_daily_ml": recommended_ml,
            "today_total_ml": total_today,
            "remaining_ml": max(recommended_ml - total_today, 0),
            "drink_schedule": schedule,
            "tcm_advice": "中医认为津液为生命根本，温水养阳，切勿大量冷饮伤胃。",
        }
    }


@router.delete("/log/{entry_id}", summary="删除饮水记录")
def delete_log(entry_id: str, user_id: str = Query(...), db: Session = Depends(get_db)):
    try:
        uid = uuid.UUID(entry_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="记录不存在")
    entry = db.query(WaterLog).filter(WaterLog.id == uid, WaterLog.user_id == user_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="记录不存在")
    db.delete(entry)
    db.commit()
    return {"success": True, "data": {"message": "记录已删除", "entry_id": entry_id}}
