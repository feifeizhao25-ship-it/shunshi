"""
顺时 — 每日健康打卡与日记系统 API
提供日记记录、健康指数计算、打卡签到、体质与季节性健康洞察。
(PostgreSQL backed)
"""

from fastapi import APIRouter, Query, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date, timedelta
from uuid import uuid4
from sqlalchemy.orm import Session
from sqlalchemy import func, and_

from app.db.database import get_db
from app.models.journal import JournalEntry as JournalEntryModel

router = APIRouter(prefix="/api/v1/journal", tags=["journal"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求/响应模型
# ─────────────────────────────────────────────────────────────────────────────

class JournalEntryRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    date: Optional[str] = Field(None, description="日期 (YYYY-MM-DD)，默认今天")
    mood: int = Field(..., ge=1, le=5, description="心情评分 1-5（1最低，5最高）")
    energy: int = Field(..., ge=1, le=5, description="精力评分 1-5（1最低，5最高）")
    sleep_quality: int = Field(..., ge=1, le=5, description="睡眠质量 1-5（1最差，5最好）")
    notes: Optional[str] = Field(None, max_length=1000, description="日记备注")
    tags: Optional[List[str]] = Field(None, description="标签列表，如 ['工作', '运动', '压力']")
    constitution_type: Optional[str] = Field(None, description="体质类型，如 'qi_deficiency', 'yin_deficiency'")


# ─────────────────────────────────────────────────────────────────────────────
# 中医健康知识库
# ─────────────────────────────────────────────────────────────────────────────

TCM_WELLNESS_INSIGHTS = {
    "low_mood": {
        "condition": "心情低落（1-2分）",
        "diagnosis": "肝气郁结，心神不宁",
        "insight": "情绪低落时，肝气易郁结。建议通过舒展活动、深呼吸来疏通气机。",
        "recommendation": "疏肝理气，宜散步、听舒缓音乐、温和瑜伽",
        "acupoints": ["太冲（LV3）", "合谷（LI4）"],
    },
    "moderate_mood": {
        "condition": "心情一般（3分）",
        "diagnosis": "气机调和，略有不适",
        "insight": "情绪稳定但未达最佳状态。建议增加户外活动和社交互动。",
        "recommendation": "调畅情志，宜郊游、见友、温阳",
        "acupoints": ["内关（PC6）"],
    },
    "good_mood": {
        "condition": "心情良好（4-5分）",
        "diagnosis": "气血调和，神志清明",
        "insight": "情绪稳定且积极，这是最佳的工作和学习状态。维持这份平和喜乐。",
        "recommendation": "维持最佳状态，宜深度工作、创意活动",
        "acupoints": ["神门（HT7）"],
    },
    "low_energy": {
        "condition": "精力不足（1-2分）",
        "diagnosis": "气虚表现，脾胃功能弱",
        "insight": "持续疲劳可能源于气虚。建议增加进补和充足休息。",
        "recommendation": "补气养血，宜食山药、红枣、黄芪、早睡",
        "acupoints": ["足三里（ST36）", "三阴交（SP6）"],
    },
    "moderate_energy": {
        "condition": "精力一般（3分）",
        "diagnosis": "气机未充，潜力未发",
        "insight": "精力还有提升空间。增加温和运动和营养补充能改善状态。",
        "recommendation": "适度补气，宜清淡易消化的饮食、温阳运动",
        "acupoints": ["足三里（ST36）"],
    },
    "high_energy": {
        "condition": "精力充沛（4-5分）",
        "diagnosis": "气血充足，阳气旺盛",
        "insight": "精力充沛是最佳养生状态。保持规律作息和均衡饮食来维持。",
        "recommendation": "维持充足精力，宜适度运动、日光照射",
        "acupoints": ["足三里（ST36）"],
    },
    "low_sleep": {
        "condition": "睡眠不佳（1-2分）",
        "diagnosis": "心神不安，阴血不足",
        "insight": "睡眠质量差会加速衰老和损耗免疫力。建议立即改善睡眠环境和习惯。",
        "recommendation": "安神助眠，宜睡前泡脚、冥想、避免蓝光",
        "acupoints": ["神门（HT7）", "涌泉（KD1）"],
    },
    "moderate_sleep": {
        "condition": "睡眠一般（3分）",
        "diagnosis": "睡眠质量有待改善",
        "insight": "睡眠已足够但深度不够。优化睡眠环境和入睡前的放松活动能显著改善。",
        "recommendation": "改善睡眠质量，宜按摩穴位、温热环境",
        "acupoints": ["内关（PC6）", "神门（HT7）"],
    },
    "good_sleep": {
        "condition": "睡眠良好（4-5分）",
        "diagnosis": "阴阳平衡，精神恢复良好",
        "insight": "优质睡眠是最好的免疫增强剂和美容秘方。继续维持规律的睡眠时间。",
        "recommendation": "维持睡眠质量，继续当前的睡前习惯",
        "acupoints": ["三阴交（SP6）"],
    },
}

CONSTITUTION_GUIDANCE = {
    "qi_deficiency": "气虚体质，易疲劳。建议增加足三里穴位按摩，食用山药、红枣等补气食物。",
    "yang_deficiency": "阳虚体质，怕冷。建议温阳补气，避免过度消耗，增加温热饮食。",
    "yin_deficiency": "阴虚体质，易口干。建议滋阴养血，避免过度劳累，增加睡眠时间。",
    "phlegm_dampness": "痰湿体质，容易困倦。建议健脾祛湿，增加运动，减少油腻饮食。",
    "damp_heat": "湿热体质，易烦躁。建议清热祛湿，避免辛辣刺激，增加清淡饮食。",
    "qi_stagnation": "气郁体质，易烦躁。建议疏肝理气，增加户外活动，进行深呼吸练习。",
    "balanced": "体质平和，保持当前的生活方式和饮食习惯即可。",
}


def _calculate_wellness_score(mood: int, energy: int, sleep_quality: int) -> float:
    """计算综合健康指数 (0-100)"""
    avg = (mood + energy + sleep_quality) / 3
    return round(avg * 20, 1)


def _get_tcm_insight(mood: int, energy: int, sleep_quality: int, constitution_type: Optional[str] = None) -> str:
    """根据三项指标生成中医健康建议"""
    insights = []

    if mood <= 2:
        insights.append(TCM_WELLNESS_INSIGHTS["low_mood"]["insight"])
    elif mood == 3:
        insights.append(TCM_WELLNESS_INSIGHTS["moderate_mood"]["insight"])
    else:
        insights.append(TCM_WELLNESS_INSIGHTS["good_mood"]["insight"])

    if energy <= 2:
        insights.append(TCM_WELLNESS_INSIGHTS["low_energy"]["insight"])
    elif energy == 3:
        insights.append(TCM_WELLNESS_INSIGHTS["moderate_energy"]["insight"])
    else:
        insights.append(TCM_WELLNESS_INSIGHTS["high_energy"]["insight"])

    if sleep_quality <= 2:
        insights.append(TCM_WELLNESS_INSIGHTS["low_sleep"]["insight"])
    elif sleep_quality == 3:
        insights.append(TCM_WELLNESS_INSIGHTS["moderate_sleep"]["insight"])
    else:
        insights.append(TCM_WELLNESS_INSIGHTS["good_sleep"]["insight"])

    if constitution_type and constitution_type in CONSTITUTION_GUIDANCE:
        insights.append(CONSTITUTION_GUIDANCE[constitution_type])

    return " | ".join(insights)


# ─────────────────────────────────────────────────────────────────────────────
# 端点 (PostgreSQL backed)
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/entry", summary="创建日记条目")
async def create_journal_entry(request: JournalEntryRequest, db: Session = Depends(get_db)):
    """创建新的日记条目，计算健康指数并生成中医建议。"""
    if not (1 <= request.mood <= 5) or not (1 <= request.energy <= 5) or not (1 <= request.sleep_quality <= 5):
        raise HTTPException(status_code=422, detail="mood, energy, sleep_quality must be between 1 and 5")

    entry_date = request.date or date.today().isoformat()
    entry_id = str(uuid4())
    wellness_score = _calculate_wellness_score(request.mood, request.energy, request.sleep_quality)
    tcm_insight = _get_tcm_insight(request.mood, request.energy, request.sleep_quality, request.constitution_type)

    # 存入数据库
    row = JournalEntryModel(
        id=entry_id,
        user_id=request.user_id,
        date=entry_date,
        mood=str(request.mood),
        mood_score=request.mood,
        energy_level=request.energy,
        sleep_quality=request.sleep_quality,
        content=request.notes or "",
        tags=request.tags or [],
        ai_insight=tcm_insight,
    )
    db.add(row)
    db.commit()
    db.refresh(row)

    return {
        "success": True,
        "data": {
            "entry_id": entry_id,
            "user_id": request.user_id,
            "date": entry_date,
            "mood": request.mood,
            "energy": request.energy,
            "sleep_quality": request.sleep_quality,
            "notes": request.notes or "",
            "tags": request.tags or [],
            "constitution_type": request.constitution_type,
            "wellness_score": wellness_score,
            "tcm_insight": tcm_insight,
            "timestamp": datetime.now().isoformat(),
        },
    }


@router.get("/entries/{user_id}", summary="获取日记历史")
async def get_journal_entries(
    user_id: str,
    limit: int = Query(30, ge=1, le=100),
    offset: int = Query(0, ge=0),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    """获取用户的日记历史，支持日期范围过滤和分页。"""
    q = db.query(JournalEntryModel).filter(JournalEntryModel.user_id == user_id)
    if start_date:
        q = q.filter(JournalEntryModel.date >= start_date)
    if end_date:
        q = q.filter(JournalEntryModel.date <= end_date)
    total = q.count()
    rows = q.order_by(JournalEntryModel.date.desc()).offset(offset).limit(limit).all()

    entries = []
    for r in rows:
        entries.append({
            "entry_id": str(r.id),
            "user_id": r.user_id,
            "date": r.date,
            "mood": r.mood_score or 0,
            "energy": r.energy_level or 0,
            "sleep_quality": r.sleep_quality or 0,
            "notes": r.content or "",
            "tags": r.tags or [],
            "wellness_score": _calculate_wellness_score(r.mood_score or 3, r.energy_level or 3, r.sleep_quality or 3),
            "tcm_insight": r.ai_insight or "",
            "timestamp": r.created_at.isoformat() if r.created_at else "",
        })

    return {"success": True, "data": {"entries": entries, "total": total, "limit": limit, "offset": offset}}


@router.get("/streak/{user_id}", summary="获取打卡签到记录")
async def get_checkin_streak(user_id: str, db: Session = Depends(get_db)):
    """获取用户的连续打卡天数、最长记录和最后打卡日期。"""
    rows = (db.query(JournalEntryModel.date)
            .filter(JournalEntryModel.user_id == user_id)
            .order_by(JournalEntryModel.date.desc()).all())

    if not rows:
        return {"success": True, "data": {"current_streak": 0, "longest_streak": 0, "total_entries": 0, "last_entry_date": None}}

    dates = sorted(set(r.date for r in rows))
    total = len(dates)
    last_date = dates[-1] if isinstance(dates[-1], date) else date.fromisoformat(str(dates[-1]))

    # 计算 current_streak（从最后一天往前数，遇到间隔停止）
    current_streak = 1
    for i in range(len(dates) - 1, 0, -1):
        d1 = dates[i] if isinstance(dates[i], date) else date.fromisoformat(str(dates[i]))
        d0 = dates[i-1] if isinstance(dates[i-1], date) else date.fromisoformat(str(dates[i-1]))
        if (d1 - d0).days == 1:
            current_streak += 1
        else:
            break

    # 计算 longest_streak
    longest_streak = 1
    streak = 1
    for i in range(len(dates) - 1, 0, -1):
        d1 = dates[i] if isinstance(dates[i], date) else date.fromisoformat(str(dates[i]))
        d0 = dates[i-1] if isinstance(dates[i-1], date) else date.fromisoformat(str(dates[i-1]))
        if (d1 - d0).days == 1:
            streak += 1
            longest_streak = max(longest_streak, streak)
        elif (d1 - d0).days > 1:
            streak = 1

    today = date.today()
    days_since = (today - last_date).days
    current_streak = current_streak if days_since <= 1 else 0

    return {"success": True, "data": {"current_streak": current_streak, "longest_streak": longest_streak, "total_entries": total, "last_entry_date": str(last_date)}}


@router.get("/insights/{user_id}", summary="获取周度健康洞察")
async def get_wellness_insights(user_id: str, db: Session = Depends(get_db)):
    """获取过去7天的平均指标、趋势分析和中医模式识别。"""
    seven_days_ago = (date.today() - timedelta(days=7)).isoformat()
    rows = (db.query(JournalEntryModel)
            .filter(and_(JournalEntryModel.user_id == user_id, JournalEntryModel.date >= seven_days_ago))
            .order_by(JournalEntryModel.date).all())

    if not rows:
        return {
            "success": True, "data": {
                "period": "last_7_days", "entries_count": 0,
                "avg_mood": 0, "avg_energy": 0, "avg_sleep_quality": 0, "avg_wellness_score": 0,
                "trend": "no_data", "tcm_pattern": "数据不足，无法分析",
                "recommendations": ["开始记录日常状态，7天后可获得详细洞察"],
            },
        }

    moods = [r.mood_score or 3 for r in rows]
    energies = [r.energy_level or 3 for r in rows]
    sleeps = [r.sleep_quality or 3 for r in rows]
    scores = [_calculate_wellness_score(m, e, s) for m, e, s in zip(moods, energies, sleeps)]

    avg_mood = round(sum(moods) / len(moods), 1)
    avg_energy = round(sum(energies) / len(energies), 1)
    avg_sleep = round(sum(sleeps) / len(sleeps), 1)
    avg_wellness = round(sum(scores) / len(scores), 1)

    mid = len(scores) // 2
    first_avg = sum(scores[:mid]) / len(scores[:mid]) if mid > 0 else 0
    second_avg = sum(scores[mid:]) / len(scores[mid:]) if len(scores) > mid else 0

    if second_avg > first_avg * 1.1:
        trend, trend_msg = "improving", "状态向好，保持当前的生活方式。"
    elif second_avg < first_avg * 0.9:
        trend, trend_msg = "declining", "状态有所下降，建议增加休息和调理。"
    else:
        trend, trend_msg = "stable", "状态稳定，继续维持。"

    if avg_mood < 2.5:
        tcm_pattern = "肝气郁结，心神不宁"
        recommendations = ["疏肝理气", "增加户外活动", "按摩太冲（LV3）和合谷（LI4）穴位"]
    elif avg_energy < 2.5:
        tcm_pattern = "气虚明显，需要进补"
        recommendations = ["食用山药、红枣、黄芪等补气食物", "增加足三里穴位按摩", "早睡以补气"]
    elif avg_sleep < 2.5:
        tcm_pattern = "心神不安，阴血不足"
        recommendations = ["优化睡眠环境（黑暗、凉爽）", "睡前避免蓝光", "按摩神门（HT7）和涌泉（KD1）穴位"]
    else:
        tcm_pattern = "气血调和，状态良好"
        recommendations = ["继续维持规律作息", "适度运动和日光照射", "均衡饮食"]

    return {
        "success": True, "data": {
            "period": "last_7_days", "entries_count": len(rows),
            "avg_mood": avg_mood, "avg_energy": avg_energy,
            "avg_sleep_quality": avg_sleep, "avg_wellness_score": avg_wellness,
            "trend": trend, "trend_message": trend_msg,
            "tcm_pattern": tcm_pattern, "recommendations": recommendations,
        },
    }


@router.delete("/entry/{entry_id}", summary="删除日记条目")
async def delete_journal_entry(entry_id: str, db: Session = Depends(get_db)):
    """删除指定的日记条目。"""
    row = db.query(JournalEntryModel).filter(JournalEntryModel.id == entry_id).first()
    if not row:
        raise HTTPException(status_code=404, detail=f"Entry '{entry_id}' not found")
    db.delete(row)
    db.commit()
    return {"success": True, "data": {"deleted_entry_id": entry_id, "message": "条目已删除"}}
