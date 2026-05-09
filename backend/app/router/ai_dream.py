"""
顺时 — AI解梦 API (shunshi-ai-dream)
中医梦境解析、脏腑关联分析、调理建议 (PostgreSQL backed)
"""
import uuid
from datetime import datetime, date
from typing import Optional, List
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import DreamLog

router = APIRouter(prefix="/api/v1/ai-dream", tags=["ai-dream"])

# TCM dream → organ mapping
_DREAM_MEANINGS = [
    {
        "keyword_group": ["火", "火焰", "燃烧", "烈火", "热"],
        "organ": "心",
        "organ_en": "Heart",
        "tcm_meaning": "心火旺盛，情志亢奋",
        "emotion": "过度兴奋、焦虑",
        "remedies": ["莲子心茶", "酸枣仁汤", "静坐冥想"],
        "acupoints": ["神门穴", "内关穴", "劳宫穴"],
    },
    {
        "keyword_group": ["水", "洪水", "大海", "溺水", "湖泊"],
        "organ": "肾",
        "organ_en": "Kidney",
        "tcm_meaning": "肾气不足，心肾不交",
        "emotion": "恐惧、不安",
        "remedies": ["六味地黄丸", "枸杞山药粥", "足浴补肾"],
        "acupoints": ["涌泉穴", "太溪穴", "肾俞穴"],
    },
    {
        "keyword_group": ["树", "森林", "草地", "绿色植物", "生长"],
        "organ": "肝",
        "organ_en": "Liver",
        "tcm_meaning": "肝气升发，气机调畅",
        "emotion": "积极向上",
        "remedies": ["保持现状", "玫瑰花茶疏肝"],
        "acupoints": ["太冲穴", "期门穴"],
    },
    {
        "keyword_group": ["飞翔", "飞行", "翅膀", "鸟"],
        "organ": "肺",
        "organ_en": "Lung",
        "tcm_meaning": "肺气充足，气机宣发",
        "emotion": "追求自由",
        "remedies": ["深呼吸练习", "百合银耳汤"],
        "acupoints": ["肺俞穴", "列缺穴"],
    },
    {
        "keyword_group": ["饮食", "食物", "吃", "宴席", "饥饿"],
        "organ": "脾",
        "organ_en": "Spleen",
        "tcm_meaning": "脾胃运化失调，思虑过重",
        "emotion": "思虑、担忧",
        "remedies": ["山药薏米粥", "规律饮食", "减少思虑"],
        "acupoints": ["足三里", "脾俞穴", "中脘穴"],
    },
    {
        "keyword_group": ["战斗", "追赶", "逃跑", "被追"],
        "organ": "胆",
        "organ_en": "Gallbladder",
        "tcm_meaning": "胆气虚怯，决断力不足",
        "emotion": "恐惧、犹豫",
        "remedies": ["温胆汤", "规律作息", "增强自信"],
        "acupoints": ["阳陵泉", "胆俞穴"],
    },
]

_QUALITY_GUIDE = {
    "quality_indicators": [
        {"type": "deep_sleep",    "cn": "深睡",   "signs": ["起床精力充沛", "很少做梦"], "tcm": "阴阳平衡，气血充足"},
        {"type": "vivid_dreams",  "cn": "多梦纷杂", "signs": ["梦境清晰多变"], "tcm": "心神不宁，气血不足或热扰心神"},
        {"type": "nightmare",     "cn": "噩梦惊醒", "signs": ["恐惧惊醒", "心跳加速"], "tcm": "肾气虚、胆气虚或心火旺"},
        {"type": "lucid_dream",   "cn": "清醒梦",   "signs": ["梦中知道自己在做梦"], "tcm": "神志清明，气血调和"},
        {"type": "recurring_dream","cn": "反复梦",  "signs": ["相同场景反复出现"], "tcm": "某一脏腑长期失调"},
    ]
}

_SLEEP_TIPS = [
    {"tip": "子时前(23:00)入睡，养护胆经与肝经", "shichen": "子时"},
    {"tip": "睡前泡脚20分钟，温水加艾叶助眠", "method": "足浴"},
    {"tip": "睡前1小时关闭电子屏幕，减少蓝光干扰", "method": "环境"},
    {"tip": "酸枣仁15g煮水睡前喝，宁心安神", "herb": "酸枣仁"},
    {"tip": "按摩神门穴、内关穴各3分钟助眠", "acupoint": "神门、内关"},
    {"tip": "睡前冥想5分钟，调息放松全身", "method": "冥想"},
    {"tip": "保持卧室凉爽（18-22℃），有利于深度睡眠", "method": "环境"},
]


