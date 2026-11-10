"""
顺时 — 成就与激励系统 API (PostgreSQL backed)
提供徽章库、积分等级、排行榜、每日打卡
增加用户粘性和参与度
"""

from zoneinfo import ZoneInfo

from fastapi import APIRouter, HTTPException, Query, Depends, Request
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.database import get_db
from app.locale_context import RequestLocale, request_locale
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
    "checkin_7": {"id": "checkin_7", "name": "春芽勋章", "description": "已记下7天", "category": "checkin", "icon_hint": "🌱", "points": 50, "rarity": "common"},
    "checkin_30": {"id": "checkin_30", "name": "夏荷勋章", "description": "已记下30天", "category": "checkin", "icon_hint": "🌸", "points": 200, "rarity": "rare"},
    "checkin_100": {"id": "checkin_100", "name": "秋月勋章", "description": "已记下100天", "category": "checkin", "icon_hint": "🍂", "points": 500, "rarity": "epic"},
    "checkin_365": {"id": "checkin_365", "name": "冬雪勋章", "description": "已记下365天", "category": "checkin", "icon_hint": "❄️", "points": 1000, "rarity": "legendary"},
    "solar_term_first": {"id": "solar_term_first", "name": "节气探索者", "description": "探索第一个节气", "category": "solar_term", "icon_hint": "🌍", "points": 30, "rarity": "common"},
    "solar_term_all": {"id": "solar_term_all", "name": "四季旅人", "description": "探索全部24个节气", "category": "solar_term", "icon_hint": "🌏", "points": 500, "rarity": "epic"},
    "constitution_test": {"id": "constitution_test", "name": "知己知彼", "description": "完成体质测试", "category": "constitution", "icon_hint": "🔍", "points": 50, "rarity": "common"},
    "food_therapy_first": {"id": "food_therapy_first", "name": "食疗初心者", "description": "尝试第一个食疗方", "category": "food_therapy", "icon_hint": "🍲", "points": 40, "rarity": "common"},
    "exercise_first": {"id": "exercise_first", "name": "运动开启者", "description": "完成第一个运动", "category": "exercise", "icon_hint": "🏃", "points": 30, "rarity": "common"},
    "meditation_first": {"id": "meditation_first", "name": "冥想初心者", "description": "第一次冥想", "category": "meditation", "icon_hint": "🧘‍♀️", "points": 25, "rarity": "common"},
    "meditation_sage": {"id": "meditation_sage", "name": "冥想大师", "description": "完成100次冥想", "category": "meditation", "icon_hint": "🌟", "points": 400, "rarity": "legendary"},
    "checkin_14": {"id": "checkin_14", "name": "两周相伴", "description": "已记下14天", "category": "checkin", "icon_hint": "🌿", "points": 90, "rarity": "common"},
    "checkin_60": {"id": "checkin_60", "name": "习惯守护者", "description": "已记下60天", "category": "checkin", "icon_hint": "🪴", "points": 320, "rarity": "rare"},
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


BADGES_EN = {
    "checkin_7": ("Spring Sprout", "Check in 7 days in a row"),
    "checkin_30": ("Summer Lotus", "Check in 30 days in a row"),
    "checkin_100": ("Autumn Moon", "Check in 100 days in a row"),
    "checkin_365": ("Winter Snow", "Check in 365 days in a row"),
    "solar_term_first": ("Season Explorer", "Explore your first solar term"),
    "solar_term_all": ("Four-Season Traveler", "Explore all 24 solar terms"),
    "constitution_test": ("Know Yourself", "Complete the body-type quiz"),
    "food_therapy_first": ("Food Curious", "Try your first food-therapy recipe"),
    "exercise_first": ("First Steps", "Finish your first movement session"),
    "meditation_first": ("First Stillness", "Meditate for the first time"),
    "meditation_sage": ("Meditation Master", "Complete 100 meditations"),
    "checkin_14": ("Two Weeks Together", "Check in 14 days in a row"),
    "checkin_60": ("Habit Keeper", "Check in 60 days in a row"),
    "solar_term_6": ("Season Watcher", "Browse 6 solar-term themes"),
    "solar_term_12": ("Half-Year Traveler", "Browse 12 solar-term themes"),
    "constitution_review": ("Self Review", "Review your quiz result and its limits"),
    "food_therapy_3": ("Recipe Collector", "Save 3 traditional recipe references"),
    "exercise_7": ("Active Week", "Log 7 self-directed activities"),
    "exercise_30": ("Activity Milestone", "Log 30 self-directed activities"),
    "meditation_7": ("Seven Quiet Moments", "Log 7 meditations"),
}
LEVEL_BENEFITS_EN = {
    "1": ["Basic check-ins and your personal achievement record"],
    "2": ["More options for personalizing content order"],
    "3": ["Monthly progress review"],
    "4": ["Yearly progress review"],
    "5": ["Full achievement history"],
}
LEVEL_NAMES_EN = {1: "Beginner", 2: "Wellness Starter", 3: "Season Learner", 4: "Wellness Enthusiast", 5: "Wellness Master"}
RARITY_EN = {"common": "Common", "rare": "Rare", "epic": "Epic", "legendary": "Legendary"}

