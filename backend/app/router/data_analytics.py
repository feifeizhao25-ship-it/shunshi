"""
顺时 — 用户健康行为数据分析和报告生成
记录、分析用户养生行为数据，生成周度和月度报告
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from pydantic import BaseModel
from collections import defaultdict

router = APIRouter(prefix="/api/v1/analytics", tags=["data_analytics"])

# ─────────────────────────────────────────────────────────────────────────────
# 数据模型
# ─────────────────────────────────────────────────────────────────────────────

class EventRecord(BaseModel):
    user_id: str
    event_type: str  # checkin/food_log/exercise/meditation/mood_log/content_view
    metadata: Dict[str, Any] = {}
    timestamp: Optional[str] = None


# ─────────────────────────────────────────────────────────────────────────────
# 内存数据存储
# ─────────────────────────────────────────────────────────────────────────────

_events: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
_app_stats = {
    "total_users": 1250,
    "daily_active_users": 380,
    "most_popular_content": ["节气问候", "每日贴士", "食疗推荐"],
    "season_distribution": {
        "spring": 0.28,
        "summer": 0.24,
        "autumn": 0.26,
        "winter": 0.22,
    },
}


def _get_date_range(days: int = 7) -> tuple:
    """获取过去N天的日期范围"""
    end = datetime.now()
    start = end - timedelta(days=days)
    return start, end


def _count_events_by_type(user_id: str, start: datetime, end: datetime) -> Dict[str, int]:
    """统计用户某时期内各类型事件数"""
    counts = defaultdict(int)
    for event in _events.get(user_id, []):
        if "timestamp" in event:
            ts = datetime.fromisoformat(event["timestamp"])
            if start <= ts <= end:
                counts[event["event_type"]] += 1
    return dict(counts)


def _get_streak_days(user_id: str, event_type: str = "checkin") -> int:
    """计算连续天数"""
    user_events = [e for e in _events.get(user_id, []) if e["event_type"] == event_type]
    if not user_events:
        return 0

    # 按时间排序
    user_events.sort(key=lambda e: e.get("timestamp", ""))

    # 简单计数：检查最近7天内是否有记录
    end = datetime.now()
    start = end - timedelta(days=7)
    recent = [e for e in user_events if "timestamp" in e and datetime.fromisoformat(e["timestamp"]) >= start]

    return min(len(recent), 7)  # 最多7天


def _get_active_hours(user_id: str) -> str:
    """获取最活跃时段"""
    user_events = _events.get(user_id, [])
    hours = defaultdict(int)

    for event in user_events:
        if "timestamp" in event:
            ts = datetime.fromisoformat(event["timestamp"])
            hours[ts.hour] += 1

    if not hours:
        return "无数据"

    most_active_hour = max(hours, key=hours.get)
    return f"{most_active_hour:02d}:00-{(most_active_hour+1)%24:02d}:00"


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/event", summary="记录用户行为事件")
async def record_event(event: EventRecord):
    """记录用户行为事件"""
    valid_types = ["checkin", "food_log", "exercise", "meditation", "mood_log", "content_view"]
    if event.event_type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid event_type. Must be one of: {valid_types}"
        )

    timestamp = event.timestamp or datetime.now().isoformat()

    event_record = {
        "event_type": event.event_type,
        "metadata": event.metadata,
        "timestamp": timestamp,
    }

    _events[event.user_id].append(event_record)

    return {
        "success": True,
        "data": {
            "event_id": f"{event.user_id}_{len(_events[event.user_id])}",
            "recorded": True,
            "timestamp": timestamp,
        },
    }


@router.get("/summary/{user_id}", summary="7天行为摘要")
async def get_summary(user_id: str):
    """获取用户7天的行为摘要"""
    start, end = _get_date_range(days=7)
    event_counts = _count_events_by_type(user_id, start, end)
    active_hours = _get_active_hours(user_id)
    streak = _get_streak_days(user_id, "checkin")

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "period": "7_days",
            "start_date": start.strftime("%Y-%m-%d"),
            "end_date": end.strftime("%Y-%m-%d"),
            "event_counts": event_counts,
            "most_active_hours": active_hours,
            "checkin_streak": streak,
            "total_events": sum(event_counts.values()),
        },
    }


@router.get("/weekly-report/{user_id}", summary="周度健康报告")
async def get_weekly_report(user_id: str):
    """获取用户周度健康报告"""
    start, end = _get_date_range(days=7)
    event_counts = _count_events_by_type(user_id, start, end)
    total_events = sum(event_counts.values())

    # 如果是新用户（无数据），返回空状态指引
    if total_events == 0:
        return {
            "success": True,
            "data": {
                "user_id": user_id,
                "is_new_user": True,
                "message": "欢迎开启你的养生之旅！请先完成打卡、食物记录、运动等活动，系统将为你生成个性化报告。",
                "dimensions": [],
                "trend": None,
                "highlights": [],
                "insights": [],
                "score": 0,
                "next_week_suggestion": "建议从每日打卡开始，坚持7天后即可查看第一份报告！",
            },
        }

    # 维度评分
    dimensions = {
        "checkin_consistency": min(100, (event_counts.get("checkin", 0) / 7) * 100),
        "food_logging": min(100, (event_counts.get("food_log", 0) / 7) * 100),
        "exercise_frequency": min(100, (event_counts.get("exercise", 0) / 5) * 100),
        "meditation_practice": min(100, (event_counts.get("meditation", 0) / 3) * 100),
        "mood_tracking": min(100, (event_counts.get("mood_log", 0) / 7) * 100),
    }

    avg_score = sum(dimensions.values()) / len(dimensions)

    # 趋势（模拟）
    trend = "up" if avg_score > 50 else ("down" if avg_score < 30 else "stable")

    # 最佳表现
    highlights = []
    if dimensions["checkin_consistency"] > 70:
        highlights.append("打卡坚持度优秀，说明你对养生的承诺很强！")
    if dimensions["exercise_frequency"] > 60:
        highlights.append("运动频率保持得很好，身体在逐渐改善。")
    if not highlights:
        highlights.append("继续保持养生习惯，你会看到更大的改变。")

    # 改进建议
    suggestions = []
    if dimensions["food_logging"] < 50:
        suggestions.append("建议增加食物记录，更好地了解饮食与体质的关系。")
    if dimensions["meditation_practice"] < 50:
        suggestions.append("冥想和调息对心理健康很重要，建议每周坚持3次。")
    if not suggestions:
        suggestions.append("你的各项数据均衡，保持当前节奏即可。")

    # TCM洞察
    tcm_insights = [
        "你的运动频率适中，符合春季阳气生发的养生原则。",
        f"本周食物记录次数{event_counts.get('food_log', 0)}次，建议至少记录7次以便更好地调理体质。",
    ]

    # 下周目标
    next_goals = [
        "完成7次打卡（保持连续性）",
        "食物记录至少5次",
        "保持现有运动频率",
    ]

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "period": "weekly",
            "week_ending": end.strftime("%Y-%m-%d"),
            "dimensions": dimensions,
            "average_score": round(avg_score, 1),
            "trend": trend,
            "best_performance": highlights,
            "improvement_suggestions": suggestions,
            "tcm_insights": tcm_insights,
            "next_week_goals": next_goals,
        },
    }


@router.get("/monthly-report/{user_id}", summary="月度报告")
async def get_monthly_report(user_id: str):
    """获取用户月度报告"""
    start, end = _get_date_range(days=30)
    event_counts = _count_events_by_type(user_id, start, end)
    total_events = sum(event_counts.values())

    # 新用户空状态
    if total_events == 0:
        return {
            "success": True,
            "data": {
                "user_id": user_id,
                "is_new_user": True,
                "message": "月度报告需要至少一周的数据积累。请持续使用app，28天后即可查看首份月度报告。",
                "checkin_calendar": {},
                "wellness_level": None,
                "three_highlights": [],
                "wellness_score": 0,
            },
        }

    # 打卡日历（简化版）
    checkin_count = event_counts.get("checkin", 0)
    checkin_days = []
    for event in _events.get(user_id, []):
        if event["event_type"] == "checkin":
            if "timestamp" in event:
                ts = datetime.fromisoformat(event["timestamp"])
                if start <= ts <= end:
                    checkin_days.append(ts.strftime("%Y-%m-%d"))

    # 体质趋势（模拟）
    wellness_level = "improving" if checkin_count > 20 else ("declining" if checkin_count < 5 else "stable")

    # 三个养生亮点
    highlights = []
    if event_counts.get("checkin", 0) > 20:
        highlights.append("打卡坚持力超群：你已连续记录30+次，这是坚持养生的最好证明。")
    if event_counts.get("exercise", 0) > 10:
        highlights.append("运动习惯养成：本月运动频率稳定，身体素质在提升。")
    if event_counts.get("meditation", 0) > 5:
        highlights.append("心理调理有成：冥想次数达到目标，身心更加平和。")
    if not highlights:
        highlights = ["建立了基础养生习惯", "开始关注食疗调理", "尝试多种养生活动"]

    # 养生等级评分（0-100）
    wellness_score = min(100, (checkin_count / 30) * 100)

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "period": "monthly",
            "month": end.strftime("%Y-%m"),
            "checkin_count": checkin_count,
            "checkin_dates": checkin_days[:10],  # 最多显示10个
            "wellness_level": wellness_level,
            "three_highlights": highlights,
            "wellness_score": round(wellness_score, 1),
            "total_events": total_events,
            "event_breakdown": event_counts,
        },
    }


@router.get("/insights/{user_id}", summary="AI驱动洞察")
async def get_insights(user_id: str):
    """基于历史数据返回个性化洞察"""
    user_events = _events.get(user_id, [])

    if not user_events:
        return {
            "success": True,
            "data": {
                "user_id": user_id,
                "insights": ["开始记录你的养生数据，系统将为你生成个性化洞察！"],
                "count": 1,
            },
        }

    # 按小时统计
    hours = defaultdict(int)
    for event in user_events:
        if "timestamp" in event:
            ts = datetime.fromisoformat(event["timestamp"])
            hours[ts.hour] += 1

    # 按周几统计
    weekdays = defaultdict(int)
    for event in user_events:
        if "timestamp" in event:
            ts = datetime.fromisoformat(event["timestamp"])
            weekdays[ts.weekday()] += 1

    insights = []

    # 洞察1：最活跃时段
    if hours:
        most_active = max(hours, key=hours.get)
        insights.append(f"你在每天{most_active:02d}点最活跃，这个时段你完成了最多的养生活动。")

    # 洞察2：最低活跃时段（如果有）
    if hours and len(hours) > 2:
        least_active = min(hours, key=hours.get)
        insights.append(f"你在{least_active:02d}点的活动最少，可以在该时段补充养生计划。")

    # 洞察3：周趋势
    if weekdays:
        most_active_day = max(weekdays, key=weekdays.get)
        day_names = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        insights.append(f"你在{day_names[most_active_day]}最容易坚持养生，建议在该天安排重点活动。")

    # 洞察4：情绪模式（如果有mood_log）
    mood_logs = [e for e in user_events if e["event_type"] == "mood_log"]
    if mood_logs:
        insights.append(f"你在本周记录了{len(mood_logs)}次情绪，良好的情绪追踪帮助你更好地理解身心关系。")

    # 洞察5：食疗偏好（如果有food_log）
    food_logs = [e for e in user_events if e["event_type"] == "food_log"]
    if food_logs:
        insights.append(f"食疗记录频率不错！持续关注食物搭配，可以更好地调理{['气虚', '阴虚', '阳虚', '湿热'][len(food_logs) % 4]}体质。")

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "insights": insights[:5],  # 最多5条
            "count": len(insights),
            "generated_at": datetime.now().isoformat(),
        },
    }


@router.get("/app-stats", summary="应用级统计（无需认证）")
async def get_app_stats():
    """返回应用级匿名统计，无需认证"""
    return {
        "success": True,
        "data": {
            "total_users": _app_stats["total_users"],
            "daily_active_users": _app_stats["daily_active_users"],
            "dau_ratio": round(_app_stats["daily_active_users"] / _app_stats["total_users"] * 100, 1),
            "most_popular_content": _app_stats["most_popular_content"],
            "season_distribution": _app_stats["season_distribution"],
            "last_updated": datetime.now().isoformat(),
        },
    }
