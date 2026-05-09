"""
顺时 — 茶饮方剂 API
提供体质茶饮配方、节气茶饮、功效检索与冲泡指南。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/tea", tags=["tea"])

# ─────────────────────────────────────────────────────────────────────────────
# 茶饮方剂知识库
# ─────────────────────────────────────────────────────────────────────────────
TEA_FORMULAS = [
    {
        "id": "chrysanthemum_goji",
        "name": "菊花枸杞茶",
        "name_en": "Chrysanthemum & Goji Berry Tea",
        "ingredients": [
            {"name": "菊花", "amount": "5g", "role": "君药，清肝明目"},
            {"name": "枸杞", "amount": "10粒", "role": "臣药，滋补肝肾"},
        ],
        "benefits": ["清肝明目", "滋阴补肾", "缓解眼疲劳", "降虚火"],
        "constitution_types": ["yin_deficiency", "heat", "damp_heat"],
        "seasons": ["spring", "summer"],
        "flavor": "甘、微苦",
        "nature": "凉",
        "brewing": {
            "water_temp": "85–90°C",
            "steep_time": "3–5 分钟",
            "servings": "1杯（300ml）",
            "method": "沸水稍凉后冲泡，菊花先放，枸杞最后加入",
        },
        "best_time": "下午或傍晚，不宜空腹",
        "caution": "脾胃虚寒者少饮，经期慎用",
        "story": "菊花入肝经，秋冬之际养肝之本；枸杞补精血，滋肾阴以制虚火。两者相配，肝肾同补，为现代久视伤目者的日常茶饮首选。",
    },
    {
        "id": "rose_hawthorn",
        "name": "玫瑰山楂茶",
        "name_en": "Rose & Hawthorn Tea",
        "ingredients": [
            {"name": "玫瑰花", "amount": "5朵", "role": "君药，疏肝理气"},
            {"name": "山楂", "amount": "5片", "role": "臣药，消食化积"},
            {"name": "冰糖", "amount": "适量", "role": "调味，缓和酸性"},
        ],
        "benefits": ["疏肝解郁", "活血化瘀", "消食健胃", "调经止痛"],
        "constitution_types": ["qi_stagnation", "blood_stasis"],
        "seasons": ["spring", "autumn"],
        "flavor": "甘、酸",
        "nature": "温",
        "brewing": {
            "water_temp": "90°C",
            "steep_time": "5 分钟",
            "servings": "1杯（250ml）",
            "method": "玫瑰花与山楂同时投入，加冰糖调味",
        },
        "best_time": "饭后 30 分钟，情绪低落或胸闷时",
        "caution": "孕妇禁用（山楂活血），胃酸过多者减少山楂用量",
        "story": "玫瑰花性温，芳香怡人，为肝郁之要药；山楂酸甘，入脾胃与肝，消滞而不伤正。春秋之际，情绪多郁，此方疏肝理气，尤宜女性日常保健。",
    },
    {
        "id": "astragalus_red_date",
        "name": "黄芪红枣茶",
        "name_en": "Astragalus & Red Date Tea",
        "ingredients": [
            {"name": "黄芪", "amount": "15g", "role": "君药，补气固表"},
            {"name": "红枣", "amount": "5枚（去核）", "role": "臣药，补血养心"},
            {"name": "枸杞", "amount": "10粒", "role": "佐药，滋补肝肾"},
        ],
        "benefits": ["补气健脾", "益气固表", "补血养颜", "增强免疫"],
        "constitution_types": ["qi_deficiency", "blood_deficiency", "yang_deficiency"],
        "seasons": ["autumn", "winter"],
        "flavor": "甘",
        "nature": "温",
        "brewing": {
            "water_temp": "100°C",
            "steep_time": "10–15 分钟（需煮沸）",
            "servings": "2杯（500ml）",
            "method": "黄芪与红枣先煮沸10分钟，熄火后加入枸杞焖5分钟",
        },
        "best_time": "早晨空腹或上午，连续饮用效果更佳",
        "caution": "感冒发烧期间停用；阴虚火旺者慎用黄芪",
        "story": "黄芪为补气第一要药，主升举阳气、固护卫表；红枣补血安神；枸杞填精益髓。三者相合，气血双补，秋冬补养最宜。",
    },
    {
        "id": "lotus_heart_licorice",
        "name": "莲心甘草茶",
        "name_en": "Lotus Plumule & Licorice Tea",
        "ingredients": [
            {"name": "莲子心", "amount": "2g", "role": "君药，清心泻火"},
            {"name": "生甘草", "amount": "3g", "role": "臣药，调和诸药，解毒"},
        ],
        "benefits": ["清心降火", "宁心安神", "缓解口疮", "改善失眠"],
        "constitution_types": ["heat", "damp_heat", "yin_deficiency"],
        "seasons": ["summer"],
        "flavor": "苦、甘",
        "nature": "寒",
        "brewing": {
            "water_temp": "100°C",
            "steep_time": "5 分钟",
            "servings": "1杯（300ml）",
            "method": "直接沸水冲泡，不宜久泡（苦味加重）",
        },
        "best_time": "午后或出现心烦、口疮时",
        "caution": "脾胃虚寒者不宜，不宜长期大量饮用",
        "story": "夏季心火旺盛，易烦躁失眠、口舌生疮。莲心苦寒，直入心经，泻心火而不伤阴；甘草调和，兼清热解毒。此方简洁而效著，是夏日清心的经典小方。",
    },
    {
        "id": "ginger_brown_sugar",
        "name": "姜糖暖茶",
        "name_en": "Ginger & Brown Sugar Warming Tea",
        "ingredients": [
            {"name": "生姜", "amount": "3–5片", "role": "君药，温中散寒"},
            {"name": "红糖", "amount": "适量", "role": "臣药，补血活血，调味"},
            {"name": "大枣", "amount": "3枚", "role": "佐药，补气养血"},
        ],
        "benefits": ["温中散寒", "驱寒暖胃", "活血调经", "缓解风寒感冒初期"],
        "constitution_types": ["yang_deficiency", "blood_stasis", "qi_deficiency"],
        "seasons": ["winter", "autumn"],
        "flavor": "辛、甘",
        "nature": "热",
        "brewing": {
            "water_temp": "100°C",
            "steep_time": "10 分钟（煮沸更佳）",
            "servings": "1杯（250ml）",
            "method": "生姜切片，与红糖、红枣同煮，去渣饮汤",
        },
        "best_time": "感受风寒后即饮，或经期前后，冬日早晨",
        "caution": "阴虚火旺、内热体质者禁用；经血量多者慎用",
        "story": "姜为御寒之圣药，辛热走表而达四末；红糖温而补血，为妇科常用；大枣益气而缓中。三者合用，阳虚寒凝者饮之，如冬日阳光普照。",
    },
    {
        "id": "poria_barley",
        "name": "茯苓薏仁茶",
        "name_en": "Poria & Job's Tears Tea",
        "ingredients": [
            {"name": "茯苓", "amount": "10g", "role": "君药，健脾渗湿"},
            {"name": "薏苡仁", "amount": "15g", "role": "臣药，利水渗湿"},
            {"name": "芡实", "amount": "10g", "role": "佐药，固肾健脾"},
        ],
        "benefits": ["健脾祛湿", "利水消肿", "改善痰湿体质", "美白祛斑"],
        "constitution_types": ["damp", "damp_heat", "spleen_weakness"],
        "seasons": ["summer", "autumn"],
        "flavor": "甘、淡",
        "nature": "平",
        "brewing": {
            "water_temp": "100°C",
            "steep_time": "20–30 分钟（需浸泡后煮）",
            "servings": "2杯（500ml）",
            "method": "薏仁提前浸泡2小时，与茯苓、芡实同煮20分钟",
        },
        "best_time": "早晨代餐，或三餐间，湿气重时连饮1–2周",
        "caution": "孕妇禁用薏仁；大便干燥者减少薏仁用量",
        "story": "痰湿体质者形体多丰腴，常感困重乏力、舌苔厚腻。茯苓、薏仁为祛湿经典对药；芡实固涩以防利湿太过伤正。此方平和，长期饮用可改善痰湿体质。",
    },
    {
        "id": "mint_lemon_balm",
        "name": "薄荷柠檬草茶",
        "name_en": "Mint & Lemon Balm Tea",
        "ingredients": [
            {"name": "薄荷叶", "amount": "5g（新鲜或干燥）", "role": "君药，疏散风热，提神醒脑"},
            {"name": "柠檬草", "amount": "3g", "role": "臣药，舒缓情绪，助消化"},
        ],
        "benefits": ["提神醒脑", "疏散风热", "缓解头痛", "助消化", "舒缓情绪"],
        "constitution_types": ["qi_stagnation", "heat", "balanced"],
        "seasons": ["spring", "summer"],
        "flavor": "辛、甘",
        "nature": "凉",
        "brewing": {
            "water_temp": "85°C（不宜沸水，以保留挥发油）",
            "steep_time": "3 分钟",
            "servings": "1杯（300ml）",
            "method": "水温稍降后冲泡，加盖焖2分钟使香气充分释放",
        },
        "best_time": "下午提神，或饭后助消化",
        "caution": "气虚自汗者少饮；婴幼儿不宜饮用薄荷",
        "story": "薄荷气芳香，走窜力强，为夏季解暑提神要药；柠檬草芳香而温和，在西方草药学中广泛用于舒缓焦虑和助眠。两者相合，清凉提神而不寒凉，尤宜春夏气郁之人。",
    },
    {
        "id": "solomon_seal_mulberry",
        "name": "玉竹桑叶茶",
        "name_en": "Solomon's Seal & Mulberry Leaf Tea",
        "ingredients": [
            {"name": "玉竹", "amount": "10g", "role": "君药，滋阴润肺"},
            {"name": "桑叶", "amount": "5g", "role": "臣药，清肺润燥"},
            {"name": "冰糖", "amount": "少许", "role": "调味，增润肺之效"},
        ],
        "benefits": ["滋阴润肺", "缓解秋燥", "止咳化痰", "养颜润肤"],
        "constitution_types": ["yin_deficiency", "dryness"],
        "seasons": ["autumn"],
        "flavor": "甘",
        "nature": "平",
        "brewing": {
            "water_temp": "95°C",
            "steep_time": "8 分钟",
            "servings": "1杯（300ml）",
            "method": "玉竹浸泡15分钟后与桑叶同泡，加冰糖调味",
        },
        "best_time": "秋季每日下午，干燥气候时连续饮用",
        "caution": "脾胃虚寒、痰湿重者慎用",
        "story": "秋属金，主肺，燥为秋之主气。玉竹甘平，为滋阴润肺之上品；桑叶清宣肺燥，又能清头目。二者合用，专为秋燥伤肺、皮肤干痒、咽干咳嗽而设。",
    },
]

# ─────────────────────────────────────────────────────────────────────────────
# 辅助查找表
# ─────────────────────────────────────────────────────────────────────────────
SEASON_TEA = {
    "spring": ["rose_hawthorn", "chrysanthemum_goji", "mint_lemon_balm"],
    "summer": ["lotus_heart_licorice", "mint_lemon_balm", "poria_barley", "chrysanthemum_goji"],
    "autumn": ["astragalus_red_date", "rose_hawthorn", "poria_barley", "solomon_seal_mulberry"],
    "winter": ["astragalus_red_date", "ginger_brown_sugar"],
}

CONSTITUTION_TEA = {
    "qi_deficiency":    ["astragalus_red_date", "ginger_brown_sugar"],
    "yang_deficiency":  ["ginger_brown_sugar", "astragalus_red_date"],
    "yin_deficiency":   ["chrysanthemum_goji", "solomon_seal_mulberry", "lotus_heart_licorice"],
    "blood_deficiency": ["astragalus_red_date", "rose_hawthorn"],
    "damp":             ["poria_barley"],
    "damp_heat":        ["lotus_heart_licorice", "poria_barley", "chrysanthemum_goji"],
    "qi_stagnation":    ["rose_hawthorn", "mint_lemon_balm"],
    "blood_stasis":     ["rose_hawthorn", "ginger_brown_sugar"],
    "heat":             ["chrysanthemum_goji", "lotus_heart_licorice", "mint_lemon_balm"],
    "balanced":         ["mint_lemon_balm", "chrysanthemum_goji"],
}

BENEFIT_TEA = {
    "睡眠": ["lotus_heart_licorice", "chrysanthemum_goji"],
    "消化": ["rose_hawthorn", "mint_lemon_balm", "ginger_brown_sugar"],
    "祛湿": ["poria_barley"],
    "补气": ["astragalus_red_date"],
    "疏肝": ["rose_hawthorn", "mint_lemon_balm"],
    "润肺": ["solomon_seal_mulberry"],
    "暖胃": ["ginger_brown_sugar"],
    "明目": ["chrysanthemum_goji"],
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

@router.get("/", summary="茶饮方剂列表")
async def list_teas(
    season: Optional[str] = Query(None, description="季节: spring/summer/autumn/winter"),
    constitution: Optional[str] = Query(None, description="体质类型"),
    benefit: Optional[str] = Query(None, description="功效关键词: 睡眠/消化/祛湿/补气等"),
    limit: int = Query(6, ge=1, le=20),
):
    """返回茶饮方剂列表，支持按季节、体质、功效筛选。"""
    results = TEA_FORMULAS.copy()

    if season and season in SEASON_TEA:
        ids = SEASON_TEA[season]
        results = [t for t in results if t["id"] in ids]

    if constitution and constitution in CONSTITUTION_TEA:
        ids = CONSTITUTION_TEA[constitution]
        results = [t for t in results if t["id"] in ids]

    if benefit and benefit in BENEFIT_TEA:
        ids = BENEFIT_TEA[benefit]
        results = [t for t in results if t["id"] in ids]

    return {
        "success": True,
        "data": {
            "teas": results[:limit],
            "total": len(results),
        },
    }


@router.get("/daily", summary="今日推荐茶饮")
async def daily_tea(
    hemisphere: str = Query("north", description="north | south"),
    constitution: Optional[str] = Query(None),
):
    """根据当前节气和体质，返回今日推荐的 2 款茶饮。"""
    season = _current_season(hemisphere)
    season_ids = SEASON_TEA.get(season, [])

    if constitution and constitution in CONSTITUTION_TEA:
        constitution_ids = CONSTITUTION_TEA[constitution]
        # 优先推荐交集（季节+体质双匹配）
        priority = [i for i in season_ids if i in constitution_ids]
        recommended_ids = priority if priority else season_ids
    else:
        recommended_ids = season_ids

    teas = [t for t in TEA_FORMULAS if t["id"] in recommended_ids[:2]]

    seasonal_notes = {
        "spring": "春季肝气升发，宜疏肝理气、清热祛湿。",
        "summer": "夏季心火旺盛，宜清心降火、消暑祛湿。",
        "autumn": "秋季燥气伤肺，宜润燥滋阴、补气固表。",
        "winter": "冬季阳气潜藏，宜温阳补肾、补气养血。",
    }

    return {
        "success": True,
        "data": {
            "season": season,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "seasonal_note": seasonal_notes[season],
            "recommended_teas": teas,
            "tip": "饭后30分钟至1小时饮茶效果最佳，空腹饮茶对肠胃刺激较大。",
        },
    }


@router.get("/constitution/{constitution_type}", summary="体质专属茶饮方案")
async def tea_by_constitution(constitution_type: str):
    """根据体质类型返回完整的茶饮调养方案。"""
    if constitution_type not in CONSTITUTION_TEA:
        raise HTTPException(
            status_code=404,
            detail=f"Constitution type '{constitution_type}' not found. Valid types: {list(CONSTITUTION_TEA.keys())}",
        )

    ids = CONSTITUTION_TEA[constitution_type]
    teas = [t for t in TEA_FORMULAS if t["id"] in ids]

    constitution_notes = {
        "qi_deficiency":   "气虚者宜温补，忌寒凉。茶饮以甘温为主，补气为先。",
        "yang_deficiency": "阳虚者怕冷，宜温热茶饮，忌生冷。",
        "yin_deficiency":  "阴虚者内热，宜滋阴清热，忌辛辣燥热。",
        "blood_deficiency":"血虚者面色苍白，宜补血养心，兼补气以生血。",
        "damp":            "痰湿者形体丰腴，宜健脾祛湿，忌甜腻食物。",
        "damp_heat":       "湿热者内热外湿，宜清热利湿，忌辛辣油腻。",
        "qi_stagnation":   "气郁者情志不畅，宜疏肝理气，保持愉悦心境。",
        "blood_stasis":    "血瘀者气血运行不畅，宜活血化瘀，注意保暖。",
        "heat":            "热性体质者易上火，宜清热解毒，忌温热食物。",
        "balanced":        "平和体质者以日常保健为主，顺应季节即可。",
    }

    return {
        "success": True,
        "data": {
            "constitution": constitution_type,
            "note": constitution_notes.get(constitution_type, ""),
            "teas": teas,
            "schedule": {
                "morning": teas[0]["name"] if teas else None,
                "afternoon": teas[1]["name"] if len(teas) > 1 else teas[0]["name"] if teas else None,
                "note": "建议固定时间饮用，连续3–4周可感受到体质改善。",
            },
        },
    }


@router.get("/benefits", summary="功效查询入口")
async def list_benefits():
    """列出可按功效筛选的关键词。"""
    return {
        "success": True,
        "data": {
            "benefits": list(BENEFIT_TEA.keys()),
            "tip": "使用 GET /api/v1/tea/?benefit=<关键词> 按功效筛选茶饮。",
        },
    }


@router.get("/{tea_id}", summary="茶饮详情")
async def get_tea(tea_id: str):
    """获取指定茶饮方剂的完整信息，包含冲泡指南和文化背景。"""
    tea = next((t for t in TEA_FORMULAS if t["id"] == tea_id), None)
    if not tea:
        raise HTTPException(status_code=404, detail=f"Tea formula '{tea_id}' not found")
    return {"success": True, "data": tea}