# 能由服务端数据直接算出来的徽章：(指标, 门槛)。其余徽章只有管理员 / 事件接口颁发后才点亮，不假装有进度。
AUTO_BADGE_RULES = {
    "checkin_7": ("best_streak", 7), "checkin_14": ("best_streak", 14), "checkin_30": ("best_streak", 30),
    "checkin_60": ("best_streak", 60), "checkin_100": ("best_streak", 100), "checkin_365": ("best_streak", 365),
    "exercise_first": ("exercise_count", 1), "exercise_7": ("exercise_count", 7), "exercise_30": ("exercise_count", 30),
    "constitution_test": ("constitution_count", 1),
}
TODAY_HABITS = ("checkin", "mood", "sleep")


def progress_today() -> date:
    """「今天」：与日记接口一致，按 Asia/Shanghai 的日历日。"""
    return datetime.now(ZoneInfo("Asia/Shanghai")).date()


def localize_badge(badge: dict, is_global: bool) -> dict:
    out = dict(badge)
    if is_global:
        name, desc = BADGES_EN.get(badge["id"], (badge["id"].replace("_", " ").title(), ""))
        out["name"], out["description"], out["unlock_condition"] = name, desc, desc
        out["rarity_label"] = RARITY_EN.get(badge.get("rarity", ""), "")
    return out


def level_name(level: int, is_global: bool, zh: str) -> str:
    return LEVEL_NAMES_EN.get(level, zh) if is_global else zh


def _streak_ending_today(dates: set, today: date) -> int:
    """从今天（今天还没记就从昨天）往前数连续有记录的天数。"""
    cur = today if today in dates else today - timedelta(days=1)
    n = 0
    while cur in dates:
        n += 1
        cur -= timedelta(days=1)
    return n


def _best_streak(dates: set) -> int:
    best = run = 0
    prev = None
    for d in sorted(dates):
        run = run + 1 if prev is not None and (d - prev).days == 1 else 1
        best = max(best, run)
        prev = d
    return best


def _legacy_dates(user_id: str, table: str) -> set:
    """老的 sqlite 记录库（睡眠 / 情绪 / 养生状态）里这个用户有记录的日期。库不可用时当作没有。"""
    try:
        from app.database.db import get_db as legacy_db

        rows = legacy_db().execute(f"SELECT date FROM {table} WHERE user_id = ?", (user_id,)).fetchall()
        out = set()
        for r in rows:
            try:
                out.add(date.fromisoformat(str(r["date"])[:10]))
            except (ValueError, TypeError):
                continue
        return out
    except Exception:
        return set()


def activity_days(db: Session, user_id: str) -> dict:
    """这个用户每一类「真实写入」落在哪些日子。打卡、日记、睡眠、心情都算数，来源就是各自的写入接口。"""
    from app.models.journal import JournalEntry

    checkin = {r[0] for r in db.query(CheckinRecord.checkin_date).filter(CheckinRecord.user_id == user_id).all()}
    journal = set()
    for (d,) in db.query(JournalEntry.date).filter(JournalEntry.user_id == user_id).all():
        try:
            journal.add(d if isinstance(d, date) else date.fromisoformat(str(d)[:10]))
        except (ValueError, TypeError):
            continue
    return {
        "checkin": checkin,
        "journal": journal,
        "sleep": journal | _legacy_dates(user_id, "sleep_records"),   # 日记里的睡眠评分也是睡眠记录
        "mood": journal | _legacy_dates(user_id, "emotion_records"),  # 日记里的心情评分也是心情记录
        "care": _legacy_dates(user_id, "care_status"),
    }


