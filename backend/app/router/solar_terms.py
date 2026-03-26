# 节气系统 API 路由
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timedelta

router = APIRouter(prefix="/api/v1/solar-terms", tags=["节气"])

# ============ 24节气英文数据 ============

SOLAR_TERMS_EN = {
    "st-001": {"en_name": "Beginning of Spring", "en_alias": "Spring Begins",
               "en_description": "The first of the 24 solar terms, marking the start of spring. All living things revive and vitality surges. The weather warms but a chill lingers — stay warm and protect yourself from lingering cold.",
               "en_suggestions": ["Rise early and sleep early; exercise moderately", "Eat pungent and sweet foods like chives, cilantro", "Stay warm to prevent colds", "Keep your emotions balanced and joyful"],
               "en_foods": ["Garlic chives", "Cilantro", "Scallion", "Honey", "Red dates"],
               "en_exercises": ["Brisk walking", "Tai Chi", "Ba Duan Jin"],
               "en_activities": ["Spring outings", "Plum blossom viewing", "Tree planting"]},
    "st-002": {"en_name": "Rain Water", "en_alias": "Spring Rain Nourishes",
               "en_description": "Rain increases and temperatures rise. The air grows humid — focus on dispelling dampness and strengthening the spleen.",
               "en_suggestions": ["Watch for dampness and moisture", "Exercise moderately to dispel dampness", "Avoid cold, raw, and greasy foods", "Nurture your spleen and stomach"],
               "en_foods": ["Job's tears (coix seed)", "Adzuki beans", "Chinese yam", "Winter melon", "Red beans"],
               "en_exercises": ["Brisk walking", "Yoga", "Swimming"],
               "en_activities": ["Indoor exercise", "Hot springs", "Anti-dampness tea"]},
    "st-003": {"en_name": "Awakening of Insects", "en_alias": "Spring Thunder Awakens",
               "en_description": "The third solar term. Insects awaken as spring energy rises. Weather fluctuates — guard against sudden cold snaps.",
               "en_suggestions": ["Stay warm and protected", "Sleep early, rise early to nourish the liver", "Exercise gently to generate yang", "Keep emotions stable"],
               "en_foods": ["Pear", "Tremella mushroom", "Honey", "Lily bulb", "Spinach"],
               "en_exercises": ["Morning jog", "Tai Chi", "Kite flying"],
               "en_activities": ["Spring outings", "Flower viewing", "Spring hiking"]},
    "st-04": {"en_name": "Spring Equinox", "en_alias": "Yin-Yang Balance",
              "en_description": "Day and night are equal — yin and yang are in perfect balance. The climate is mild, making it an ideal time for wellness practices.",
              "en_suggestions": ["Harmonize yin and yang, balance qi and blood", "Eat plenty of green vegetables", "Exercise moderately", "Rest your eyes regularly"],
              "en_foods": ["Spring bamboo shoots", "Toona sprouts", "Shepherd's purse", "Bean sprouts", "Celery"],
              "en_exercises": ["Badminton", "Cycling", "Yoga"],
              "en_activities": ["Kite flying", "Flower viewing", "Nature walks"]},
    "st-05": {"en_name": "Clear and Bright", "en_alias": "Pure and Bright",
              "en_description": "The air is clear and the scenery is vivid — nature reveals itself in full splendor. A time for remembrance and spring outings.",
              "en_suggestions": ["Honor ancestors with remembrance", "Take spring walks and connect with nature", "Be mindful of fire safety", "Regulate your emotions"],
              "en_foods": ["Green rice balls (Qingtuan)", "Mugwort", "River snails", "River shrimp", "Wild greens"],
              "en_exercises": ["Walking", "Spring outings", "Tai Chi"],
              "en_activities": ["Ancestor remembrance", "Spring outings", "Willow planting"]},
    "st-06": {"en_name": "Grain Rain", "en_alias": "Rain Nurtures Grain",
              "en_description": "The last solar term of spring. Rainfall increases, nourishing the growing grain. Focus on strengthening the spleen and dispelling dampness.",
              "en_suggestions": ["Dispel dampness, strengthen the spleen", "Nourish and protect the liver", "Exercise moderately", "Guard against allergies"],
              "en_foods": ["Toona sprouts", "Soybeans", "Goji berries", "Chrysanthemum", "Rose petals"],
              "en_exercises": ["Walking", "Swimming", "Yoga"],
              "en_activities": ["Peony viewing", "Tea picking", "Nature walks"]},
    "st-07": {"en_name": "Beginning of Summer", "en_alias": "Summer Begins",
              "en_description": "Summer's first solar term. Temperatures rise — wellness focuses on nourishing the heart and calming the spirit.",
              "en_suggestions": ["Nourish the heart and calm the spirit", "Eat light, clean foods", "Take a midday nap", "Protect against sun and heat"],
              "en_foods": ["Mung beans", "Bitter melon", "Watermelon", "Lotus seeds", "Lily bulb"],
              "en_exercises": ["Swimming", "Morning exercise", "Yoga"],
              "en_activities": ["Lotus viewing", "Tea tasting", "Cool retreat"]},
    "st-08": {"en_name": "Grain Buds", "en_alias": "Seeds Swell",
              "en_description": "Ample rain, and crops begin to plump. Focus on clearing heat and draining dampness.",
              "en_suggestions": ["Clear heat, drain dampness", "Strengthen the spleen, dispel dampness", "Exercise moderately", "Use sun protection"],
              "en_foods": ["Job's tears", "Winter melon", "Watermelon", "Cucumber", "Mung bean soup"],
              "en_exercises": ["Swimming", "Walking", "Tai Chi"],
              "en_activities": ["Wheat field viewing", "Tea tasting", "Countryside tour"]},
    "st-09": {"en_name": "Grain in Ear", "en_alias": "Busy Planting Season",
              "en_description": "A time of harvest and planting. The weather turns hot — focus on clearing heat and nourishing the heart.",
              "en_suggestions": ["Clear heat, relieve summer discomfort", "Nourish the heart, calm the spirit", "Exercise moderately", "Stay well hydrated"],
              "en_foods": ["Sour plum drink", "Mung beans", "Job's tears", "Watermelon", "Bitter melon"],
              "en_exercises": ["Morning exercise", "Swimming", "Yoga"],
              "en_activities": ["Green plum wine", "Lotus viewing", "Tea tasting"]},
    "st-10": {"en_name": "Summer Solstice", "en_alias": "Peak Yang Energy",
              "en_description": "The longest day in the Northern Hemisphere — yang energy reaches its peak. Focus on nourishing yin and clearing heat.",
              "en_suggestions": ["Nourish yin, clear heat", "Take a midday nap", "Eat a light diet", "Stay cool and hydrated"],
              "en_foods": ["Watermelon", "Mung beans", "Lotus seeds", "Bitter melon", "Lotus leaf"],
              "en_exercises": ["Morning exercise", "Swimming", "Tai Chi"],
              "en_activities": ["Lotus viewing", "Cooling off", "Tea tasting"]},
    "st-11": {"en_name": "Minor Heat", "en_alias": "Heat Begins",
              "en_description": "Heat intensifies but hasn't peaked. Focus on clearing heat and strengthening the spleen.",
              "en_suggestions": ["Clear heat, relieve discomfort", "Strengthen the spleen, dispel dampness", "Exercise moderately", "Rest well"],
              "en_foods": ["Mung bean soup", "Watermelon", "Winter melon", "Lotus seeds", "Job's tears"],
              "en_exercises": ["Morning exercise", "Swimming", "Yoga"],
              "en_activities": ["Lotus viewing", "Cooling off", "Tea tasting"]},
    "st-12": {"en_name": "Major Heat", "en_alias": "Extreme Heat",
              "en_description": "The hottest time of year. Focus on clearing heat, detoxifying, and preventing heatstroke.",
              "en_suggestions": ["Clear heat, detoxify", "Prevent heatstroke, stay cool", "Stay well hydrated", "Rest adequately"],
              "en_foods": ["Watermelon", "Mung beans", "Winter melon", "Lotus seeds", "Chrysanthemum tea"],
              "en_exercises": ["Morning exercise", "Swimming", "Indoor exercise"],
              "en_activities": ["Heat avoidance", "Lotus viewing", "Tea tasting"]},
    "st-13": {"en_name": "Beginning of Autumn", "en_alias": "Autumn Arrives",
              "en_description": "Autumn's first solar term. The weather begins to cool — focus on moistening dryness and nourishing the lungs.",
              "en_suggestions": ["Moisten dryness, nourish the lungs", "Begin gentle nourishment", "Exercise moderately", "Start dressing warmer"],
              "en_foods": ["Pear", "Tremella mushroom", "Honey", "Lily bulb", "Lotus seeds"],
              "en_exercises": ["Walking", "Tai Chi", "Yoga"],
              "en_activities": ["Autumn scenery", "Fruit picking", "Mountain climbing"]},
    "st-14": {"en_name": "End of Heat", "en_alias": "Heat Retreats",
              "en_description": "Summer heat fades and the weather turns cool. Focus on nourishing yin and moistening the lungs.",
              "en_suggestions": ["Nourish yin, moisten the lungs", "Begin gentle nourishment", "Exercise moderately", "Prevent autumn dryness"],
              "en_foods": ["Pear", "Lily bulb", "Tremella mushroom", "Honey", "Sesame"],
              "en_exercises": ["Walking", "Tai Chi", "Mountain climbing"],
              "en_activities": ["Autumn scenery", "Fruit picking", "Tea tasting"]},
    "st-15": {"en_name": "White Dew", "en_alias": "Morning Dew",
              "en_description": "Temperature differences between day and night grow. Dew forms — focus on strengthening the spleen and nourishing the lungs.",
              "en_suggestions": ["Strengthen spleen, nourish lungs", "Begin seasonal nourishment", "Stay warm", "Prevent colds"],
              "en_foods": ["Longan", "Red dates", "Lily bulb", "Lotus seeds", "Tremella mushroom"],
              "en_exercises": ["Walking", "Tai Chi", "Yoga"],
              "en_activities": ["Osmanthus viewing", "Fruit picking", "Mountain climbing"]},
    "st-16": {"en_name": "Autumn Equinox", "en_alias": "Yin-Yang Balance",
              "en_description": "The midpoint of autumn — day and night are equal. Focus on harmonizing yin and yang.",
              "en_suggestions": ["Harmonize yin and yang", "Moisten dryness, nourish lungs", "Exercise moderately", "Prioritize quality sleep"],
              "en_foods": ["Honey", "Pear", "Lily bulb", "Tremella mushroom", "Sesame"],
              "en_exercises": ["Walking", "Tai Chi", "Yoga"],
              "en_activities": ["Moon viewing", "Autumn scenery", "Fruit picking"]},
    "st-17": {"en_name": "Cold Dew", "en_alias": "Chilly Dew",
              "en_description": "Temperatures drop further — focus on nourishing the liver and kidneys.",
              "en_suggestions": ["Nourish liver and kidneys", "Begin seasonal nourishment", "Stay warm", "Prevent colds"],
              "en_foods": ["Red dates", "Longan", "Walnuts", "Sesame", "Lamb"],
              "en_exercises": ["Walking", "Tai Chi", "Mountain climbing"],
              "en_activities": ["Red leaf viewing", "Mountain climbing", "Tea tasting"]},
    "st-18": {"en_name": "Frost Descent", "en_alias": "First Frost",
              "en_description": "The last solar term of autumn — frost descends. Focus on warming the spleen and kidneys.",
              "en_suggestions": ["Warm the spleen and kidneys", "Begin nourishment", "Stay warm", "Prevent colds"],
              "en_foods": ["Lamb", "Red dates", "Walnuts", "Chestnuts", "Honey"],
              "en_exercises": ["Walking", "Tai Chi", "Yoga"],
              "en_activities": ["Autumn scenery", "Fruit picking", "Hot springs"]},
    "st-19": {"en_name": "Beginning of Winter", "en_alias": "Winter Begins",
              "en_description": "Winter's first solar term — nature enters storage mode. Focus on warming kidney yang.",
              "en_suggestions": ["Warm and nourish kidney yang", "Begin seasonal nourishment", "Stay warm", "Exercise moderately"],
              "en_foods": ["Lamb", "Beef", "Red dates", "Longan", "Ginger"],
              "en_exercises": ["Walking", "Tai Chi", "Yoga"],
              "en_activities": ["Hot springs", "Snow viewing", "Tea tasting"]},
    "st-20": {"en_name": "Minor Snow", "en_alias": "First Snow",
              "en_description": "Snow begins to fall. Focus on warming the kidneys and supporting yang.",
              "en_suggestions": ["Warm kidneys, support yang", "Begin nourishment", "Stay warm", "Prevent colds"],
              "en_foods": ["Lamb", "Walnuts", "Black beans", "Red dates", "Longan"],
              "en_exercises": ["Indoor exercise", "Tai Chi", "Yoga"],
              "en_activities": ["Snow viewing", "Hot springs", "Tea tasting"]},
    "st-21": {"en_name": "Major Snow", "en_alias": "Heavy Snow",
              "en_description": "Snow deepens. Focus on nourishing kidney essence.",
              "en_suggestions": ["Nourish kidney essence", "Begin nourishment", "Stay warm", "Prevent frostbite"],
              "en_foods": ["Lamb", "Beef", "Longan", "Red dates", "Walnuts"],
              "en_exercises": ["Indoor exercise", "Tai Chi", "Yoga"],
              "en_activities": ["Snow viewing", "Skiing", "Hot springs"]},
    "st-22": {"en_name": "Winter Solstice", "en_alias": "Peak Yin Energy",
              "en_description": "The shortest day in the Northern Hemisphere — yin energy peaks. Focus on nourishing the kidneys and storing essence.",
              "en_suggestions": ["Nourish kidneys, store essence", "Begin nourishment", "Rest well", "Prevent colds"],
              "en_foods": ["Lamb", "Dumplings", "Tangyuan (sweet rice balls)", "Red dates", "Longan"],
              "en_exercises": ["Indoor exercise", "Tai Chi", "Walking"],
              "en_activities": ["Ancestor remembrance", "Dumpling eating", "Winter appreciation"]},
    "st-23": {"en_name": "Minor Cold", "en_alias": "Cold Deepens",
              "en_description": "Bitter cold but not yet the deepest. Focus on warming yang and dispelling cold.",
              "en_suggestions": ["Warm yang, dispel cold", "Begin nourishment", "Stay warm", "Prevent colds"],
              "en_foods": ["Lamb", "Red dates", "Longan", "Ginger", "Walnuts"],
              "en_exercises": ["Indoor exercise", "Tai Chi", "Yoga"],
              "en_activities": ["Plum blossom viewing", "Skiing", "Hot springs"]},
    "st-24": {"en_name": "Major Cold", "en_alias": "Extreme Cold",
              "en_description": "The coldest time of year. Focus on warming the kidneys and strengthening the spleen.",
              "en_suggestions": ["Warm kidneys, strengthen spleen", "Begin nourishment", "Stay warm", "Prevent frostbite"],
              "en_foods": ["Lamb", "Beef", "Red dates", "Longan", "Ginger"],
              "en_exercises": ["Indoor exercise", "Tai Chi", "Yoga"],
              "en_activities": ["Plum blossom viewing", "New Year preparation", "Family reunion dinner"]},
}


