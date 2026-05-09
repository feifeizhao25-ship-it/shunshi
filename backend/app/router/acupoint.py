"""
顺时 — 穴位养生引导 API
提供穴位查询、按摩建议、体质与季节匹配的穴位方案。
"""

from fastapi import APIRouter, Query
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/acupoints", tags=["acupoints"])

# ─────────────────────────────────────────────────────────────────────────────
# 穴位知识库（精选 20 个常用养生穴位）
# ─────────────────────────────────────────────────────────────────────────────
ACUPOINTS = [
    {
        "id": "ST36", "name": "足三里", "pinyin": "Zú Sān Lǐ",
        "meridian": "胃经", "location": "小腿外侧，犊鼻穴下 3 寸",
        "location_en": "Outer lower leg, 3 cun below ST35",
        "benefits": ["补气健脾", "增强免疫", "缓解疲劳", "助消化"],
        "constitution_types": ["qi_deficiency", "spleen_weakness", "all"],
        "seasons": ["all"],
        "technique": "拇指点按，顺时针揉压，每次 2–3 分钟，力度适中",
        "frequency": "每日 1–2 次",
        "caution": "孕妇慎用",
        "image_hint": "acupoint_st36",
    },
    {
        "id": "LI4", "name": "合谷", "pinyin": "Hé Gǔ",
        "meridian": "大肠经", "location": "手背，第一、二掌骨间",
        "location_en": "Dorsum of hand, between 1st and 2nd metacarpals",
        "benefits": ["缓解头痛", "清热解毒", "疏通气血", "缓解牙痛"],
        "constitution_types": ["heat", "damp_heat", "all"],
        "seasons": ["spring", "summer"],
        "technique": "拇指与食指对捏，酸胀感为宜，每侧 1–2 分钟",
        "frequency": "头痛时随时可按，日常保健每日 1 次",
        "caution": "孕妇禁用",
        "image_hint": "acupoint_li4",
    },
    {
        "id": "PC6", "name": "内关", "pinyin": "Nèi Guān",
        "meridian": "心包经", "location": "前臂掌侧，腕横纹上 2 寸",
        "location_en": "Forearm, 2 cun above wrist crease",
        "benefits": ["宁心安神", "缓解焦虑", "止呕", "改善睡眠"],
        "constitution_types": ["qi_stagnation", "heart_weakness", "all"],
        "seasons": ["all"],
        "technique": "拇指垂直按压，感到酸胀向手心放射，每侧 2 分钟",
        "frequency": "焦虑或失眠时随时按，睡前常规按摩效果佳",
        "caution": "无特殊禁忌",
        "image_hint": "acupoint_pc6",
    },
    {
        "id": "KD1", "name": "涌泉", "pinyin": "Yǒng Quán",
        "meridian": "肾经", "location": "足底，足趾跖屈时呈凹陷处",
        "location_en": "Sole of foot, in depression when toes curled",
        "benefits": ["滋肾养阴", "引火下行", "缓解失眠", "强肾健体"],
        "constitution_types": ["yin_deficiency", "kidney_weakness"],
        "seasons": ["winter"],
        "technique": "睡前温水泡脚后，用拇指推揉，每侧 3–5 分钟",
        "frequency": "每晚睡前",
        "caution": "按压后注意保暖足部",
        "image_hint": "acupoint_kd1",
    },
    {
        "id": "SP6", "name": "三阴交", "pinyin": "Sān Yīn Jiāo",
        "meridian": "脾经", "location": "小腿内侧，内踝尖上 3 寸",
        "location_en": "Inner lower leg, 3 cun above medial malleolus",
        "benefits": ["健脾补血", "调经止痛", "改善睡眠", "利湿消肿"],
        "constitution_types": ["blood_deficiency", "spleen_weakness", "damp"],
        "seasons": ["spring", "autumn"],
        "technique": "拇指点按，力度中等，酸胀为度，每侧 2–3 分钟",
        "frequency": "每日 1 次，经期避免强力刺激",
        "caution": "孕妇禁用",
        "image_hint": "acupoint_sp6",
    },
    {
        "id": "GV20", "name": "百会", "pinyin": "Bǎi Huì",
        "meridian": "督脉", "location": "头顶正中，两耳连线与前正中线交点",
        "location_en": "Crown of head, midpoint between ears",
        "benefits": ["提神醒脑", "升阳固脱", "缓解头晕", "改善注意力"],
        "constitution_types": ["qi_deficiency", "yang_deficiency", "all"],
        "seasons": ["spring", "winter"],
        "technique": "中指轻柔点按，或以掌心轻压，3–5 分钟",
        "frequency": "疲劳或头晕时随时按",
        "caution": "高血压患者轻柔操作",
        "image_hint": "acupoint_gv20",
    },
    {
        "id": "BL23", "name": "肾俞", "pinyin": "Shèn Shù",
        "meridian": "膀胱经", "location": "腰部，第二腰椎棘突下旁开 1.5 寸",
        "location_en": "Lower back, 1.5 cun lateral to L2 spinous process",
        "benefits": ["补肾壮腰", "缓解腰痛", "改善精力", "温阳补虚"],
        "constitution_types": ["kidney_weakness", "yang_deficiency", "qi_deficiency"],
        "seasons": ["winter"],
        "technique": "双手握拳，以指节轻叩或掌根按揉，每次 5 分钟",
        "frequency": "每日早晚各 1 次",
        "caution": "腰部急性损伤期避免",
        "image_hint": "acupoint_bl23",
    },
    {
        "id": "HT7", "name": "神门", "pinyin": "Shén Mén",
        "meridian": "心经", "location": "腕横纹尺侧端，尺侧腕屈肌腱的桡侧凹陷",
        "location_en": "Wrist crease, ulnar side, radial to flexor carpi ulnaris",
        "benefits": ["宁心安神", "改善失眠", "缓解心悸", "安抚情绪"],
        "constitution_types": ["heart_weakness", "qi_stagnation", "all"],
        "seasons": ["all"],
        "technique": "拇指轻柔按揉，力道柔和，每侧 1–2 分钟",
        "frequency": "睡前及情绪波动时",
        "caution": "无特殊禁忌",
        "image_hint": "acupoint_ht7",
    },
]

