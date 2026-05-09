"""
顺时 — 桌面小组件 API (shunshi-widget)
iOS/Android桌面小组件数据接口
"""

from fastapi import APIRouter, Query
from typing import Optional
from datetime import datetime, date

router = APIRouter(prefix="/api/v1/widget", tags=["widget"])

WIDGET_TYPES = [
    {"id": "solar_term", "name": "节气倒计时", "sizes": ["small", "medium"], "description": "显示当前节气及养生要点"},
    {"id": "daily_tip", "name": "每日养生提示", "sizes": ["small", "medium", "large"], "description": "每日一条养生小知识"},
    {"id": "water_tracker", "name": "饮水进度", "sizes": ["small"], "description": "显示今日饮水量进度"},
    {"id": "constitution_tip", "name": "体质养生", "sizes": ["medium"], "description": "根据体质显示当日养生建议"},
    {"id": "checkin_streak", "name": "打卡连续天数", "sizes": ["small"], "description": "显示连续打卡天数"},
    {"id": "shichen", "name": "时辰养生", "sizes": ["small", "medium"], "description": "当前时辰的养生建议"},
]

DAILY_TIPS = [
    "立春之后，肝气升发，宜多食绿色食物，保持心情舒畅",
    "每日饮水应根据体重调整，一般成人约1500-1700ml",
    "子时（23:00-1:00）前入睡，有助于胆经的自我修复",
    "足三里穴是'长寿穴'，每天按压5分钟，强身健体",
    "顺应节气饮食，是中医养生的核心智慧",
    "情绪是健康的重要因素，'七情'过度均会伤及脏腑",
    "八段锦每日15分钟，调和气血，强筋健骨",
]

SOLAR_TERMS_MINI = {
    "lichun": {"name": "立春", "date_typical": "2月4日", "key_tip": "养肝护阳，顺应升发"},
    "yushui": {"name": "雨水", "date_typical": "2月19日", "key_tip": "健脾祛湿，防湿邪"},
    "jingzhe": {"name": "惊蛰", "date_typical": "3月6日", "key_tip": "顺肝气，避免情绪激动"},
    "chunfen": {"name": "春分", "date_typical": "3月21日", "key_tip": "阴阳平衡，注意保暖"},
}


def _get_current_shichen_code() -> str:
    hour = datetime.now().hour
    if 23 <= hour or hour < 1: return "zi"
    if 1 <= hour < 3: return "chou"
    if 3 <= hour < 5: return "yin"
    if 5 <= hour < 7: return "mao"
    if 7 <= hour < 9: return "chen"
    if 9 <= hour < 11: return "si"
    if 11 <= hour < 13: return "wu"
    if 13 <= hour < 15: return "wei"
    if 15 <= hour < 17: return "shen"
    if 17 <= hour < 19: return "you"
    if 19 <= hour < 21: return "xu"
    return "hai"


SHICHEN_MINI = {
    "zi": {"name": "子时", "tip": "深度睡眠，胆经修复"},
    "chou": {"name": "丑时", "tip": "熟睡，血归于肝"},
    "yin": {"name": "寅时", "tip": "肺经当令，注意保暖"},
    "mao": {"name": "卯时", "tip": "排便时间，喝温水"},
    "chen": {"name": "辰时", "tip": "吃早餐，消化最旺"},
    "si": {"name": "巳时", "tip": "脾经当令，专注工作"},
    "wu": {"name": "午时", "tip": "心经当令，午休养神"},
    "wei": {"name": "未时", "tip": "小肠吸收，适量喝水"},
    "shen": {"name": "申时", "tip": "膀胱经，适合学习"},
    "you": {"name": "酉时", "tip": "肾经当令，温和运动"},
    "xu": {"name": "戌时", "tip": "心包经，家庭放松"},
    "hai": {"name": "亥时", "tip": "三焦经，准备入睡"},
}


@router.get("/types", summary="小组件类型列表")
async def list_widget_types():
    return {"success": True, "data": {"widgets": WIDGET_TYPES}}


@router.get("/data/solar-term", summary="节气小组件数据")
async def get_solar_term_widget():
    today = date.today()
    month = today.month
    if month in [2, 3]: current = "lichun"
    elif month in [4, 5]: current = "chunfen"
    elif month in [6, 7, 8]: current = "dashu"
    else: current = "dongzhi"
    term = SOLAR_TERMS_MINI.get(current, {"name": "节气", "date_typical": "", "key_tip": "顺应节气养生"})
    return {
        "success": True,
        "data": {
            "current_solar_term": term["name"],
            "key_tip": term["key_tip"],
            "date": today.isoformat()
        }
    }


@router.get("/data/daily-tip", summary="每日提示小组件")
async def get_daily_tip_widget():
    day_of_year = date.today().timetuple().tm_yday
    tip = DAILY_TIPS[day_of_year % len(DAILY_TIPS)]
    return {
        "success": True,
        "data": {
            "tip": tip,
            "date": date.today().isoformat()
        }
    }


@router.get("/data/shichen", summary="时辰小组件数据")
async def get_shichen_widget():
    code = _get_current_shichen_code()
    shichen = SHICHEN_MINI[code]
    return {
        "success": True,
        "data": {
            "current_time": datetime.now().strftime("%H:%M"),
            "shichen_code": code,
            "shichen_name": shichen["name"],
            "tip": shichen["tip"]
        }
    }


@router.get("/data/water-tracker", summary="饮水进度小组件")
async def get_water_widget(
    user_id: str = Query(..., description="用户ID"),
    today_ml: int = Query(0, description="今日饮水量(ml)"),
    goal_ml: int = Query(1700, description="目标饮水量(ml)")
):
    progress = min(100, round(today_ml / goal_ml * 100)) if goal_ml > 0 else 0
    return {
        "success": True,
        "data": {
            "today_ml": today_ml,
            "goal_ml": goal_ml,
            "progress_pct": progress,
            "remaining_ml": max(0, goal_ml - today_ml),
            "status": "达标" if today_ml >= goal_ml else f"还差{goal_ml - today_ml}ml"
        }
    }


@router.get("/data/checkin-streak", summary="打卡连续天数小组件")
async def get_checkin_widget(
    user_id: str = Query(...),
    streak_days: int = Query(0)
):
    if streak_days >= 100:
        badge = "冬雪勋章"
    elif streak_days >= 30:
        badge = "秋月勋章"
    elif streak_days >= 7:
        badge = "春芽勋章"
    else:
        badge = None
    return {
        "success": True,
        "data": {
            "streak_days": streak_days,
            "badge": badge,
            "motivation": f"已坚持{streak_days}天！" if streak_days > 0 else "开始今日打卡吧！"
        }
    }
