"""
顺时 — 艾灸居家引导系统 API
提供穴位方案、三伏灸/三九灸、体质艾灸方案、安全指南。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/moxibustion", tags=["moxibustion"])

# ─────────────────────────────────────────────────────────────────────────────
# 艾灸穴位库（12个常用穴位）
# ─────────────────────────────────────────────────────────────────────────────
MOXIBUSTION_POINTS = [
    {
        "id": "zusanli",
        "name": "足三里",
        "location": "膝下外侧三寸（约四指宽），胫骨外缘旁开一寸",
        "benefits": ["增强免疫力", "益气补脾", "扶阳培元", "抗衰老"],
        "constitution_suitable": ["qi_deficiency", "balanced", "yang_deficiency"],
        "moxibustion_duration_minutes": 15,
        "technique": "温灸",
        "contraindications": "皮肤破损、高热不适用",
        "best_season": ["autumn", "winter"],
        "tcm_function": "足阳明胃经穴，健脾益气，扶阳第一穴",
        "warning": "孕妇慎用，饭后1小时方可施灸",
    },
    {
        "id": "shenque",
        "name": "神阙",
        "location": "脐窝中央（肚脐中），为全身阳气汇聚之处",
        "benefits": ["温阳扶正", "益气固脱", "调理脾胃", "培元"],
        "constitution_suitable": ["yang_deficiency", "qi_deficiency", "balanced"],
        "moxibustion_duration_minutes": 10,
        "technique": "隔姜灸",
        "contraindications": "脐部皮肤破损、腹腔手术后3个月内禁灸",
        "best_season": ["spring", "autumn", "winter"],
        "tcm_function": "任脉穴，温阳纳气，扭转衰落之妙药",
        "warning": "直接艾灸容易烫伤，需隔姜或其他介质",
    },
    {
        "id": "guanyuan",
        "name": "关元",
        "location": "腹部正中线，脐下三寸（约四指宽）",
        "benefits": ["培元补气", "补肾阳", "益气固脱", "强身健体"],
        "constitution_suitable": ["yang_deficiency", "qi_deficiency"],
        "moxibustion_duration_minutes": 15,
        "technique": "温灸",
        "contraindications": "皮肤破损禁用，孕妇慎用",
        "best_season": ["autumn", "winter"],
        "tcm_function": "任脉穴，小肠募穴，为先天后天之本汇聚之处",
        "warning": "三伏灸、三九灸常用穴位，四季常灸可培元",
    },
    {
        "id": "qihai",
        "name": "气海",
        "location": "腹部正中线，脐下一寸半（约两指宽）",
        "benefits": ["益气培元", "扶阳助阳", "调理脾胃", "增强体质"],
        "constitution_suitable": ["qi_deficiency", "yang_deficiency"],
        "moxibustion_duration_minutes": 12,
        "technique": "温灸",
        "contraindications": "皮肤破损禁灸",
        "best_season": ["spring", "autumn", "winter"],
        "tcm_function": "任脉穴，为气之海，益气之要穴",
        "warning": "配合关元、神阙效果更佳",
    },
    {
        "id": "mingmen",
        "name": "命门",
        "location": "腰部后正中线，第二腰椎棘突下凹陷处",
        "benefits": ["温阳补肾", "强腰膝", "增强体质", "益精补髓"],
        "constitution_suitable": ["yang_deficiency", "qi_deficiency"],
        "moxibustion_duration_minutes": 15,
        "technique": "温灸",
        "contraindications": "妊娠期禁灸，皮肤破损禁用",
        "best_season": ["autumn", "winter"],
        "tcm_function": "督脉穴，生命之门，阳气之根",
        "warning": "冬季施灸效果最佳，可配合足三里同灸",
    },
    {
        "id": "feishu",
        "name": "肺俞",
        "location": "背部，第3胸椎棘突下，旁开1.5寸（约两指宽）",
        "benefits": ["补肺气", "宣通肺气", "增强抵抗力", "调理呼吸"],
        "constitution_suitable": ["qi_deficiency", "yin_deficiency"],
        "moxibustion_duration_minutes": 12,
        "technique": "温灸",
        "contraindications": "皮肤破损禁用，肺部急性炎症禁灸",
        "best_season": ["spring", "autumn"],
        "tcm_function": "膀胱经穴，肺的背俞穴，调肺气扶正气",
        "warning": "秋季施灸可防冬季呼吸道疾病",
    },
    {
        "id": "pishu",
        "name": "脾俞",
        "location": "背部，第11胸椎棘突下，旁开1.5寸",
        "benefits": ["健脾益气", "增强脾阳", "调理消化", "祛湿"],
        "constitution_suitable": ["spleen_weakness", "damp", "qi_deficiency"],
        "moxibustion_duration_minutes": 12,
        "technique": "温灸",
        "contraindications": "皮肤破损禁用",
        "best_season": ["spring", "summer", "autumn"],
        "tcm_function": "膀胱经穴，脾的背俞穴，为健脾祛湿之要穴",
        "warning": "脾虚湿困者的常用穴位，配合足三里效果更佳",
    },
    {
        "id": "shenshu",
        "name": "肾俞",
        "location": "背部，第2腰椎棘突下，旁开1.5寸",
        "benefits": ["补肾阳", "强腰膝", "益精补髓", "增强体质"],
        "constitution_suitable": ["yang_deficiency", "qi_deficiency"],
        "moxibustion_duration_minutes": 15,
        "technique": "温灸",
        "contraindications": "妊娠期禁灸，皮肤破损禁用",
        "best_season": ["autumn", "winter"],
        "tcm_function": "膀胱经穴，肾的背俞穴，补肾之要穴",
        "warning": "冬季常灸可培养先天之本，与命门配合效果最佳",
    },
    {
        "id": "sanyinjiao",
        "name": "三阴交",
        "location": "小腿内侧，踝内尖上三寸（约四指宽），胫骨内侧缘后",
        "benefits": ["健脾益血", "调理月经", "增强体质", "调理脾胃肾"],
        "constitution_suitable": ["blood_deficiency", "yin_deficiency", "balanced"],
        "moxibustion_duration_minutes": 10,
        "technique": "温灸",
        "contraindications": "妊娠期慎用，皮肤破损禁灸",
        "best_season": ["spring", "autumn"],
        "tcm_function": "足太阴、厥阴、少阴三经交会穴，调理三阴之枢纽",
        "warning": "女性保健重穴，月经后灸效果更佳",
    },
    {
        "id": "zhongwan",
        "name": "中脘",
        "location": "腹部正中线，脐上4寸（约五指宽）",
        "benefits": ["调理脾胃", "健脾和胃", "消食积", "温中散寒"],
        "constitution_suitable": ["spleen_weakness", "damp", "qi_deficiency"],
        "moxibustion_duration_minutes": 12,
        "technique": "温灸",
        "contraindications": "皮肤破损禁灸，饱食后不宜立即施灸",
        "best_season": ["spring", "autumn", "winter"],
        "tcm_function": "任脉穴，胃的募穴，调理脾胃之第一穴",
        "warning": "脾胃虚弱者常灸，可配合足三里、脾俞",
    },
    {
        "id": "taixi",
        "name": "太溪",
        "location": "足内侧，内踝尖与跟腱之间的凹陷处",
        "benefits": ["滋阴补肾", "益精补髓", "调理腰膝", "增强体质"],
        "constitution_suitable": ["yin_deficiency", "yang_deficiency", "balanced"],
        "moxibustion_duration_minutes": 10,
        "technique": "温灸",
        "contraindications": "皮肤破损禁灸",
        "best_season": ["autumn", "winter"],
        "tcm_function": "足少阴肾经穴，肾经原穴，补肾之枢纽",
        "warning": "秋冬灸效果更佳，可补肾阴阳",
    },
    {
        "id": "yongquan",
        "name": "涌泉",
        "location": "足底，足掌心，第2、3趾骨间的凹陷处",
        "benefits": ["补肾阳", "益精补髓", "滋阴补肾", "增强免疫"],
        "constitution_suitable": ["yin_deficiency", "yang_deficiency"],
        "moxibustion_duration_minutes": 10,
        "technique": "温灸",
        "contraindications": "皮肤破损禁灸，妊娠期慎用",
        "best_season": ["autumn", "winter"],
        "tcm_function": "足少阴肾经穴，肾之根，补肾强身之穴",
        "warning": "配合足三里灸效果更佳，可增强体质",
    },
]

# ─────────────────────────────────────────────────────────────────────────────
# 体质艾灸方案（9种体质）
# ─────────────────────────────────────────────────────────────────────────────
CONSTITUTION_PLANS = {
    "qi_deficiency": {
        "name": "气虚质",
        "description": "形体消瘦，语声低微，易疲劳，脸色淡白",
        "main_points": ["zusanli", "guanyuan", "qihai"],
        "auxiliary_points": ["pishu", "feishu"],
        "duration_minutes": 15,
        "frequency": "每周3-4次，连续4-8周",
        "tip": "需长期施灸，冬季效果更佳",
    },
    "yang_deficiency": {
        "name": "阳虚质",
        "description": "手脚冰凉，怕冷，面色晦暗，容易疲劳",
        "main_points": ["mingmen", "shenshu", "zusanli"],
        "auxiliary_points": ["guanyuan", "qihai"],
        "duration_minutes": 15,
        "frequency": "每周3-4次，冬季强化为5-6次",
        "tip": "冬季三九灸为最佳时机，可大补阳气",
    },
    "yin_deficiency": {
        "name": "阴虚质",
        "description": "口干、皮肤干燥、易急躁、手脚心热",
        "main_points": ["taixi", "yongquan", "sanyinjiao"],
        "auxiliary_points": ["zusanli"],
        "duration_minutes": 10,
        "frequency": "每周2-3次，避免过度温阳",
        "tip": "秋季施灸效果好，需配合滋阴食物",
    },
    "blood_deficiency": {
        "name": "血虚质",
        "description": "面色淡白、唇色淡、易头晕、容易疲劳",
        "main_points": ["zusanli", "sanyinjiao", "pishu"],
        "auxiliary_points": ["feishu", "zhongwan"],
        "duration_minutes": 12,
        "frequency": "每周3次，连续6-8周",
        "tip": "配合补血食物效果更佳，如红枣、黑芝麻",
    },
    "damp": {
        "name": "痰湿质",
        "description": "形体肥胖、腹部松软、容易疲劳、舌苔厚腻",
        "main_points": ["pishu", "zhongwan", "zusanli"],
        "auxiliary_points": ["guanyuan", "qihai"],
        "duration_minutes": 12,
        "frequency": "每周3-4次，夏季尤为适宜",
        "tip": "配合运动和饮食调理效果最佳，避免甜腻食物",
    },
    "damp_heat": {
        "name": "湿热质",
        "description": "面部油腻、容易长痘、口苦、大便粘滞",
        "main_points": ["zhongwan", "pishu", "zusanli"],
        "auxiliary_points": ["qihai"],
        "duration_minutes": 10,
        "frequency": "每周2-3次，避免过度温阳",
        "tip": "配合清淡饮食，避免辛辣油腻，夏季施灸效果好",
    },
    "qi_stagnation": {
        "name": "气郁质",
        "description": "情绪不畅、容易烦躁、胸闷、面色晦暗",
        "main_points": ["zhongwan", "zusanli", "qihai"],
        "auxiliary_points": ["pishu"],
        "duration_minutes": 12,
        "frequency": "每周3次，配合调节情绪",
        "tip": "需调理情绪，配合舒缓音乐效果更佳",
    },
    "blood_stasis": {
        "name": "血瘀质",
        "description": "面色晦暗、容易长斑、舌质暗、容易疼痛",
        "main_points": ["zusanli", "sanyinjiao", "mingmen"],
        "auxiliary_points": ["guanyuan"],
        "duration_minutes": 12,
        "frequency": "每周3-4次，持续8-12周",
        "tip": "配合活血食物效果好，如黑木耳、海带",
    },
    "balanced": {
        "name": "平和质",
        "description": "面色润泽、精力充沛、睡眠良好、大便正常",
        "main_points": ["zusanli", "qihai", "guanyuan"],
        "auxiliary_points": ["shenshu", "pishu"],
        "duration_minutes": 12,
        "frequency": "每周1-2次，作为保健性灸",
        "tip": "定期施灸可维持体质平衡，四季皆宜",
    },
}

# ─────────────────────────────────────────────────────────────────────────────
# 三伏灸/三九灸时间表（2024-2027）
# ─────────────────────────────────────────────────────────────────────────────
SANFU_THERAPY_DATA = {
    2024: {
        "initial_fu": {"start_date": "2024-07-15", "end_date": "2024-07-24", "name": "初伏"},
        "middle_fu": {"start_date": "2024-07-25", "end_date": "2024-08-13", "name": "中伏"},
        "final_fu": {"start_date": "2024-08-14", "end_date": "2024-08-23", "name": "末伏"},
    },
    2025: {
        "initial_fu": {"start_date": "2025-07-14", "end_date": "2025-07-23", "name": "初伏"},
        "middle_fu": {"start_date": "2025-07-24", "end_date": "2025-08-12", "name": "中伏"},
        "final_fu": {"start_date": "2025-08-13", "end_date": "2025-08-22", "name": "末伏"},
    },
    2026: {
        "initial_fu": {"start_date": "2026-07-16", "end_date": "2026-07-25", "name": "初伏"},
        "middle_fu": {"start_date": "2026-07-26", "end_date": "2026-08-14", "name": "中伏"},
        "final_fu": {"start_date": "2026-08-15", "end_date": "2026-08-24", "name": "末伏"},
    },
    2027: {
        "initial_fu": {"start_date": "2027-07-15", "end_date": "2027-07-24", "name": "初伏"},
        "middle_fu": {"start_date": "2027-07-25", "end_date": "2027-08-13", "name": "中伏"},
        "final_fu": {"start_date": "2027-08-14", "end_date": "2027-08-23", "name": "末伏"},
    },
}

SANJIU_THERAPY_DATA = {
    2024: {
        "first_jiu": {"start_date": "2024-12-21", "end_date": "2024-12-29", "name": "初九"},
        "second_jiu": {"start_date": "2024-12-30", "end_date": "2025-01-07", "name": "二九"},
        "third_jiu": {"start_date": "2025-01-08", "end_date": "2025-01-16", "name": "三九"},
    },
    2025: {
        "first_jiu": {"start_date": "2025-12-21", "end_date": "2025-12-29", "name": "初九"},
        "second_jiu": {"start_date": "2025-12-30", "end_date": "2026-01-07", "name": "二九"},
        "third_jiu": {"start_date": "2026-01-08", "end_date": "2026-01-16", "name": "三九"},
    },
    2026: {
        "first_jiu": {"start_date": "2026-12-21", "end_date": "2026-12-29", "name": "初九"},
        "second_jiu": {"start_date": "2026-12-30", "end_date": "2027-01-07", "name": "二九"},
        "third_jiu": {"start_date": "2027-01-08", "end_date": "2027-01-16", "name": "三九"},
    },
    2027: {
        "first_jiu": {"start_date": "2027-12-21", "end_date": "2027-12-29", "name": "初九"},
        "second_jiu": {"start_date": "2027-12-30", "end_date": "2028-01-07", "name": "二九"},
        "third_jiu": {"start_date": "2028-01-08", "end_date": "2028-01-16", "name": "三九"},
    },
}

# ─────────────────────────────────────────────────────────────────────────────
# 辅助函数
# ─────────────────────────────────────────────────────────────────────────────

def _get_point_by_id(point_id: str):
    """根据ID获取穴位"""
    return next((p for p in MOXIBUSTION_POINTS if p["id"] == point_id), None)


def _current_season():
    """获取当前季节"""
    month = datetime.now().month
    if month in (3, 4, 5):
        return "spring"
    elif month in (6, 7, 8):
        return "summer"
    elif month in (9, 10, 11):
        return "autumn"
    else:
        return "winter"


def _get_daily_timchen_recommendation():
    """根据时辰推荐艾灸时间"""
    hour = datetime.now().hour
    if 6 <= hour < 9:
        return "晨间（卯时）：阳气初生，适合温阳穴位"
    elif 9 <= hour < 12:
        return "上午（巳时）：阳气生发，最适合艾灸"
    elif 12 <= hour < 15:
        return "午后（午时）：阳气最盛，可灸阳虚体质穴位"
    elif 15 <= hour < 18:
        return "下午（申时）：阳气收敛，可灸阴虚体质穴位"
    else:
        return "晚间：避免灸，可用温阳茶饮"


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/points", summary="穴位列表")
async def list_points(
    constitution: Optional[str] = Query(None, description="体质: qi_deficiency/yang_deficiency等"),
    season: Optional[str] = Query(None, description="季节: spring/summer/autumn/winter"),
    limit: int = Query(12, ge=1, le=20),
):
    """返回艾灸穴位列表，支持按体质和季节筛选。"""
    results = MOXIBUSTION_POINTS.copy()

    if constitution and constitution in CONSTITUTION_PLANS:
        plan = CONSTITUTION_PLANS[constitution]
        point_ids = plan["main_points"] + plan["auxiliary_points"]
        results = [p for p in results if p["id"] in point_ids]

    if season and season in ["spring", "summer", "autumn", "winter"]:
        results = [p for p in results if season in p["best_season"]]

    return {
        "success": True,
        "data": {
            "points": results[:limit],
            "total": len(results),
        },
    }


@router.get("/points/{point_id}", summary="穴位详情")
async def get_point_detail(point_id: str):
    """获取指定穴位的完整信息。"""
    point = _get_point_by_id(point_id)
    if not point:
        raise HTTPException(status_code=404, detail=f"Point '{point_id}' not found")
    return {"success": True, "data": point}


@router.get("/constitution-plan/{constitution_type}", summary="体质专属艾灸方案")
async def get_constitution_plan(constitution_type: str):
    """根据体质返回专属艾灸方案。"""
    if constitution_type not in CONSTITUTION_PLANS:
        raise HTTPException(status_code=404, detail=f"Constitution type '{constitution_type}' not found")

    plan = CONSTITUTION_PLANS[constitution_type]
    main_points = [_get_point_by_id(pid) for pid in plan["main_points"]]
    auxiliary_points = [_get_point_by_id(pid) for pid in plan["auxiliary_points"]]

    return {
        "success": True,
        "data": {
            "constitution": constitution_type,
            "name": plan["name"],
            "description": plan["description"],
            "main_points": [p for p in main_points if p],
            "auxiliary_points": [p for p in auxiliary_points if p],
            "duration_minutes": plan["duration_minutes"],
            "frequency": plan["frequency"],
            "tip": plan["tip"],
        },
    }


@router.get("/seasonal-therapy", summary="三伏灸/三九灸信息")
async def seasonal_therapy():
    """根据当前月份返回三伏灸或三九灸信息。"""
    now = datetime.now()
    current_month = now.month
    current_year = now.year

    is_sanfu_season = current_month in (7, 8)
    is_sanjiu_season = current_month in (12, 1)

    result = {
        "current_month": current_month,
        "current_year": current_year,
        "sanfu_therapy": None,
        "sanjiu_therapy": None,
    }

    if is_sanfu_season:
        therapy_data = SANFU_THERAPY_DATA.get(current_year)
        if therapy_data:
            result["sanfu_therapy"] = {
                "active": True,
                "periods": therapy_data,
                "main_points": ["zusanli", "guanyuan", "mingmen"],
                "description": "三伏灸为冬病夏治之法，在三伏天艾灸穴位，可温阳扶正，预防冬季疾病",
            }
    else:
        # 查找下一个三伏灸时期
        next_year = current_year if current_month < 7 else current_year + 1
        therapy_data = SANFU_THERAPY_DATA.get(next_year)
        if therapy_data:
            result["sanfu_therapy"] = {
                "active": False,
                "next_period": f"{next_year}年7月-8月",
                "periods": therapy_data,
            }

    if is_sanjiu_season:
        year_key = current_year if current_month == 12 else current_year - 1
        therapy_data = SANJIU_THERAPY_DATA.get(year_key)
        if therapy_data:
            result["sanjiu_therapy"] = {
                "active": True,
                "periods": therapy_data,
                "main_points": ["mingmen", "shenshu", "guanyuan"],
                "description": "三九灸为冬季扶阳之法，在三九天艾灸穴位，可大补阳气，增强体质",
            }
    else:
        # 查找下一个三九灸时期
        next_year = current_year if current_month <= 11 else current_year + 1
        therapy_data = SANJIU_THERAPY_DATA.get(next_year)
        if therapy_data:
            result["sanjiu_therapy"] = {
                "active": False,
                "next_period": f"{next_year}年12月-{next_year + 1}年1月",
                "periods": therapy_data,
            }

    return {
        "success": True,
        "data": result,
    }


@router.get("/daily-recommendation", summary="今日艾灸建议")
async def daily_recommendation():
    """根据季节和时辰提供今日艾灸建议。"""
    season = _current_season()
    timchen_tip = _get_daily_timchen_recommendation()

    season_recommendations = {
        "spring": {
            "season_name": "春季",
            "principle": "春季阳气升发，宜疏肝理气，健脾益气",
            "recommended_points": ["zusanli", "qihai", "zhongwan"],
        },
        "summer": {
            "season_name": "夏季",
            "principle": "夏季心火旺盛，宜健脾祛湿，增强体质",
            "recommended_points": ["pishu", "zhongwan", "zusanli"],
        },
        "autumn": {
            "season_name": "秋季",
            "principle": "秋季燥气伤肺，宜调理脾胃，准备冬季补阳",
            "recommended_points": ["feishu", "pishu", "zusanli"],
        },
        "winter": {
            "season_name": "冬季",
            "principle": "冬季阳气潜藏，宜温阳扶正，三九灸最佳时机",
            "recommended_points": ["mingmen", "shenshu", "guanyuan"],
        },
    }

    rec = season_recommendations.get(season, {})

    return {
        "success": True,
        "data": {
            "current_season": season,
            "season_name": rec.get("season_name"),
            "principle": rec.get("principle"),
            "recommended_points": rec.get("recommended_points"),
            "timchen_tip": timchen_tip,
            "today": datetime.now().strftime("%Y-%m-%d"),
        },
    }


@router.get("/safety-guide", summary="艾灸安全指南")
async def safety_guide():
    """返回艾灸安全指南，包含禁忌、注意事项和急救措施。"""
    return {
        "success": True,
        "data": {
            "contraindications": [
                "妊娠早期（前3个月）禁灸腹部穴位，需在医生指导下进行",
                "皮肤破损、溃疡、炎症部位禁灸",
                "高热、急性炎症期间禁灸",
                "极度疲劳、饥饿状态禁灸",
                "饭后立即禁灸（需等待1小时）",
                "酗酒后禁灸",
            ],
            "precautions": [
                "首次施灸应咨询中医专业人士",
                "施灸时环境温暖，避免吹风",
                "施灸后避免立即洗冷水澡",
                "施灸后避免接触冷水、冷风（至少2小时）",
                "皮肤敏感者应在医生指导下使用隔姜灸或温和灸法",
                "连续施灸4-8周后应休息1-2周",
                "孕妇、儿童、老年人应在医生指导下进行",
            ],
            "emergency_measures": [
                "若灸伤皮肤（烫伤），立即停止，用冷水冷敷",
                "若出现晕灸（头晕、恶心、心悸），应立即停止，平卧休息",
                "若出现皮肤红肿，可涂抹烫伤膏或润肤油",
                "若症状加重，应立即就医",
            ],
            "best_practice": "建议在中医专业人士指导下进行艾灸，尤其是初学者。",
        },
    }