def _count(db: Session, model, *filters) -> int:
    try:
        return db.query(func.count()).select_from(model).filter(*filters).scalar() or 0
    except Exception:
        db.rollback()
        return 0


def counters(db: Session, user_id: str) -> dict:
    from app.models.chat import ChatMessage
    from app.models.constitution import ConstitutionResult
    from app.models.exercise import ExerciseLog
    from app.models.favorite import Favorite
    from app.models.journal import JournalEntry

    return {
        "journal_count": _count(db, JournalEntry, JournalEntry.user_id == user_id),
        "favorite_count": _count(db, Favorite, Favorite.user_id == user_id),
        "chat_count": _count(db, ChatMessage, ChatMessage.user_id == user_id, ChatMessage.role == "user"),
        "exercise_count": _count(db, ExerciseLog, ExerciseLog.user_id == user_id, ExerciseLog.completed.is_(True)),
        "constitution_count": _count(db, ConstitutionResult, ConstitutionResult.user_id == user_id),
    }


def sync_auto_badges(db: Session, user_id: str, metrics: dict) -> list:
    """按真实数据点亮能算出来的徽章（幂等：每个徽章只发一次积分）。返回这次新点亮的徽章 id。"""
    have = {b[0] for b in db.query(UserBadge.badge_id).filter(UserBadge.user_id == user_id).all()}
    new = []
    for bid, (metric, need) in AUTO_BADGE_RULES.items():
        if bid in have or (metrics.get(metric) or 0) < need:
            continue
        db.add(UserBadge(user_id=user_id, badge_id=bid, reason=f"auto:{metric}>={need}"))
        pts = _get_or_create_points(db, user_id)
        pts.total_points += BADGES[bid]["points"]
        lv = _get_level_for_points(pts.total_points)
        pts.level, pts.title = lv["level"], lv["name"]
        new.append(bid)
    if new:
        db.commit()
    return new


def award_checkin(db: Session, user_id: str) -> dict:
    """今天第一次打卡：记一条、发积分、算连续天数。重复调用不重复发。日记保存也走这里（日记就是每日打卡）。"""
    today = progress_today()
    existing = db.query(CheckinRecord).filter(CheckinRecord.user_id == user_id, CheckinRecord.checkin_date == today).first()
    if existing:
        return {"checked_in": False, "current_streak": existing.consecutive_days, "today_date": today.isoformat(), "points_earned": 0}
    days = activity_days(db, user_id)
    streak = _streak_ending_today(days["checkin"] | days["journal"] | {today}, today)
    base_points = 10
    streak_bonus = (streak - 1) // 7 * 5
    earned = base_points + streak_bonus
    db.add(CheckinRecord(user_id=user_id, checkin_date=today, consecutive_days=streak, points_earned=earned))
    pts = _get_or_create_points(db, user_id)
    pts.total_points += earned
    lv = _get_level_for_points(pts.total_points)
    pts.level, pts.title = lv["level"], lv["name"]
    db.commit()
    sync_auto_badges(db, user_id, {**counters(db, user_id), "best_streak": max(streak, _best_streak(days["checkin"] | days["journal"] | {today}))})
    db.refresh(pts)
    return {
        "checked_in": True, "points_earned": earned, "base_points": base_points, "streak_bonus": streak_bonus,
        "current_streak": streak, "user_total_points": pts.total_points, "user_level": pts.level,
        "today_date": today.isoformat(),
    }


