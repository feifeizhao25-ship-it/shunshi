"""
顺时 — 智能闹钟 API (shunshi-smart-alarm)
基于时辰和用户习惯的智能闹钟设置与推荐 (PostgreSQL backed)
"""
import uuid
from datetime import datetime
from typing import Optional, List, Literal
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import SmartAlarm

router = APIRouter(prefix="/api/v1/smart-alarm", tags=["smart-alarm"])

_SHICHEN_ALARMS = [
    {"type": "wake_up",      "time": "07:00", "shichen": "辰时 (07-09)",
     "organ": None, "reason": "示例时间，请按自己的工作、休息和生活安排调整"},
    {"type": "breakfast",    "time": "07:30", "shichen": "辰时 (07-09)",
     "organ": None, "reason": "示例时间，请按自己的工作、休息和生活安排调整"},
    {"type": "exercise",     "time": "06:30", "shichen": "卯时 (05-07)",
     "organ": None, "reason": "示例时间，请按自己的工作、休息和生活安排调整"},
    {"type": "lunch",        "time": "12:00", "shichen": "午时 (11-13)",
     "organ": None, "reason": "示例时间，请按自己的工作、休息和生活安排调整"},
    {"type": "afternoon_rest", "time": "13:00", "shichen": "未时 (13-15)",
     "organ": None, "reason": "示例时间，请按自己的工作、休息和生活安排调整"},
    {"type": "meditation",   "time": "17:00", "shichen": "酉时 (17-19)",
     "organ": None, "reason": "示例时间，请按自己的工作、休息和生活安排调整"},
    {"type": "sleep",        "time": "22:30", "shichen": "亥时 (21-23)",
     "organ": None, "reason": "示例时间，请按自己的工作、休息和生活安排调整"},
]

_SOUNDS = [
    {"id": "morning_bell", "name": "晨钟", "description": "寺院晨钟，宁静唤醒"},
    {"id": "bamboo_flute",  "name": "竹笛", "description": "悠扬竹笛，温柔起床"},
    {"id": "nature_birds",  "name": "林间鸟鸣", "description": "大自然鸟声，清新自然"},
    {"id": "guqin",         "name": "古琴", "description": "古典琴音，雅致唤醒"},
    {"id": "bowl_bell",     "name": "颂钵", "description": "颂钵共鸣，冥想唤醒"},
    {"id": "spring_rain",   "name": "春雨", "description": "淅沥雨声，温柔渐进"},
]


class AlarmIn(BaseModel):
    user_id: str
    type: str = Field(..., min_length=1, max_length=32)
    time: str = Field(..., pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    days: List[Literal["mon", "tue", "wed", "thu", "fri", "sat", "sun"]] = Field(default_factory=list, max_length=7)
    sound: Literal["morning_bell", "bamboo_flute", "nature_birds", "guqin", "bowl_bell", "spring_rain"] = "morning_bell"
    shichen_aligned: bool = False


class AlarmUpdateIn(BaseModel):
    time: Optional[str] = Field(None, pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    days: Optional[List[Literal["mon", "tue", "wed", "thu", "fri", "sat", "sun"]]] = Field(None, max_length=7)
    sound: Optional[Literal["morning_bell", "bamboo_flute", "nature_birds", "guqin", "bowl_bell", "spring_rain"]] = None
    enabled: Optional[bool] = None


def _alarm_dict(a: SmartAlarm) -> dict:
    return {
        "alarm_id": str(a.id),
        "type": a.alarm_type,
        "time": a.time,
        "days": a.days,
        "sound": a.sound,
        "enabled": a.enabled,
        "shichen_aligned": a.shichen_aligned,
        "created_at": a.created_at.isoformat(),
    }


@router.get("/recommend", summary="智能推荐闹钟设置")
def recommend_alarms(
    constitution: Optional[str] = Query(None),
    lifestyle: Optional[str] = Query(None),
):
    recommendations = [dict(item) for item in _SHICHEN_ALARMS]
    # For yang-deficiency: suggest earlier sleep
    if constitution == "yang_deficiency":
        for r in recommendations:
            if r["type"] == "sleep":
                r["time"] = "22:00"
                r["reason"] = "较早入睡的示例时间，请按实际作息调整，不代表体质诊断或治疗建议"
    return {
        "success": True,
        "data": {
            "recommendations": recommendations,
            "principle": "以下为作息提醒示例，时辰名称仅作传统文化说明，不代表最佳生理时间或医疗建议。",
        }
    }


@router.post("/", summary="创建闹钟")
def create_alarm(body: AlarmIn, db: Session = Depends(get_db)):
    alarm = SmartAlarm(
        id=uuid.uuid4(),
        user_id=body.user_id,
        alarm_type=body.type,
        time=body.time,
        days=body.days,
        sound=body.sound,
        enabled=True,
        shichen_aligned=body.shichen_aligned,
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )
    db.add(alarm)
    db.commit()
    db.refresh(alarm)
    return {"success": True, "data": _alarm_dict(alarm)}


@router.get("/user/{user_id}", summary="获取用户闹钟列表")
def user_alarms(user_id: str, db: Session = Depends(get_db)):
    alarms = db.query(SmartAlarm).filter(
        SmartAlarm.user_id == user_id,
    ).order_by(SmartAlarm.time.asc()).all()
    return {
        "success": True,
        "data": {"alarms": [_alarm_dict(a) for a in alarms], "total": len(alarms)}
    }


@router.put("/user/{user_id}/alarm/{alarm_id}", summary="更新闹钟")
def update_alarm(
    user_id: str,
    alarm_id: str,
    body: AlarmUpdateIn,
    db: Session = Depends(get_db),
):
    try:
        aid = uuid.UUID(alarm_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="闹钟不存在")
    alarm = db.query(SmartAlarm).filter(
        SmartAlarm.id == aid, SmartAlarm.user_id == user_id
    ).first()
    if not alarm:
        raise HTTPException(status_code=404, detail="闹钟不存在")
    if body.time is not None:
        alarm.time = body.time
    if body.days is not None:
        alarm.days = body.days
    if body.sound is not None:
        alarm.sound = body.sound
    if body.enabled is not None:
        alarm.enabled = body.enabled
    alarm.updated_at = datetime.now()
    db.commit()
    return {"success": True, "data": _alarm_dict(alarm)}


@router.delete("/user/{user_id}/alarm/{alarm_id}", summary="删除闹钟")
def delete_alarm(user_id: str, alarm_id: str, db: Session = Depends(get_db)):
    try:
        aid = uuid.UUID(alarm_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="闹钟不存在")
    alarm = db.query(SmartAlarm).filter(
        SmartAlarm.id == aid, SmartAlarm.user_id == user_id
    ).first()
    if not alarm:
        raise HTTPException(status_code=404, detail="闹钟不存在")
    db.delete(alarm)
    db.commit()
    return {"success": True, "data": {"alarm_id": alarm_id, "message": "闹钟已删除"}}


@router.get("/sounds", summary="铃声列表")
def list_sounds():
    return {"success": True, "data": {"sounds": _SOUNDS}}
