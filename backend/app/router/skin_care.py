"""
顺时 — 护肤养颜 API (shunshi-skin-care)
中医护肤方案、体质护肤、节气护肤
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/skin-care", tags=["skin-care"])

CONSTITUTION_SKIN_CARE = {
    "balanced": {
        "skin_type": "平和", "description": "皮肤光滑有弹性",
        "care": "维持日常清洁保湿，注意防晒",
        "diet": ["均衡饮食", "多吃新鲜蔬菜水果"],
        "avoid": ["熬夜", "过度化妆"]
    },
    "qi_deficiency": {
        "skin_type": "气虚", "description": "面色萎黄，皮肤缺乏弹性光泽",
        "care": "注重补气养血，加强保湿，避免过度清洁",
        "diet": ["黄芪", "红枣", "山药", "小米"],
        "avoid": ["过劳", "生冷食物"]
    },
    "yin_deficiency": {
        "skin_type": "阴虚", "description": "皮肤干燥，容易起皱纹",
        "care": "重点保湿滋润，使用油脂性护肤品，避免去角质过度",
        "diet": ["银耳", "百合", "莲子", "蜂蜜", "冰糖"],
        "avoid": ["辛辣", "熬夜", "长期处于干燥环境"]
    },
    "yang_deficiency": {
        "skin_type": "阳虚", "description": "面色苍白，皮肤不红润",
        "care": "温补阳气，注意保暖，可用温热面膜",
        "diet": ["姜", "葱", "羊肉", "核桃"],
        "avoid": ["生冷食物", "受寒"]
    },
    "damp_heat": {
        "skin_type": "湿热", "description": "面部油腻，容易长痤疮",
        "care": "清热祛湿，控油为主，注意清洁但不过度",
        "diet": ["薏米", "绿豆", "苦瓜", "冬瓜"],
        "avoid": ["油腻甜食", "辛辣", "酒精"]
    },
    "blood_stasis": {
        "skin_type": "血瘀", "description": "面色晦暗，有色素沉着",
        "care": "活血化瘀，可用红花、当归等泡浴",
        "diet": ["山楂", "玫瑰花茶", "黑木耳", "红糖"],
        "avoid": ["熬夜", "久坐不动"]
    }
}

SEASONAL_SKIN_CARE = {
    "spring": {
        "season": "春季",
        "characteristics": "气温升高，皮肤开始分泌皮脂，但湿度低",
        "focus": "保湿 + 防敏",
        "tips": ["换用轻盈保湿产品", "防花粉过敏", "防晒SPF30+", "温和清洁"],
        "tcm_tip": "春季肝气升发，可能导致皮肤油脂分泌增加，饮玫瑰花茶疏肝调肤"
    },
    "summer": {
        "season": "夏季",
        "characteristics": "高温出汗多，皮脂分泌旺盛，紫外线强",
        "focus": "控油 + 防晒",
        "tips": ["轻薄无油保湿", "防晒SPF50+", "及时补充水分", "清爽洁面"],
        "tcm_tip": "夏季心火旺，可能影响皮肤，宜清心降火，多食苦味食物"
    },
    "autumn": {
        "season": "秋季",
        "characteristics": "湿度下降，皮肤开始干燥",
        "focus": "保湿 + 修复",
        "tips": ["切换保湿滋润产品", "去角质不宜过频", "补充维生素E", "室内加湿"],
        "tcm_tip": "秋季燥邪伤肺，肺主皮毛，润肺就是护肤，多吃梨、银耳"
    },
    "winter": {
        "season": "冬季",
        "characteristics": "严寒干燥，皮肤容易龟裂",
        "focus": "滋润 + 防干裂",
        "tips": ["使用滋润面霜", "注意手部和嘴唇防护", "不宜用过热水洗脸", "室内保湿"],
        "tcm_tip": "冬季肾气闭藏，宜温补，黑色食物补肾养肤"
    }
}

SKIN_BRIGHTENING_RECIPES = [
    {
        "name": "白茯苓面膜",
        "ingredients": ["白茯苓粉10g", "蜂蜜1茶匙", "牛奶适量"],
        "method": "混合调成糊状，敷面15分钟，用温水洗净",
        "benefit": "淡斑美白，改善肤色",
        "frequency": "每周2次"
    },
    {
        "name": "珍珠粉面膜",
        "ingredients": ["珍珠粉3g", "蜂蜜1茶匙"],
        "method": "混合均匀，敷面10分钟",
        "benefit": "美白亮肤，细腻毛孔",
        "frequency": "每周1-2次"
    },
    {
        "name": "红枣枸杞内调汤",
        "ingredients": ["红枣5颗", "枸杞15g", "当归5g"],
        "method": "水煎30分钟饮用",
        "benefit": "补血养颜，从内改善面色",
        "frequency": "每日1次"
    }
]


@router.get("/constitution-care", summary="体质护肤方案")
async def get_constitution_care(constitution: Optional[str] = Query(None)):
    if constitution:
        care = CONSTITUTION_SKIN_CARE.get(constitution)
        if not care:
            from fastapi import HTTPException
            raise HTTPException(status_code=404, detail="体质类型不存在")
        return {"success": True, "data": {"constitution": constitution, "care": care}}
    return {"success": True, "data": {"constitutions": CONSTITUTION_SKIN_CARE}}


@router.get("/seasonal-care", summary="四季护肤方案")
async def get_seasonal_care(season: Optional[str] = Query(None)):
    if season:
        care = SEASONAL_SKIN_CARE.get(season)
        if not care:
            from fastapi import HTTPException
            raise HTTPException(status_code=404, detail="季节参数无效")
        return {"success": True, "data": care}
    return {"success": True, "data": {"seasonal_care": SEASONAL_SKIN_CARE}}


@router.get("/brightening-recipes", summary="美白亮肤食疗方")
async def get_brightening_recipes():
    return {"success": True, "data": {"recipes": SKIN_BRIGHTENING_RECIPES}}


@router.get("/daily-routine", summary="每日护肤步骤")
async def get_daily_routine():
    routine = {
        "morning": [
            "温水洁面（避免过热）",
            "化妆水补水",
            "精华液",
            "保湿乳霜",
            "防晒（SPF30+）"
        ],
        "evening": [
            "卸妆（有妆容）",
            "温和洁面",
            "化妆水/爽肤水",
            "精华液（重点修护）",
            "晚霜（可比日霜更滋润）"
        ],
        "weekly": [
            "深层清洁1-2次",
            "面膜1-2次（根据肤质选择）",
            "去角质（干性每2周一次，油性每周一次）"
        ]
    }
    return {"success": True, "data": {"routine": routine}}
