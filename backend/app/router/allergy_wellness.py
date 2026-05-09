"""
顺时 — 季节性过敏TCM预防与调节 API
提供过敏日历、类型调养、预防性调理、急性缓解
"""

from fastapi import APIRouter, HTTPException, Query
from datetime import datetime

router = APIRouter(prefix="/api/v1/allergy", tags=["allergy_seasonal"])


# ─────────────────────────────────────────────────────────────────────────────
# 过敏日历与数据
# ─────────────────────────────────────────────────────────────────────────────

ALLERGY_CALENDAR = {
    1: {
        "month": "1月",
        "season": "冬末春初",
        "allergens": ["尘螨", "室内霉菌", "宠物皮毛"],
        "risk_level": "低",
        "description": "冬季室内污染物积累，尘螨活跃。",
    },
    2: {
        "month": "2月",
        "season": "早春",
        "allergens": ["柏树花粉", "杨树花粉"],
        "risk_level": "中",
        "description": "春季开始，树木花粉开始释放。",
    },
    3: {
        "month": "3月",
        "season": "春季",
        "allergens": ["柏树花粉", "桦树花粉", "杨树花粉"],
        "risk_level": "高",
        "description": "春季花粉浓度最高的时段。",
    },
    4: {
        "month": "4月",
        "season": "春季",
        "allergens": ["桦树花粉", "杨树花粉", "榆树花粉"],
        "risk_level": "高",
        "description": "春季花粉仍然浓度较高。",
    },
    5: {
        "month": "5月",
        "season": "晚春初夏",
        "allergens": ["草类花粉", "牧草花粉"],
        "risk_level": "中",
        "description": "树木花粉减少，草类花粉增加。",
    },
    6: {
        "month": "6月",
        "season": "初夏",
        "allergens": ["草类花粉", "牧草花粉"],
        "risk_level": "中",
        "description": "草类花粉高峰期。",
    },
    7: {
        "month": "7月",
        "season": "盛夏",
        "allergens": ["草类花粉", "牧草花粉", "尘螨"],
        "risk_level": "中",
        "description": "高温潮湿，尘螨活跃增加。",
    },
    8: {
        "month": "8月",
        "season": "夏末秋初",
        "allergens": ["杂草花粉", "艾蒿花粉", "豚草花粉"],
        "risk_level": "中",
        "description": "杂草花粉开始增加。",
    },
    9: {
        "month": "9月",
        "season": "秋季",
        "allergens": ["杂草花粉", "艾蒿花粉", "豚草花粉"],
        "risk_level": "高",
        "description": "秋季杂草花粉高峰期，易诱发过敏。",
    },
    10: {
        "month": "10月",
        "season": "秋季",
        "allergens": ["杂草花粉", "艾蒿花粉"],
        "risk_level": "中",
        "description": "花粉浓度逐渐下降。",
    },
    11: {
        "month": "11月",
        "season": "晚秋冬初",
        "allergens": ["尘螨", "室内霉菌"],
        "risk_level": "低",
        "description": "花粉减少，室内污染物增加。",
    },
    12: {
        "month": "12月",
        "season": "冬季",
        "allergens": ["尘螨", "室内霉菌", "宠物皮毛"],
        "risk_level": "低",
        "description": "冬季室内环境污染。",
    },
}