from app.services.solar_term_enhanced import solar_term_enhanced_service


def _localize_term(term: dict, locale: str) -> dict:
    """Localize a solar term dict based on locale"""
    if locale != "en-US":
        return term
    
    en = SOLAR_TERMS_EN.get(term.get("id"), {})
    if not en:
        return term
    
    result = dict(term)
    result["name"] = en.get("en_name", term.get("name"))
    result["alias"] = en.get("en_alias", term.get("alias"))
    result["description"] = en.get("en_description", term.get("description"))
    result["suggestions"] = en.get("en_suggestions", term.get("suggestions"))
    result["foods"] = en.get("en_foods", term.get("foods"))
    result["exercises"] = en.get("en_exercises", term.get("exercises"))
    result["activities"] = en.get("en_activities", term.get("activities"))
    return result

# ============ 24节气数据 ============

SOLAR_TERMS = [
    {
        "id": "st-001",
        "name": "立春",
        "emoji": "🌱",
        "alias": "春季开始",
        "description": "立春是二十四节气之首，标志着春季的开始。万物复苏，生机勃发。此时节气候转暖，但仍有寒意，需注意保暖。",
        "start_date": "02-04",
        "end_date": "02-18",
        "suggestions": [
            "宜早睡早起，适度运动",
            "多食辛甘发散之物，如韭菜、香菜",
            "注意保暖，预防感冒",
            "调畅情志，保持愉悦"
        ],
        "foods": ["韭菜", "香菜", "葱", "蜂蜜", "红枣"],
        "exercises": ["散步", "太极拳", "八段锦"],
        "activities": ["踏春", "赏梅", "植树"]
    },
    {
        "id": "st-002",
        "name": "雨水",
        "emoji": "💧",
        "alias": "春雨润物",
        "description": "雨水时节，降雨开始增多，气温回升。此时空气潮湿，应注意祛湿健脾。",
        "start_date": "02-19",
        "end_date": "03-05",
        "suggestions": [
            "注意祛湿防潮",
            "适度运动排湿",
            "少食生冷油腻",
            "养护脾胃"
        ],
        "foods": ["薏米", "红豆", "山药", "冬瓜", "赤小豆"],
        "exercises": ["快走", "瑜伽", "游泳"],
        "activities": ["室内运动", "泡温泉", "祛湿茶饮"]
    },
    {
        "id": "st-003",
        "name": "惊蛰",
        "emoji": "⚡",
        "alias": "春雷惊醒",
        "description": "惊蛰标志着仲春时节的开始，春雷惊醒冬眠的万物。此时气候多变，需注意防寒。",
        "start_date": "03-06",
        "end_date": "03-20",
        "suggestions": [
            "注意防寒保暖",
            "早睡早起养肝",
            "适度运动生阳",
            "保持情绪稳定"
        ],
        "foods": ["梨", "银耳", "蜂蜜", "百合", "菠菜"],
        "exercises": ["晨跑", "太极拳", "放风筝"],
        "activities": ["踏青", "赏花", "春游"]
    },
    {
        "id": "st-04",
        "name": "春分",
        "emoji": "🌸",
        "alias": "阴阳平衡",
        "description": "春分是阴阳平衡、昼夜相等的时节。此时气候温和，是养生的好时机。",
        "start_date": "03-21",
        "end_date": "04-04",
        "suggestions": [
            "阴阳平衡，调和气血",
            "多食绿色蔬菜",
            "适度运动锻炼",
            "注意眼部休息"
        ],
        "foods": ["春笋", "香椿", "荠菜", "豆芽", "芹菜"],
        "exercises": ["羽毛球", "骑行", "瑜伽"],
        "activities": ["放风筝", "赏花", "踏青"]
    },
    {
        "id": "st-05",
        "name": "清明",
        "emoji": "🌿",
        "alias": "气清景明",
        "description": "清明时节，气清景明，万物皆显。此时是祭祖和踏青的好时节。",
        "start_date": "04-05",
        "end_date": "04-19",
        "suggestions": [
            "扫墓祭祖，缅怀先人",
            "踏青赏春，亲近自然",
            "注意防火安全",
            "调节情绪"
        ],
        "foods": ["青团", "艾草", "螺蛳", "河虾", "野菜"],
        "exercises": ["散步", "踏青", "太极"],
        "activities": ["扫墓", "踏青", "插柳"]
    },
    {
        "id": "st-06",
        "name": "谷雨",
        "emoji": "🌧️",
        "alias": "雨生百谷",
        "description": "谷雨是春季最后一个节气，降雨增多，有利于谷物生长。",
        "start_date": "04-20",
        "end_date": "05-05",
        "suggestions": [
            "祛湿健脾",
            "养肝护肝",
            "适当运动",
            "防过敏"
        ],
        "foods": ["香椿", "黄豆", "枸杞", "菊花", "玫瑰花"],
        "exercises": ["散步", "游泳", "瑜伽"],
        "activities": ["赏牡丹", "采茶", "踏青"]
    },
    {
        "id": "st-07",
        "name": "立夏",
        "emoji": "☀️",
        "alias": "夏季开始",
        "description": "立夏是夏季的第一个节气，标志着夏天正式开始。气温升高，养生重在养心。",
        "start_date": "05-06",
        "end_date": "05-20",
        "suggestions": [
            "养心安神",
            "清淡饮食",
            "适当午睡",
            "防晒防暑"
        ],
        "foods": ["绿豆", "苦瓜", "西瓜", "莲子", "百合"],
        "exercises": ["游泳", "晨练", "瑜伽"],
        "activities": ["赏荷", "品茶", "避暑"]
    },
    {
        "id": "st-08",
        "name": "小满",
        "emoji": "🌾",
        "alias": "物至于此",
        "description": "小满时节，雨水充沛，农作物开始饱满。此时养生重在祛湿清热。",
        "start_date": "05-21",
        "end_date": "06-05",
        "suggestions": [
            "清热利湿",
            "健脾祛湿",
            "适当运动",
            "注意防晒"
        ],
        "foods": ["薏仁", "冬瓜", "西瓜", "黄瓜", "绿豆汤"],
        "exercises": ["游泳", "散步", "太极"],
        "activities": ["赏麦", "品茶", "田园游"]
    },
    {
        "id": "st-09",
        "name": "芒种",
        "emoji": "🌾",
        "alias": "忙种时节",
        "description": "芒种是夏收夏种的时节，天气炎热，养生重在清热养心。",
        "start_date": "06-06",
        "end_date": "06-20",
        "suggestions": [
            "清热解暑",
            "养心安神",
            "适当运动",
            "补充水分"
        ],
        "foods": ["酸梅汤", "绿豆", "薏米", "西瓜", "苦瓜"],
        "exercises": ["晨练", "游泳", "瑜伽"],
        "activities": ["青梅煮酒", "赏荷", "品茶"]
    },
    {
        "id": "st-10",
        "name": "夏至",
        "emoji": "🌞",
        "alias": "阳气最旺",
        "description": "夏至是北半球白最长的一天，阳气达到最旺。此时养生重在养阴清热。",
        "start_date": "06-21",
        "end_date": "07-06",
        "suggestions": [
            "养阴清热",
            "适当午睡",
            "清淡饮食",
            "防暑降温"
        ],
        "foods": ["西瓜", "绿豆", "莲子", "苦瓜", "荷叶"],
        "exercises": ["晨练", "游泳", "太极"],
        "activities": ["赏莲", "纳凉", "品茶"]
    },
    {
        "id": "st-11",
        "name": "小暑",
        "emoji": "🔥",
        "alias": "暑热初起",
        "description": "小暑时节，暑热开始，但未达到最热。养生重在清热健脾。",
        "start_date": "07-07",
        "end_date": "07-22",
        "suggestions": [
            "清热解暑",
            "健脾祛湿",
            "适当运动",
            "注意休息"
        ],
        "foods": ["绿豆汤", "西瓜", "冬瓜", "莲子", "薏米"],
        "exercises": ["晨练", "游泳", "瑜伽"],
        "activities": ["赏荷", "纳凉", "品茶"]
    },
    {
        "id": "st-12",
        "name": "大暑",
        "emoji": "🌡️",
        "alias": "炎热至极",
        "description": "大暑是一年中最热的时节，养生重在清热解毒、防暑降温。",
        "start_date": "07-23",
        "end_date": "08-07",
        "suggestions": [
            "清热解毒",
            "防暑降温",
            "补充水分",
            "适当休息"
        ],
        "foods": ["西瓜", "绿豆", "冬瓜", "莲子", "菊花茶"],
        "exercises": ["晨练", "游泳", "室内运动"],
        "activities": ["避暑", "赏荷", "品茶"]
    },
    {
        "id": "st-13",
        "name": "立秋",
        "emoji": "🍂",
        "alias": "秋意渐起",
        "description": "立秋是秋季的第一个节气，天气开始转凉，养生重在润燥养肺。",
        "start_date": "08-08",
        "end_date": "08-22",
        "suggestions": [
            "润燥养肺",
            "适当进补",
            "适度运动",
            "注意保暖"
        ],
        "foods": ["梨", "银耳", "蜂蜜", "百合", "莲子"],
        "exercises": ["散步", "太极", "瑜伽"],
        "activities": ["赏秋", "采摘", "登高"]
    },
    {
        "id": "st-14",
        "name": "处暑",
        "emoji": "🍃",
        "alias": "暑热渐退",
        "description": "处暑时节，暑热开始消退，天气转凉。养生重在滋阴润肺。",
        "start_date": "08-23",
        "end_date": "09-07",
        "suggestions": [
            "滋阴润肺",
            "适当进补",
            "适度运动",
            "预防秋燥"
        ],
        "foods": ["梨", "百合", "银耳", "蜂蜜", "芝麻"],
        "exercises": ["散步", "太极", "登山"],
        "activities": ["赏秋", "采摘", "品茶"]
    },
    {
        "id": "st-15",
        "name": "白露",
        "emoji": "💧",
        "alias": "露凝而白",
        "description": "白露时节，昼夜温差增大，露水凝结。养生重在补脾养肺。",
        "start_date": "09-08",
        "end_date": "09-22",
        "suggestions": [
            "补脾养肺",
            "适当进补",
            "注意保暖",
            "预防感冒"
        ],
        "foods": ["龙眼", "红枣", "百合", "莲子", "银耳"],
        "exercises": ["散步", "太极", "瑜伽"],
        "activities": ["赏桂", "采摘", "登高"]
    },
    {
        "id": "st-16",
        "name": "秋分",
        "emoji": "🍁",
        "alias": "阴阳平衡",
        "description": "秋分是秋季的中间点，昼夜相等。养生重在调和阴阳。",
        "start_date": "09-23",
        "end_date": "10-08",
        "suggestions": [
            "调和阴阳",
            "润燥养肺",
            "适当运动",
            "注意睡眠"
        ],
        "foods": ["蜂蜜", "梨", "百合", "银耳", "芝麻"],
        "exercises": ["散步", "太极", "瑜伽"],
        "activities": ["赏月", "赏秋", "采摘"]
    },
    {
        "id": "st-17",
        "name": "寒露",
        "emoji": "🍂",
        "alias": "露寒风凉",
        "description": "寒露时节，气温进一步下降，养生重在滋补肝肾。",
        "start_date": "10-09",
        "end_date": "10-22",
        "suggestions": [
            "滋补肝肾",
            "适当进补",
            "注意保暖",
            "预防感冒"
        ],
        "foods": ["红枣", "桂圆", "核桃", "芝麻", "羊肉"],
        "exercises": ["散步", "太极", "登山"],
        "activities": ["赏红叶", "登高", "品茶"]
    },
    {
        "id": "st-18",
        "name": "霜降",
        "emoji": "❄️",
        "alias": "霜降始寒",
        "description": "霜降是秋季最后一个节气，天气渐冷。养生重在温补脾肾。",
        "start_date": "10-23",
        "end_date": "11-06",
        "suggestions": [
            "温补脾肾",
            "适当进补",
            "注意保暖",
            "预防感冒"
        ],
        "foods": ["羊肉", "红枣", "核桃", "板栗", "蜂蜜"],
        "exercises": ["散步", "太极", "瑜伽"],
        "activities": ["赏秋", "采摘", "泡温泉"]
    },
    {
        "id": "st-19",
        "name": "立冬",
        "emoji": "❄️",
        "alias": "冬藏开始",
        "description": "立冬是冬季的第一个节气，万物收藏。养生重在温补肾阳。",
        "start_date": "11-07",
        "end_date": "11-21",
        "suggestions": [
            "温补肾阳",
            "适当进补",
            "注意保暖",
            "适当运动"
        ],
        "foods": ["羊肉", "牛肉", "红枣", "桂圆", "生姜"],
        "exercises": ["散步", "太极", "瑜伽"],
        "activities": ["泡温泉", "赏雪", "品茶"]
    },
    {
        "id": "st-20",
        "name": "小雪",
        "emoji": "🌨️",
        "alias": "雪未大",
        "description": "小雪时节，雪开始落下，但不大。养生重在温肾助阳。",
        "start_date": "11-22",
        "end_date": "12-06",
        "suggestions": [
            "温肾助阳",
            "适当进补",
            "注意保暖",
            "预防感冒"
        ],
        "foods": ["羊肉", "核桃", "黑豆", "红枣", "桂圆"],
        "exercises": ["室内运动", "太极", "瑜伽"],
        "activities": ["赏雪", "泡温泉", "品茶"]
    },
    {
        "id": "st-21",
        "name": "大雪",
        "emoji": "⛄",
        "alias": "雪盛时节",
        "description": "大雪时节，雪量增多。养生重在温补肾精。",
        "start_date": "12-07",
        "end_date": "12-21",
        "suggestions": [
            "温补肾精",
            "适当进补",
            "注意保暖",
            "预防冻疮"
        ],
        "foods": ["羊肉", "牛肉", "桂圆", "红枣", "核桃"],
        "exercises": ["室内运动", "太极", "瑜伽"],
        "activities": ["赏雪", "滑雪", "泡温泉"]
    },
    {
        "id": "st-22",
        "name": "冬至",
        "emoji": "☀️",
        "alias": "阴阳交替",
        "description": "冬至是北半球白昼最短的一天，阴气极盛。养生重在养肾藏精。",
        "start_date": "12-22",
        "end_date": "01-05",
        "suggestions": [
            "养肾藏精",
            "适当进补",
            "注意休息",
            "预防感冒"
        ],
        "foods": ["羊肉", "饺子", "汤圆", "红枣", "桂圆"],
        "exercises": ["室内运动", "太极", "散步"],
        "activities": ["祭祖", "吃饺子", "赏冬"]
    },
    {
        "id": "st-23",
        "name": "小寒",
        "emoji": "🥶",
        "alias": "寒气渐盛",
        "description": "小寒时节，天气寒冷，但未达到最冷。养生重在温阳散寒。",
        "start_date": "01-06",
        "end_date": "01-19",
        "suggestions": [
            "温阳散寒",
            "适当进补",
            "注意保暖",
            "预防感冒"
        ],
        "foods": ["羊肉", "红枣", "桂圆", "生姜", "核桃"],
        "exercises": ["室内运动", "太极", "瑜伽"],
        "activities": ["赏梅", "滑雪", "泡温泉"]
    },
    {
        "id": "st-24",
        "name": "大寒",
        "emoji": "🥶",
        "alias": "寒至极点",
        "description": "大寒是一年中最冷的时节。养生重在温肾健脾。",
        "start_date": "01-20",
        "end_date": "02-03",
        "suggestions": [
            "温肾健脾",
            "适当进补",
            "注意保暖",
            "预防冻疮"
        ],
        "foods": ["羊肉", "牛肉", "红枣", "桂圆", "生姜"],
        "exercises": ["室内运动", "太极", "瑜伽"],
        "activities": ["赏梅", "备年货", "团圆饭"]
    }
]

