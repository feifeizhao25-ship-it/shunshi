"""
顺时 — 体重管理 API (shunshi-weight-manage)
中医体重管理、辨证减重方案 (PostgreSQL backed)
"""
import uuid
from datetime import datetime, date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import WeightLog, WeightGoal

router = APIRouter(prefix="/api/v1/weight-manage", tags=["weight-manage"])

_TCM_PLANS = {
    "phlegm_dampness": {
        "type": "痰湿质肥胖",
        "description": "痰湿体质者脂肪容易积聚，需化痰祛湿",
        "diet": ["薏米", "冬瓜", "山楂", "荷叶茶"],
        "exercise": "八段锦第五式、太极拳",
        "acupoints": ["丰隆穴", "中脘穴", "足三里"],
        "avoid": ["油腻食物", "甜食", "冷饮"],
    },
    "qi_stagnation": {
        "type": "气郁质肥胖",
        "description": "气郁体质者情绪影响代谢，需疏肝理气",
        "diet": ["玫瑰花茶", "陈皮", "佛手"],
        "exercise": "散步、瑜伽、冥想",
        "acupoints": ["太冲穴", "期门穴", "气海穴"],
        "avoid": ["暴饮暴食", "宵夜"],
    },
    "yang_deficiency": {
        "type": "阳虚质肥胖",
        "description": "阳虚体质代谢缓慢，需温阳化湿",
        "diet": ["生姜", "肉桂", "羊肉", "韭菜"],
        "exercise": "晨间快走、艾灸配合运动",
        "acupoints": ["命门穴", "关元穴", "气海穴"],
        "avoid": ["生冷食物", "夜间进食"],
    },
}

_BMI_CATEGORIES = [
    {"range": "< 18.5", "category": "偏瘦", "advice": "建议增加营养摄入，注意脾胃调养"},
    {"range": "18.5 – 23.9", "category": "正常", "advice": "保持现有生活方式，注重均衡养生"},
    {"range": "24.0 – 27.9", "category": "超重", "advice": "建议减少高热量饮食，增加运动"},
    {"range": "≥ 28.0", "category": "肥胖", "advice": "建议咨询医师制定个性化减重方案"},
]


class WeightLogIn(BaseModel):
    user_id: str
    weight_kg: float = Field(..., gt=0, lt=500)
    date: Optional[str] = None
    note: Optional[str] = None


class WeightGoalIn(BaseModel):
    user_id: str
    target_weight_kg: float = Field(..., gt=0, lt=500)
    weeks: int = Field(default=12, ge=1, le=104)


@router.post("/log", summary="记录体重")
def log_weight(body: WeightLogIn, db: Session = Depends(get_db)):
    log_date = date.fromisoformat(body.date) if body.date else date.today()
    bmi = None  # Could compute if height known

    entry = WeightLog(
        id=uuid.uuid4(),
        user_id=body.user_id,
        weight_kg=body.weight_kg,
        bmi=bmi,
        date=log_date,
        note=body.note,
        logged_at=datetime.now(),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return {
        "success": True,
        "data": {
            "entry_id": str(entry.id),
            "weight_kg": body.weight_kg,
            "date": log_date.isoformat(),
            "message": "体重记录成功",
        }
    }


@router.get("/history/{user_id}", summary="体重历史记录")
def weight_history(
    user_id: str,
    days: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db),
):
    from datetime import timedelta
    since = date.today() - timedelta(days=days)
    rows = db.query(WeightLog).filter(
        WeightLog.user_id == user_id,
        WeightLog.date >= since,
    ).order_by(WeightLog.date.asc()).all()

    records = [
        {"date": r.date.isoformat(), "weight_kg": r.weight_kg,
         "entry_id": str(r.id), "note": r.note}
        for r in rows
    ]
    trend = None
    if len(records) >= 2:
        diff = records[-1]["weight_kg"] - records[0]["weight_kg"]
        trend = {"change_kg": round(diff, 2), "direction": "下降" if diff < 0 else "上升" if diff > 0 else "持平"}

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "records": records,
            "trend": trend,
            "total_records": len(records),
        }
    }


@router.post("/goal", summary="设置体重目标")
def set_goal(body: WeightGoalIn, db: Session = Depends(get_db)):
    row = db.query(WeightGoal).filter(WeightGoal.user_id == body.user_id).first()
    if row:
        row.target_weight_kg = body.target_weight_kg
        row.weeks = body.weeks
        row.updated_at = datetime.now()
    else:
        row = WeightGoal(
            id=uuid.uuid4(),
            user_id=body.user_id,
            target_weight_kg=body.target_weight_kg,
            weeks=body.weeks,
        )
        db.add(row)
    db.commit()
    return {
        "success": True,
        "data": {
            "user_id": body.user_id,
            "target_weight_kg": body.target_weight_kg,
            "weeks": body.weeks,
            "message": "体重目标已设置",
        }
    }


@router.get("/tcm-plan", summary="中医减重方案")
def tcm_plan(constitution: Optional[str] = Query(None)):
    if constitution and constitution in _TCM_PLANS:
        return {"success": True, "data": _TCM_PLANS[constitution]}
    return {
        "success": True,
        "data": {
            "plans": list(_TCM_PLANS.values()),
            "tip": "根据体质选择合适的减重方案效果更佳",
        }
    }


@router.get("/acupoints", summary="减重穴位")
def weight_acupoints():
    return {
        "success": True,
        "data": {
            "acupoints": [
                {"name": "天枢穴", "location": "肚脐旁开2寸", "function": "调理肠胃，促进代谢"},
                {"name": "丰隆穴", "location": "小腿外侧中点", "function": "化痰祛湿，利水消肿"},
                {"name": "足三里", "location": "膝盖下三寸", "function": "补气健脾，增强代谢"},
                {"name": "三阴交", "location": "内踝上三寸", "function": "调理内分泌，消水肿"},
                {"name": "中脘穴", "location": "肚脐上四寸", "function": "健脾和胃，助消化"},
            ],
            "method": "每穴按揉3-5分钟，每日1-2次，配合运动效果更佳",
        }
    }


@router.get("/bmi-guide", summary="BMI健康指导")
def bmi_guide():
    return {
        "success": True,
        "data": {
            "categories": _BMI_CATEGORIES,
            "formula": "BMI = 体重(kg) ÷ 身高(m)²",
            "tcm_perspective": "中医不以BMI为唯一标准，更注重体质平衡与气血调和",
        }
    }