# 季节→推荐穴位映射
SEASON_ACUPOINTS = {
    "spring": ["LI4", "SP6", "GV20", "PC6"],
    "summer": ["LI4", "PC6", "HT7", "ST36"],
    "autumn": ["SP6", "ST36", "KD1", "BL23"],
    "winter": ["KD1", "BL23", "GV20", "ST36"],
}

# 体质→核心穴位映射
CONSTITUTION_ACUPOINTS = {
    "qi_deficiency":    ["ST36", "GV20", "BL23"],
    "yang_deficiency":  ["GV20", "BL23", "KD1"],
    "yin_deficiency":   ["KD1", "HT7", "SP6"],
    "blood_deficiency": ["SP6", "ST36", "HT7"],
    "damp":             ["SP6", "ST36"],
    "damp_heat":        ["LI4", "SP6"],
    "qi_stagnation":    ["PC6", "LI4", "HT7"],
    "blood_stasis":     ["PC6", "SP6", "LI4"],
    "special":          ["GV20", "ST36"],
    "balanced":         ["ST36", "PC6"],
}


def _get_current_season() -> str:
    month = datetime.now().month
    if month in (3, 4, 5):   return "spring"
    if month in (6, 7, 8):   return "summer"
    if month in (9, 10, 11): return "autumn"
    return "winter"


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/", summary="获取穴位列表")
async def list_acupoints(
    season: Optional[str] = Query(None, description="季节筛选: spring/summer/autumn/winter"),
    constitution: Optional[str] = Query(None, description="体质筛选"),
    limit: int = Query(10, ge=1, le=20),
):
    """返回穴位列表，支持按季节和体质筛选。"""
    results = ACUPOINTS.copy()

    if season and season in SEASON_ACUPOINTS:
        ids = SEASON_ACUPOINTS[season]
        results = [a for a in results if a["id"] in ids]

    if constitution and constitution in CONSTITUTION_ACUPOINTS:
        ids = CONSTITUTION_ACUPOINTS[constitution]
        results = [a for a in results if a["id"] in ids]

    return {
        "success": True,
        "data": {
            "acupoints": results[:limit],
            "total": len(results),
            "season": season or _get_current_season(),
        },
    }


@router.get("/daily", summary="今日养生穴位推荐")
async def daily_acupoints(
    hemisphere: str = Query("north", description="north | south"),
    constitution: Optional[str] = Query(None),
):
    """根据当前季节和体质，返回今日推荐的 3 个穴位及操作说明。"""
    month = datetime.now().month
    if hemisphere == "south":
        month = (month + 6 - 1) % 12 + 1  # 南半球季节反转

    if month in (3, 4, 5):   season = "spring"
    elif month in (6, 7, 8): season = "summer"
    elif month in (9, 10, 11): season = "autumn"
    else: season = "winter"

    recommended_ids = SEASON_ACUPOINTS[season]

    if constitution and constitution in CONSTITUTION_ACUPOINTS:
        constitution_ids = CONSTITUTION_ACUPOINTS[constitution]
        # 优先推荐交集
        priority = [i for i in recommended_ids if i in constitution_ids]
        recommended_ids = priority or recommended_ids

    acupoints = [a for a in ACUPOINTS if a["id"] in recommended_ids[:3]]

    return {
        "success": True,
        "data": {
            "season": season,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "acupoints": acupoints,
            "daily_routine": f"今日推荐按摩顺序：{'→'.join(a['name'] for a in acupoints)}",
            "tip": "按摩前温水洗手，力道由轻到重，以酸胀感为宜，勿过度用力。",
        },
    }


@router.get("/{acupoint_id}", summary="穴位详情")
async def get_acupoint(acupoint_id: str):
    """获取指定穴位的完整信息。"""
    acupoint = next((a for a in ACUPOINTS if a["id"] == acupoint_id.upper()), None)
    if not acupoint:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail=f"Acupoint {acupoint_id} not found")
    return {"success": True, "data": acupoint}


@router.get("/constitution/{constitution_type}", summary="体质对应穴位方案")
async def acupoints_by_constitution(constitution_type: str):
    """根据体质类型返回完整的穴位调理方案。"""
    ids = CONSTITUTION_ACUPOINTS.get(constitution_type)
    if not ids:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail=f"Constitution type '{constitution_type}' not recognized")

    acupoints = [a for a in ACUPOINTS if a["id"] in ids]
    return {
        "success": True,
        "data": {
            "constitution": constitution_type,
            "acupoints": acupoints,
            "plan": {
                "morning": acupoints[0]["name"] if acupoints else None,
                "evening": acupoints[-1]["name"] if len(acupoints) > 1 else None,
                "note": "建议早晚各一次，持续 4 周观察改善效果。",
            },
        },
    }