# 过敏类型的TCM调养方案
ALLERGY_TYPES = {
    "pollen": {
        "id": "pollen",
        "name": "花粉过敏 (Pollen Allergy)",
        "tcm_theory": "中医认为过敏属于'特禀质'和'肺卫不固'。花粉过敏需要宣肺疏风，增强体表防御。",
        "tcm_pattern": "宣肺疏风，益气固表",
        "symptoms": "打喷嚏、流鼻涕、鼻痒、眼痒、咳嗽",
        "food_therapy": [
            {"name": "黄芪炖鸡", "description": "增强肺卫功能，预防花粉入侵"},
            {"name": "蜂蜜柚子茶", "description": "润肺化痰，增强呼吸道抵抗力"},
            {"name": "薏米红豆粥", "description": "祛湿健脾，改善体质"},
            {"name": "冬虫夏草炖瘦肉", "description": "补肺气，增强免疫功能"},
        ],
        "acupoints": [
            {"point": "迎香穴(LI20)", "effect": "通鼻窍，缓解鼻痒"},
            {"point": "肺俞穴(BL13)", "effect": "宣肺祛风，增强肺功能"},
            {"point": "风门穴(BL12)", "effect": "祛风，预防外邪入侵"},
        ],
        "herbal_warning": "辛夷花和苍耳子有毒性，需在专业医生指导下使用，不可自行大量服用。",
    },
    "dust_mite": {
        "id": "dust_mite",
        "name": "尘螨过敏 (Dust Mite Allergy)",
        "tcm_theory": "尘螨过敏主要与脾胃功能和体内湿气有关。健脾化湿能从根本上改善。",
        "tcm_pattern": "健脾化湿，祛除体内湿气",
        "symptoms": "打喷嚏、流鼻涕、皮肤瘙痒、哮喘加重",
        "food_therapy": [
            {"name": "薏米红豆粥", "description": "祛湿，改善过敏体质"},
            {"name": "冬瓜海带汤", "description": "清热利水，减少湿气"},
            {"name": "山楂麦芽粥", "description": "健脾消食，改善脾胃功能"},
            {"name": "绿豆薏米粥", "description": "清热祛湿，适合湿热体质"},
        ],
        "acupoints": [
            {"point": "脾俞穴(BL20)", "effect": "健脾利湿，增强脾功能"},
            {"point": "足三里(ST36)", "effect": "补气健脾，增强免疫力"},
            {"point": "三阴交(SP6)", "effect": "调理脾胃，改善湿气"},
        ],
        "lifestyle": "保持室内干燥，定期清洁床品，使用除湿机。",
    },
    "food": {
        "id": "food",
        "name": "食物过敏 (Food Allergy)",
        "tcm_theory": "食物过敏多源于脾胃功能失调和消化能力减弱。调理脾胃是根本之策。",
        "tcm_pattern": "调理脾胃，增强消化功能，识别敏感体质",
        "symptoms": "口腔瘙痒、咽喉肿胀、腹泻、皮肤荨麻疹",
        "food_therapy": [
            {"name": "黄芪红枣粥", "description": "补脾气，增强消化能力"},
            {"name": "山药薏米粥", "description": "健脾益气，改善消化"},
            {"name": "红糖生姜茶", "description": "温中健脾，促进消化"},
            {"name": "南瓜粥", "description": "温中补气，易于消化"},
        ],
        "acupoints": [
            {"point": "脾俞穴(BL20)", "effect": "调理脾胃，增强消化功能"},
            {"point": "足三里(ST36)", "effect": "增强脾胃功能，改善消化"},
            {"point": "胃俞穴(BL21)", "effect": "调理胃功能，减少不适"},
        ],
        "avoid_foods": "常见致敏食物：海鲜、坚果、鸡蛋、牛奶、花生、芒果等。需根据个人体质辨识。",
    },
    "skin": {
        "id": "skin",
        "name": "皮肤过敏 (Skin Allergy)",
        "tcm_theory": "皮肤过敏多因肺卫不固、血热、湿热引起。需清热凉血，内外兼治。",
        "tcm_pattern": "清热凉血，滋阴润肺，外用和内服结合",
        "symptoms": "皮肤瘙痒、红肿、荨麻疹、湿疹",
        "food_therapy": [
            {"name": "绿豆薏米粥", "description": "清热祛湿，缓解皮肤炎症"},
            {"name": "百合银耳汤", "description": "滋阴润肺，舒缓皮肤"},
            {"name": "冬瓜薏米粥", "description": "清热利水，改善皮肤状况"},
            {"name": "黑木耳粥", "description": "清肺热，改善皮肤代谢"},
        ],
        "acupoints": [
            {"point": "曲池穴(LI11)", "effect": "清热，缓解皮肤瘙痒"},
            {"point": "血海穴(SP10)", "effect": "活血化瘀，改善皮肤"},
            {"point": "膈俞(BL17)", "effect": "调理血液功能，缓解皮肤过敏"},
        ],
        "external_treatment": "可外敷金银花、芦荟等清热物质，但需避免过度烫洗。",
    },
}

# 预防性调理方案（玉屏风散为核心）
PREVENTION_PLAN = {
    "stage_1": {
        "stage": "第1阶段（4周前开始）",
        "duration": "4周",
        "objective": "增强体表防御，补气固表",
        "core_formula": "玉屏风散（黄芪、白术、防风）",
        "food_therapy": [
            "黄芪炖鸡：每周2-3次，补气增强抵抗力",
            "山药粥：每天可食，健脾益气",
        ],
        "acupoints": ["足三里(ST36)", "三阴交(SP6)", "脾俞(BL20)"],
        "lifestyle": "规律作息，避免过度疲劳，为花粉季做准备。",
    },
    "stage_2": {
        "stage": "第2阶段（过敏季开始前1-2周）",
        "duration": "1-2周",
        "objective": "加强疏风驱邪功能",
        "core_formula": "玉屏风散加减（增加疏风药物）",
        "food_therapy": [
            "黄芪红枣茶：每天1杯，持续增强抵抗力",
            "冬虫夏草粥：每周1-2次，补肺气",
        ],
        "acupoints": ["风门穴(BL12)", "肺俞穴(BL13)"],
        "lifestyle": "减少外出时间，使用空气净化器，准备防护措施。",
    },
    "stage_3": {
        "stage": "第3阶段（过敏季期间）",
        "duration": "持续至过敏季结束",
        "objective": "维持防御，随时应对",
        "core_formula": "玉屏风散维持+按需调理",
        "food_therapy": [
            "黄芪粥：每天食用，持续增强体表防御",
            "蜂蜜柚子茶：缓解呼吸道症状",
        ],
        "acupoints": ["迎香穴(LI20)", "足三里(ST36)"],
        "lifestyle": "监测症状，及时调整，做好防护。",
    },
}

