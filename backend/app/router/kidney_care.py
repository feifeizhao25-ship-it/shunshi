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

# 以前这里是「肾阴虚 / 肾阳虚 / 肾精不足」三种证型，按症状对号入座，再配六味地黄丸、金匮肾气丸、左归丸/右归丸
# 和附子、肉桂。按症状给出证型结论属于辨证，配成药属于开方，顺时都不做。
# 现在只按日常感受给作息、饮食、运动、情绪四方面的生活建议，不下证型结论、不给药名。
# 接口路径和 id 保持不变，旧客户端不会 404。
TYPE_NOTICE = "这里只按日常感受给生活方式建议，不判断你属于哪种证型，也不推荐任何药物。如有不适请就医，用药请遵医嘱。"

KIDNEY_DEFICIENCY_TYPES = {
    "kidney_yin": {
        "name": "容易口干、睡不踏实的时候",
        "common_feelings": ["口干", "手脚心发热", "睡不踏实、多梦", "夜里出汗"],
        "lifestyle": {
            "作息": "晚上 11 点前睡，睡前 1 小时放下手机",
            "饮食": "清淡少辣，多喝温水，可以吃百合、银耳、梨等润燥的食物",
            "运动": "选择散步、太极等舒缓运动，避免大汗淋漓",
            "情绪": "睡前做几分钟深呼吸或听轻音乐，让自己慢下来",
        },
        "diet": ["百合", "银耳", "梨", "黑芝麻", "桑椹"],
        "avoid": ["辛辣燥热食物", "酒精", "熬夜"],
        "see_doctor": ["夜间出汗持续两周以上", "伴有发热或体重下降", "失眠影响白天生活"],
    },
    "kidney_yang": {
        "name": "怕冷、手脚凉的时候",
        "common_feelings": ["怕冷", "手脚发凉", "腰背发凉", "容易没精神"],
        "lifestyle": {
            "作息": "早睡，冬季早上可以等太阳出来再出门活动",
            "饮食": "少吃生冷，多吃温热熟食，可以喝点生姜红枣茶",
            "运动": "每天快走或八段锦 20-30 分钟，让身体微微发热即可",
            "情绪": "多晒太阳，多和家人朋友走动",
        },
        "diet": ["羊肉", "韭菜", "核桃", "栗子", "生姜"],
        "avoid": ["生冷食物", "冷饮", "过度劳累"],
        "see_doctor": ["怕冷伴明显乏力、体重变化", "手脚发凉伴麻木或疼痛", "夜尿突然增多"],
    },
    "kidney_jing": {
        "name": "容易累、记性变差的时候",
        "common_feelings": ["容易疲劳", "记性变差", "腰膝无力", "头发变白变少"],
        "lifestyle": {
            "作息": "保证 7-8 小时睡眠，避免连续熬夜",
            "饮食": "饮食多样，适量吃蛋、奶、豆类、坚果和深色蔬菜",
            "运动": "规律运动，量力而行，逐步增加",
            "情绪": "压力大时安排放松时间，多和人交流",
        },
        "diet": ["黑芝麻", "核桃", "黑豆", "鸡蛋", "牛奶"],
        "avoid": ["长期熬夜", "过度劳累", "精神压力过大"],
        "see_doctor": ["记忆力明显下降、影响生活", "持续疲劳休息后不缓解", "腰痛、水肿或排尿异常"],
    },
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


@router.get("/deficiency-types", summary="按日常感受的生活建议")
async def get_deficiency_types():
    types = [
        {"id": k, "name": v["name"], "common_feelings": v["common_feelings"]}
        for k, v in KIDNEY_DEFICIENCY_TYPES.items()
    ]
    return {
        "success": True,
        "data": {
            "types": types,
            "deficiency_types": types,
            "notice": TYPE_NOTICE,
            "safety_notice": SAFETY_NOTICE,
        },
    }


@router.get("/deficiency-types/{type_id}", summary="生活方式建议")
async def get_deficiency_type(type_id: str):
    if type_id not in KIDNEY_DEFICIENCY_TYPES:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="没有这一项内容")
    return {
        "success": True,
        "data": {
            "id": type_id,
            **KIDNEY_DEFICIENCY_TYPES[type_id],
            "notice": TYPE_NOTICE,
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
            "winter": "冬季宜早睡晚起，注意保暖，饮食以温热熟食为主",
            "spring": "春季顺应生发之气，适当活动但避免过度劳耗",
            "summer": "夏季注意补水护肾，避免大汗伤津",
            "autumn": "秋季干燥，多喝温水，饮食清润"
        },
        "safety_notice": SAFETY_NOTICE,
    }
