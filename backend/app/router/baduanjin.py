"""
顺时 — 八段锦专项 API (shunshi-baduanjin)
八段锦功法详解、练习指导、功效说明
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List

router = APIRouter(prefix="/api/v1/baduanjin", tags=["baduanjin"])

BADUANJIN_SECTIONS = [
    {
        "section": 1,
        "name_cn": "两手托天理三焦",
        "name_en": "Holding Up Heaven with Both Hands",
        "duration_seconds": 60,
        "repetitions": 8,
        "description": "两手交叉上托，拔伸腰背，提拉胸腹，调理三焦气机",
        "steps": [
            "自然站立，两脚平行，与肩同宽",
            "两手自体侧缓缓举至头顶，十指交叉",
            "翻掌向上，用力上托，同时两脚跟提起",
            "保持1-2秒，缓缓放下，脚跟还原",
            "重复8次"
        ],
        "benefits": ["调节三焦气机", "拉伸脊柱和四肢", "改善全身气血循环"],
        "organ_focus": "三焦",
        "acupoints": ["百会穴", "涌泉穴"],
        "breathing": "上托时吸气，下落时呼气",
        "contraindications": ["颈椎严重病变", "高血压严重期"]
    },
    {
        "section": 2,
        "name_cn": "左右开弓似射雕",
        "name_en": "Drawing the Bow",
        "duration_seconds": 60,
        "repetitions": 8,
        "description": "马步开弓，展肩扩胸，调理心肺",
        "steps": [
            "两脚开立，略宽于肩，屈膝呈马步",
            "左手向左侧伸展如拉弓之状，右手握拳屈肘向右拉",
            "目视左手，保持1-2秒",
            "还原后换方向，左右各做4次"
        ],
        "benefits": ["展胸宽肺", "调理心肺功能", "增强肩背肌力"],
        "organ_focus": "肺、心",
        "acupoints": ["云门穴", "中府穴"],
        "breathing": "展开时吸气，还原时呼气",
        "contraindications": ["肩关节损伤急性期"]
    },
    {
        "section": 3,
        "name_cn": "调理脾胃须单举",
        "name_en": "Separating Heaven and Earth",
        "duration_seconds": 60,
        "repetitions": 8,
        "description": "单手上举下按，舒展脾胃，调理中焦",
        "steps": [
            "自然站立，两手掌心向上",
            "左手上举翻掌托天，右手下按至腰",
            "两手同时用力，形成对拔之势",
            "保持1-2秒，还原，换手，各做4次"
        ],
        "benefits": ["调理脾胃功能", "改善消化吸收", "锻炼腰部肌肉"],
        "organ_focus": "脾、胃",
        "acupoints": ["中脘穴", "足三里穴"],
        "breathing": "上举时吸气，下按时呼气",
        "contraindications": ["腰椎间盘突出急性期"]
    },
    {
        "section": 4,
        "name_cn": "五劳七伤往后瞧",
        "name_en": "Looking Backward",
        "duration_seconds": 60,
        "repetitions": 8,
        "description": "头颈向后转动，舒缓颈部，消除疲劳",
        "steps": [
            "自然站立，两臂自然下垂",
            "头慢慢向左后方转动，目视左后方",
            "保持1-2秒，缓缓回正",
            "换右侧，左右各做4次"
        ],
        "benefits": ["消除颈部疲劳", "改善脑部供血", "预防颈椎病"],
        "organ_focus": "心、肝",
        "acupoints": ["风池穴", "大椎穴"],
        "breathing": "转头时呼气，回正时吸气",
        "contraindications": ["颈椎病急性期", "椎动脉供血不足"]
    },
    {
        "section": 5,
        "name_cn": "摇头摆尾去心火",
        "name_en": "Swaying the Head and Tail",
        "duration_seconds": 60,
        "repetitions": 8,
        "description": "马步摇摆，清泻心火，平衡阴阳",
        "steps": [
            "两脚开立，屈膝成马步，双手按膝",
            "上体向左前倾，头随之转向左下方",
            "臀部向右后摆动，形成摇头摆尾之势",
            "还原，换方向，左右各做4次"
        ],
        "benefits": ["去除心火", "调节神经系统", "锻炼腰腹核心"],
        "organ_focus": "心、肾",
        "acupoints": ["命门穴", "神门穴"],
        "breathing": "自然呼吸，动作柔缓",
        "contraindications": ["膝关节损伤", "腰椎病变"]
    },
    {
        "section": 6,
        "name_cn": "两手攀足固肾腰",
        "name_en": "Touching the Toes",
        "duration_seconds": 60,
        "repetitions": 8,
        "description": "弯腰攀足，壮腰健肾，疏通经络",
        "steps": [
            "自然站立，两脚并拢",
            "两手从身体两侧上举，再从背后向下攀足",
            "保持1-2秒，缓缓起身",
            "重复8次"
        ],
        "benefits": ["补肾固腰", "疏通膀胱经", "增强腰背柔韧性"],
        "organ_focus": "肾、膀胱",
        "acupoints": ["委中穴", "承山穴", "肾俞穴"],
        "breathing": "弯腰时呼气，起身时吸气",
        "contraindications": ["腰椎间盘突出急性期", "血压过高"]
    },
    {
        "section": 7,
        "name_cn": "攒拳怒目增气力",
        "name_en": "Clenching the Fists",
        "duration_seconds": 60,
        "repetitions": 8,
        "description": "马步攒拳，怒目圆睁，疏肝强气",
        "steps": [
            "两脚开立成马步，两手握拳置于腰间",
            "左拳猛力向前冲出，目睁圆怒视",
            "收回，换右拳，左右各做4次"
        ],
        "benefits": ["增强气力", "疏泄肝气", "激活全身肌肉"],
        "organ_focus": "肝",
        "acupoints": ["太冲穴", "期门穴"],
        "breathing": "冲拳时呼气，收回时吸气",
        "contraindications": ["严重心脏病", "高血压危象"]
    },
    {
        "section": 8,
        "name_cn": "背后七颠百病消",
        "name_en": "Bouncing on the Toes",
        "duration_seconds": 60,
        "repetitions": 7,
        "description": "踮脚颠动，振奋脊椎，通调气血",
        "steps": [
            "自然站立，两脚并拢，两臂自然下垂",
            "脚跟缓缓提起，保持1-2秒",
            "全身放松，脚跟下落着地，有适度震动感",
            "共做7次"
        ],
        "benefits": ["振奋阳气", "刺激脊椎", "调节全身气血", "强健足部"],
        "organ_focus": "督脉",
        "acupoints": ["涌泉穴", "大椎穴"],
        "breathing": "踮起时吸气，落下时呼气",
        "contraindications": ["足跟痛", "骨质疏松严重", "脊椎骨折"]
    }
]

PRACTICE_GUIDE = {
    "total_duration": "约15-20分钟",
    "best_time": "清晨或傍晚，空腹或饭后1小时",
    "frequency": "每日1-2次",
    "environment": "空气清新、安静的室内外均可",
    "attire": "宽松舒适的服装，平底软鞋或赤脚",
    "precautions": [
        "初学者动作宜缓不宜急，以不疲劳为度",
        "高血压、心脏病患者应在医生指导下练习",
        "孕妇不宜练习",
        "急性损伤期间不宜练习",
        "动作与呼吸配合是关键"
    ],
    "progression": {
        "week_1_2": "每节各做4次，熟悉动作要领",
        "week_3_4": "每节各做8次，注意呼吸配合",
        "month_2_plus": "每节各做8-16次，加强意念引导"
    }
}


@router.get("/sections", summary="八段锦全套功法")
async def list_sections():
    return {
        "success": True,
        "data": {
            "sections": BADUANJIN_SECTIONS,
            "total_sections": 8,
            "practice_guide": PRACTICE_GUIDE
        }
    }


@router.get("/sections/{section_num}", summary="指定节功法详情")
async def get_section(section_num: int):
    if section_num < 1 or section_num > 8:
        raise HTTPException(status_code=404, detail="节数应在1-8之间")
    section = next((s for s in BADUANJIN_SECTIONS if s["section"] == section_num), None)
    return {"success": True, "data": section}


@router.get("/guide", summary="练习总体指南")
async def get_practice_guide():
    return {"success": True, "data": PRACTICE_GUIDE}


@router.get("/by-organ/{organ}", summary="按脏腑查询相关节段")
async def get_sections_by_organ(organ: str):
    sections = [s for s in BADUANJIN_SECTIONS if organ in s["organ_focus"]]
    return {"success": True, "data": {"organ": organ, "sections": sections}}


@router.get("/daily-plan", summary="每日练习计划")
async def get_daily_plan(
    duration_minutes: int = Query(15, description="可用时间(分钟)"),
    level: str = Query("beginner", description="水平: beginner/intermediate/advanced")
):
    reps = {"beginner": 4, "intermediate": 8, "advanced": 16}.get(level, 8)
    plan = [{"section": s["section"], "name": s["name_cn"], "repetitions": reps} for s in BADUANJIN_SECTIONS]
    return {
        "success": True,
        "data": {
            "level": level,
            "total_sections": 8,
            "repetitions_per_section": reps,
            "estimated_duration": f"约{8 * reps // 8 * 2}分钟",
            "plan": plan
        }
    }
