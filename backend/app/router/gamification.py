"""
顺时 — 成就与激励系统 API (PostgreSQL backed)
提供徽章库、积分等级、排行榜、每日打卡
增加用户粘性和参与度
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.database import get_db
from app.models.gamification import UserBadge, UserPoints, CheckinRecord

router = APIRouter(prefix="/api/v1/gamification", tags=["gamification"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求模型
# ─────────────────────────────────────────────────────────────────────────────

class AwardBadgeRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    badge_id: str = Field(..., description="徽章ID")
    reason: str = Field(..., max_length=500, description="颁发原因")


class CheckInRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")


# ─────────────────────────────────────────────────────────────────────────────
# 徽章库（静态定义，不变）
# ─────────────────────────────────────────────────────────────────────────────

BADGES = {
    "checkin_7": {"id": "checkin_7", "name": "春芽勋章", "description": "连续打卡7天", "category": "checkin", "icon_hint": "🌱", "points": 50, "rarity": "common"},
    "checkin_30": {"id": "checkin_30", "name": "夏荷勋章", "description": "连续打卡30天", "category": "checkin", "icon_hint": "🌸", "points": 200, "rarity": "rare"},
    "checkin_100": {"id": "checkin_100", "name": "秋月勋章", "description": "连续打卡100天", "category": "checkin", "icon_hint": "🍂", "points": 500, "rarity": "epic"},
    "checkin_365": {"id": "checkin_365", "name": "冬雪勋章", "description": "连续打卡365天", "category": "checkin", "icon_hint": "❄️", "points": 1000, "rarity": "legendary"},
    "solar_term_first": {"id": "solar_term_first", "name": "节气探索者", "description": "探索第一个节气", "category": "solar_term", "icon_hint": "🌍", "points": 30, "rarity": "common"},
    "solar_term_all": {"id": "solar_term_all", "name": "四季旅人", "description": "探索全部24个节气", "category": "solar_term", "icon_hint": "🌏", "points": 500, "rarity": "epic"},
    "constitution_test": {"id": "constitution_test", "name": "知己知彼", "description": "完成体质测试", "category": "constitution", "icon_hint": "🔍", "points": 50, "rarity": "common"},
    "food_therapy_first": {"id": "food_therapy_first", "name": "食疗初心者", "description": "尝试第一个食疗方", "category": "food_therapy", "icon_hint": "🍲", "points": 40, "rarity": "common"},
    "exercise_first": {"id": "exercise_first", "name": "运动开启者", "description": "完成第一个运动", "category": "exercise", "icon_hint": "🏃", "points": 30, "rarity": "common"},
    "meditation_first": {"id": "meditation_first", "name": "冥想初心者", "description": "第一次冥想", "category": "meditation", "icon_hint": "🧘‍♀️", "points": 25, "rarity": "common"},
    "meditation_sage": {"id": "meditation_sage", "name": "冥想大师", "description": "完成100次冥想", "category": "meditation", "icon_hint": "🌟", "points": 400, "rarity": "legendary"},
    "checkin_14": {"id": "checkin_14", "name": "两周相伴", "description": "连续打卡14天", "category": "checkin", "icon_hint": "🌿", "points": 90, "rarity": "common"},
    "checkin_60": {"id": "checkin_60", "name": "习惯守护者", "description": "连续打卡60天", "category": "checkin", "icon_hint": "🪴", "points": 320, "rarity": "rare"},
    "solar_term_6": {"id": "solar_term_6", "name": "一季观察者", "description": "完成6个节气主题浏览", "category": "solar_term", "icon_hint": "🌤️", "points": 90, "rarity": "common"},
    "solar_term_12": {"id": "solar_term_12", "name": "半岁旅人", "description": "完成12个节气主题浏览", "category": "solar_term", "icon_hint": "🌓", "points": 180, "rarity": "rare"},
    "constitution_review": {"id": "constitution_review", "name": "自我复核", "description": "查看并确认一次体质问卷结果及其限制说明", "category": "constitution", "icon_hint": "📝", "points": 35, "rarity": "common"},
    "food_therapy_3": {"id": "food_therapy_3", "name": "食谱收藏家", "description": "收藏3个传统食谱参考", "category": "food_therapy", "icon_hint": "🥣", "points": 60, "rarity": "common"},
    "exercise_7": {"id": "exercise_7", "name": "活动一周", "description": "记录7次自主活动", "category": "exercise", "icon_hint": "👟", "points": 80, "rarity": "common"},
    "exercise_30": {"id": "exercise_30", "name": "活动里程碑", "description": "记录30次自主活动", "category": "exercise", "icon_hint": "🏅", "points": 220, "rarity": "rare"},
    "meditation_7": {"id": "meditation_7", "name": "七次静心", "description": "完成7次冥想记录", "category": "meditation", "icon_hint": "🕯️", "points": 70, "rarity": "common"},
}

for _badge in BADGES.values():
    _badge.setdefault("unlock_condition", _badge["description"])

LEVEL_SYSTEM = {
    "levels": [
        {"level": 1, "name": "初学者", "min_points": 0, "max_points": 100},
        {"level": 2, "name": "养生入门", "min_points": 101, "max_points": 300},
        {"level": 3, "name": "顺时学者", "min_points": 301, "max_points": 600},
        {"level": 4, "name": "健康达人", "min_points": 601, "max_points": 1000},
        {"level": 5, "name": "养生大师", "min_points": 1001, "max_points": 999999},
    ]
}

# 等级权益只描述产品内功能，不承诺健康效果，也不把基本健康内容设为付费门槛。
LEVEL_BENEFITS = {
    "1": ["基础打卡与个人成就记录"],
    "2": ["解锁更多个性化内容排序选项"],
    "3": ["解锁月度成长回顾"],
    "4": ["解锁年度成长回顾"],
    "5": ["解锁完整历史成就档案"],
}


def _get_level_for_points(points: int) -> dict:
    for lv in LEVEL_SYSTEM["levels"]:
        if lv["min_points"] <= points <= lv["max_points"]:
            return lv
    return LEVEL_SYSTEM["levels"][-1]


def _get_or_create_points(db: Session, user_id: str) -> UserPoints:
    row = db.query(UserPoints).filter(UserPoints.user_id == user_id).first()
    if not row:
        row = UserPoints(user_id=user_id, total_points=0, level=1, title="初学养生")
        db.add(row)
        db.commit()
        db.refresh(row)
    return row


# ─────────────────────────────────────────────────────────────────────────────
# 端点 (PostgreSQL backed)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/badges", summary="所有徽章列表")
async def get_badges(
    category: Optional[str] = Query(None, description="徽章分类"),
    rarity: Optional[str] = Query(None, description="稀有度"),
):
    badges_list = list(BADGES.values())
    if category:
        badges_list = [b for b in badges_list if b["category"] == category]
    if rarity:
        badges_list = [b for b in badges_list if b["rarity"] == rarity]
    return {"success": True, "data": {"badges": badges_list, "total": len(badges_list)}}


@router.get("/badges/{badge_id}", summary="徽章详情")
async def get_badge_detail(badge_id: str):
    if badge_id not in BADGES:
        raise HTTPException(status_code=404, detail=f"Badge '{badge_id}' not found.")
    return {"success": True, "data": BADGES[badge_id]}


@router.get("/user/{user_id}", summary="用户成就总览")
async def get_user_achievements(user_id: str, db: Session = Depends(get_db)):
    pts = _get_or_create_points(db, user_id)
    badges = db.query(UserBadge).filter(UserBadge.user_id == user_id).all()
    last_checkin = db.query(CheckinRecord).filter(CheckinRecord.user_id == user_id).order_by(CheckinRecord.checkin_date.desc()).first()
    total_checkins = db.query(CheckinRecord).filter(CheckinRecord.user_id == user_id).count()
    lv = _get_level_for_points(pts.total_points)

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "points": pts.total_points,
            "level": lv["level"],
            "level_name": lv["name"],
            "badges_unlocked": [b.badge_id for b in badges],
            "badge_count": len(badges),
            "streak_days": last_checkin.consecutive_days if last_checkin else 0,
            "total_checkins": total_checkins,
        },
    }


@router.post("/award", summary="颁发徽章")
async def award_badge(request: AwardBadgeRequest, db: Session = Depends(get_db)):
    if request.badge_id not in BADGES:
        raise HTTPException(status_code=404, detail=f"Badge '{request.badge_id}' not found.")
    badge = BADGES[request.badge_id]

    existing = db.query(UserBadge).filter(UserBadge.user_id == request.user_id, UserBadge.badge_id == request.badge_id).first()
    is_new = existing is None

    if is_new:
        db.add(UserBadge(user_id=request.user_id, badge_id=request.badge_id, reason=request.reason))
        pts = _get_or_create_points(db, request.user_id)
        pts.total_points += badge["points"]
        lv = _get_level_for_points(pts.total_points)
        pts.level = lv["level"]
        pts.title = lv["name"]
        db.commit()

    pts = _get_or_create_points(db, request.user_id)
    return {
        "success": True,
        "data": {
            "awarded": True, "badge": badge, "is_new_unlock": is_new,
            "points_earned": badge["points"] if is_new else 0,
            "user_total_points": pts.total_points, "user_level": pts.level,
            "message": f"恭喜！解锁新徽章：{badge['name']} 🎉，获得 {badge['points']} 积分！" if is_new else f"你已经拥有此徽章：{badge['name']}",
        },
    }


@router.post("/checkin", summary="每日打卡积分")
async def daily_checkin(request: CheckInRequest, db: Session = Depends(get_db)):
    today = date.today()

    existing = db.query(CheckinRecord).filter(CheckinRecord.user_id == request.user_id, CheckinRecord.checkin_date == today).first()
    if existing:
        return {"success": True, "data": {"checked_in": False, "message": "今天已打卡，明天再来吧！", "current_streak": existing.consecutive_days, "today_date": today.isoformat()}}

    # 计算连续天数
    yesterday = today - timedelta(days=1)
    last = db.query(CheckinRecord).filter(CheckinRecord.user_id == request.user_id, CheckinRecord.checkin_date == yesterday).first()
    streak = (last.consecutive_days + 1) if last else 1

    base_points = 10
    streak_bonus = (streak - 1) // 7 * 5
    total_points = base_points + streak_bonus

    db.add(CheckinRecord(user_id=request.user_id, checkin_date=today, consecutive_days=streak, points_earned=total_points))

    pts = _get_or_create_points(db, request.user_id)
    pts.total_points += total_points
    lv = _get_level_for_points(pts.total_points)
    pts.level = lv["level"]
    pts.title = lv["name"]
    db.commit()

    milestones = [7, 30, 100, 365]
    milestone_message = f"太棒了！你已连续打卡 {streak} 天！" if streak in milestones else ""

    return {
        "success": True,
        "data": {
            "checked_in": True, "points_earned": total_points,
            "base_points": base_points, "streak_bonus": streak_bonus,
            "current_streak": streak, "user_total_points": pts.total_points,
            "user_level": pts.level, "today_date": today.isoformat(),
            "milestone_message": milestone_message,
            "message": f"打卡成功！获得 {total_points} 积分，连续 {streak} 天。",
        },
    }


@router.get("/leaderboard", summary="积分排行榜")
async def get_leaderboard(limit: int = Query(10, ge=1, le=100), db: Session = Depends(get_db)):
    rows = db.query(UserPoints).order_by(UserPoints.total_points.desc()).limit(limit).all()
    total_users = db.query(UserPoints).count()
    badge_counts = dict(
        db.query(UserBadge.user_id, func.count(UserBadge.id))
        .filter(UserBadge.user_id.in_([row.user_id for row in rows]))
        .group_by(UserBadge.user_id)
        .all()
    ) if rows else {}
    leaderboard = [{
        "rank": idx + 1,
        "user_id": r.user_id[:4] + "**" if len(r.user_id) > 4 else "**",
        "points": r.total_points,
        "level": r.level,
        "badges_count": badge_counts.get(r.user_id, 0),
    } for idx, r in enumerate(rows)]
    return {"success": True, "data": {"leaderboard": leaderboard, "total_users": total_users, "limit": limit}}


@router.get("/levels", summary="积分等级系统说明")
async def get_levels():
    return {
        "success": True,
        "data": {
            "levels": LEVEL_SYSTEM["levels"],
            "description": "通过完成任务、打卡、解锁徽章获得积分，积分达到一定阈值可升级。",
            "level_benefits": LEVEL_BENEFITS,
        },
    }
