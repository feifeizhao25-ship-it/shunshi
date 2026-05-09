"""
顺时 — 食疗方剂 API
提供体质食疗配方、节气美食、功效检索与烹饪指南。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/recipes", tags=["recipes"])

# ─────────────────────────────────────────────────────────────────────────────
# 食疗方剂知识库
# ─────────────────────────────────────────────────────────────────────────────
RECIPES = [
    {
        "id": "yam_coix_porridge",
        "name": "山药薏米粥",
        "name_en": "Yam & Coix Porridge",
        "category": "粥",
        "seasons": ["spring", "summer", "autumn", "winter"],
        "constitution_types": ["qi_deficiency", "spleen_weakness", "damp"],
        "ingredients": [
            {"name": "山药", "amount": "50g", "tcm_property": "健脾益气，补脾肺肾"},
            {"name": "薏苡仁", "amount": "30g", "tcm_property": "健脾祛湿，清热排脓"},
            {"name": "粳米", "amount": "100g", "tcm_property": "补气健脾，和胃"},
            {"name": "水", "amount": "1000ml", "tcm_property": ""},
        ],
        "method": [
            "山药削皮切块，薏米提前浸泡30分钟。",
            "粳米洗净，与薏米、山药同放入砂锅。",
            "加水烧开后转小火，煮45分钟至粥成。",
            "调味可加少许冰糖或盐。",
        ],
        "benefits": ["健脾益气", "补中焦", "祛湿气", "改善疲劳"],
        "tcm_principle": "脾为后天之本，气血生化之源。山药补脾，薏米祛湿，两者相合专治脾气虚弱、湿气困重。",
        "prep_time_minutes": 50,
        "difficulty": "easy",
        "cultural_note": "四君子汤化粥，温和而有效，四季皆宜，尤宜脾虚食少者。",
    },
    {
        "id": "jujube_longan_soup",
        "name": "红枣桂圆汤",
        "name_en": "Jujube & Longan Soup",
        "category": "汤",
        "seasons": ["winter", "autumn"],
        "constitution_types": ["blood_deficiency", "qi_deficiency"],
        "ingredients": [
            {"name": "红枣", "amount": "8枚（去核）", "tcm_property": "补气养血，安神"},
            {"name": "龙眼肉", "amount": "15g", "tcm_property": "补血健脾，益心脾"},
            {"name": "冰糖", "amount": "适量", "tcm_property": "调味，润肺止咳"},
            {"name": "水", "amount": "600ml", "tcm_property": ""},
        ],
        "method": [
            "红枣洗净，龙眼肉备好。",
            "水烧开，放入红枣和龙眼肉。",
            "大火烧5分钟后转小火，煮20分钟。",
            "加冰糖调味即可。",
        ],
        "benefits": ["补血补气", "安神益心", "改善面色", "缓解失眠"],
        "tcm_principle": "红枣、龙眼皆为补血之要品，合用能补气健脾、补血安神，冬季进补之佳品。",
        "prep_time_minutes": 30,
        "difficulty": "easy",
        "cultural_note": "民间常见的冬季补血方，温暖甘甜，女性尤宜。",
    },
    {
        "id": "mung_bean_coix_soup",
        "name": "绿豆薏仁汤",
        "name_en": "Mung Bean & Coix Soup",
        "category": "汤",
        "seasons": ["summer"],
        "constitution_types": ["damp_heat", "heat"],
        "ingredients": [
            {"name": "绿豆", "amount": "50g", "tcm_property": "清热解毒，利水消肿"},
            {"name": "薏苡仁", "amount": "30g", "tcm_property": "健脾祛湿，清热排脓"},
            {"name": "冰糖", "amount": "适量", "tcm_property": "调味"},
            {"name": "水", "amount": "1000ml", "tcm_property": ""},
        ],
        "method": [
            "绿豆、薏米各洗净，薏米提前浸泡1小时。",
            "水烧开，放入绿豆和薏米。",
            "大火烧开转小火，煮60分钟至豆烂。",
            "加冰糖调味。",
        ],
        "benefits": ["清热祛湿", "利水消肿", "清热解毒", "缓解痘痘"],
        "tcm_principle": "绿豆清热解毒，薏米祛湿健脾，夏季湿热最宜。",
        "prep_time_minutes": 70,
        "difficulty": "easy",
        "cultural_note": "夏日清凉汤饮，是清热祛湿的经典方。",
    },
    {
        "id": "angelica_lamb_soup",
        "name": "当归羊肉汤",
        "name_en": "Angelica & Lamb Soup",
        "category": "汤",
        "seasons": ["winter"],
        "constitution_types": ["yang_deficiency", "qi_deficiency"],
        "ingredients": [
            {"name": "当归", "amount": "10g", "tcm_property": "补血活血，调经"},
            {"name": "羊肉", "amount": "200g", "tcm_property": "温阳补气，暖中"},
            {"name": "生姜", "amount": "5片", "tcm_property": "温中散寒"},
            {"name": "红枣", "amount": "3枚", "tcm_property": "补气养血"},
            {"name": "水", "amount": "1200ml", "tcm_property": ""},
        ],
        "method": [
            "羊肉切块，用热水焯去血沫。",
            "当归、红枣洗净，生姜切片。",
            "砂锅中加水烧开，放入羊肉、当归、生姜、红枣。",
            "大火烧开转小火，炖90分钟至肉烂。",
            "加盐调味。",
        ],
        "benefits": ["温阳补气", "补血调经", "暖中驱寒", "改善怕冷"],
        "tcm_principle": "羊肉温阳，当归补血，合用为温阳补气之要方，冬季进补首选。",
        "prep_time_minutes": 100,
        "difficulty": "medium",
        "cultural_note": "冬季进补羊肉不上火的秘诀在当归。古人云：冬吃羊肉，赛人参。",
    },
    {
        "id": "lotus_root_pork_rib_soup",
        "name": "莲藕排骨汤",
        "name_en": "Lotus Root & Pork Rib Soup",
        "category": "汤",
        "seasons": ["autumn"],
        "constitution_types": ["yin_deficiency", "dryness"],
        "ingredients": [
            {"name": "莲藕", "amount": "300g", "tcm_property": "滋阴清热，健脾益胃"},
            {"name": "猪排骨", "amount": "200g", "tcm_property": "滋阴补气"},
            {"name": "蜜枣", "amount": "3枚", "tcm_property": "补气健脾"},
            {"name": "生姜", "amount": "3片", "tcm_property": "温中和胃"},
            {"name": "水", "amount": "1500ml", "tcm_property": ""},
        ],
        "method": [
            "排骨洗净，用热水焯去血沫。",
            "莲藕削皮切段，蜜枣洗净，生姜切片。",
            "砂锅中加水烧开，放入排骨、莲藕、蜜枣、生姜。",
            "大火烧开转小火，炖120分钟。",
            "加盐调味。",
        ],
        "benefits": ["滋阴润燥", "清热健脾", "补气养血", "缓解秋燥"],
        "tcm_principle": "莲藕为秋季第一滋阴食物，搭配排骨补气，最适秋季进补。",
        "prep_time_minutes": 130,
        "difficulty": "medium",
        "cultural_note": "秋冬进补汤，清甜爽口，特别适合秋燥伤肺者。",
    },
    {
        "id": "astragalus_chicken_soup",
        "name": "黄芪鸡汤",
        "name_en": "Astragalus Chicken Soup",
        "category": "汤",
        "seasons": ["spring", "autumn", "winter"],
        "constitution_types": ["qi_deficiency", "yang_deficiency"],
        "ingredients": [
            {"name": "黄芪", "amount": "20g", "tcm_property": "补气固表，益卫气"},
            {"name": "鸡肉", "amount": "150g", "tcm_property": "补气健脾"},
            {"name": "红枣", "amount": "3枚", "tcm_property": "补气养血"},
            {"name": "生姜", "amount": "3片", "tcm_property": "温中"},
            {"name": "水", "amount": "1000ml", "tcm_property": ""},
        ],
        "method": [
            "鸡肉洗净，用热水焯去血沫。",
            "黄芪用布包裹（便于后期取出），红枣、生姜备好。",
            "砂锅中加水烧开，放入鸡肉、黄芪包、红枣、生姜。",
            "大火烧开转小火，炖60分钟。",
            "取出黄芪包，加盐调味。",
        ],
        "benefits": ["补气健脾", "益卫气固表", "增强免疫", "补气补虚"],
        "tcm_principle": "黄芪为补气第一要药，鸡肉补气健脾，长期饮用可增强体质。",
        "prep_time_minutes": 75,
        "difficulty": "easy",
        "cultural_note": "常见的四季补气方，特别适合经常感冒、体质虚弱者。",
    },
    {
        "id": "hawthorn_tangerine_peel_dish",
        "name": "山楂陈皮茶饭",
        "name_en": "Hawthorn & Tangerine Peel Rice",
        "category": "菜",
        "seasons": ["spring"],
        "constitution_types": ["blood_stasis", "qi_stagnation"],
        "ingredients": [
            {"name": "粳米", "amount": "200g", "tcm_property": "补气健脾"},
            {"name": "山楂", "amount": "8片", "tcm_property": "活血化瘀，消食"},
            {"name": "陈皮", "amount": "3g", "tcm_property": "理气健脾"},
            {"name": "冰糖", "amount": "少许", "tcm_property": "调味"},
            {"name": "水", "amount": "400ml", "tcm_property": ""},
        ],
        "method": [
            "粳米洗净，山楂切片，陈皮洗净。",
            "粳米放入砂锅，加水烧开。",
            "转小火，加入山楂片和陈皮，煮30分钟至饭成。",
            "加冰糖调味。",
        ],
        "benefits": ["活血化瘀", "消食健胃", "理气开郁", "春季调理"],
        "tcm_principle": "山楂活血化瘀，陈皮理气，春季升阳之时配合食用，最宜疏通气血。",
        "prep_time_minutes": 40,
        "difficulty": "easy",
        "cultural_note": "春季万物生发，此方帮助气血循环，为春季养生要点。",
    },
    {
        "id": "poria_lily_bulb_porridge",
        "name": "茯苓百合粥",
        "name_en": "Poria & Lily Bulb Porridge",
        "category": "粥",
        "seasons": ["summer"],
        "constitution_types": ["qi_stagnation", "damp"],
        "ingredients": [
            {"name": "茯苓", "amount": "20g", "tcm_property": "健脾祛湿"},
            {"name": "百合", "amount": "30g", "tcm_property": "润肺安神"},
            {"name": "粳米", "amount": "100g", "tcm_property": "补气"},
            {"name": "冰糖", "amount": "适量", "tcm_property": "调味"},
            {"name": "水", "amount": "1000ml", "tcm_property": ""},
        ],
        "method": [
            "茯苓、百合各洗净，粳米洗净。",
            "砂锅中加水烧开，放入粳米、茯苓、百合。",
            "大火烧开转小火，煮45分钟至粥成。",
            "加冰糖调味。",
        ],
        "benefits": ["健脾祛湿", "润肺安神", "清心降火", "改善睡眠"],
        "tcm_principle": "茯苓祛湿健脾，百合润肺安神，适合夏季湿气重、睡眠差者。",
        "prep_time_minutes": 50,
        "difficulty": "easy",
        "cultural_note": "夏季常见的健脾安神粥，特别适合失眠多梦、湿气困重者。",
    },
    {
        "id": "walnut_black_sesame_paste",
        "name": "核桃黑芝麻糊",
        "name_en": "Walnut & Black Sesame Paste",
        "category": "菜",
        "seasons": ["winter"],
        "constitution_types": ["kidney_deficiency", "blood_deficiency"],
        "ingredients": [
            {"name": "核桃仁", "amount": "50g", "tcm_property": "补肾健脑，润肠"},
            {"name": "黑芝麻", "amount": "50g", "tcm_property": "补肝肾，乌须黑发"},
            {"name": "黑米", "amount": "30g", "tcm_property": "补气补血"},
            {"name": "冰糖", "amount": "适量", "tcm_property": "调味"},
            {"name": "水", "amount": "600ml", "tcm_property": ""},
        ],
        "method": [
            "核桃、黑芝麻、黑米各洗净，沥干。",
            "放入破壁机或料理机，加水。",
            "搅打至细腻光滑的糊状。",
            "转入锅中，小火煮5分钟至略浓稠，加冰糖调味。",
        ],
        "benefits": ["补肾益脑", "补血乌发", "润肠通便", "增强记忆"],
        "tcm_principle": "核桃、黑芝麻、黑米皆为补肾之品，冬季进补，特别补肾气。",
        "prep_time_minutes": 20,
        "difficulty": "easy",
        "cultural_note": "中医有言：黑色入肾。冬季食黑色食物，补肾最直接。",
    },
    {
        "id": "bamboo_shoot_tofu_soup",
        "name": "春笋豆腐汤",
        "name_en": "Bamboo Shoot & Tofu Soup",
        "category": "汤",
        "seasons": ["spring"],
        "constitution_types": ["liver_qi_constraint", "qi_stagnation", "blood_stasis"],
        "ingredients": [
            {"name": "春笋", "amount": "100g", "tcm_property": "疏肝解郁，食疗之品"},
            {"name": "豆腐", "amount": "150g", "tcm_property": "补脾益气"},
            {"name": "木耳", "amount": "5g", "tcm_property": "活血化瘀"},
            {"name": "生姜", "amount": "2片", "tcm_property": "温中"},
            {"name": "水", "amount": "800ml", "tcm_property": ""},
        ],
        "method": [
            "春笋削皮切片，豆腐切块，木耳泡软，生姜切片。",
            "砂锅中加水烧开，放入春笋、木耳、生姜。",
            "大火烧开转小火，煮15分钟。",
            "加入豆腐，再煮10分钟。",
            "加盐调味。",
        ],
        "benefits": ["疏肝解郁", "活血化瘀", "健脾益气", "春季升阳"],
        "tcm_principle": "春笋为春季第一鲜，有疏肝之功；豆腐清淡，适合春季养生。",
        "prep_time_minutes": 30,
        "difficulty": "easy",
        "cultural_note": "春季食春笋，是传统养生智慧。春笋疏肝气，特别适合春季情绪调理。",
    },
]

# ─────────────────────────────────────────────────────────────────────────────
# 辅助查找表
# ─────────────────────────────────────────────────────────────────────────────
SEASON_RECIPES = {
    "spring": ["hawthorn_tangerine_peel_dish", "bamboo_shoot_tofu_soup", "yam_coix_porridge"],
    "summer": ["mung_bean_coix_soup", "poria_lily_bulb_porridge", "yam_coix_porridge"],
    "autumn": ["lotus_root_pork_rib_soup", "astragalus_chicken_soup", "yam_coix_porridge"],
    "winter": ["angelica_lamb_soup", "jujube_longan_soup", "astragalus_chicken_soup", "walnut_black_sesame_paste"],
}

CONSTITUTION_RECIPES = {
    "qi_deficiency":           ["yam_coix_porridge", "astragalus_chicken_soup"],
    "yang_deficiency":         ["angelica_lamb_soup", "astragalus_chicken_soup"],
    "yin_deficiency":          ["lotus_root_pork_rib_soup"],
    "blood_deficiency":        ["jujube_longan_soup", "walnut_black_sesame_paste"],
    "damp":                    ["yam_coix_porridge", "poria_lily_bulb_porridge"],
    "damp_heat":               ["mung_bean_coix_soup"],
    "qi_stagnation":           ["poria_lily_bulb_porridge", "bamboo_shoot_tofu_soup"],
    "blood_stasis":            ["hawthorn_tangerine_peel_dish", "bamboo_shoot_tofu_soup"],
    "heat":                    ["mung_bean_coix_soup"],
    "balanced":                ["yam_coix_porridge"],
    "kidney_deficiency":       ["walnut_black_sesame_paste"],
    "liver_qi_constraint":     ["bamboo_shoot_tofu_soup"],
    "spleen_weakness":         ["yam_coix_porridge"],
    "dryness":                 ["lotus_root_pork_rib_soup"],
}

CATEGORY_RECIPES = {
    "粥": ["yam_coix_porridge", "poria_lily_bulb_porridge"],
    "汤": ["jujube_longan_soup", "mung_bean_coix_soup", "angelica_lamb_soup", "lotus_root_pork_rib_soup", "astragalus_chicken_soup", "bamboo_shoot_tofu_soup"],
    "菜": ["hawthorn_tangerine_peel_dish", "walnut_black_sesame_paste"],
    "茶": [],
}

DIFFICULTY_RECIPES = {
    "easy": ["yam_coix_porridge", "jujube_longan_soup", "mung_bean_coix_soup", "astragalus_chicken_soup", "hawthorn_tangerine_peel_dish", "poria_lily_bulb_porridge", "walnut_black_sesame_paste", "bamboo_shoot_tofu_soup"],
    "medium": ["angelica_lamb_soup", "lotus_root_pork_rib_soup"],
}


def _current_season(hemisphere: str = "north") -> str:
    month = datetime.now().month
    if hemisphere == "south":
        month = (month + 6 - 1) % 12 + 1
    if month in (3, 4, 5):   return "spring"
    if month in (6, 7, 8):   return "summer"
    if month in (9, 10, 11): return "autumn"
    return "winter"


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/", summary="食疗方剂列表")
async def list_recipes(
    season: Optional[str] = Query(None, description="季节: spring/summer/autumn/winter"),
    constitution: Optional[str] = Query(None, description="体质类型"),
    category: Optional[str] = Query(None, description="分类: 粥/汤/菜/茶"),
    difficulty: Optional[str] = Query(None, description="难度: easy/medium"),
    limit: int = Query(10, ge=1, le=20),
):
    """返回食疗方剂列表，支持按季节、体质、分类、难度筛选。"""
    results = RECIPES.copy()

    if season:
        if season in SEASON_RECIPES:
            ids = SEASON_RECIPES[season]
            results = [r for r in results if r["id"] in ids]
        else:
            results = []

    if constitution:
        if constitution in CONSTITUTION_RECIPES:
            ids = CONSTITUTION_RECIPES[constitution]
            results = [r for r in results if r["id"] in ids]
        else:
            results = []

    if category:
        if category in CATEGORY_RECIPES:
            ids = CATEGORY_RECIPES[category]
            results = [r for r in results if r["id"] in ids]
        else:
            results = []

    if difficulty:
        if difficulty in DIFFICULTY_RECIPES:
            ids = DIFFICULTY_RECIPES[difficulty]
            results = [r for r in results if r["id"] in ids]
        else:
            results = []

    return {
        "success": True,
        "data": {
            "recipes": results[:limit],
            "total": len(results),
        },
    }


@router.get("/daily", summary="今日推荐食疗")
async def daily_recipes(
    hemisphere: str = Query("north", description="north | south"),
    constitution: Optional[str] = Query(None),
):
    """根据当前节气和体质，返回今日推荐的 2-3 款食疗方。"""
    season = _current_season(hemisphere)
    season_ids = SEASON_RECIPES.get(season, [])

    if constitution and constitution in CONSTITUTION_RECIPES:
        constitution_ids = CONSTITUTION_RECIPES[constitution]
        # 优先推荐交集（季节+体质双匹配）
        priority = [i for i in season_ids if i in constitution_ids]
        recommended_ids = priority if priority else season_ids
    else:
        recommended_ids = season_ids

    recipes = [r for r in RECIPES if r["id"] in recommended_ids[:3]]

    seasonal_notes = {
        "spring": "春季宜疏肝解郁、升阳举陷，食疗应以清淡、疏肝为主。",
        "summer": "夏季宜清热祛湿、调理脾胃，食疗应避免过于油腻。",
        "autumn": "秋季宜滋阴润燥、补肺气，食疗应以润肺清燥为主。",
        "winter": "冬季宜温阳补肾、进补气血，食疗应以温热补益为主。",
    }

    return {
        "success": True,
        "data": {
            "season": season,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "seasonal_note": seasonal_notes[season],
            "recommended_recipes": recipes,
            "tip": "食疗重在坚持，建议每周食用2–3次，连续4周可感受到体质改善。",
        },
    }


@router.get("/constitution/{constitution_type}", summary="体质专属食疗方案")
async def recipes_by_constitution(constitution_type: str):
    """根据体质类型返回完整的食疗调养方案。"""
    if constitution_type not in CONSTITUTION_RECIPES:
        raise HTTPException(
            status_code=404,
            detail=f"Constitution type '{constitution_type}' not found. Valid types: {list(CONSTITUTION_RECIPES.keys())}",
        )

    ids = CONSTITUTION_RECIPES[constitution_type]
    recipes = [r for r in RECIPES if r["id"] in ids]

    constitution_notes = {
        "qi_deficiency":         "气虚者宜温补，食疗以健脾益气为主，忌过度劳累。",
        "yang_deficiency":       "阳虚者怕冷，食疗应温阳扶阳，忌生冷饮食。",
        "yin_deficiency":        "阴虚者内热，食疗应滋阴清热，忌辛辣燥热。",
        "blood_deficiency":      "血虚者面色苍白，食疗应补血养血，兼补气以生血。",
        "damp":                  "痰湿者形体丰腴，食疗应健脾祛湿，忌甜腻食物。",
        "damp_heat":             "湿热者内热外湿，食疗应清热利湿，忌辛辣油腻。",
        "qi_stagnation":         "气郁者情志不畅，食疗应疏肝理气，保持愉悦心境。",
        "blood_stasis":          "血瘀者气血运行不畅，食疗应活血化瘀，注意保暖。",
        "heat":                  "热性体质者易上火，食疗应清热解毒，忌温热食物。",
        "balanced":              "平和体质者以日常保健为主，食疗顺应季节即可。",
        "kidney_deficiency":     "肾虚者易疲劳，食疗应补肾益精，特别冬季进补。",
        "liver_qi_constraint":   "肝郁者情绪易波动，食疗应疏肝解郁，调畅心境。",
        "spleen_weakness":       "脾弱者食欲差，食疗应健脾益气，以消化为先。",
        "dryness":               "燥性体质者皮肤干，食疗应滋阴润燥，秋季尤宜。",
    }

    return {
        "success": True,
        "data": {
            "constitution": constitution_type,
            "note": constitution_notes.get(constitution_type, ""),
            "recipes": recipes,
            "schedule": {
                "monday": recipes[0]["name"] if recipes else None,
                "wednesday": recipes[1]["name"] if len(recipes) > 1 else recipes[0]["name"] if recipes else None,
                "friday": recipes[2]["name"] if len(recipes) > 2 else recipes[0]["name"] if recipes else None,
                "note": "建议每周食用2–3次，连续4周可感受到体质改善。",
            },
        },
    }


@router.get("/seasonal", summary="当季特色食疗")
async def seasonal_recipes(
    hemisphere: str = Query("north", description="north | south"),
):
    """返回当前季节的特色食疗方。"""
    season = _current_season(hemisphere)
    season_ids = SEASON_RECIPES.get(season, [])
    recipes = [r for r in RECIPES if r["id"] in season_ids]

    seasonal_details = {
        "spring": {
            "theme": "春季升阳、疏肝解郁",
            "principle": "春季阳气生发，宜疏肝理气、升阳举陷。食疗应清淡易消化，助脾阳升发。",
            "caution": "春季不宜过补，易助阳而导致热象。忌油腻厚腻之物。",
        },
        "summer": {
            "theme": "夏季清热祛湿、调理脾胃",
            "principle": "夏季炎热湿重，宜清热祛湿、健脾益气。食疗应清淡清凉，但不宜过多冷饮。",
            "caution": "夏季忌过度饮冷，易伤脾阳。应温胃阳，避免腹泻。",
        },
        "autumn": {
            "theme": "秋季滋阴润燥、补肺气",
            "principle": "秋季燥气主令，宜滋阴润燥、补肺气、健脾气。食疗应以润肺清燥为主。",
            "caution": "秋季忌过度辛辣，易加重燥象。应多食滋阴润肺之品。",
        },
        "winter": {
            "theme": "冬季温阳补肾、进补气血",
            "principle": "冬季阳气潜藏，宜温阳补肾、补气养血。食疗应以温热补益为主，扶阳气。",
            "caution": "冬季进补宜循序渐进，不宜过度进补。应与适度运动相配合。",
        },
    }

    return {
        "success": True,
        "data": {
            "season": season,
            "seasonal_theme": seasonal_details[season]["theme"],
            "tcm_principle": seasonal_details[season]["principle"],
            "caution": seasonal_details[season]["caution"],
            "recipes": recipes,
            "tip": "食疗贵在坚持，应结合自身体质与季节特点，循序渐进地调理。",
        },
    }


@router.get("/{recipe_id}", summary="食疗详情")
async def get_recipe(recipe_id: str):
    """获取指定食疗方的完整信息，包含烹饪方法和中医原理。"""
    recipe = next((r for r in RECIPES if r["id"] == recipe_id), None)
    if not recipe:
        raise HTTPException(status_code=404, detail=f"Recipe '{recipe_id}' not found")
    return {"success": True, "data": recipe}
