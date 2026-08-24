"""
顺时 — 中医食材安全与营养 API
提供食材安全指导、食物相克检测、季节选购建议。
"""

from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/food-safety", tags=["tcm_food_safety"])

FOOD_PAIRING_EVIDENCE = {
    "reviewed_at": "2026-08-24",
    "conclusion": "营养学中没有普遍成立的‘食物相克’；应关注过敏、变质、食用量和个人疾病限制。",
    "sources": [
        {"title": "关于螃蟹的流言 几分真假？", "publisher": "陕西省卫生健康委员会", "url": "https://sxwjw.shaanxi.gov.cn/ywgz/gbbj/202012/t20201214_2145555.html"},
        {"title": "柿子不能和鱼、虾、蟹、牛奶等同食？", "publisher": "广州市健康科普信息平台（来源：中国疾控中心）", "url": "https://kepu.wjw.gz.gov.cn/zs/content/post_4812.html"},
    ],
}


# ─────────────────────────────────────────────────────────────────────────────
# Pydantic 请求模型
# ─────────────────────────────────────────────────────────────────────────────

class FoodCompatCheckRequest(BaseModel):
    """食材相克检查请求"""
    food1: str = Field(..., min_length=1, max_length=50, description="第一种食材名称或ID")
    food2: str = Field(..., min_length=1, max_length=50, description="第二种食材名称或ID")

