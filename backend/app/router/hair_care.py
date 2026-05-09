"""
顺时 — 护发养发 API (shunshi-hair-care)
中医护发方案、食疗、穴位按摩
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/hair-care", tags=["hair-care"])

HAIR_TCM_THEORY = {
    "principle": "发为血之余，肾其华在发",
    "key_organs": ["肾", "肝"],
    "explanation": "中医认为头发的健康与肾气的盛衰密切相关，同时肝藏血，血盛则发旺。"
}

HAIR_CONDITIONS = {
    "hair_loss": {
        "id": "hair_loss", "name": "脱发",
        "tcm_types": [
            {
                "type": "血虚脱发",
                "signs": ["头发稀疏干枯", "面色苍白", "头晕眼花"],
                "treatment": "补血养发",
                "remedies": ["四物汤", "当归补血汤"],
                "diet": ["黑芝麻", "何首乌", "核桃", "红枣", "猪肝"],
                "acupoints": ["血海穴", "三阴交穴", "肾俞穴"]
            },
            {
                "type": "肾虚脱发",
                "signs": ["头发早白", "腰膝酸软", "耳鸣"],
                "treatment": "补肾益精",
                "remedies": ["六味地黄丸", "五子衍宗丸"],
                "diet": ["黑豆", "黑芝麻", "枸杞", "核桃"],
                "acupoints": ["肾俞穴", "太溪穴", "百会穴"]
            },
            {
                "type": "湿热脱发",
                "signs": ["头发油腻", "毛囊炎", "头皮瘙痒"],
                "treatment": "清热祛湿",
                "remedies": ["龙胆泻肝汤加减"],
                "diet": ["薏米", "绿豆", "冬瓜", "苦瓜"],
                "acupoints": ["曲池穴", "血海穴", "阴陵泉穴"]
            }
        ]
    },
    "premature_gray": {
        "id": "premature_gray", "name": "少白头",
        "tcm_view": "肾气虚衰或血热，导致发失所养",
        "remedies": ["何首乌", "桑椹", "黑芝麻", "核桃"],
        "diet": ["黑色食物为主", "减少辛辣", "充足睡眠"],
        "acupoints": ["百会穴", "肾俞穴", "三阴交穴"]
    }
}

HAIR_CARE_FOODS = [
    {"name": "黑芝麻", "benefit": "补肝肾，益精血，乌发润发"},
    {"name": "何首乌", "benefit": "补肝肾，益精血，乌须发（需在医师指导下使用）"},
    {"name": "核桃", "benefit": "补肾固精，润发"},
    {"name": "桑椹", "benefit": "滋阴补血，乌发"},
    {"name": "黑豆", "benefit": "补肾益精，养发"},
    {"name": "鸡蛋", "benefit": "富含蛋白质和生物素，养发"},
    {"name": "深海鱼", "benefit": "富含Omega-3脂肪酸，营养头皮"},
]

SCALP_MASSAGE = [
    {
        "name": "百会穴按摩",
        "location": "头顶正中",
        "method": "用食指或中指按压，顺时针旋转20次",
        "benefit": "促进头皮血液循环，生发固发"
    },
    {
        "name": "头皮梳理",
        "tool": "宽齿梳或指尖",
        "method": "从前额发际开始，轻柔梳向后颈，每次5分钟",
        "benefit": "疏通头皮经络，改善发质"
    },
    {
        "name": "五指扣头",
        "method": "五指微曲，像弹琴一样轻叩整个头皮，每次3分钟",
        "benefit": "激活头皮毛囊，促进头发生长"
    }
]


@router.get("/tcm-theory", summary="中医护发理论")
async def get_tcm_theory():
    return {"success": True, "data": HAIR_TCM_THEORY}


@router.get("/conditions", summary="常见头发问题")
async def list_conditions():
    items = [{"id": k, "name": v["name"]} for k, v in HAIR_CONDITIONS.items()]
    return {"success": True, "data": {"conditions": items}}


@router.get("/conditions/{condition_id}", summary="头发问题调理方案")
async def get_condition(condition_id: str):
    if condition_id not in HAIR_CONDITIONS:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="问题类型不存在")
    return {"success": True, "data": HAIR_CONDITIONS[condition_id]}


@router.get("/foods", summary="护发食物推荐")
async def get_hair_foods():
    return {"success": True, "data": {"foods": HAIR_CARE_FOODS}}


@router.get("/scalp-massage", summary="头皮按摩指南")
async def get_scalp_massage():
    return {"success": True, "data": {"massage_techniques": SCALP_MASSAGE}}


@router.get("/daily-care", summary="日常护发方案")
async def get_daily_care():
    return {
        "success": True,
        "data": {
            "morning": "用宽齿梳轻梳头发5分钟，促进血液循环",
            "diet": "每日食用黑芝麻、核桃等护发食物",
            "washing": "水温不宜过热（40°C以下），用温和洗发水",
            "drying": "避免过度使用热风，自然晾干为佳",
            "evening": "睡前按摩百会穴和头皮5分钟",
            "lifestyle": "保证充足睡眠，减少精神压力"
        }
    }
