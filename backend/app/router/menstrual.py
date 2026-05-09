"""
顺时 — 月经期养护 API (shunshi-menstrual)
月经周期追踪、各阶段养护建议、痛经调理 (PostgreSQL backed)
"""
import uuid
from datetime import datetime, date, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import MenstrualCycle, MenstrualSettings

router = APIRouter(prefix="/api/v1/menstrual", tags=["menstrual"])

_PHASE_CARE = {
    "menstrual": {
        "phase": "行经期",
        "days": "第1-5天",
        "principle": "顺势而为，以通为主",
        "diet": ["红糖姜茶", "阿胶糯米粥", "黑木耳", "菠菜"],
        "avoid": ["生冷食物", "辛辣刺激", "剧烈运动"],
        "acupoints": ["血海穴", "三阴交", "关元穴"],
        "emotion": "保持心情平和，避免过度情绪波动",
        "exercise": "轻柔散步、瑜伽猫牛式",
    },
    "follicular": {
        "phase": "卵泡期",
        "days": "第6-13天",
        "principle": "滋阴养血，蓄积能量",
        "diet": ["桑椹", "黑芝麻", "乌鸡汤", "枸杞"],
        "avoid": ["过度节食", "熬夜"],
        "acupoints": ["足三里", "肾俞穴", "太溪穴"],
        "emotion": "此期精力渐旺，适合规划新计划",
        "exercise": "有氧运动、八段锦、太极",
    },
    "ovulation": {
        "phase": "排卵期",
        "days": "第14天前后",
        "principle": "阴阳转化，活血通络",
        "diet": ["山楂", "益母草茶", "红花茶"],
        "avoid": ["过度劳累"],
        "acupoints": ["气海穴", "关元穴"],
        "emotion": "心情开朗、社交活跃的好时机",
        "exercise": "适度有氧、舞蹈",
    },
    "luteal": {
        "phase": "黄体期",
        "days": "第15-28天",
        "principle": "疏肝理气，温阳化湿",
        "diet": ["玫瑰花茶", "陈皮", "薏米", "茯苓"],
        "avoid": ["咖啡因", "高盐食物", "情绪激动"],
        "acupoints": ["太冲穴", "期门穴", "内关穴"],
        "emotion": "注意情绪管理，避免PMS加重",
        "exercise": "瑜伽、冥想、轻度有氧",
    },
}

_DYSMENORRHEA_PLANS = [
    {
        "type": "寒凝血瘀型",
        "symptoms": "经血暗红有血块，小腹冷痛，热敷缓解",
        "treatment": "温经散寒，活血化瘀",
        "diet": ["生姜红糖茶", "当归炖羊肉", "艾叶鸡蛋汤"],
        "acupoints": ["关元穴（艾灸）", "三阴交", "地机穴"],
        "avoid": ["生冷饮食", "淋雨受寒"],
    },
    {
        "type": "气滞血瘀型",
        "symptoms": "胀痛为主，经前乳房胀痛，情绪烦躁",
        "treatment": "疏肝理气，活血止痛",
        "diet": ["玫瑰花茶", "香附茶", "山楂"],
        "acupoints": ["太冲穴", "血海穴", "期门穴"],
        "avoid": ["情绪激动", "压力过大"],
    },
    {
        "type": "气血虚弱型",
        "symptoms": "隐隐作痛，经后加重，面色苍白，乏力",
        "treatment": "补气养血",
        "diet": ["阿胶红枣汤", "八珍汤", "桂圆莲子粥"],
        "acupoints": ["气海穴", "足三里", "脾俞穴"],
        "avoid": ["劳累过度", "节食减肥"],
    },
]


class CycleLogIn(BaseModel):
    user_id: str
    start_date: str
    cycle_length: Optional[int] = Field(None, ge=21, le=45)
    end_date: Optional[str] = None
    flow_level: Optional[str] = "normal"
    symptoms: Optional[list] = []
    notes: Optional[str] = None


class SettingsIn(BaseModel):
    user_id: str
    cycle_length: int = Field(28, ge=21, le=45)
    period_length: int = Field(5, ge=2, le=10)
    reminder_enabled: bool = True
    reminder_days_before: int = Field(2, ge=1, le=7)


def _get_settings(db: Session, user_id: str) -> dict:
    row = db.query(MenstrualSettings).filter(MenstrualSettings.user_id == user_id).first()
    if row:
        return {"cycle_length": row.avg_cycle_length, "period_length": row.avg_period_length}
    return {"cycle_length": 28, "period_length": 5}


