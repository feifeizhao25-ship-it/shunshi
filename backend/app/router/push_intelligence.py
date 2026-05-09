"""
顺时 — 智能推送策略管理系统
管理推送规则、用户偏好、A/B测试，不真实发送推送
"""

from fastapi import APIRouter, HTTPException, Query, Path
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from pydantic import BaseModel
from collections import defaultdict
import random

router = APIRouter(prefix="/api/v1/push-intel", tags=["push_intelligence"])

# ─────────────────────────────────────────────────────────────────────────────
# 数据模型
# ─────────────────────────────────────────────────────────────────────────────

class PushPreferences(BaseModel):
    enabled_types: List[str]
    preferred_time: str  # HH:MM format
    frequency: str  # daily/weekly/smart


class SchedulePushRequest(BaseModel):
    user_id: str
    push_type: str
    content: str
    send_at: Optional[str] = None  # ISO datetime or "smart"


class ABTestRequest(BaseModel):
    name: str
    variant_a_title: str
    variant_b_title: str
    target_push_type: str
    sample_size: int


# ─────────────────────────────────────────────────────────────────────────────
# 推送类型和默认设置
# ─────────────────────────────────────────────────────────────────────────────

PUSH_TYPES = {
    "daily_tip": "每日养生小贴士",
    "solar_term_reminder": "节气提醒",
    "checkin_reminder": "打卡提醒",
    "health_alert": "健康警报",
    "achievement_unlock": "成就解锁",
    "content_recommendation": "内容推荐",
    "weekly_report": "周报推送",
    "festival_reminder": "节日养生提醒",
}

DEFAULT_PREFERENCES = {
    "enabled_types": ["daily_tip", "checkin_reminder", "content_recommendation"],
    "preferred_time": "08:00",
    "frequency": "daily",
}

# ─────────────────────────────────────────────────────────────────────────────
# 内存数据存储
# ─────────────────────────────────────────────────────────────────────────────

_user_preferences: Dict[str, Dict] = {}
_push_history: Dict[str, List[Dict]] = defaultdict(list)
_ab_tests: Dict[str, Dict] = {}
_user_open_records: Dict[str, List[Dict]] = defaultdict(list)  # 用于学习最优推送时间


def _get_default_preferences() -> Dict:
    """返回默认推送偏好副本"""
    return DEFAULT_PREFERENCES.copy()


def _calculate_optimal_time(user_id: str) -> str:
    """基于打开记录计算最优推送时间"""
    opens = _user_open_records.get(user_id, [])
    if not opens:
        return "08:00"

    # 统计打开时段
    hours = defaultdict(int)
    for record in opens:
        if "open_time" in record:
            ts = datetime.fromisoformat(record["open_time"])
            hours[ts.hour] += 1

    if not hours:
        return "08:00"

    most_active_hour = max(hours, key=hours.get)
    return f"{most_active_hour:02d}:00"


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/preferences/{user_id}", summary="获取用户推送偏好")
async def get_preferences(user_id: str):
    """获取用户推送偏好，不存在时返回默认值"""
    preferences = _user_preferences.get(user_id)

    if not preferences:
        preferences = _get_default_preferences()

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "preferences": preferences,
            "is_default": user_id not in _user_preferences,
        },
    }


@router.put("/preferences/{user_id}", summary="更新推送偏好")
async def update_preferences(user_id: str, prefs: PushPreferences):
    """更新用户推送偏好"""
    # 验证推送类型
    valid_types = set(PUSH_TYPES.keys())
    invalid_types = set(prefs.enabled_types) - valid_types
    if invalid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid push types: {invalid_types}"
        )

    # 验证时间格式
    try:
        datetime.strptime(prefs.preferred_time, "%H:%M")
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid time format, use HH:MM")

    # 验证频率
    if prefs.frequency not in ["daily", "weekly", "smart"]:
        raise HTTPException(status_code=400, detail="Frequency must be daily/weekly/smart")

    preferences = {
        "enabled_types": prefs.enabled_types,
        "preferred_time": prefs.preferred_time,
        "frequency": prefs.frequency,
    }

    _user_preferences[user_id] = preferences

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "preferences": preferences,
            "updated_at": datetime.now().isoformat(),
        },
    }


@router.post("/schedule", summary="调度一条推送")
async def schedule_push(req: SchedulePushRequest):
    """调度推送"""
    # 验证推送类型
    if req.push_type not in PUSH_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid push_type: {req.push_type}")

    # 确定发送时间
    if req.send_at == "smart":
        # smart模式：使用用户偏好时间
        prefs = _user_preferences.get(req.user_id, _get_default_preferences())
        preferred_time = prefs.get("preferred_time", "08:00")
        now = datetime.now()
        hour, minute = map(int, preferred_time.split(":"))
        send_time = now.replace(hour=hour, minute=minute, second=0)

        # 如果已过该时间，推送到明天
        if send_time < now:
            send_time = send_time + timedelta(days=1)
    elif req.send_at:
        # 指定时间
        try:
            send_time = datetime.fromisoformat(req.send_at)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid datetime format")
    else:
        send_time = datetime.now()

    push_record = {
        "push_id": f"push_{req.user_id}_{len(_push_history[req.user_id])}",
        "user_id": req.user_id,
        "push_type": req.push_type,
        "content": req.content,
        "scheduled_time": send_time.isoformat(),
        "created_at": datetime.now().isoformat(),
        "status": "scheduled",
    }

    _push_history[req.user_id].append(push_record)

    return {
        "success": True,
        "data": {
            "push_id": push_record["push_id"],
            "user_id": req.user_id,
            "push_type": req.push_type,
            "scheduled_time": send_time.isoformat(),
            "status": "scheduled",
        },
    }


