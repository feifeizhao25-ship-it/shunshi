"""
顺时 — 中国地区差异化养生建议 API
根据地理区域提供专业的中医养生方案。
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/regional", tags=["regional_wellness"])

# ─────────────────────────────────────────────────────────────────────────────
# 中国地区数据库（8 个大区）
# ─────────────────────────────────────────────────────────────────────────────
REGIONS = {
    "northeast": {
        "region_code": "northeast",
        "name": "东北地区",
        "provinces": ["黑龙江", "吉林", "辽宁"],
        "climate_type": "严寒干燥",
        "dominant_constitution": "阳虚",
        "seasonal_focus": {
            "spring": "温阳祛湿，疏肝理气",
            "summer": "扶阳祛湿，清热解毒",
            "autumn": "滋阴润肺，温阳为主",
            "winter": "温阳补气，进补储能",
        },
        "recommended_foods": ["羊肉", "黄芪", "红参", "核桃", "黑芝麻", "葱", "生姜"],
        "avoided_foods": ["冷饮", "生冷海鲜", "油腻过多", "过度冷食"],
        "tcm_principle": "温阳扶正，防寒护阳，四季温阳为纲",
        "special_notes": "冬季严寒，需加强温阳；春季回暖，谨防倒春寒；全年避免过度贪凉。",
    },
    "north": {
        "region_code": "north",
        "name": "华北地区",
        "provinces": ["北京", "天津", "河北", "山西", "内蒙古"],
        "climate_type": "干燥四季分明",
        "dominant_constitution": "阴虚燥热",
        "seasonal_focus": {
            "spring": "润肺祛燥，疏肝理气",
            "summer": "清热祛暑，滋阴润肺",
            "autumn": "润肺养阴，防秋燥",
            "winter": "温阳润肺，防干燥",
        },
        "recommended_foods": ["蜂蜜", "银耳", "雪梨", "百合", "黑木耳", "绿豆", "冬瓜"],
        "avoided_foods": ["辛辣刺激", "烧烤油炸", "烟酒", "过度温燥"],
        "tcm_principle": "滋阴润肺，护阴液，防燥邪",
        "special_notes": "春秋扬沙多，注意肺部保护；冬季干燥，加强滋阴润肺；夏季虽热但干，需兼顾润肺。",
    },
    "northwest": {
        "region_code": "northwest",
        "name": "西北地区",
        "provinces": ["陕西", "甘肃", "宁夏", "新疆", "青海"],
        "climate_type": "高原干旱",
        "dominant_constitution": "阴虚体质",
        "seasonal_focus": {
            "spring": "润肺补气，适应高原",
            "summer": "清热祛暑，滋阴润肺",
            "autumn": "滋阴润肺，防高原反应",
            "winter": "温阳滋阴，适应高原",
        },
        "recommended_foods": ["冬虫夏草", "黄芪", "党参", "红枣", "黑木耳", "银耳", "蜂蜜"],
        "avoided_foods": ["过辛辣", "烟酒过量", "过度温燥", "生冷刺激"],
        "tcm_principle": "补气滋阴，适应高原，防高反",
        "special_notes": "高原低氧，全年需补气；紫外线强，需防晒和滋阴；干燥明显，加强润肺。高反预防需补气活血。",
    },
    "east": {
        "region_code": "east",
        "name": "华东地区",
        "provinces": ["上海", "江苏", "浙江", "安徽", "福建", "江西"],
        "climate_type": "梅雨湿热",
        "dominant_constitution": "湿热痰湿",
        "seasonal_focus": {
            "spring": "祛湿疏肝，防春困",
            "summer": "清热祛湿，健脾祛湿",
            "autumn": "祛湿润肺，调理脾胃",
            "winter": "温阳祛湿，扶阳气",
        },
        "recommended_foods": ["薏米", "红豆", "冬瓜", "冬笋", "绿豆", "荷叶", "冬瓜皮"],
        "avoided_foods": ["过油腻厚腻", "甜腻食物", "冷饮", "生冷海鲜"],
        "tcm_principle": "健脾祛湿，疏肝理气，全年除湿",
        "special_notes": "梅雨季节（5-6月）湿气最重，需加强祛湿；春夏多见湿热体质，宜清热祛湿；全年湿气困脾。",
    },
    "south": {
        "region_code": "south",
        "name": "华南地区",
        "provinces": ["广东", "广西", "海南"],
        "climate_type": "岭南湿热",
        "dominant_constitution": "湿热",
        "seasonal_focus": {
            "spring": "清热祛湿，疏肝理气",
            "summer": "清热祛暑，健脾祛湿",
            "autumn": "清热祛湿，调理脾胃",
            "winter": "温阳清热，健脾祛湿",
        },
        "recommended_foods": ["凉茶", "绿豆", "冬瓜", "薏米", "赤小豆", "冬笋", "冬瓜皮"],
        "avoided_foods": ["过油腻", "辛辣刺激", "烟酒", "甜腻过多"],
        "tcm_principle": "清热祛湿，健脾益气，全年祛湿为主",
        "special_notes": "岭南全年湿热，凉茶文化深厚，宜全年清热祛湿；夏季尤其需要清热祛暑；冬季虽冷但湿气仍重。",
    },
    "central": {
        "region_code": "central",
        "name": "华中地区",
        "provinces": ["湖北", "湖南", "河南"],
        "climate_type": "冬冷夏热",
        "dominant_constitution": "湿热阳虚兼备",
        "seasonal_focus": {
            "spring": "祛湿疏肝，温阳为辅",
            "summer": "清热祛湿，健脾益气",
            "autumn": "滋阴润肺，祛湿",
            "winter": "温阳补气，防冷防湿",
        },
        "recommended_foods": ["薏米", "红豆", "冬瓜", "黄芪", "党参", "红枣", "核桃"],
        "avoided_foods": ["过油腻", "冷饮", "生冷", "辛辣过多"],
        "tcm_principle": "四季平衡，冬温阳，夏祛湿，全面调养",
        "special_notes": "四季明显变化，需四季不同重点调理；冬季寒冷需温阳；夏季炎热潮湿需清热祛湿；春秋转换需调理。",
    },
    "southwest": {
        "region_code": "southwest",
        "name": "西南地区",
        "provinces": ["四川", "重庆", "云南", "贵州"],
        "climate_type": "盆地潮湿",
        "dominant_constitution": "痰湿阳虚",
        "seasonal_focus": {
            "spring": "祛湿疏肝，温阳为主",
            "summer": "清热祛湿，健脾益气",
            "autumn": "祛湿润肺，调理脾胃",
            "winter": "温阳补气，祛湿",
        },
        "recommended_foods": ["薏米", "红豆", "冬瓜", "黄芪", "党参", "辛夷花", "川贝"],
        "avoided_foods": ["过油腻", "甜腻食物", "冷饮", "过度生冷"],
        "tcm_principle": "健脾祛湿，温阳益气，全年除湿为纲",
        "special_notes": "盆地潮湿，川人易痰湿，需长期健脾祛湿；雾气重，需保护肺部；全年湿气困脾，需四季调理。",
    },
    "tibet": {
        "region_code": "tibet",
        "name": "西藏地区",
        "provinces": ["西藏"],
        "climate_type": "高原低氧",
        "dominant_constitution": "气虚血虚",
        "seasonal_focus": {
            "spring": "补气活血，适应高原",
            "summer": "补气活血，清热为辅",
            "autumn": "补气活血，滋阴润肺",
            "winter": "温阳补气，活血，适应高原",
        },
        "recommended_foods": ["冬虫夏草", "红参", "黄芪", "红枣", "黑芝麻", "核桃", "黑木耳"],
        "avoided_foods": ["过度活动导致耗气", "冷饮", "生冷", "油腻过多"],
        "tcm_principle": "补气活血，适应高原，防高反，全年扶正为主",
        "special_notes": "高原低氧，全年需补气活血；高反风险高，需预防性补气；紫外线强，需防晒；冬季特别寒冷，需温阳。",
    },
}

# ─────────────────────────────────────────────────────────────────────────────
# 省份与区域映射
# ─────────────────────────────────────────────────────────────────────────────
PROVINCE_TO_REGION = {
    "黑龙江": "northeast",
    "吉林": "northeast",
    "辽宁": "northeast",
    "北京": "north",
    "天津": "north",
    "河北": "north",
    "山西": "north",
    "内蒙古": "north",
    "陕西": "northwest",
    "甘肃": "northwest",
    "宁夏": "northwest",
    "新疆": "northwest",
    "青海": "northwest",
    "上海": "east",
    "江苏": "east",
    "浙江": "east",
    "安徽": "east",
    "福建": "east",
    "江西": "east",
    "广东": "south",
    "广西": "south",
    "海南": "south",
    "湖北": "central",
    "湖南": "central",
    "河南": "central",
    "四川": "southwest",
    "重庆": "southwest",
    "云南": "southwest",
    "贵州": "southwest",
    "西藏": "tibet",
}

# ─────────────────────────────────────────────────────────────────────────────
# 地区常见体质数据
# ─────────────────────────────────────────────────────────────────────────────
REGION_CONSTITUTION = {
    "northeast": {
        "region_code": "northeast",
        "dominant_constitution": "阳虚",
        "common_constitutions": ["yang_deficiency", "qi_deficiency", "cold_damp"],
        "constitution_profiles": [
            {
                "type": "yang_deficiency",
                "description": "阳虚体质，怕冷，四肢凉，需温阳扶正",
                "adjustment_focus": "温阳补气，避免贪凉",
            },
            {
                "type": "qi_deficiency",
                "description": "气虚体质，容易疲劳，体力差，需补气健脾",
                "adjustment_focus": "补气健脾，增强体质",
            },
            {
                "type": "cold_damp",
                "description": "寒湿体质，怕冷，身重，需温阳祛湿",
                "adjustment_focus": "温阳祛湿，活动增加",
            },
        ],
        "adjustment_recommendations": [
            "温阳补气食物为主",
            "增加体育运动，增强体质",
            "避免过度贪凉，注意腹部保暖",
            "冬季加强进补",
        ],
    },
    "north": {
        "region_code": "north",
        "dominant_constitution": "阴虚燥热",
        "common_constitutions": ["yin_deficiency", "damp_heat", "dryness"],
        "constitution_profiles": [
            {
                "type": "yin_deficiency",
                "description": "阴虚体质，口干，怕热，需滋阴润肺",
                "adjustment_focus": "滋阴润肺，清热为辅",
            },
            {
                "type": "damp_heat",
                "description": "湿热体质，口苦，易长痘，需清热祛湿",
                "adjustment_focus": "清热祛湿，饮食清淡",
            },
            {
                "type": "dryness",
                "description": "燥热体质，皮肤干，容易便秘，需润肺润肠",
                "adjustment_focus": "滋阴润肺，多食蜂蜜水果",
            },
        ],
        "adjustment_recommendations": [
            "滋阴润肺食物为主",
            "多饮白开水，少食辛辣",
            "春秋扬沙注意肺部保护",
            "皮肤护理注意保湿",
        ],
    },
    "east": {
        "region_code": "east",
        "dominant_constitution": "湿热痰湿",
        "common_constitutions": ["damp_heat", "phlegm_damp", "liver_qi_stagnation"],
        "constitution_profiles": [
            {
                "type": "damp_heat",
                "description": "湿热体质，口苦，身重，易长痘，需清热祛湿",
                "adjustment_focus": "清热祛湿，运动出汗",
            },
            {
                "type": "phlegm_damp",
                "description": "痰湿体质，肥胖，困倦，需健脾祛湿",
                "adjustment_focus": "健脾祛湿，控制体重",
            },
            {
                "type": "liver_qi_stagnation",
                "description": "肝气郁滞，烦躁，月经不调，需疏肝理气",
                "adjustment_focus": "疏肝理气，心情舒畅",
            },
        ],
        "adjustment_recommendations": [
            "健脾祛湿食物为主",
            "梅雨季节加强祛湿",
            "增加运动，促进出汗",
            "饮食清淡，少食油腻",
        ],
    },
    "south": {
        "region_code": "south",
        "dominant_constitution": "湿热",
        "common_constitutions": ["damp_heat", "heat", "liver_heat"],
        "constitution_profiles": [
            {
                "type": "damp_heat",
                "description": "湿热体质，口苦口臭，易长痘，需清热祛湿",
                "adjustment_focus": "清热祛湿，凉茶适度",
            },
            {
                "type": "heat",
                "description": "热性体质，易上火，便秘，需清热降火",
                "adjustment_focus": "清热降火，多食清凉食物",
            },
            {
                "type": "liver_heat",
                "description": "肝热体质，烦躁，目赤，需清肝热",
                "adjustment_focus": "清肝热，舒缓心情",
            },
        ],
        "adjustment_recommendations": [
            "全年清热祛湿为主",
            "适度饮用凉茶调理",
            "夏季特别需要清热祛暑",
            "冬季虽冷仍需祛湿",
        ],
    },
}


def _get_current_season() -> str:
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


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/regions", summary="获取所有区域列表")
async def list_regions():
    """返回所有地区的基本信息列表。"""
    all_regions = list(REGIONS.values())
    return {
        "success": True,
        "data": {
            "regions": all_regions,
            "total": len(all_regions),
        },
    }


@router.get("/{region_code}", summary="获取区域详情")
async def get_region(region_code: str):
    """获取指定地区的完整养生信息。"""
    region = REGIONS.get(region_code)
    if not region:
        raise HTTPException(status_code=404, detail=f"Region '{region_code}' not found")

    return {"success": True, "data": region}


@router.get("/{region_code}/seasonal", summary="获取当季养生方案")
async def seasonal_wellness(region_code: str):
    """获取当前季节该地区的专业养生方案。"""
    region = REGIONS.get(region_code)
    if not region:
        raise HTTPException(status_code=404, detail=f"Region '{region_code}' not found")

    season = _get_current_season()
    seasonal_focus = region.get("seasonal_focus", {}).get(season, "")

    return {
        "success": True,
        "data": {
            "region_code": region_code,
            "region_name": region.get("name", ""),
            "current_season": season,
            "seasonal_focus": seasonal_focus,
            "climate_type": region.get("climate_type", ""),
            "dominant_constitution": region.get("dominant_constitution", ""),
            "recommended_foods": region.get("recommended_foods", []),
            "avoided_foods": region.get("avoided_foods", []),
            "tcm_principle": region.get("tcm_principle", ""),
            "special_notes": region.get("special_notes", ""),
            "activity_suggestions": [
                "散步",
                "太极",
                "八段锦",
                "慢走",
            ],
        },
    }


@router.get("/province/{province_name}", summary="按省份查询区域")
async def get_region_by_province(province_name: str):
    """按省份名称查询所属的地区。"""
    from urllib.parse import unquote

    province_name = unquote(province_name)

    region_code = PROVINCE_TO_REGION.get(province_name)
    if not region_code:
        raise HTTPException(status_code=404, detail=f"Province '{province_name}' not found")

    region = REGIONS.get(region_code)
    return {
        "success": True,
        "data": {
            "province_name": province_name,
            "region_code": region_code,
            "region": region,
        },
    }


@router.get("/{region_code}/constitution", summary="获取地区常见体质")
async def get_region_constitution(region_code: str):
    """获取该地区常见体质及调理建议。"""
    constitution = REGION_CONSTITUTION.get(region_code)
    if not constitution:
        # 检查地区是否存在
        if region_code not in REGIONS:
            raise HTTPException(status_code=404, detail=f"Region '{region_code}' not found")
        # 如果地区存在但体质信息不全，返回默认信息
        region = REGIONS.get(region_code)
        constitution = {
            "region_code": region_code,
            "dominant_constitution": region.get("dominant_constitution", ""),
            "common_constitutions": [],
            "constitution_profiles": [],
            "adjustment_recommendations": region.get("special_notes", "").split("；"),
        }

    return {"success": True, "data": constitution}
