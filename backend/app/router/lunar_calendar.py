"""
顺时 — 农历日期与传统节日养生 API
提供农历日期计算、传统节日的养生建议、农历月份的季节性调养指导。
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/lunar", tags=["lunar_calendar"])


class BirthdayWellnessRequest(BaseModel):
    lunar_month: int = Field(..., ge=1, le=12)
    lunar_day: int = Field(..., ge=1, le=30)
    constitution_type: Optional[str] = Field(None, max_length=50)

# ─────────────────────────────────────────────────────────────────────────────
# 传统节日数据库（12 个节日）
# ─────────────────────────────────────────────────────────────────────────────
FESTIVALS = {
    "春节": {
        "festival_name": "春节",
        "lunar_date": "正月初一",
        "approx_solar_month": 2,
        "theme": "迎新春，调理肝气",
        "taboo_foods": ["过度油腻", "辛辣刺激", "冷冻食物"],
        "recommended_foods": ["红枣", "桂圆", "黄芪粥", "鸡汤", "山药"],
        "wellness_advice": "春节期间作息规律，避免熬夜，适度户外活动以疏肝理气。",
        "tcm_principle": "春生，主肝，疏肝解郁，温阳祛湿",
        "activity_suggestions": ["散步", "太极", "八段锦", "慢走"],
    },
    "元宵": {
        "festival_name": "元宵",
        "lunar_date": "正月十五",
        "approx_solar_month": 2,
        "theme": "赏月调脾，温阳扶正",
        "taboo_foods": ["黏腻汤圆过多", "冷饮", "烧烤"],
        "recommended_foods": ["黑芝麻汤圆（少量）", "红糖", "生姜茶", "薏米粥"],
        "wellness_advice": "适量进食汤圆，配热茶。夜间户外活动注意保暖，特别是腹部和脚。",
        "tcm_principle": "温脾阳，助消化，活血通络",
        "activity_suggestions": ["赏月散步", "八段锦", "太极"],
    },
    "清明": {
        "festival_name": "清明",
        "lunar_date": "三月初五左右",
        "approx_solar_month": 4,
        "theme": "清气上升，疏肝祛湿",
        "taboo_foods": ["过甘厚腻", "动物内脏过多", "腌制品"],
        "recommended_foods": ["艾草青团", "春笋", "春菜", "蜂蜜", "红豆薏米"],
        "wellness_advice": "清明时节湿气渐重，宜清淡饮食，多食时令春菜，踏青活动疏肝。",
        "tcm_principle": "清热祛湿，疏肝理气，调畅阳气",
        "activity_suggestions": ["踏青", "散步", "登山"],
    },
    "端午": {
        "festival_name": "端午",
        "lunar_date": "五月初五",
        "approx_solar_month": 6,
        "theme": "驱邪祛湿，扶阳气",
        "taboo_foods": ["冷粽过多", "过甜", "油炸"],
        "recommended_foods": ["粽子（限量）", "绿豆汤", "冬瓜薏米粥", "艾草茶"],
        "wellness_advice": "端午节前后是祛湿黄金期，佩戴艾草，饮艾草茶，避免过度贪凉。",
        "tcm_principle": "温阳扶阳，祛湿排毒，防病驱邪",
        "activity_suggestions": ["划龙舟", "散步", "太极"],
    },
    "七夕": {
        "festival_name": "七夕",
        "lunar_date": "七月初七",
        "approx_solar_month": 8,
        "theme": "调补心脾，安神助眠",
        "taboo_foods": ["过辛辣", "过油腻", "烟酒过量"],
        "recommended_foods": ["莲子心茶", "龙眼干", "红豆", "黑芝麻", "百合"],
        "wellness_advice": "七夕时值仲夏，心火旺盛，宜静坐冥想，调补心脾，安神助眠。",
        "tcm_principle": "滋阴补心，安神定志，调理脾胃",
        "activity_suggestions": ["静坐冥想", "瑜伽", "穴位按摩"],
    },
    "中元": {
        "festival_name": "中元",
        "lunar_date": "七月十五",
        "approx_solar_month": 8,
        "theme": "秋初调理，温脾阳",
        "taboo_foods": ["过冷", "生冷海鲜", "过甜"],
        "recommended_foods": ["红薯粥", "南瓜", "黄芪炖鸡", "山楂"],
        "wellness_advice": "中元后秋意渐浓，脾阳渐衰，宜温脾阳，少食冷饮，早睡早起。",
        "tcm_principle": "温脾阳，调畅气机，为秋冬做准备",
        "activity_suggestions": ["散步", "八段锦", "拜月"],
    },
    "中秋": {
        "festival_name": "中秋",
        "lunar_date": "八月十五",
        "approx_solar_month": 9,
        "theme": "滋阴润肺，秋冬养阴",
        "taboo_foods": ["月饼过多", "油炸", "过甜刺激"],
        "recommended_foods": ["银耳莲子羹", "蜂蜜", "雪梨", "百合", "山药"],
        "wellness_advice": "中秋时值秋分，宜滋阴润肺，少食辛辣，多食白色食物，适度赏月散步。",
        "tcm_principle": "滋阴润肺，调理秋燥，养护脾胃",
        "activity_suggestions": ["赏月散步", "冥想", "静坐"],
    },
    "重阳": {
        "festival_name": "重阳",
        "lunar_date": "九月初九",
        "approx_solar_month": 10,
        "theme": "培补脾阳，入冬储能",
        "taboo_foods": ["过度滋腻", "辛辣刺激", "冷饮"],
        "recommended_foods": ["红枣粥", "栗子", "黄芪", "冬虫夏草", "羊肉汤"],
        "wellness_advice": "重阳登高可强身健体，调理脾胃，为冬季进补准备。饮菊花茶清热。",
        "tcm_principle": "培补脾阳，温阳益气，为冬季准备",
        "activity_suggestions": ["登山", "登高", "散步"],
    },
    "冬至": {
        "festival_name": "冬至",
        "lunar_date": "十一月初一左右",
        "approx_solar_month": 12,
        "theme": "温阳进补，冬季养藏",
        "taboo_foods": ["过度进补", "辛辣过量", "冷饮"],
        "recommended_foods": ["羊肉汤", "黄芪鸡汤", "红参", "冬虫夏草", "核桃"],
        "wellness_advice": "冬至进补黄金期，宜温阳补气，但勿过量，配合适度运动。",
        "tcm_principle": "温阳益气，扶阳护阳，冬季养藏",
        "activity_suggestions": ["散步", "八段锦", "太极"],
    },
    "腊八": {
        "festival_name": "腊八",
        "lunar_date": "十二月初八",
        "approx_solar_month": 1,
        "theme": "温阳暖脾，为新年做准备",
        "taboo_foods": ["过冷", "生冷食物"],
        "recommended_foods": ["腊八粥", "黑豆", "红豆", "薏米", "黄芪"],
        "wellness_advice": "腊八粥为冬季进补妙品，温阳健脾，适度进食，不可过饱。",
        "tcm_principle": "温脾阳，调理气机，为新年储备阳气",
        "activity_suggestions": ["散步", "静坐", "太极"],
    },
    "小年": {
        "festival_name": "小年",
        "lunar_date": "十二月二十三",
        "approx_solar_month": 1,
        "theme": "清扫旧气，为新年做准备",
        "taboo_foods": ["过度油腻", "辛辣"],
        "recommended_foods": ["糍粑", "灶糖", "清粥", "山楂"],
        "wellness_advice": "小年时宜清淡，调理脾胃，为春节大鱼大肉做准备。",
        "tcm_principle": "调理脾胃，疏肝理气，为新岁做准备",
        "activity_suggestions": ["扫除", "散步", "打扫卫生"],
    },
    "除夕": {
        "festival_name": "除夕",
        "lunar_date": "十二月三十",
        "approx_solar_month": 2,
        "theme": "温阳扶正，迎新春",
        "taboo_foods": ["过度饮酒", "过油腻"],
        "recommended_foods": ["鸡汤", "鱼汤", "红枣", "桂圆", "黄芪粥"],
        "wellness_advice": "除夕宜家庭团聚，心情舒畅，适度进食，早睡早起迎新春。",
        "tcm_principle": "温阳益气，调畅气机，喜悦迎新",
        "activity_suggestions": ["家庭团聚", "散步", "静坐"],
    },
}

# ─────────────────────────────────────────────────────────────────────────────
# 农历月份养生重点数据库（12 个月）
# ─────────────────────────────────────────────────────────────────────────────
LUNAR_MONTHLY_WELLNESS = {
    1: {
        "lunar_month": 1,
        "month_name": "正月",
        "approx_solar_month": "1-2月",
        "season": "冬末春初",
        "focus": "养肝气，疏肝理气，为一年储备阳气",
        "tcm_principle": "春生，主肝，初阳生发，需顺应自然",
        "recommended_foods": ["红枣", "桂圆", "黄芪", "甘草", "黄酒"],
        "avoided_foods": ["过辛辣", "过油腻", "冷饮"],
        "activities": ["散步", "太极", "八段锦"],
        "sleep_advice": "晚卧早起，适度户外活动，不可过度疲劳",
        "emotion_care": "心情舒畅，避免忧思",
    },
    2: {
        "lunar_month": 2,
        "month_name": "二月",
        "approx_solar_month": "2-3月",
        "season": "春季",
        "focus": "疏肝理气，防春困，调理脾胃",
        "tcm_principle": "春生，肝主生发，需疏肝解郁",
        "recommended_foods": ["春笋", "春菜", "蜂蜜", "大枣", "蛋黄"],
        "avoided_foods": ["过甘厚腻", "动物脂肪"],
        "activities": ["踏青", "散步", "太极"],
        "sleep_advice": "适度增加户外活动，调理因冬季导致的阳气虚弱",
        "emotion_care": "疏肝解郁，多与人交往，参加活动",
    },
    3: {
        "lunar_month": 3,
        "month_name": "三月",
        "approx_solar_month": "3-4月",
        "season": "春季",
        "focus": "护脾胃，祛湿气，疏肝理气",
        "tcm_principle": "脾主湿，春季湿气渐重，需健脾祛湿",
        "recommended_foods": ["薏米", "红豆", "冬瓜", "冬笋", "赤小豆"],
        "avoided_foods": ["油腻厚腻", "生冷刺激"],
        "activities": ["散步", "慢走", "八段锦"],
        "sleep_advice": "晚卧早起，增加户外活动，通过出汗祛湿",
        "emotion_care": "保持心情开朗，避免过度思虑",
    },
    4: {
        "lunar_month": 4,
        "month_name": "四月",
        "approx_solar_month": "4-5月",
        "season": "春末夏初",
        "focus": "温脾阳，祛湿热，调理脾胃",
        "tcm_principle": "脾虚湿困，需温脾运湿",
        "recommended_foods": ["粳米粥", "山药", "薏米", "冬瓜薏米粥"],
        "avoided_foods": ["冷饮", "油腻", "甜腻"],
        "activities": ["散步", "太极", "八段锦"],
        "sleep_advice": "适应逐渐升高的气温，不可贪凉，避免吹空调",
        "emotion_care": "心情舒畅，适度劳动",
    },
    5: {
        "lunar_month": 5,
        "month_name": "五月",
        "approx_solar_month": "5-6月",
        "season": "初夏",
        "focus": "祛湿热，调理心脾，防疫病",
        "tcm_principle": "夏至前后湿热最盛，需扶阳祛湿",
        "recommended_foods": ["冬瓜", "绿豆", "薏米", "红豆", "绿豆粥"],
        "avoided_foods": ["冷饮", "油腻厚腻", "辛辣刺激"],
        "activities": ["散步", "游泳（温水）", "瑜伽"],
        "sleep_advice": "避免过度贪凉，夜间睡眠注意腹部保暖",
        "emotion_care": "心平气和，避免过度兴奋或烦躁",
    },
    6: {
        "lunar_month": 6,
        "month_name": "六月",
        "approx_solar_month": "6-7月",
        "season": "仲夏",
        "focus": "清心火，祛暑湿，滋阴补阳",
        "tcm_principle": "心火旺，湿热盛，需清热祛湿",
        "recommended_foods": ["绿豆汤", "冬瓜", "薏米", "莲子", "百合"],
        "avoided_foods": ["辛辣刺激", "过温燥", "油炸厚腻"],
        "activities": ["游泳", "散步", "静坐冥想"],
        "sleep_advice": "午睡 30 分钟调理心阳，夜间卧室保持通风凉爽",
        "emotion_care": "避免过度兴奋，保持心平气和",
    },
    7: {
        "lunar_month": 7,
        "month_name": "七月",
        "approx_solar_month": "7-8月",
        "season": "盛夏",
        "focus": "扶阳气，祛湿热，调理脾胃",
        "tcm_principle": "三伏天，伏阳在内，需温阳扶正",
        "recommended_foods": ["黄芪炖鸡", "党参粥", "红枣", "姜汤"],
        "avoided_foods": ["过度冷饮", "生冷", "冰镇水果"],
        "activities": ["散步", "八段锦", "太极"],
        "sleep_advice": "三伏贴最佳时期，虽然天气热，仍需温阳，避免吹空调直吹",
        "emotion_care": "保持平和心态，避免过度兴奋",
    },
    8: {
        "lunar_month": 8,
        "month_name": "八月",
        "approx_solar_month": "8-9月",
        "season": "秋初",
        "focus": "滋阴润肺，养护心脾",
        "tcm_principle": "秋燥初现，脾阳渐衰，需滋阴润肺",
        "recommended_foods": ["银耳", "蜂蜜", "雪梨", "百合", "山药"],
        "avoided_foods": ["过辛辣", "油腻厚腻", "烧烤"],
        "activities": ["散步", "冥想", "慢走"],
        "sleep_advice": "适度增加睡眠，早卧早起适应秋天，滋阴润肺",
        "emotion_care": "避免悲秋，保持心情舒畅",
    },
    9: {
        "lunar_month": 9,
        "month_name": "九月",
        "approx_solar_month": "9-10月",
        "season": "秋季",
        "focus": "滋阴补肺，调理脾胃，适度进补",
        "tcm_principle": "秋燥伤肺，需滋阴润肺，为冬季做准备",
        "recommended_foods": ["山药粥", "银耳粥", "蜂蜜", "核桃", "黑芝麻"],
        "avoided_foods": ["过辛辣", "油炸食品", "烧烤"],
        "activities": ["散步", "登山", "太极"],
        "sleep_advice": "早卧早起，适应秋季昼夜温差，滋阴润肺",
        "emotion_care": "避免过度悲秋，保持积极心态",
    },
    10: {
        "lunar_month": 10,
        "month_name": "十月",
        "approx_solar_month": "10-11月",
        "season": "秋末冬初",
        "focus": "培补脾阳，温阳益气，为冬季进补做准备",
        "tcm_principle": "脾阳渐虚，需温脾阳，为冬季储备能量",
        "recommended_foods": ["黄芪鸡汤", "红枣粥", "栗子", "羊肉汤"],
        "avoided_foods": ["过度油腻", "辛辣刺激"],
        "activities": ["登高", "散步", "八段锦"],
        "sleep_advice": "适度增加保暖，早卧早起适应冬季，逐步增加进补",
        "emotion_care": "适度劳动，培补阳气",
    },
    11: {
        "lunar_month": 11,
        "month_name": "十一月",
        "approx_solar_month": "11-12月",
        "season": "冬季",
        "focus": "温阳进补，冬季养藏，储备能量",
        "tcm_principle": "冬季主藏，需温阳补气，为来年储备能量",
        "recommended_foods": ["羊肉汤", "黄芪粥", "核桃", "冬虫夏草", "红参"],
        "avoided_foods": ["过度冷食", "生冷", "油腻过多"],
        "activities": ["散步", "太极", "八段锦"],
        "sleep_advice": "早卧晚起，适度进补，避免过度疲劳",
        "emotion_care": "保持内心平和，避免过度消耗阳气",
    },
    12: {
        "lunar_month": 12,
        "month_name": "十二月",
        "approx_solar_month": "12-1月",
        "season": "隆冬",
        "focus": "温阳扶正，冬季养藏，迎接新年",
        "tcm_principle": "冬季最冷，需温阳益气，为来年做准备",
        "recommended_foods": ["黄芪鸡汤", "羊肉汤", "红参", "核桃", "黑芝麻"],
        "avoided_foods": ["过度冷食", "生冷刺激"],
        "activities": ["散步", "八段锦", "太极"],
        "sleep_advice": "早卧晚起，避免过度消耗阳气，为新年储备能量",
        "emotion_care": "保持心情舒畅，迎接新年",
    },
}


def _get_lunar_month() -> int:
    """根据公历月份推算农历月份（简化模型）"""
    month = datetime.now().month
    # 简化模型：农历月份大致与公历月份对应，但有偏移
    lunar_month = month
    if lunar_month > 12:
        lunar_month = lunar_month - 12
    return lunar_month


def _get_upcoming_festival():
    """获取最近的节日信息和倒计时（简化）"""
    month = datetime.now().month
    # 简化：根据公历月份返回近期节日
    if month == 1:
        return "春节", 30
    elif month == 2:
        return "清明", 40
    elif month == 3:
        return "清明", 30
    elif month == 4:
        return "端午", 30
    elif month == 5:
        return "端午", 15
    elif month == 6:
        return "七夕", 35
    elif month == 7:
        return "中秋", 40
    elif month == 8:
        return "中秋", 15
    elif month == 9:
        return "重阳", 20
    elif month == 10:
        return "冬至", 45
    elif month == 11:
        return "冬至", 30
    else:
        return "春节", 50


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/today", summary="获取今日农历信息")
async def today_lunar():
    """返回今日农历信息，包含当月养生重点和近期节日倒计时。"""
    lunar_month = _get_lunar_month()
    upcoming_festival, days_until = _get_upcoming_festival()

    monthly_info = LUNAR_MONTHLY_WELLNESS.get(lunar_month, {})

    return {
        "success": True,
        "data": {
            "solar_date": datetime.now().strftime("%Y-%m-%d"),
            "lunar_month": lunar_month,
            "month_name": monthly_info.get("month_name", ""),
            "season": monthly_info.get("season", ""),
            "monthly_focus": monthly_info.get("focus", ""),
            "recommended_foods": monthly_info.get("recommended_foods", []),
            "activities": monthly_info.get("activities", []),
            "upcoming_festival": upcoming_festival,
            "days_until_festival": days_until,
            "tcm_principle": monthly_info.get("tcm_principle", ""),
        },
    }


@router.get("/festival/{festival_name}", summary="获取节日详情")
async def get_festival(festival_name: str):
    """获取指定节日的养生建议（支持中文名称）。"""
    # 支持 URL 编码的中文
    from urllib.parse import unquote
    festival_name = unquote(festival_name)

    festival = FESTIVALS.get(festival_name)
    if not festival:
        raise HTTPException(status_code=404, detail=f"Festival '{festival_name}' not found")

    return {"success": True, "data": festival}


@router.get("/festivals", summary="全年节日列表")
async def list_festivals(month: Optional[int] = Query(None, ge=1, le=12)):
    """返回全年节日列表，支持按农历月份过滤。"""
    all_festivals = list(FESTIVALS.values())

    if month:
        # 根据 approx_solar_month 过滤
        all_festivals = [f for f in all_festivals if f.get("approx_solar_month") == month]

    return {
        "success": True,
        "data": {
            "festivals": all_festivals,
            "total": len(all_festivals),
            "month_filter": month,
        },
    }


@router.get("/monthly/{month}", summary="指定农历月份的养生重点")
async def monthly_wellness(month: int):
    """获取指定农历月份（1-12）的养生重点。"""
    if month < 1 or month > 12:
        raise HTTPException(status_code=422, detail="Month must be between 1 and 12")

    monthly_info = LUNAR_MONTHLY_WELLNESS.get(month)
    if not monthly_info:
        raise HTTPException(status_code=404, detail=f"Month {month} not found")

    return {"success": True, "data": monthly_info}


@router.post("/birthday", summary="农历生日养生建议")
async def birthday_wellness(
    request: BirthdayWellnessRequest,
):
    """返回生日月份对应的文化季节内容，不依据生日诊断体质。"""
    lunar_month = request.lunar_month
    lunar_day = request.lunar_day
    constitution_type = request.constitution_type

    monthly_info = LUNAR_MONTHLY_WELLNESS.get(lunar_month, {})

    # 保留旧字段名以兼容客户端；值只接受用户自述，生日不能推断体质。
    inferred_constitution = constitution_type or "not_assessed"

    return {
        "success": True,
        "data": {
            "lunar_birthday": f"{lunar_month}-{lunar_day}",
            "birth_month_name": monthly_info.get("month_name", ""),
            "inferred_constitution": constitution_type or inferred_constitution,
            "constitution_description": "体质不能依据出生日期推断；如需记录，仅展示用户自述结果。",
            "constitution_source": "self_reported" if constitution_type else "not_assessed",
            "content_scope": "传统历法文化与一般生活方式参考，不构成医学诊断或个体化治疗建议。",
            "monthly_focus": monthly_info.get("focus", ""),
            "recommended_foods": monthly_info.get("recommended_foods", []),
            "avoided_foods": monthly_info.get("avoided_foods", []),
            "activities": monthly_info.get("activities", []),
            "sleep_advice": monthly_info.get("sleep_advice", ""),
            "emotion_care": monthly_info.get("emotion_care", ""),
            "tcm_principle": monthly_info.get("tcm_principle", ""),
        },
    }