# 急性发作即时缓解方案
ACUTE_RELIEF = {
    "acupoint_techniques": [
        {
            "point": "迎香穴(LI20)",
            "location": "鼻翼外缘，法令纹上方",
            "technique": "轻轻按压或揉搓1-2分钟，每天3-4次",
            "effect": "立即通鼻窍，缓解鼻痒和流鼻涕",
        },
        {
            "point": "合谷穴(LI4)",
            "location": "虎口中央，拇指和食指骨交点",
            "technique": "深按1-2分钟，每天3-4次",
            "effect": "疏风解毒，增强免疫功能",
        },
        {
            "point": "印堂穴(EX-HN3)",
            "location": "眉间正中",
            "technique": "轻柔按摩1-2分钟，每天2-3次",
            "effect": "缓解眼睛瘙痒和头昏",
        },
    ],
    "food_relief": [
        {"name": "生姜蜂蜜水", "effect": "温中疏风，缓解症状"},
        {"name": "薄荷茶", "effect": "清热疏风，舒缓症状"},
        {"name": "红枣粥", "effect": "补气增强体质"},
    ],
    "precautions": [
        "避免冷热刺激，不要冷水洗脸",
        "少吃辛辣刺激食物",
        "避免长时间在高浓度花粉环境中",
        "使用生理盐水冲洗鼻腔，缓解鼻痒",
        "如症状严重或持续，请就医",
    ],
}


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/calendar", summary="全年过敏日历")
async def get_allergy_calendar():
    """返回全年12个月的过敏日历，含主要过敏原和风险等级。"""
    calendar_list = []
    for month in range(1, 13):
        calendar_list.append({
            "month": month,
            **ALLERGY_CALENDAR[month],
        })

    return {
        "success": True,
        "data": {
            "calendar": calendar_list,
            "total_months": 12,
        },
    }


@router.get("/types", summary="过敏类型列表")
async def get_allergy_types():
    """返回所有支持的过敏类型。"""
    types_list = []
    for allergy_id, allergy_data in ALLERGY_TYPES.items():
        types_list.append({
            "id": allergy_id,
            "name": allergy_data["name"],
            "tcm_pattern": allergy_data["tcm_pattern"],
        })

    return {
        "success": True,
        "data": {
            "types": types_list,
            "total": len(types_list),
        },
    }


@router.get("/types/{allergy_type}", summary="指定过敏类型的TCM调养方案")
async def get_allergy_type_detail(allergy_type: str):
    """获取指定过敏类型的详细TCM调养方案。"""
    if allergy_type not in ALLERGY_TYPES:
        raise HTTPException(
            status_code=404,
            detail=f"Allergy type '{allergy_type}' not found. Valid: {list(ALLERGY_TYPES.keys())}",
        )

    allergy = ALLERGY_TYPES[allergy_type]
    return {
        "success": True,
        "data": allergy,
    }


@router.get("/prevention-plan", summary="预防性调理方案")
async def get_prevention_plan(weeks_before: int = Query(4, ge=2, le=8, description="预防周期（周）")):
    """返回预防性调理方案，支持自定义预防周期。"""
    # 标准预防方案（4周）
    plan_stages = [
        PREVENTION_PLAN["stage_1"],
        PREVENTION_PLAN["stage_2"],
        PREVENTION_PLAN["stage_3"],
    ]

    # 如果周期不是4周，进行调整提示
    if weeks_before != 4:
        adjustment_note = f"已根据{weeks_before}周周期调整方案。建议最少提前2周开始预防。"
    else:
        adjustment_note = None

    return {
        "success": True,
        "data": {
            "prevention_stages": plan_stages,
            "weeks_before": weeks_before,
            "total_stages": len(plan_stages),
            "core_principle": "玉屏风散理论：黄芪补气固表，白术健脾祛湿，防风疏风驱邪。",
            "adjustment_note": adjustment_note,
        },
    }


@router.get("/acute-relief", summary="急性发作即时缓解方案")
async def get_acute_relief():
    """返回过敏急性发作时的即时缓解方案。"""
    return {
        "success": True,
        "data": ACUTE_RELIEF,
    }


@router.get("/current-risk", summary="当前月份的过敏风险")
async def get_current_risk():
    """基于系统当前日期，返回当月的过敏风险等级和主要过敏原。"""
    current_month = datetime.now().month
    current_data = ALLERGY_CALENDAR.get(current_month)

    if not current_data:
        raise HTTPException(
            status_code=500,
            detail="Unable to determine current month",
        )

    return {
        "success": True,
        "data": {
            "current_month": current_month,
            "month_name": current_data["month"],
            "season": current_data["season"],
            "allergens": current_data["allergens"],
            "risk_level": current_data["risk_level"],
            "description": current_data["description"],
            "recommendation": (
                "建议采取预防措施" if current_data["risk_level"] in ["中", "高"]
                else "过敏风险较低，但仍需注意日常防护"
            ),
        },
    }