class DreamLogIn(BaseModel):
    user_id: str
    dream_description: str = Field(..., min_length=5)
    dream_quality: str = "vivid_dreams"
    emotions: List[str] = []
    sleep_time: Optional[str] = None
    wake_time: Optional[str] = None
    body_symptoms: List[str] = []


def _analyze_dream(description: str) -> dict:
    """Match description keywords to organ."""
    description_lower = description.lower()
    for meaning in _DREAM_MEANINGS:
        if any(kw in description_lower or kw in description
               for kw in meaning["keyword_group"]):
            return {
                "organ": meaning["organ"],
                "organ_en": meaning["organ_en"],
                "tcm_meaning": meaning["tcm_meaning"],
                "emotion": meaning["emotion"],
                "remedies": meaning["remedies"],
                "acupoints": meaning["acupoints"],
                "matched_keywords": [
                    kw for kw in meaning["keyword_group"]
                    if kw in description or kw in description_lower
                ],
            }
    # Default: general advice
    return {
        "organ": "心神",
        "organ_en": "Shen (Spirit)",
        "tcm_meaning": "心神略有不宁，宜调养作息",
        "emotion": "一般",
        "remedies": ["规律作息", "减少压力", "适度运动"],
        "acupoints": ["百会穴", "神门穴"],
        "matched_keywords": [],
    }


@router.post("/log", summary="记录并解析梦境")
def log_dream(body: DreamLogIn, db: Session = Depends(get_db)):
    tcm_analysis = _analyze_dream(body.dream_description)
    today = date.today()

    entry = DreamLog(
        id=uuid.uuid4(),
        user_id=body.user_id,
        description=body.dream_description,
        dream_quality=body.dream_quality,
        emotions=body.emotions,
        sleep_time=body.sleep_time,
        wake_time=body.wake_time,
        body_symptoms=body.body_symptoms,
        tcm_analysis=tcm_analysis,
        date=today,
        logged_at=datetime.now(),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)

    return {
        "success": True,
        "data": {
            "entry": {
                "dream_id": str(entry.id),
                "description": body.dream_description,
                "dream_quality": body.dream_quality,
                "date": today.isoformat(),
                "tcm_analysis": tcm_analysis,
            },
            "tcm_insight": (
                f"您的梦境与【{tcm_analysis['organ']}】相关，"
                f"{tcm_analysis['tcm_meaning']}。"
                f"建议：{tcm_analysis['remedies'][0]}。"
            ),
            "remedies": tcm_analysis["remedies"],
            "acupoints": tcm_analysis["acupoints"],
        }
    }


@router.get("/history/{user_id}", summary="梦境历史")
def dream_history(
    user_id: str,
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    rows = db.query(DreamLog).filter(
        DreamLog.user_id == user_id
    ).order_by(DreamLog.logged_at.desc()).limit(limit).all()
    return {
        "success": True,
        "data": {
            "dreams": [
                {
                    "dream_id": str(r.id),
                    "description": r.description[:80] + "…" if len(r.description) > 80 else r.description,
                    "dream_quality": r.dream_quality,
                    "date": r.date.isoformat(),
                    "organ": r.tcm_analysis.get("organ") if r.tcm_analysis else None,
                }
                for r in rows
            ],
            "total": len(rows),
        }
    }


@router.get("/meanings", summary="中医梦境含义参考")
def dream_meanings():
    return {
        "success": True,
        "data": {
            "meanings": [
                {
                    "organ": m["organ"],
                    "keywords": m["keyword_group"],
                    "tcm_meaning": m["tcm_meaning"],
                    "emotion": m["emotion"],
                }
                for m in _DREAM_MEANINGS
            ],
            "note": "中医梦境分析仅供参考，具体调理请咨询专业中医师。",
        }
    }


@router.get("/quality-guide", summary="睡眠质量与中医解读")
def quality_guide():
    return {"success": True, "data": _QUALITY_GUIDE}


@router.get("/sleep-tips", summary="中医助眠建议")
def sleep_tips():
    return {
        "success": True,
        "data": {
            "sleep_tips": _SLEEP_TIPS,
            "tcm_principle": "中医认为「阳入于阴则寐」，睡眠是阴阳平衡的自然体现。",
        }
    }