def progress_snapshot(db: Session, user_id: str, is_global: bool = False) -> dict:
    """个人进度：积分、等级、打卡天数、连续天数、今日习惯、各类真实计数、徽章（带进度）。所有数字来自写入接口留下的记录。"""
    today = progress_today()
    days = activity_days(db, user_id)
    checkin_days = days["checkin"] | days["journal"]
    metrics = {**counters(db, user_id), "best_streak": _best_streak(checkin_days)}
    sync_auto_badges(db, user_id, metrics)
    pts = _get_or_create_points(db, user_id)
    lv = _get_level_for_points(pts.total_points)
    nxt = next((x for x in LEVEL_SYSTEM["levels"] if x["level"] == lv["level"] + 1), None)
    have = {b[0] for b in db.query(UserBadge.badge_id).filter(UserBadge.user_id == user_id).all()}
    done = {
        "checkin": today in checkin_days,
        "mood": today in days["mood"],
        "sleep": today in days["sleep"],
    }
    badges = []
    for b in BADGES.values():
        item = localize_badge(b, is_global)
        item["unlocked"] = b["id"] in have
        rule = AUTO_BADGE_RULES.get(b["id"])
        if rule:
            item["progress"] = min(metrics.get(rule[0], 0), rule[1])
            item["target"] = rule[1]
        badges.append(item)
    week_start = today - timedelta(days=6)
    return {
        "user_id": user_id,
        "points": pts.total_points,
        "total_points": pts.total_points,
        "level": lv["level"],
        "level_name": level_name(lv["level"], is_global, lv["name"]),
        "next_level": nxt["level"] if nxt else None,
        "next_level_name": level_name(nxt["level"], is_global, nxt["name"]) if nxt else None,
        "next_level_points": nxt["min_points"] if nxt else None,
        "streak_days": _streak_ending_today(checkin_days, today),
        "best_streak": metrics["best_streak"],
        "total_checkin_days": len(checkin_days),
        "week_checkin_days": len([d for d in checkin_days if week_start <= d <= today]),
        "today": {"date": today.isoformat(), "completed": sum(done.values()), "total": len(TODAY_HABITS), "done": done},
        "badge_count": len(have & set(BADGES)),
        "badge_total": len(BADGES),
        "badges": badges,
        **{k: metrics[k] for k in ("journal_count", "favorite_count", "chat_count", "exercise_count", "constitution_count")},
    }


# ─────────────────────────────────────────────────────────────────────────────
# 端点 (PostgreSQL backed)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/badges", summary="所有徽章列表")
async def get_badges(
    category: Optional[str] = Query(None, description="徽章分类"),
    rarity: Optional[str] = Query(None, description="稀有度"),
    loc: RequestLocale = Depends(request_locale),
):
    badges_list = [localize_badge(b, loc.is_global) for b in BADGES.values()]
    if category:
        badges_list = [b for b in badges_list if b["category"] == category]
    if rarity:
        badges_list = [b for b in badges_list if b["rarity"] == rarity]
    return {"success": True, "data": {"badges": badges_list, "total": len(badges_list)}}


@router.get("/badges/{badge_id}", summary="徽章详情")
async def get_badge_detail(badge_id: str, loc: RequestLocale = Depends(request_locale)):
    if badge_id not in BADGES:
        raise HTTPException(status_code=404, detail=f"Badge '{badge_id}' not found.")
    return {"success": True, "data": localize_badge(BADGES[badge_id], loc.is_global)}


@router.get("/user/{user_id}", summary="用户成就总览")
async def get_user_achievements(user_id: str, db: Session = Depends(get_db), loc: RequestLocale = Depends(request_locale)):
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
            "level_name": level_name(lv["level"], loc.is_global, lv["name"]),
            "badges_unlocked": [b.badge_id for b in badges],
            "badge_count": len(badges),
            "streak_days": last_checkin.consecutive_days if last_checkin else 0,
            "total_checkins": total_checkins,
        },
    }