# ============ Helper Functions ============

def get_current_solar_term():
    """获取当前节气"""
    month = datetime.now().month
    day = datetime.now().day
    
    # 简化逻辑：按月份返回对应节气
    idx = ((month - 2) * 2 + (1 if day > 15 else 0)) % 24
    return SOLAR_TERMS[idx]

def get_solar_term_by_name(name: str):
    """根据名称获取节气"""
    for term in SOLAR_TERMS:
        if term["name"] == name:
            return term
    return None

# ============ Models ============

class SolarTerm(BaseModel):
    id: str
    name: str
    emoji: str
    alias: str
    description: str
    start_date: str
    end_date: str
    suggestions: List[str]
    foods: List[str]
    exercises: List[str]
    activities: List[str]

class SolarTermSummary(BaseModel):
    id: str
    name: str
    emoji: str
    alias: str
    start_date: str
    end_date: str

# ============ API Endpoints ============

@router.get("", response_model=dict)
async def get_solar_terms(
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
    page: int = Query(1, ge=1),
    limit: int = Query(24, ge=1, le=24)
):
    """获取所有节气"""
    start = (page - 1) * limit
    end = start + limit
    items = [_localize_term(SOLAR_TERMS[i], locale) for i in range(start, end)]
    
    return {
        "success": True,
        "data": {
            "items": items,
            "total": len(SOLAR_TERMS),
            "page": page,
            "limit": limit
        }
    }