@router.get("/history/{user_id}", summary="推送历史")
async def get_history(
    user_id: str,
    limit: int = Query(20, ge=1, le=100),
    push_type: Optional[str] = Query(None),
):
    """获取推送历史，支持过滤"""
    history = _push_history.get(user_id, [])

    # 按类型过滤
    if push_type:
        history = [h for h in history if h["push_type"] == push_type]

    # 按最新优先排序并限制数量
    history = sorted(history, key=lambda x: x["created_at"], reverse=True)[:limit]

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "total_count": len(_push_history.get(user_id, [])),
            "history": history,
            "limit": limit,
        },
    }


@router.get("/optimal-time/{user_id}", summary="最优推送时间")
async def get_optimal_time(user_id: str):
    """计算该用户的最优推送时间"""
    optimal = _calculate_optimal_time(user_id)

    # 模拟学习数据
    opens = _user_open_records.get(user_id, [])
    confidence = min(len(opens) / 20, 1.0)  # 20次打开为100%信心

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "optimal_time": optimal,
            "confidence": round(confidence, 2),
            "data_points": len(opens),
            "recommendation": f"建议在{optimal}前后发送推送，留存率最高" if confidence > 0.5 else "数据不足，使用默认时间",
        },
    }


@router.post("/ab-test", summary="创建A/B测试")
async def create_ab_test(req: ABTestRequest):
    """创建推送A/B测试"""
    # 验证推送类型
    if req.target_push_type not in PUSH_TYPES:
        raise HTTPException(status_code=400, detail="Invalid push_type")

    if req.sample_size < 10:
        raise HTTPException(status_code=400, detail="Sample size must be at least 10")

    test_id = f"ab_test_{len(_ab_tests)}_{int(datetime.now().timestamp())}"

    ab_test = {
        "test_id": test_id,
        "name": req.name,
        "target_push_type": req.target_push_type,
        "variant_a": {
            "title": req.variant_a_title,
            "allocation": 0.5,
            "users": [],
        },
        "variant_b": {
            "title": req.variant_b_title,
            "allocation": 0.5,
            "users": [],
        },
        "sample_size": req.sample_size,
        "created_at": datetime.now().isoformat(),
        "status": "active",
        "metrics": {
            "variant_a_opens": 0,
            "variant_a_clicks": 0,
            "variant_b_opens": 0,
            "variant_b_clicks": 0,
        },
    }

    _ab_tests[test_id] = ab_test

    return {
        "success": True,
        "data": {
            "test_id": test_id,
            "name": req.name,
            "target_push_type": req.target_push_type,
            "sample_size": req.sample_size,
            "variant_a_title": req.variant_a_title,
            "variant_b_title": req.variant_b_title,
            "allocation_rule": "每个用户有50%概率看到A版本、50%概率看到B版本",
            "status": "active",
            "created_at": ab_test["created_at"],
        },
    }


@router.get("/types", summary="所有推送类型")
async def get_push_types():
    """返回所有推送类型及说明"""
    types = [
        {
            "id": type_id,
            "name": description,
            "description": _get_push_type_description(type_id),
        }
        for type_id, description in PUSH_TYPES.items()
    ]

    return {
        "success": True,
        "data": {
            "push_types": types,
            "total": len(types),
        },
    }


def _get_push_type_description(push_type: str) -> str:
    """获取推送类型的详细说明"""
    descriptions = {
        "daily_tip": "每日个性化养生建议，根据体质和季节定制",
        "solar_term_reminder": "24节气提醒，提供节气养生指导",
        "checkin_reminder": "提醒用户完成每日打卡",
        "health_alert": "重要健康警报，如异常数据提示",
        "achievement_unlock": "用户成就解锁通知（如连续打卡里程碑）",
        "content_recommendation": "推荐相关养生内容、文章或食疗方案",
        "weekly_report": "周度养生报告汇总",
        "festival_reminder": "节日养生提醒和禁忌提示",
    }
    return descriptions.get(push_type, "推送类型")


# ─────────────────────────────────────────────────────────────────────────────
# 辅助函数（模拟用户打开记录）
# ─────────────────────────────────────────────────────────────────────────────

def _simulate_user_opens(user_id: str, count: int = 5) -> None:
    """为用户模拟一些打开记录（用于测试最优时间计算）"""
    for _ in range(count):
        hour = random.randint(7, 22)
        minute = random.randint(0, 59)
        open_time = datetime.now().replace(hour=hour, minute=minute, second=0)
        _user_open_records[user_id].append({"open_time": open_time.isoformat()})
