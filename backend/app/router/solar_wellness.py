"""
Solar Wellness API — 顺时养生 wellness endpoints
Provides: current solar term, daily advice, shichen info, context
"""

from fastapi import APIRouter, Query
from typing import Optional
from datetime import datetime
from sqlalchemy import text

router = APIRouter(prefix="/api/v1/solar-wellness", tags=["solar-wellness"])


@router.get("/current")
async def get_current_solar_wellness():
    """获取当前节气养生信息"""
    now = datetime.now()
    month = now.month
    day = now.day

    # Simple solar term mapping
    terms = [
        (1, 6, "小寒"), (1, 20, "大寒"),
        (2, 4, "立春"), (2, 19, "雨水"),
        (3, 6, "惊蛰"), (3, 21, "春分"),
        (4, 5, "清明"), (4, 20, "谷雨"),
        (5, 6, "立夏"), (5, 21, "小满"),
        (6, 6, "芒种"), (6, 21, "夏至"),
        (7, 7, "小暑"), (7, 23, "大暑"),
        (8, 7, "立秋"), (8, 23, "处暑"),
        (9, 8, "白露"), (9, 23, "秋分"),
        (10, 8, "寒露"), (10, 23, "霜降"),
        (11, 7, "立冬"), (11, 22, "小雪"),
        (12, 7, "大雪"), (12, 22, "冬至"),
    ]
    term_name = "春分"
    for t in terms:
        if month < t[0] or (month == t[0] and day < t[1]):
            break
        term_name = t[2]

    return {
        "success": True,
        "data": {
            "term": term_name,
            "season": get_season(month),
            "date": now.strftime("%Y-%m-%d"),
        }
    }


@router.get("/daily-advice")
async def get_daily_advice(
    user_id: Optional[str] = Query(None, description="用户ID"),
    constitution: Optional[str] = Query(None, description="体质类型"),
):
    """获取每日养生建议"""
    return {
        "success": True,
        "data": {
            "morning": "晨起喝一杯温水，舒展筋骨",
            "noon": "午餐后小憩15分钟，养心安神",
            "evening": "晚餐清淡，避免油腻，助眠安神",
            "diet": "宜食当季蔬果，少食生冷",
            "exercise": "推荐八段锦或散步30分钟",
        }
    }


@router.get("/shichen")
async def get_current_shichen():
    """获取当前时辰信息"""
    hour = datetime.now().hour
    shichen_data = [
        (23, 1, "子时", "胆经", "万籁俱寂·养胆气"),
        (1, 3, "丑时", "肝经", "肝血归藏·养肝阴"),
        (3, 5, "寅时", "肺经", "气血布散·养肺气"),
        (5, 7, "卯时", "大肠经", "天明排便·通肠腑"),
        (7, 9, "辰时", "胃经", "朝食养胃·补气血"),
        (9, 11, "巳时", "脾经", "运化水谷·健脾土"),
        (11, 13, "午时", "心经", "日中养心·调阴阳"),
        (13, 15, "未时", "小肠经", "分清泌浊·利消化"),
        (15, 17, "申时", "膀胱经", "排毒利水·泻火气"),
        (17, 19, "酉时", "肾经", "藏精纳气·养肾元"),
        (19, 21, "戌时", "心包经", "护心减压·畅情志"),
        (21, 23, "亥时", "三焦经", "百脉通调·备入眠"),
    ]

    current = shichen_data[0]
    for sc in shichen_data:
        start, end = sc[0], sc[1]
        if start <= end:
            if start <= hour < end:
                current = sc
                break
        else:
            if hour >= start or hour < end:
                current = sc
                break

    return {
        "success": True,
        "data": {
            "name": current[2],
            "meridian": current[3],
            "principle": current[4],
            "time_range": f"{current[0]}:00 - {current[1]}:00",
        }
    }


@router.get("/context")
async def get_wellness_context(
    user_id: Optional[str] = Query(None, description="用户ID"),
):
    """获取用户养生上下文"""
    now = datetime.now()
    return {
        "success": True,
        "data": {
            "date": now.strftime("%Y-%m-%d"),
            "hour": now.hour,
            "greeting": get_greeting(now.hour),
        }
    }


def get_season(month: int) -> str:
    if 3 <= month <= 5:
        return "spring"
    elif 6 <= month <= 8:
        return "summer"
    elif 9 <= month <= 11:
        return "autumn"
    return "winter"


def get_greeting(hour: int) -> str:
    if 5 <= hour < 11:
        return "早安，开启美好的一天"
    elif 11 <= hour < 13:
        return "午安，适时休息"
    elif 13 <= hour < 18:
        return "下午好，保持精力"
    elif 18 <= hour < 22:
        return "晚上好，放松身心"
    return "夜深了，早些休息"