@router.get("/current", response_model=dict)
async def get_current(locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """获取当前节气"""
    current = get_current_solar_term()
    return {"success": True, "data": _localize_term(current, locale)}

@router.get("/today", response_model=dict)
async def get_today_solar_term(locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """获取今日节气和建议"""
    current = get_current_solar_term()
    
    # 获取前后两个节气
    current_idx = SOLAR_TERMS.index(current)
    prev_term = SOLAR_TERMS[current_idx - 1] if current_idx > 0 else SOLAR_TERMS[-1]
    next_term = SOLAR_TERMS[current_idx + 1] if current_idx < len(SOLAR_TERMS) - 1 else SOLAR_TERMS[0]
    
    # 生成七日养生建议
    seven_day_suggestions = []
    for i in range(7):
        day_term = SOLAR_TERMS[(current_idx + i) % 24]
        localized = _localize_term(day_term, locale)
        seven_day_suggestions.append({
            "day": i + 1,
            "term": localized["name"],
            "emoji": day_term["emoji"],
            "suggestion": localized["suggestions"][i % len(localized["suggestions"])]
        })
    
    return {
        "success": True,
        "data": {
            "current": _localize_term(current, locale),
            "previous": _localize_term(prev_term, locale),
            "next": _localize_term(next_term, locale),
            "seven_day_suggestions": seven_day_suggestions
        }
    }

@router.get("/upcoming", response_model=dict)
async def get_upcoming_solar_term(locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """获取即将到来的节气（7天内）"""
    now = datetime.now()
    upcoming = []
    
    for term in SOLAR_TERMS:
        try:
            start_str = f"{now.year}-{term['start_date']}"
            start_date = datetime.strptime(start_str, "%Y-%m-%d")
            
            # 如果开始日期已过但结束日期未到，视为当前进行中
            try:
                end_str = f"{now.year}-{term['end_date']}"
                end_date = datetime.strptime(end_str, "%Y-%m-%d")
            except ValueError:
                continue
            
            # 检查7天内
            delta_start = (start_date - now).days
            if -1 <= delta_start <= 7:  # -1 表示今天或进行中
                days_until = max(delta_start, 0)
                upcoming.append({
                    **_localize_term(term, locale),
                    "days_until": days_until,
                    "start_at": start_date.isoformat(),
                })
        except (ValueError, KeyError):
            continue
    
    upcoming.sort(key=lambda x: x["days_until"])
    
    return {
        "success": True,
        "data": {
            "items": upcoming[:5],
            "total": len(upcoming),
            "now": now.isoformat(),
        }
    }

@router.get("/notifications", response_model=dict)
async def get_solar_term_notifications(locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """节气通知内容生成 - 返回即将到来节气的提醒文案"""
    now = datetime.now()
    notifications = []
    
    for term in SOLAR_TERMS:
        try:
            start_str = f"{now.year}-{term['start_date']}"
            start_date = datetime.strptime(start_str, "%Y-%m-%d")
            delta = (start_date - now).days
            
            if 0 <= delta <= 7:
                localized = _localize_term(term, locale)
                
                if locale == "en-US":
                    if delta == 0:
                        title = f"Today: {localized['name']}"
                        body = f"{localized['name']} has arrived! {localized['suggestions'][0] if localized['suggestions'] else ''}"
                    elif delta == 1:
                        title = f"Tomorrow: {localized['name']}"
                        body = f"{localized['name']} is coming tomorrow. Time to prepare!"
                    else:
                        title = f"{localized['name']} in {delta} days"
                        body = f"Get ready for {localized['name']}: {localized['suggestions'][0] if localized['suggestions'] else ''}"
                else:
                    if delta == 0:
                        title = f"今日{localized['name']}"
                        body = f"今天是{localized['name']}，{localized['suggestions'][0] if localized['suggestions'] else ''}"
                    elif delta == 1:
                        title = f"明日{localized['name']}"
                        body = f"明天就是{localized['name']}了，注意调整养生方案。"
                    else:
                        title = f"{localized['name']}还有{delta}天"
                        body = f"即将迎来{localized['name']}：{localized['suggestions'][0] if localized['suggestions'] else ''}"
                
                notifications.append({
                    "type": "solar_term",
                    "term_id": term["id"],
                    "term_name": localized["name"],
                    "title": title,
                    "body": body,
                    "days_until": delta,
                    "emoji": term.get("emoji", ""),
                    "priority": "high" if delta <= 1 else "normal",
                    "foods": localized.get("foods", []),
                    "suggestions": localized.get("suggestions", []),
                })
        except (ValueError, KeyError):
            continue
    
    notifications.sort(key=lambda x: x["days_until"])
    
    return {
        "success": True,
        "data": {
            "notifications": notifications[:5],
            "total": len(notifications),
            "has_immediate": any(n["days_until"] <= 1 for n in notifications),
        }
    }

@router.get("/enhanced/current")
async def get_enhanced_current_term():
    """获取当前节气（含倒计时和进度）"""
    return {"success": True, "data": solar_term_enhanced_service.get_current_term()}


@router.get("/enhanced/all")
async def get_all_terms_with_status(
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
):
    """获取所有节气（含当前/过去/未来状态和高亮）"""
    terms = solar_term_enhanced_service.get_all_terms_with_status(locale)
    return {"success": True, "data": {"terms": terms, "total": len(terms)}}

@router.get("/enhanced/{term_name}")
async def get_enhanced_term_detail(
    term_name: str,
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
):
    """获取节气详细养生方案（食疗/茶饮/运动/穴位/睡眠/作息）"""
    try:
        return {"success": True, "data": solar_term_enhanced_service.get_term_detail(term_name, locale)}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/{name}", response_model=dict)
async def get_solar_term(name: str, locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """获取指定节气详情"""
    term = get_solar_term_by_name(name)
    if not term:
        # Try matching by en_name
        en_match = None
        for t in SOLAR_TERMS:
            en_data = SOLAR_TERMS_EN.get(t["id"], {})
            if en_data and en_data.get("en_name", "").replace(" ", "_").lower() == name.replace(" ", "_").lower():
                en_match = t
                break
        if not en_match:
            raise HTTPException(status_code=404, detail="节气不存在" if locale == "zh-CN" else "Solar term not found")
        term = en_match
    return {"success": True, "data": _localize_term(term, locale)}


# ============ 增强功能端点 ============

