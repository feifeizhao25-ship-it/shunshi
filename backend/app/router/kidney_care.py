"""
顺时 — 肾脏养护 API (shunshi-kidney-care)
中医护肾方案、补肾食疗、肾经养生
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/kidney-care", tags=["kidney-care"])

SAFETY_NOTICE = (
    "以下内容是中医传统理论与生活方式资料，不用于诊断或治疗肾脏疾病。"
    "水肿、血尿、排尿异常、持续腰痛或肾功能异常时请及时就医；药物和穴位操作请咨询合格专业人员。"
)

KIDNEY_TCM = {
    "functions": [
        "肾主藏精，为先天之本",
        "肾主水，调节水液代谢",
        "肾主纳气，协助肺主气",
        "肾主骨生髓，通于脑",
        "肾开窍于耳及二阴",
        "肾其华在发（头发与肾有关）"
    ],
    "season": "冬",
    "peak_time": "酉时（17-19点）",
    "element": "水",
    "emotion": "恐",
    "flavor": "咸"
}

KIDNEY_DEFICIENCY_TYPES = {
    "kidney_yin": {
        "name": "肾阴虚",
        "signs": ["腰膝酸软", "手足心热", "失眠多梦", "潮热盗汗", "头晕耳鸣"],
        "diet": ["黑色食物", "枸杞", "桑椹", "黑芝麻", "核桃", "百合"],
        "avoid": ["辛辣热性食物", "酒精", "熬夜"],
        "herbs": ["六味地黄丸（代表方）", "枸杞", "山茱萸"],
        "acupoints": ["肾俞穴", "太溪穴", "照海穴"]
    },
    "kidney_yang": {
        "name": "肾阳虚",
        "signs": ["畏寒肢冷", "腰膝酸冷", "小便清长", "精神萎靡", "面色㿠白"],
        "diet": ["温热食物", "羊肉", "韭菜", "虾", "核桃", "栗子"],
        "avoid": ["生冷食物", "苦寒药物", "过度劳累"],
        "herbs": ["金匮肾气丸（代表方）", "附子", "肉桂"],
        "acupoints": ["肾俞穴", "命门穴", "关元穴"]
    },
    "kidney_jing": {
        "name": "肾精不足",
        "signs": ["早衰", "记忆力减退", "牙齿松动", "腰膝无力", "头发早白早脱"],
        "diet": ["黑色食物", "核桃", "黑芝麻", "桑椹", "枸杞", "海参"],
        "avoid": ["过度用脑", "房劳过度", "精神压力过大"],
        "herbs": ["左归丸", "右归丸"],
        "acupoints": ["肾俞穴", "太溪穴", "三阴交穴"]
    }
}

KIDNEY_FOODS = [
    {"name": "黑豆", "benefit": "补肾益精，活血利水", "color": "黑"},
    {"name": "黑芝麻", "benefit": "补肝肾，益精血", "color": "黑"},
    {"name": "核桃", "benefit": "补肾固精，温肺定喘", "color": "棕"},
    {"name": "枸杞", "benefit": "滋补肝肾，益精明目", "color": "红"},
    {"name": "桑椹", "benefit": "滋阴补血，补益肝肾", "color": "紫黑"},
    {"name": "牡蛎", "benefit": "滋阴潜阳，补肾益精", "color": "灰白"},
    {"name": "韭菜", "benefit": "温补肾阳，固精止遗", "color": "绿"},
    {"name": "栗子", "benefit": "补肾强筋，健脾养胃", "color": "棕"},
]

KIDNEY_ACUPOINTS = [
    {"code": "KD3", "name": "太溪穴", "location": "内踝后方凹陷处", "function": "滋阴补肾，清热宁神"},
    {"code": "KD1", "name": "涌泉穴", "location": "足底前1/3凹陷处", "function": "补肾开窍，引火归原"},
    {"code": "BL23", "name": "肾俞穴", "location": "腰部第2腰椎棘突旁开1.5寸", "function": "补肾气，壮腰脊"},
    {"code": "GV4", "name": "命门穴", "location": "腰部第2腰椎棘突下", "function": "温肾壮阳，培元固本"},
]


@router.get("/tcm-functions", summary="中医肾脏功能")
async def get_tcm_functions():
    return {"success": True, "data": {**KIDNEY_TCM, "safety_notice": SAFETY_NOTICE}}


@router.get("/deficiency-types", summary="肾虚类型辨识")
async def get_deficiency_types():
    types = [{"id": k, "name": v["name"], "signs": v["signs"]} for k, v in KIDNEY_DEFICIENCY_TYPES.items()]
    return {
        "success": True,
        "data": {
            "types": types,
            "deficiency_types": types,
            "safety_notice": SAFETY_NOTICE,
        },
    }


@router.get("/deficiency-types/{type_id}", summary="肾虚类型详细方案")
async def get_deficiency_type(type_id: str):
    if type_id not in KIDNEY_DEFICIENCY_TYPES:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="肾虚类型不存在")
    return {
        "success": True,
        "data": {
            **KIDNEY_DEFICIENCY_TYPES[type_id],
            "traditional_context": True,
            "safety_notice": SAFETY_NOTICE,
        },
    }


@router.get("/foods", summary="补肾食物推荐")
async def get_kidney_foods():
    return {"success": True, "data": {"foods": KIDNEY_FOODS, "tip": "黑色食物入肾属于中医传统理论，并不代表颜色可以改善肾功能。", "safety_notice": SAFETY_NOTICE}}


@router.get("/acupoints", summary="护肾穴位")
async def get_kidney_acupoints():
    return {"success": True, "data": {"acupoints": KIDNEY_ACUPOINTS, "safety_notice": SAFETY_NOTICE}}


@router.get("/daily-plan", summary="每日护肾计划")
async def get_daily_plan():
    plan = {
        "morning": "按自身情况安排轻柔活动；不适时立即停止",
        "afternoon_peak": "可选择方便的时间放松，传统时辰说法不代表疗效差异",
        "exercise": "按体能选择散步或温和伸展，逐步增加活动量",
        "diet": "保持食物多样和适量；肾病患者按医嘱控制盐、钾、磷和液体",
        "sleep": "保持规律且充足的睡眠",
        "foot_bath": "如选择泡脚，注意水温并避免烫伤；糖尿病或感觉障碍者先咨询医生"
    }
    return {"success": True, "data": {"daily_plan": plan, "safety_notice": SAFETY_NOTICE}}


@router.get("/seasonal-care", summary="四季护肾方案")
async def get_seasonal_care():
    return {
        "success": True,
        "data": {
            "winter": "冬季是护肾的最佳季节，宜早睡晚起，温补肾阳",
            "spring": "春季顺应生发之气，适当活动但避免过度劳耗",
            "summer": "夏季注意补水护肾，避免大汗伤津",
            "autumn": "秋季滋阴补肾，多食黑色滋补食物"
        },
        "safety_notice": SAFETY_NOTICE,
    }