@router.post("/award", summary="颁发徽章")
async def award_badge(request: AwardBadgeRequest, db: Session = Depends(get_db), loc: RequestLocale = Depends(request_locale)):
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
            "awarded": True, "badge": localize_badge(badge, loc.is_global), "is_new_unlock": is_new,
            "points_earned": badge["points"] if is_new else 0,
            "user_total_points": pts.total_points, "user_level": pts.level,
            "message": (
                (f"Congratulations! New badge unlocked: {BADGES_EN[badge['id']][0]}, +{badge['points']} points!" if is_new else f"You already have this badge: {BADGES_EN[badge['id']][0]}")
                if loc.is_global else
                (f"恭喜！解锁新徽章：{badge['name']} 🎉，获得 {badge['points']} 积分！" if is_new else f"你已经拥有此徽章：{badge['name']}")
            ),
        },
    }


@router.post("/checkin", summary="每日打卡积分")
async def daily_checkin(request: CheckInRequest, db: Session = Depends(get_db), loc: RequestLocale = Depends(request_locale)):
    r = award_checkin(db, request.user_id)
    streak = r["current_streak"]
    if not r["checked_in"]:
        return {"success": True, "data": {
            "checked_in": False, "current_streak": streak, "today_date": r["today_date"],
            "message": "Already checked in today. See you tomorrow!" if loc.is_global else "今天已打卡，明天再来吧！",
        }}
    milestone = streak in (7, 30, 100, 365)
    if loc.is_global:
        milestone_message = f"Amazing! {streak} days in a row!" if milestone else ""
        message = f"Checked in! +{r['points_earned']} points, {streak}-day streak."
    else:
        milestone_message = f"太棒了！你已记下 {streak} 天！" if milestone else ""
        message = f"打卡成功！获得 {r['points_earned']} 积分，连续 {streak} 天。"
    return {"success": True, "data": {**r, "milestone_message": milestone_message, "message": message}}


@router.get("/me", summary="我的积分、等级、打卡与徽章（取自令牌里的本人）")
async def my_progress(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    db: Session = Depends(get_db),
    loc: RequestLocale = Depends(request_locale),
):
    return {"success": True, "data": progress_snapshot(db, user_id, loc.is_global)}


@router.get("/stats", summary="积分与打卡统计（/me 的别名）")
async def my_stats(user_id: str = Query(...), db: Session = Depends(get_db), loc: RequestLocale = Depends(request_locale)):
    return {"success": True, "data": progress_snapshot(db, user_id, loc.is_global)}


@router.get("/points", summary="我的积分与等级")
async def my_points(user_id: str = Query(...), db: Session = Depends(get_db), loc: RequestLocale = Depends(request_locale)):
    snap = progress_snapshot(db, user_id, loc.is_global)
    keys = ("user_id", "points", "level", "level_name", "next_level", "next_level_name", "next_level_points")
    return {"success": True, "data": {k: snap[k] for k in keys}}


@router.get("/summary", summary="打卡与今日习惯概览")
async def my_summary(user_id: str = Query(...), db: Session = Depends(get_db), loc: RequestLocale = Depends(request_locale)):
    snap = progress_snapshot(db, user_id, loc.is_global)
    keys = ("user_id", "points", "level", "level_name", "streak_days", "best_streak", "total_checkin_days", "week_checkin_days", "today", "badge_count", "badge_total")
    return {"success": True, "data": {k: snap[k] for k in keys}}


@router.get("/achievements", summary="我的徽章（带解锁状态与进度）")
async def my_achievements(user_id: str = Query(...), db: Session = Depends(get_db), loc: RequestLocale = Depends(request_locale)):
    snap = progress_snapshot(db, user_id, loc.is_global)
    return {"success": True, "data": {"badges": snap["badges"], "badge_count": snap["badge_count"], "total": snap["badge_total"]}}


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
async def get_levels(loc: RequestLocale = Depends(request_locale)):
    if loc.is_global:
        return {
            "success": True,
            "data": {
                "levels": [{**lv, "name": LEVEL_NAMES_EN[lv["level"]]} for lv in LEVEL_SYSTEM["levels"]],
                "description": "Earn points by checking in and unlocking badges; reaching a threshold moves you up a level.",
                "level_benefits": LEVEL_BENEFITS_EN,
            },
        }
    return {
        "success": True,
        "data": {
            "levels": LEVEL_SYSTEM["levels"],
            "description": "通过完成任务、打卡、解锁徽章获得积分，积分达到一定阈值可升级。",
            "level_benefits": LEVEL_BENEFITS,
        },
    }
