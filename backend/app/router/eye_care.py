"""
顺时 — 护眼养生 API (shunshi-eye-care)
中医护眼方案、眼部穴位、用眼建议
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/eye-care", tags=["eye-care"])

EYE_EXERCISES = [
    {
        "id": "ex_001", "name": "眼保健操", "duration_minutes": 5,
        "steps": [
            {"step": 1, "name": "按揉攒竹穴", "duration": "1分钟", "method": "两拇指弯曲，用拇指背面第一关节刮眉头"},
            {"step": 2, "name": "按压睛明穴", "duration": "1分钟", "method": "拇指和食指分别按压眼内角睛明穴"},
            {"step": 3, "name": "按揉四白穴", "duration": "1分钟", "method": "食指按揉眼眶下缘正中直下约1指处"},
            {"step": 4, "name": "按太阳穴", "duration": "1分钟", "method": "两拇指按太阳穴，食指刮上下眼皮"},
            {"step": 5, "name": "远眺放松", "duration": "1分钟", "method": "注视远处绿色植物，让眼部肌肉放松"},
        ],
        "benefit": "可帮助安排短暂休息和放松感；没有替代验光或近视防控的作用"
    },
    {
        "id": "ex_002", "aliases": ["eye_roll"], "name": "眼球运动操", "duration_minutes": 3,
        "steps": [
            {"step": 1, "name": "上下运动", "duration": "30秒", "method": "眼球缓慢上下移动10次"},
            {"step": 2, "name": "左右运动", "duration": "30秒", "method": "眼球缓慢左右移动10次"},
            {"step": 3, "name": "顺时针转动", "duration": "30秒", "method": "眼球顺时针缓慢转动5圈"},
            {"step": 4, "name": "逆时针转动", "duration": "30秒", "method": "眼球逆时针缓慢转动5圈"},
            {"step": 5, "name": "远近交替", "duration": "1分钟", "method": "看近处（10cm）然后看远处（6m），交替10次"},
        ],
        "benefit": "可作为短暂的用眼休息活动；不能替代视力检查或近视防控"
    }
]

EYE_ACUPOINTS = [
    {
        "code": "BL1", "name": "睛明穴",
        "location": "眼内角，鼻根旁0.1寸",
        "function": "明目利窍，疏风清热",
        "massage_method": "闭目，用双手食指轻按，每次1-2分钟",
        "conditions": ["近视", "远视", "迎风流泪", "眼睛疲劳"]
    },
    {
        "code": "ST1", "name": "承泣穴",
        "location": "眼眶下缘正中，直视时正对瞳孔",
        "function": "散风清热，明目止泪",
        "massage_method": "用食指轻压，感觉有轻微酸胀感，每次30-60秒",
        "conditions": ["眼袋", "黑眼圈", "眼睛干涩"]
    },
    {
        "code": "GB1", "name": "瞳子髎穴",
        "location": "外眼角旁约0.5寸",
        "function": "疏散风热，明目退翳",
        "massage_method": "用中指按揉，每次1分钟",
        "conditions": ["眼角皱纹", "眼睛干涩", "头痛"]
    },
    {
        "code": "EX-HN5", "name": "太阳穴",
        "location": "眉梢与外眼角之间向后约1横指的凹陷处",
        "function": "清热止痛，明目醒脑",
        "massage_method": "双手拇指或食指按揉，顺时针各旋转20次",
        "conditions": ["眼部疲劳", "头痛", "偏头痛"]
    },
    {
        "code": "LV3", "name": "太冲穴（护眼要穴）",
        "location": "足背第1-2跖骨结合部前凹陷中",
        "function": "清肝明目，疏肝理气",
        "massage_method": "拇指按压，每次3-5分钟，两侧交替",
        "conditions": ["肝火旺引起的眼红目赤", "眼睛干涩", "视力下降"]
    },
    {
        "code": "KD1", "name": "涌泉穴（明目补肾）",
        "location": "足底前部凹陷处",
        "function": "补肾滋阴，明目固精",
        "massage_method": "睡前按揉，每侧5分钟",
        "conditions": ["肾虚引起的视力减退", "眼睛干涩"]
    }
]

DIGITAL_EYE_STRAIN_TIPS = {
    "20_20_20_rule": {
        "name": "20-20-20法则",
        "description": "每使用屏幕20分钟，休息20秒，注视20英尺（约6米）外的物体",
        "frequency": "每20分钟"
    },
    "screen_settings": {
        "brightness": "屏幕亮度与周围环境亮度相近",
        "contrast": "适当增加对比度",
        "font_size": "字体大小以舒适阅读为准",
        "distance": "屏幕与眼睛保持50-70cm距离",
        "angle": "屏幕中心略低于视线水平"
    },
    "blink_reminder": "用眼时注意多眨眼，避免眼干，正常眨眼频率约15-20次/分钟"
}

TCM_EYE_DIET = {
    "liver_nourishing": {
        "principle": "中医认为'肝开窍于目'，护眼首先养肝",
        "foods": [
            {"name": "枸杞", "benefit": "滋补肝肾，明目"},
            {"name": "菊花", "benefit": "清肝明目，疏散风热"},
            {"name": "桑椹", "benefit": "滋阴补血，明目"},
            {"name": "猪肝", "benefit": "以肝补肝，富含维生素A"},
            {"name": "胡萝卜", "benefit": "富含β-胡萝卜素，护眼"},
            {"name": "蓝莓", "benefit": "含花青素，保护视网膜"},
        ]
    }
}


@router.get("/exercises", summary="眼部保健操列表")
async def list_eye_exercises():
    return {"success": True, "data": {
        "exercises": EYE_EXERCISES,
        "disclaimer": "仅供一般性用眼休息参考；眼痛、视力突然变化、闪光或飞蚊骤增时应及时就医。",
    }}


@router.get("/exercises/{exercise_id}", summary="眼部保健操详情")
async def get_eye_exercise(exercise_id: str):
    exercise = next(
        (e for e in EYE_EXERCISES if e["id"] == exercise_id or exercise_id in e.get("aliases", [])),
        None,
    )
    if not exercise:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="保健操不存在")
    return {"success": True, "data": {
        **exercise,
        "disclaimer": "动作应轻柔且不得按压眼球；不适时立即停止并咨询眼科专业人员。",
    }}


@router.get("/acupoints", summary="护眼穴位列表")
async def list_eye_acupoints():
    return {"success": True, "data": {"acupoints": EYE_ACUPOINTS}}


@router.get("/digital-eye-strain", summary="数字眼疲劳预防建议")
async def get_digital_eye_strain_tips():
    return {"success": True, "data": DIGITAL_EYE_STRAIN_TIPS}


@router.get("/diet", summary="护眼饮食建议")
async def get_eye_diet():
    return {"success": True, "data": TCM_EYE_DIET}


@router.get("/daily-care", summary="每日护眼方案")
async def get_daily_eye_care(
    screen_hours: float = Query(8.0, description="每日屏幕使用时长(小时)")
):
    intensity = "high" if screen_hours >= 8 else "medium" if screen_hours >= 4 else "low"
    plan = {
        "morning": "起床后用温水轻敷眼部，做一次眼保健操",
        "every_hour": "休息5分钟，远眺或闭目养神",
        "noon": "午休时闭目休息，可热敷眼部15分钟",
        "evening": "睡前按摩睛明、太阳、四白穴各1分钟",
        "exercise": "每周进行三次以上有氧运动，促进眼部血液循环"
    }
    if intensity == "high":
        plan["extra"] = "用眼超过8小时，建议增加规律休息；人工泪液的选择和使用请咨询药师或眼科专业人员"
    return {
        "success": True,
        "data": {
            "screen_hours": screen_hours,
            "eye_strain_level": intensity,
            "daily_plan": plan
        }
    }
