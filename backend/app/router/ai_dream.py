"""
顺时 — AI解梦 API (shunshi-ai-dream)
梦境记录与非诊断性回顾 (PostgreSQL backed)
"""
import uuid
from datetime import datetime
from zoneinfo import ZoneInfo
from typing import Optional, List, Literal
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import DreamLog

router = APIRouter(prefix="/api/v1/ai-dream", tags=["ai-dream"])

# Keywords describe dream scenes only; they are not diagnostic criteria.
_SCENES = [
    ("火与热", ["火", "火焰", "燃烧", "烈火", "热"]),
    ("水域", ["水", "洪水", "大海", "溺水", "湖泊"]),
    ("植物", ["树", "森林", "草地", "绿色植物", "生长"]),
    ("飞行", ["飞翔", "飞行", "翅膀", "鸟"]),
    ("饮食", ["饮食", "食物", "吃", "宴席", "饥饿"]),
    ("追逐", ["战斗", "追赶", "逃跑", "被追"]),
]
_NOTE = "梦境内容不能用于判断脏腑、体质或疾病，也不能据此选择药物。"
_SOURCES = [{
    "title": "国家卫生健康委2026年3月18日新闻发布会",
    "url": "https://www.nhc.gov.cn/xcs/c100122/202603/c59335ec83d4498db23acd303a1a14f0.shtml",
    "published_at": "2026-03-18",
    "verified_at": "2026-09-28",
    "scope": "普通梦境不等于睡眠异常；反复噩梦影响白天状态时寻求专业帮助",
}, {
    "title": "英国国家医疗服务体系：夜惊与噩梦",
    "url": "https://www.nhs.uk/conditions/night-terrors/",
    "source_reviewed_at": "2025-11-24",
    "verified_at": "2026-09-28",
    "scope": "睡眠记录、睡前放松及持续困扰时就医；不支持梦境脏腑推断",
}]
_QUALITY_GUIDE = {
    "quality_indicators": [
        {"type": key, "cn": label, "signs": [description], "tcm": _NOTE}
        for key, label, description in [
            ("deep_sleep", "醒后感受", "记录醒来后是否感到休息充分，不能据此确认深睡时长"),
            ("vivid_dreams", "清晰梦境", "记录自己能回忆的梦境"),
            ("nightmare", "噩梦", "记录是否惊醒，以及对次日生活的影响"),
            ("lucid_dream", "清醒梦", "记录梦中知道自己在做梦的感受"),
            ("recurring_dream", "反复梦", "记录重复出现的场景和频率"),
        ]
    ],
    "diagnostic": False,
    "sources": _SOURCES,
}
_SLEEP_TIPS = [
    {"tip": "尝试建立让自己放松的睡前习惯。", "method": "放松"},
    {"tip": "记录睡眠时长、入睡所需时间和次日感受，方便后续核对。", "method": "记录"},
    {"tip": "如果噩梦反复出现并影响睡眠或日常生活，可向医疗专业人员咨询。", "method": "求助"},
]


class DreamLogIn(BaseModel):
    user_id: str
    dream_description: str = Field(..., min_length=5, max_length=10000)
    dream_quality: Literal["deep_sleep", "vivid_dreams", "nightmare", "lucid_dream", "recurring_dream"] = "vivid_dreams"
    emotions: List[str] = []
    sleep_time: Optional[str] = Field(None, pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    wake_time: Optional[str] = Field(None, pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    body_symptoms: List[str] = []


def _analyze_dream(description: str) -> dict:
    """Return descriptive prompts without inferring health or emotions."""
    matched = [(label, [word for word in words if word in description]) for label, words in _SCENES]
    return {
        "organ": None,
        "tcm_meaning": _NOTE,
        "emotion": "请按自己的感受记录，不由梦境关键词推断",
        "remedies": [],
        "acupoints": [],
        "matched_keywords": [word for _, words in matched for word in words],
        "themes": [label for label, words in matched if words],
        "reflection_prompts": ["醒来时，你有什么感受？", "这个梦对今天的生活有影响吗？"],
        "diagnostic": False,
        "evidence_status": "insufficient_for_diagnosis",
    }


@router.post("/log", summary="记录与回顾梦境")
def log_dream(body: DreamLogIn, db: Session = Depends(get_db)):
    tcm_analysis = _analyze_dream(body.dream_description)
    now = datetime.now(ZoneInfo("Asia/Shanghai"))
    today = now.date()

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
        logged_at=now.replace(tzinfo=None),
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
            "tcm_insight": _NOTE,
            "diagnostic": False,
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
                    "organ": None,
                    "diagnostic": False,
                    "note": _NOTE,
                }
                for r in rows
            ],
            "total": len(rows),
        }
    }


@router.get("/meanings", summary="梦境回顾提示")
def dream_meanings():
    return {"success": True, "data": {
        "meanings": [{"theme": label, "organ": None, "keywords": words,
                      "tcm_meaning": _NOTE, "emotion": "由用户自行记录"}
                     for label, words in _SCENES],
        "diagnostic": False, "note": _NOTE,
    }}


@router.get("/quality-guide", summary="睡眠记录说明")
def quality_guide():
    return {"success": True, "data": _QUALITY_GUIDE}


@router.get("/sleep-tips", summary="睡眠记录与放松建议")
def sleep_tips():
    return {"success": True, "data": {
        "sleep_tips": _SLEEP_TIPS, "tcm_principle": _NOTE,
        "diagnostic": False, "sources": _SOURCES,
    }}