# ─────────────────────────────────────────────────────────────────────────────
# 食材知识库（20种常见食材）
# ─────────────────────────────────────────────────────────────────────────────
FOODS = [
    {
        "id": "spinach",
        "name": "菠菜",
        "season_best": "春冬",
        "storage_tips": "冷藏4-5°C，湿润环境，3-5天内食用",
        "washing_tips": "逐叶冲洗，去除泥沙，不宜长时间浸泡",
        "tcm_property": "凉",
        "common_combinations_safe": ["鸡蛋", "黑芝麻", "红糖"],
        "forbidden_combinations": [
            {"food": "豆腐", "reason": "菠菜含草酸与豆腐钙易形成草酸钙结石", "severity": "warning"},
        ],
        "residue_risk": "medium",
        "selection_tips": "叶片深绿有光泽，茎不软不黄，根部鲜红为上品",
    },
    {
        "id": "tofu",
        "name": "豆腐",
        "season_best": "全年",
        "storage_tips": "冷藏保存，盛于清水中，每日换水，5天内食用",
        "washing_tips": "轻轻冲洗，勿浸泡过久免吸水过多",
        "tcm_property": "凉",
        "common_combinations_safe": ["鸡蛋", "海带", "萝卜"],
        "forbidden_combinations": [
            {"food": "菠菜", "reason": "草酸钙易形成结石", "severity": "warning"},
            {"food": "竹笋", "reason": "同食影响钙吸收", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "色泽洁白有光泽，无异味，含水量适中为佳",
    },
    {
        "id": "sweet_potato",
        "name": "红薯",
        "season_best": "秋冬",
        "storage_tips": "通风干燥处，温度12-15°C，可保存2-3个月",
        "washing_tips": "清水冲洗表面泥沙，去除腐烂部分",
        "tcm_property": "温",
        "common_combinations_safe": ["红糖", "蜂蜜", "粳米"],
        "forbidden_combinations": [
            {"food": "柿子", "reason": "易致腹胀、结石，宜间隔2小时以上", "severity": "danger"},
        ],
        "residue_risk": "low",
        "selection_tips": "外皮光滑无破损，掂量结实为佳，避免过软",
    },
    {
        "id": "white_radish",
        "name": "白萝卜",
        "season_best": "秋冬",
        "storage_tips": "冷藏4-5°C，可保存1-2周，去除绿叶后存放",
        "washing_tips": "冷水冲洗，泥沙易嵌入须仔细",
        "tcm_property": "凉",
        "common_combinations_safe": ["蜂蜜", "生姜", "冰糖"],
        "forbidden_combinations": [
            {"food": "人参", "reason": "萝卜性凉，人参补气，易相克", "severity": "warning"},
        ],
        "residue_risk": "medium",
        "selection_tips": "根部圆润，表皮光滑，掂量沉手为佳",
    },
    {
        "id": "ginger",
        "name": "生姜",
        "season_best": "夏秋",
        "storage_tips": "阴凉通风处，5-10°C保存，可放3-4个月",
        "washing_tips": "轻轻刷洗，清除泥沙，需要可去皮",
        "tcm_property": "温",
        "common_combinations_safe": ["蜂蜜", "红糖", "大枣"],
        "forbidden_combinations": [
            {"food": "兔肉", "reason": "同食易导致腹泻", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "肉质紧实，皮薄黄亮，味道清香为上品",
    },
    {
        "id": "garlic",
        "name": "大蒜",
        "season_best": "春夏",
        "storage_tips": "通风干燥处，室温保存，可放4-5个月",
        "washing_tips": "去除外皮即可，勿浸水",
        "tcm_property": "温",
        "common_combinations_safe": ["鸡蛋", "牛奶", "蜂蜜"],
        "forbidden_combinations": [
            {"food": "蜂蜜", "reason": "二者性质相反，易腹泻", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "蒜头紧实，皮薄白亮，无软烂点为佳",
    },
    {
        "id": "honey",
        "name": "蜂蜜",
        "season_best": "全年",
        "storage_tips": "密封阴凉处，避免阳光直射，常温可保存数年",
        "washing_tips": "勿洗，直接取用",
        "tcm_property": "平",
        "common_combinations_safe": ["白萝卜", "生姜", "柠檬"],
        "forbidden_combinations": [
            {"food": "豆腐", "reason": "蜂蜜含物质与豆腐成分相克", "severity": "warning"},
            {"food": "大蒜", "reason": "性质相反，易腹泻", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "色泽清亮，结晶细腻，香气纯正为佳",
    },
    {
        "id": "milk",
        "name": "牛奶",
        "season_best": "全年",
        "storage_tips": "冷藏2-8°C，开启后3天内饮用",
        "washing_tips": "勿洗，密封保存",
        "tcm_property": "平",
        "common_combinations_safe": ["蜂蜜", "红糖", "核桃"],
        "forbidden_combinations": [
            {"food": "浓茶", "reason": "茶多酚与蛋白质结合，降低吸收", "severity": "warning"},
            {"food": "柿子", "reason": "易形成消化不良", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "冷链完整，生产日期新鲜，无异味",
    },
    {
        "id": "egg",
        "name": "鸡蛋",
        "season_best": "全年",
        "storage_tips": "冷藏4-8°C，竖放避免蛋液泄漏，2-3周内食用",
        "washing_tips": "轻轻冲洗或干布擦拭，勿浸泡",
        "tcm_property": "平",
        "common_combinations_safe": ["蜂蜜", "豆浆", "番茄"],
        "forbidden_combinations": [
            {"food": "豆浆", "reason": "豆浆含物质与蛋白相克，影响吸收", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "蛋壳光洁，拿起时无异响，沉重感适中",
    },
    {
        "id": "crab",
        "name": "螃蟹",
        "season_best": "秋冬",
        "storage_tips": "冷藏5°C左右，活蟹可保存3-5天，死蟹勿食",
        "washing_tips": "用刷子刷洗背腹及爪缝，清除泥沙和细菌",
        "tcm_property": "凉",
        "common_combinations_safe": ["生姜", "紫苏", "黄酒"],
        "forbidden_combinations": [
            {"food": "柿子", "reason": "柿子鞣酸与螃蟹蛋白结合，致消化不良", "severity": "danger"},
            {"food": "西红柿", "reason": "易形成结石", "severity": "warning"},
        ],
        "residue_risk": "medium",
        "selection_tips": "壳硬有光泽，腹部呈褐色，活力旺盛为佳",
    },
    {
        "id": "shrimp",
        "name": "虾",
        "season_best": "秋冬",
        "storage_tips": "冷藏2-8°C或冷冻-18°C以下，活虾3-5天内食用",
        "washing_tips": "清水冲洗，去除背部黑线",
        "tcm_property": "温",
        "common_combinations_safe": ["豆腐", "冬瓜", "黄酒"],
        "forbidden_combinations": [
            {"food": "维生素C高食物", "reason": "易产生砒霜毒性（仅指大剂量高含量情况）", "severity": "warning"},
        ],
        "residue_risk": "medium",
        "selection_tips": "壳硬身挺，腹部弯曲，无黑斑为佳",
    },
    {
        "id": "pork",
        "name": "猪肉",
        "season_best": "全年",
        "storage_tips": "冷藏3-5°C可保3-5天，冷冻-18°C可保数月",
        "washing_tips": "冷水轻轻冲洗，勿长时间浸泡",
        "tcm_property": "平",
        "common_combinations_safe": ["黄豆", "冬瓜", "海带"],
        "forbidden_combinations": [
            {"food": "鸭肉", "reason": "同食会导致脾胃不适", "severity": "warning"},
        ],
        "residue_risk": "medium",
        "selection_tips": "色泽淡粉红，肉质紧实，无腥臭味为佳",
    },
    {
        "id": "lamb",
        "name": "羊肉",
        "season_best": "秋冬",
        "storage_tips": "冷藏3-5°C保存3-5天，冷冻-18°C可保数月",
        "washing_tips": "冷水冲洗，可用少量醋浸泡去膻",
        "tcm_property": "温",
        "common_combinations_safe": ["萝卜", "生姜", "黄酒"],
        "forbidden_combinations": [
            {"food": "西瓜", "reason": "一热一凉，易伤脾胃", "severity": "warning"},
            {"food": "醋", "reason": "同食会降低营养价值", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "肉色鲜红，肉质细腻，无腥臭为佳",
    },
    {
        "id": "green_tea",
        "name": "绿茶",
        "season_best": "春夏",
        "storage_tips": "密封冷藏或常温阴凉处，避免受潮受光，6-12个月内饮用",
        "washing_tips": "勿洗，直接冲泡",
        "tcm_property": "凉",
        "common_combinations_safe": ["蜂蜜", "柠檬", "薄荷"],
        "forbidden_combinations": [
            {"food": "牛奶", "reason": "茶多酚与蛋白结合降低吸收", "severity": "warning"},
            {"food": "鸡蛋", "reason": "同食影响营养吸收", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "条索紧实有光泽，香气鲜活，色泽翠绿为佳",
    },
    {
        "id": "black_tea",
        "name": "红茶",
        "season_best": "秋冬",
        "storage_tips": "密封阴凉处，避免受潮，可保存1-2年",
        "washing_tips": "勿洗，直接冲泡",
        "tcm_property": "温",
        "common_combinations_safe": ["蜂蜜", "牛奶", "红糖"],
        "forbidden_combinations": [
            {"food": "药物", "reason": "茶多酚可能降低某些药物疗效", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "条索乌润，香气浓郁，汤色红亮为佳",
    },
    {
        "id": "bitter_melon",
        "name": "苦瓜",
        "season_best": "夏季",
        "storage_tips": "冷藏4-8°C，可保存1-2周",
        "washing_tips": "清水冲洗，可轻轻刷洗表面",
        "tcm_property": "凉",
        "common_combinations_safe": ["猪肉", "黄豆", "冬瓜"],
        "forbidden_combinations": [
            {"food": "豆浆", "reason": "易导致腹胀消化不良", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "颗粒饱满突起，色泽翠绿，无软点为佳",
    },
    {
        "id": "lotus_root",
        "name": "莲藕",
        "season_best": "秋冬",
        "storage_tips": "冷藏4-8°C，用湿纸包裹，可保存1-2周",
        "washing_tips": "冷水冲洗，用软刷轻轻刷洗，去除淤泥",
        "tcm_property": "凉",
        "common_combinations_safe": ["红糖", "黄酒", "排骨"],
        "forbidden_combinations": [
            {"food": "鹿茸", "reason": "性质相反易相克", "severity": "warning"},
        ],
        "residue_risk": "medium",
        "selection_tips": "节段短圆润，皮肤光滑，掂量沉手为佳",
    },
    {
        "id": "chinese_yam",
        "name": "山药",
        "season_best": "秋冬",
        "storage_tips": "通风干燥处，温度10-15°C，可保存1-2个月",
        "washing_tips": "轻轻冲洗泥沙，可用刷子轻刷，去皮前可浸水软化",
        "tcm_property": "平",
        "common_combinations_safe": ["红枣", "蜂蜜", "粳米"],
        "forbidden_combinations": [
            {"food": "碱性物质", "reason": "会破坏山药营养成分", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "外形直，皮肤光滑无伤痕，断面洁白细腻为佳",
    },
    {
        "id": "black_fungus",
        "name": "黑木耳",
        "season_best": "全年",
        "storage_tips": "干制状态常温干燥处保存，可保存数月；发泡后冷藏2-3天",
        "washing_tips": "冷水浸泡30分钟至软，逐个清洗去杂质，勿长时间泡水",
        "tcm_property": "平",
        "common_combinations_safe": ["红枣", "红糖", "豆腐"],
        "forbidden_combinations": [
            {"food": "萝卜", "reason": "同食可能降低营养价值", "severity": "warning"},
        ],
        "residue_risk": "medium",
        "selection_tips": "色泽黑褐，朵大肉厚，无杂质为佳",
    },
    {
        "id": "white_fungus",
        "name": "银耳",
        "season_best": "秋冬",
        "storage_tips": "干制常温保存，避免受潮，可保存1年以上",
        "washing_tips": "冷水浸泡15-20分钟至软，轻轻搓洗去杂质",
        "tcm_property": "平",
        "common_combinations_safe": ["红糖", "蜂蜜", "红枣"],
        "forbidden_combinations": [
            {"food": "鹿茸", "reason": "性质不配，易相克", "severity": "warning"},
        ],
        "residue_risk": "low",
        "selection_tips": "色泽洁白，朵大肉厚，无碎末为佳",
    },
]

# ─────────────────────────────────────────────────────────────────────────────
# 食物相克库（10个经典相克对）
# ─────────────────────────────────────────────────────────────────────────────
INCOMPATIBLE_PAIRS = [
    {
        "combination": "菠菜 + 豆腐",
        "reason": "菠菜含草酸，豆腐含钙，形成草酸钙沉淀，难以吸收，易致结石",
        "tcm_view": "菠菜性凉，豆腐性凉，两凉相遇伤脾阳",
        "severity": "warning",
        "recommended_interval_hours": 2,
    },
    {
        "combination": "螃蟹 + 柿子",
        "reason": "柿子含鞣酸与螃蟹蛋白结合，形成沉淀，导致消化不良、腹痛",
        "tcm_view": "螃蟹性凉滋阴，柿子性凉收敛，二凉相遇易伤脾胃",
        "severity": "danger",
        "recommended_interval_hours": 3,
    },
    {
        "combination": "牛奶 + 浓茶",
        "reason": "茶中单宁与牛奶蛋白质相结合，降低蛋白质吸收率",
        "tcm_view": "茶性凉，牛奶性平，配合不当易伤脾胃消化",
        "severity": "warning",
        "recommended_interval_hours": 1,
    },
    {
        "combination": "虾 + 维生素C高食物",
        "reason": "虾中五价砷在高剂量维生素C作用下可还原为三价砷（砒霜）",
        "tcm_view": "虾温补，大量维C易破坏虾的温阳之性",
        "severity": "warning",
        "recommended_interval_hours": 2,
    },
    {
        "combination": "红薯 + 柿子",
        "reason": "红薯淀粉多，柿子鞣酸多，同食易致胃结石",
        "tcm_view": "红薯性温助脾，柿子凉而收敛，温凉失调易伤脾阳",
        "severity": "danger",
        "recommended_interval_hours": 3,
    },
    {
        "combination": "鸡蛋 + 豆浆",
        "reason": "豆浆含蛋白酶抑制物，与鸡蛋蛋白相克，降低营养吸收",
        "tcm_view": "豆浆凉，鸡蛋平，豆浆生冷可抑制蛋白消化",
        "severity": "warning",
        "recommended_interval_hours": 1,
    },
    {
        "combination": "羊肉 + 西瓜",
        "reason": "羊肉温阳，西瓜凉阴，一热一冷，易伤脾阳，导致腹泻",
        "tcm_view": "温凉相冲，脾阳受损，易生湿困脾",
        "severity": "warning",
        "recommended_interval_hours": 2,
    },
    {
        "combination": "大蒜 + 蜂蜜",
        "reason": "大蒜辛温杀菌，蜂蜜滋阴，二者性质相反，同食易腹泻",
        "tcm_view": "大蒜温，蜂蜜平偏凉，阴阳失调伤脾",
        "severity": "warning",
        "recommended_interval_hours": 2,
    },
    {
        "combination": "绿茶 + 鸡蛋",
        "reason": "茶多酚与蛋白质相结合，降低蛋白吸收，影响营养价值",
        "tcm_view": "绿茶凉，蛋白补气，凉性易散补气之功",
        "severity": "warning",
        "recommended_interval_hours": 1,
    },
    {
        "combination": "黑木耳 + 萝卜",
        "reason": "两者同食可能降低营养吸收，影响消化功能",
        "tcm_view": "黑木耳滋阴，萝卜下气破气，二者功效相克",
        "severity": "warning",
        "recommended_interval_hours": 1,
    },
]

# ─────────────────────────────────────────────────────────────────────────────
# 辅助查找表
# ─────────────────────────────────────────────────────────────────────────────
SEASON_FOODS = {
    "春": ["spinach", "white_radish", "ginger"],
    "夏": ["bitter_melon", "crab", "shrimp"],
    "秋": ["lotus_root", "chinese_yam", "sweet_potato"],
    "冬": ["white_radish", "sweet_potato", "lamb"],
}

def _get_food_by_id(food_id: str):
    """根据ID获取食材，不存在则返回None"""
    return next((f for f in FOODS if f["id"] == food_id), None)


def _get_food_by_name(food_name: str):
    """根据中文名称获取食材，不存在则返回None"""
    return next((f for f in FOODS if f["name"] == food_name), None)


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/foods", summary="食材列表")
async def list_foods(
    season: Optional[str] = Query(None, description="采购季节: 春/夏/秋/冬"),
    tcm_property: Optional[str] = Query(None, pattern=r"^(凉|温|平)$", description="中医性质: 凉/温/平"),
    limit: int = Query(20, ge=1, le=50),
):
    """返回食材列表，支持按季节和中医性质筛选。"""
    results = FOODS.copy()

    if season and season in SEASON_FOODS:
        ids = SEASON_FOODS[season]
        results = [f for f in results if f["id"] in ids]

    if tcm_property:
        results = [f for f in results if f["tcm_property"] == tcm_property]

    return {
        "success": True,
        "data": {
            "foods": results[:limit],
            "total": len(results),
        },
    }


@router.get("/foods/{food_id}", summary="食材详情")
async def get_food_detail(food_id: str):
    """获取指定食材的完整信息，包含禁忌和选购指南。"""
    food = _get_food_by_id(food_id)
    if not food:
        raise HTTPException(status_code=404, detail=f"Food '{food_id}' not found")
    return {"success": True, "data": food}


@router.get("/incompatible-pairs", summary="食物相克组合列表")
async def list_incompatible_pairs(limit: int = Query(10, ge=1, le=20)):
    """兼容旧路径，返回已辟谣的民间搭配说法及权威依据。"""
    myths = [
        {**pair, "is_myth": True, "compatible": True, "correction": FOOD_PAIRING_EVIDENCE["conclusion"]}
        for pair in INCOMPATIBLE_PAIRS[:limit]
    ]
    return {
        "success": True,
        "data": {
            "pairs": myths,
            "total": len(INCOMPATIBLE_PAIRS),
            "evidence": FOOD_PAIRING_EVIDENCE,
        },
    }


@router.post("/check", summary="食材相克检查")
async def check_compatibility(body: FoodCompatCheckRequest):
    """检查食材搭配，并纠正没有科学依据的普遍‘相克’说法。"""
    food1 = body.food1
    food2 = body.food2

    f1 = _get_food_by_name(food1) or _get_food_by_id(food1)
    f2 = _get_food_by_name(food2) or _get_food_by_id(food2)
    known_names = {
        name
        for pair in INCOMPATIBLE_PAIRS
        for name in pair["combination"].split(" + ")
    } | {"冰糖", "番茄", "西红柿"}

    if (not f1 and food1 not in known_names) or (not f2 and food2 not in known_names):
        raise HTTPException(status_code=404, detail="One or both foods not found")
    return {
        "success": True,
        "data": {
            "food1": food1,
            "food2": food2,
            "compatible": True,
            "message": FOOD_PAIRING_EVIDENCE["conclusion"],
            "cautions": ["确认食材新鲜并充分烹调", "有食物过敏或基础疾病时遵医嘱", "任何食物均应适量"],
            "evidence": FOOD_PAIRING_EVIDENCE,
        },
    }


@router.get("/seasonal", summary="当季推荐食材")
async def seasonal_foods():
    """根据当前季节返回推荐食材，含选购和储存指南。"""
    month = datetime.now().month
    if month in (3, 4, 5):
        season = "春"
    elif month in (6, 7, 8):
        season = "夏"
    elif month in (9, 10, 11):
        season = "秋"
    else:
        season = "冬"

    ids = SEASON_FOODS.get(season, [])
    foods = [f for f in FOODS if f["id"] in ids]

    return {
        "success": True,
        "data": {
            "season": season,
            "month": month,
            "foods": foods,
            "tip": f"当前是{season}季，推荐食用这些应时食材，符合春生夏长秋收冬藏的自然之道。",
        },
    }


@router.get("/foods/{food_id}/storage", summary="食材储存和清洗指南")
async def storage_guide(food_id: str):
    """获取指定食材的储存、清洗和选购专项指导。"""
    food = _get_food_by_id(food_id)
    if not food:
        raise HTTPException(status_code=404, detail=f"Food '{food_id}' not found")

    return {
        "success": True,
        "data": {
            "food_name": food["name"],
            "food_id": food_id,
            "storage": food["storage_tips"],
            "washing": food["washing_tips"],
            "selection": food["selection_tips"],
            "season_best": food["season_best"],
            "residue_risk": food["residue_risk"],
        },
    }
