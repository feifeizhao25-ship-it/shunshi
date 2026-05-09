"""
顺时 — 肝脏养护 API (shunshi-liver-care)
中医护肝方案、肝脏功能、护肝食疗
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/liver-care", tags=["liver-care"])

LIVER_TCM_FUNCTIONS = [
    {"function": "肝主疏泄", "description": "调节气机运行，促进脾胃运化，调节情志"},
    {"function": "肝藏血", "description": "储存血液，调节血量，女子月经与肝密切相关"},
    {"function": "肝开窍于目", "description": "眼睛的功能与肝脏健康密切相关"},
    {"function": "肝主筋", "description": "筋腱的正常功能有赖于肝血的濡养"},
    {"function": "其华在爪", "description": "指甲的光泽反映肝血是否充盈"},
]

LIVER_CARE_FOODS = [
    {"name": "枸杞", "benefit": "滋补肝肾，明目", "usage": "泡茶或煮粥"},
    {"name": "菊花", "benefit": "清肝泻火，明目疏风", "usage": "泡茶饮用"},
    {"name": "西兰花", "benefit": "含萝卜硫素，支持肝脏解毒功能", "usage": "轻炒或蒸"},
    {"name": "大蒜", "benefit": "含硫化合物，促进肝脏酶活性", "usage": "生食或轻炒"},
    {"name": "绿茶", "benefit": "含儿茶素，保护肝细胞", "usage": "冲泡饮用"},
    {"name": "核桃", "benefit": "富含精氨酸，协助肝脏排毒", "usage": "每日4-5颗"},
    {"name": "柠檬", "benefit": "促进胆汁分泌，助消化", "usage": "柠檬水"},
    {"name": "姜黄", "benefit": "含姜黄素，有护肝抗炎作用", "usage": "烹饪调料"},
]

LIVER_MERIDIAN_CARE = {
    "peak_time": "丑时（凌晨1-3点）",
    "principle": "丑时肝经当令，此时应保证熟睡，让血液回流肝脏解毒",
    "key_acupoints": [
        {"code": "LV3", "name": "太冲穴", "location": "足背第1-2跖骨结合部前凹陷", "function": "疏肝解郁，理气和血"},
        {"code": "LV14", "name": "期门穴", "location": "前胸第6肋间隙", "function": "疏肝健脾，理气活血"},
        {"code": "GB34", "name": "阳陵泉穴", "location": "小腿外侧，腓骨头前下方", "function": "疏肝利胆，舒筋活络"},
    ]
}

LIVER_EMOTIONS = {
    "emotion": "怒",
    "tcm_view": "中医认为'怒伤肝'，暴怒会导致肝气上逆，损伤肝脏功能",
    "emotion_regulation": [
        "深呼吸：感到愤怒时，先深呼吸10次",
        "按压太冲穴：疏泄肝气，平息怒火",
        "运动发泄：打球、快走等适度运动",
        "倾诉沟通：找可信任的朋友或心理咨询师",
        "冥想静心：每日10-15分钟正念冥想"
    ],
    "positive_emotions": ["保持乐观开朗", "培养兴趣爱好", "与人为善"]
}


@router.get("/tcm-functions", summary="中医肝脏功能")
async def get_tcm_functions():
    return {"success": True, "data": {"functions": LIVER_TCM_FUNCTIONS}}


@router.get("/care-foods", summary="护肝食物推荐")
async def get_care_foods():
    return {"success": True, "data": {"foods": LIVER_CARE_FOODS}}


@router.get("/meridian-care", summary="肝经养生方案")
async def get_meridian_care():
    return {"success": True, "data": LIVER_MERIDIAN_CARE}


@router.get("/emotion-regulation", summary="肝脏情志调节")
async def get_emotion_regulation():
    return {"success": True, "data": LIVER_EMOTIONS}


@router.get("/daily-plan", summary="每日护肝计划")
async def get_daily_plan():
    plan = {
        "morning": {
            "time": "07:00-08:00",
            "actions": ["喝一杯温柠檬水", "早餐清淡，多吃绿色蔬菜", "轻柔伸展运动"]
        },
        "midday": {
            "time": "12:00-14:00",
            "actions": ["午餐七分饱", "饭后散步15分钟", "避免午后立即工作造成疲劳"]
        },
        "evening": {
            "time": "19:00-21:00",
            "actions": ["晚餐清淡少量", "按摩太冲穴5分钟", "散步或瑜伽放松"]
        },
        "bedtime": {
            "time": "23:00前",
            "actions": ["23点前入睡", "丑时（1-3点）保证深度睡眠", "戒酒（酒精是肝脏最大负担）"]
        }
    }
    return {"success": True, "data": {"daily_plan": plan}}


@router.get("/seasonal-care", summary="四季护肝建议")
async def get_seasonal_care(season: Optional[str] = Query(None)):
    care = {
        "spring": {
            "principle": "春季肝气旺，宜疏肝养肝",
            "advice": "春天是肝脏最活跃的季节，顺应肝的升发之性",
            "foods": ["韭菜", "香椿", "菠菜", "枸杞"],
            "activities": ["踏青", "伸展运动", "情绪舒畅"]
        },
        "summer": {
            "principle": "夏季注意心肝协调",
            "advice": "夏季心火旺，肝火易随之上升，需清心降火",
            "foods": ["苦瓜", "绿豆", "菊花茶"],
            "activities": ["避免暴晒", "规律作息"]
        },
        "autumn": {
            "principle": "秋季养肝血，收敛肝气",
            "advice": "秋天对应肺金，金克木，需保护肝气不被过度压制",
            "foods": ["枸杞", "黑芝麻", "桑椹"],
            "activities": ["保持乐观", "早睡早起"]
        },
        "winter": {
            "principle": "冬季补肾滋肝，养精蓄锐",
            "advice": "肾水滋养肝木，冬季补肾即是护肝",
            "foods": ["黑豆", "核桃", "猪肝"],
            "activities": ["早睡晚起", "减少激烈运动"]
        }
    }
    if season:
        return {"success": True, "data": care.get(season, {"message": "季节参数无效"})}
    return {"success": True, "data": {"seasonal_care": care}}