@router.post("/cycle/log", summary="记录月经周期")
def log_cycle(body: CycleLogIn, db: Session = Depends(get_db)):
    start = date.fromisoformat(body.start_date)
    end = date.fromisoformat(body.end_date) if body.end_date else None
    settings = _get_settings(db, body.user_id)
    cycle_len = body.cycle_length or settings["cycle_length"]

    entry = MenstrualCycle(
        id=uuid.uuid4(),
        user_id=body.user_id,
        start_date=start,
        end_date=end,
        cycle_length=cycle_len,
        period_length=settings["period_length"],
        flow_level=body.flow_level or "normal",
        symptoms=body.symptoms or [],
        notes=body.notes,
        logged_at=datetime.now(),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)

    next_start = start + timedelta(days=cycle_len)
    return {
        "success": True,
        "data": {
            "cycle_id": str(entry.id),
            "start_date": body.start_date,
            "cycle_length": cycle_len,
            "next_predicted_start": next_start.isoformat(),
            "message": "月经周期记录成功",
        }
    }


@router.get("/cycle/history", summary="月经周期历史")
def cycle_history(
    user_id: str = Query(...),
    limit: int = Query(12, ge=1, le=36),
    db: Session = Depends(get_db),
):
    rows = db.query(MenstrualCycle).filter(
        MenstrualCycle.user_id == user_id
    ).order_by(MenstrualCycle.start_date.desc()).limit(limit).all()
    return {
        "success": True,
        "data": {
            "cycles": [
                {
                    "cycle_id": str(r.id),
                    "start_date": r.start_date.isoformat(),
                    "end_date": r.end_date.isoformat() if r.end_date else None,
                    "cycle_length": r.cycle_length,
                    "flow_level": r.flow_level,
                    "symptoms": r.symptoms,
                }
                for r in rows
            ],
            "total": len(rows),
        }
    }


@router.post("/settings", summary="设置周期参数")
def save_settings(body: SettingsIn, db: Session = Depends(get_db)):
    row = db.query(MenstrualSettings).filter(MenstrualSettings.user_id == body.user_id).first()
    if row:
        row.avg_cycle_length = body.cycle_length
        row.avg_period_length = body.period_length
        row.reminder_enabled = body.reminder_enabled
        row.reminder_days_before = body.reminder_days_before
        row.updated_at = datetime.now()
    else:
        row = MenstrualSettings(
            id=uuid.uuid4(),
            user_id=body.user_id,
            avg_cycle_length=body.cycle_length,
            avg_period_length=body.period_length,
            reminder_enabled=body.reminder_enabled,
            reminder_days_before=body.reminder_days_before,
        )
        db.add(row)
    db.commit()
    return {
        "success": True,
        "data": {"user_id": body.user_id, "cycle_length": body.cycle_length,
                 "period_length": body.period_length, "message": "设置已保存"}
    }


@router.get("/predict", summary="预测下次月经")
def predict_next(user_id: str = Query(...), db: Session = Depends(get_db)):
    last = db.query(MenstrualCycle).filter(
        MenstrualCycle.user_id == user_id
    ).order_by(MenstrualCycle.start_date.desc()).first()

    settings = _get_settings(db, user_id)
    cycle_len = settings["cycle_length"]

    if last:
        next_start = last.start_date + timedelta(days=last.cycle_length)
        next_end = next_start + timedelta(days=settings["period_length"])
        ovulation = next_start - timedelta(days=14)
        fertile_start = ovulation - timedelta(days=2)
        fertile_end = ovulation + timedelta(days=2)
    else:
        today = date.today()
        next_start = today + timedelta(days=cycle_len)
        next_end = next_start + timedelta(days=5)
        ovulation = next_start - timedelta(days=14)
        fertile_start = ovulation - timedelta(days=2)
        fertile_end = ovulation + timedelta(days=2)

    return {
        "success": True,
        "data": {
            "next_period_start": next_start.isoformat(),
            "next_period_end": next_end.isoformat(),
            "ovulation_date": ovulation.isoformat(),
            "fertile_window": {"start": fertile_start.isoformat(), "end": fertile_end.isoformat()},
            "days_until_next": (next_start - date.today()).days,
            "based_on": "last_cycle" if last else "default_28_day",
        }
    }


@router.get("/phase-care", summary="当前阶段养护建议")
def phase_care(user_id: str = Query(...), db: Session = Depends(get_db)):
    last = db.query(MenstrualCycle).filter(
        MenstrualCycle.user_id == user_id
    ).order_by(MenstrualCycle.start_date.desc()).first()

    settings = _get_settings(db, user_id)
    today = date.today()

    if last:
        days_since = (today - last.start_date).days
        period_len = last.period_length
    else:
        days_since = 14  # Default to follicular phase
        period_len = 5

    if days_since < period_len:
        phase_key = "menstrual"
    elif days_since < 13:
        phase_key = "follicular"
    elif days_since < 16:
        phase_key = "ovulation"
    else:
        phase_key = "luteal"

    care = _PHASE_CARE[phase_key].copy()
    care["day_of_cycle"] = days_since + 1
    care["cycle_length"] = settings["cycle_length"]
    return {"success": True, "data": care}


@router.get("/dysmenorrhea", summary="痛经调理方案")
def dysmenorrhea_plans():
    return {
        "success": True,
        "data": {
            "plans": _DYSMENORRHEA_PLANS,
            "general_advice": "经期注意保暖，避免生冷；情绪平稳有助于减轻痛经；严重痛经请就医。",
        }
    }
