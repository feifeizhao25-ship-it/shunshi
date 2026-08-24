"""
顺时 — 运动健身 TCM 恢复方案 API
提供不同运动类型的 TCM 恢复方案、运动损伤处理、赛前调理等。
"""

from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/sports", tags=["sports_recovery"])


# ─────────────────────────────────────────────────────────────────────────────
# Pydantic 请求模型
# ─────────────────────────────────────────────────────────────────────────────

class PostWorkoutRequest(BaseModel):
    """运动后调养请求"""
    sport_type: str = Field(..., min_length=1, max_length=50, description="运动类型")
    duration_minutes: int = Field(0, ge=0, le=600, description="运动时长（分钟）")
    intensity: str = Field("medium", pattern=r'^(low|medium|high|extreme)$', description="运动强度")
    current_time: Optional[str] = Field(None, description="当前时间 ISO 格式")

# ─────────────────────────────────────────────────────────────────────────────
# 运动类型恢复方案
# ─────────────────────────────────────────────────────────────────────────────
SPORTS_RECOVERY = {
    "strength_training": {
        "sport_name": "力量训练",
        "sport_id": "strength_training",
        "tcm_mechanism": "力量训练导致乳酸堆积、气血瘀滞，需要活血化瘀、补充气血",
        "recovery_timeline": "24-48小时完全恢复",
        "immediate_care": [
            "训练后30分钟内摄入温热蛋白质食物（促进肌肉修复）",
            "做5-10分钟温和拉伸，避免立即停止（缓解乳酸堆积）",
            "训练后2小时内可轻度运动（促进血液循环）"
        ],
        "diet_recommendations": [
            {"food": "山楂", "benefit": "活血化瘀，消除乳酸堆积", "timing": "训练后1小时", "usage": "山楂粥或山楂茶"},
            {"food": "黄芪红枣汤", "benefit": "补气血，加速恢复", "timing": "训练后2小时", "usage": "每周2-3次"},
            {"food": "红花浴脚", "benefit": "活血化瘀，缓解肌肉酸痛", "timing": "训练当晚", "usage": "温水加红花，浸泡15分钟"},
            {"food": "鸡蛋", "benefit": "优质蛋白，修复肌肉", "timing": "训练后立即", "usage": "每次2-3枚"},
            {"food": "豆腐", "benefit": "植物蛋白，易消化", "timing": "训练后2小时", "usage": "豆腐汤或清炒豆腐"}
        ],
        "acupoint_massage": [
            {
                "acupoint": "足三里（ST36）",
                "benefit": "补气，加速恢复",
                "technique": "按摩1-2分钟，每天1-2次"
            },
            {
                "acupoint": "三阴交（SP6）",
                "benefit": "调理脾胃，增强营养吸收",
                "technique": "按摩1-2分钟，每天1次"
            }
        ],
        "sleep_importance": "力量训练后需要充足睡眠（8小时），肌肉在睡眠中修复增长"
    },
    "endurance_running": {
        "sport_name": "长跑/马拉松",
        "sport_id": "endurance_running",
        "tcm_mechanism": "长跑耗气伤精，需要补气、补肾精，同时避免过度消耗阳气",
        "recovery_timeline": "3-7天逐渐恢复",
        "immediate_care": [
            "比赛后立即补充温热电解质饮料（盐水、竹沥水）",
            "避免立即冷静（易伤阳气），缓慢降温后再喝冷水",
            "比赛后2小时后可进食温热营养食物"
        ],
        "diet_recommendations": [
            {"food": "黄芪红枣汤", "benefit": "大补元气，快速恢复", "timing": "比赛后6小时", "usage": "每天1-2次，连续3-7天"},
            {"food": "鸡汤", "benefit": "补气血，增强体质", "timing": "恢复期", "usage": "清汤，每周2-3次"},
            {"food": "黑芝麻糊", "benefit": "补肾精，滋阴", "timing": "早餐", "usage": "每周3次"},
            {"food": "红糖生姜水", "benefit": "温阳复气，适合马拉松后", "timing": "比赛当晚", "usage": "温热饮用"},
            {"food": "电解质补充", "benefit": "补充矿物质，恢复体液平衡", "timing": "运动中和运动后", "usage": "盐水、运动饮料"}
        ],
        "recovery_protocol": {
            "day_1": "被动恢复，温和散步，充足休息",
            "day_2_3": "缓慢增加活动，轻度跑步或快走",
            "day_4_7": "逐步恢复训练强度"
        }
    },
    "swimming": {
        "sport_name": "游泳",
        "sport_id": "swimming",
        "tcm_mechanism": "游泳后身体被冷水包围，湿寒易入体，需要温阳祛湿，保护脾阳",
        "recovery_timeline": "12-24小时",
        "immediate_care": [
            "游泳后立即用温毛巾擦干身体，避免在冷风中停留",
            "游泳后30分钟内不要吹空调或吹风",
            "游泳后1小时内饮用温热饮品"
        ],
        "diet_recommendations": [
            {"food": "姜糖暖茶", "benefit": "温阳祛湿，驱散游泳后的湿气", "timing": "游泳后30分钟", "usage": "温热饮用"},
            {"food": "足部暖身（热水泡脚）", "benefit": "温阳，激发身体自愈力", "timing": "游泳当晚", "usage": "温水加生姜，泡脚15分钟"},
            {"food": "薏米粥", "benefit": "祛湿，强化脾胃", "timing": "游泳后1-2天", "usage": "每天1次"},
            {"food": "黄芪粥", "benefit": "补气，增强抵抗力", "timing": "恢复期", "usage": "每周2次"},
            {"food": "红枣粥", "benefit": "补气血，温阳", "timing": "恢复期", "usage": "每周3次"}
        ],
        "warning_signs": [
            "如出现怕冷、腹泻、喉咙痛，需立即温阳祛湿"
        ]
    },
    "hiit": {
        "sport_name": "高强度间歇(HIIT)",
        "sport_id": "hiit",
        "tcm_mechanism": "HIIT强度极大，易导致肝火亢盛、阴血消耗，需要清热、滋阴、调理心神",
        "recovery_timeline": "24-36小时",
        "immediate_care": [
            "运动后不要立即停止，进行5-10分钟温和运动缓冲",
            "运动后冷静15分钟，让心率逐步降低（避免心脏负荷过大）",
            "进行5-10分钟呼吸调理（腹式呼吸），平复心神"
        ],
        "diet_recommendations": [
            {"food": "绿豆粥", "benefit": "清热，降肝火", "timing": "运动后6小时", "usage": "每周2-3次"},
            {"food": "冬瓜汤", "benefit": "清热利尿，避免热气囤积", "timing": "运动后2小时", "usage": "清汤"},
            {"food": "百合莲子粥", "benefit": "滋阴安神，平复心神", "timing": "运动后2-3小时", "usage": "每周2次"},
            {"food": "黑芝麻", "benefit": "滋阴补肾，恢复阴液", "timing": "恢复期", "usage": "黑芝麻糊，每周3次"}
        ],
        "mental_recovery": "HIIT后需要30分钟的静坐冥想或腹式呼吸，帮助心脏和心神恢复"
    },
    "yoga_stretching": {
        "sport_name": "瑜伽/拉伸",
        "sport_id": "yoga_stretching",
        "tcm_mechanism": "瑜伽和拉伸加速气血运行，配合调息可以疏通经络，需要配合呼吸调理",
        "recovery_timeline": "4-8小时",
        "immediate_care": [
            "瑜伽后进行5-10分钟的调息冥想，配合腹式呼吸",
            "避免立即进行激烈活动，保持缓和状态",
            "充足补水，但避免一次性大量饮水"
        ],
        "diet_recommendations": [
            {"food": "温热花茶", "benefit": "舒缓身心，促进气血循环", "timing": "瑜伽后30分钟", "usage": "玫瑰花或洋甘菊茶"},
            {"food": "蜜枣茶", "benefit": "补气血，缓解身体疲劳", "timing": "瑜伽后1小时", "usage": "温热饮用"},
            {"food": "清粥", "benefit": "清淡易消化，适合瑜伽后", "timing": "瑜伽后2小时", "usage": "清粥配榨菜"}
        ],
        "breathing_emphasis": "瑜伽最重要的是调息和冥想，需要5-10分钟深度放松"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 运动损伤处理
# ─────────────────────────────────────────────────────────────────────────────
INJURY_CARE = {
    "sprain": {
        "injury_type": "sprain",
        "name": "扭伤",
        "tcm_cause": "经络受损，气血瘀滞，需要活血化瘀、消肿止痛",
        "phases": [
            {
                "phase": "急性期（0-24小时）",
                "principle": "RICE（Rest, Ice, Compress, Elevate）+ 冷敷",
                "treatment": [
                    "立即停止运动，抬高患肢",
                    "冷敷患处（冰块或冷毛巾），15分钟/次，间隔1小时",
                    "用弹性绷带轻轻压迫，避免肿胀扩大",
                    "避免按摩或热敷"
                ],
                "diet": "清淡，避免过度进补"
            },
            {
                "phase": "缓解期（24小时-3天）",
                "principle": "逐步转向活血化瘀，缓解疼痛",
                "treatment": [
                    "可开始热敷（温毛巾或热水袋），10-15分钟/次",
                    "轻度按摩周围肌肉，避免直接按压伤处",
                    "活血穴位按摩（足三里、三阴交）"
                ],
                "diet": "山楂粥、黑木耳，促进活血化瘀"
            },
            {
                "phase": "恢复期（3天以后）",
                "principle": "加强活血，促进功能恢复",
                "treatment": [
                    "可进行轻微活动，逐步增加运动范围",
                    "继续温热疗法和穴位按摩",
                    "可使用红花油外敷"
                ]
            }
        ]
    },
    "strain": {
        "injury_type": "strain",
        "name": "拉伤",
        "tcm_cause": "肌肉纤维撕裂，气血瘀滞，需要快速活血化瘀、缓解疼痛",
        "phases": [
            {
                "phase": "急性期（0-48小时）",
                "principle": "冷敷+完全休息，防止进一步撕裂",
                "treatment": [
                    "立即停止运动，受伤肢体完全休息",
                    "冷敷患处（冰块），20分钟/次，间隔2小时",
                    "用弹性绷带固定，避免二次损伤",
                    "抬高患肢，减少肿胀"
                ],
                "diet": "清淡食物，适度补充水分"
            },
            {
                "phase": "缓解期（2-7天）",
                "principle": "开始温和热敷，活血化瘀",
                "treatment": [
                    "改为温热敷（温毛巾），10-15分钟/次，每天2-3次",
                    "轻度穴位按摩（非伤处周围），促进血液循环",
                    "可开始轻微活动（被动或主动活动）"
                ],
                "diet": "山楂、黑木耳、红花浴脚，活血化瘀"
            },
            {
                "phase": "恢复期（7天以后）",
                "principle": "强化活血，逐步恢复功能",
                "treatment": [
                    "继续温热疗法和穴位按摩",
                    "逐步增加活动量和强度",
                    "可使用红花油或膏药外敷"
                ]
            }
        ]
    },
    "soreness": {
        "injury_type": "soreness",
        "name": "肌肉酸痛（DOMS）",
        "tcm_cause": "乳酸堆积、气血瘀滞，通常在运动后24-48小时出现，不属于严重损伤",
        "management": [
            {
                "method": "温和运动",
                "description": "轻度有氧运动（散步、缓跑）可促进血液循环，加速乳酸清除"
            },
            {
                "method": "温热疗法",
                "description": "温毛巾敷患处，10-15分钟，促进血液循环和代谢"
            },
            {
                "method": "穴位按摩",
                "description": "足三里、三阴交穴位按摩，1-2分钟/次，促进气血流通"
            },
            {
                "method": "食疗",
                "description": "山楂粥、黑木耳、红花浴脚，活血化瘀，加速乳酸代谢"
            },
            {
                "method": "充足休息和睡眠",
                "description": "7-8小时睡眠，肌肉在休息中修复"
            }
        ],
        "timeline": "通常3-5天自动恢复，无需特殊治疗"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 赛前调理方案
# ─────────────────────────────────────────────────────────────────────────────
PRE_COMPETITION = {
    "7_days_before": {
        "phase": "赛前7天",
        "focus": "稳定状态，逐步减量，储备能量",
        "training": "减少训练强度至平时的60-70%，保持身体状态但避免过度消耗",
        "diet": [
            {
                "food": "黄芪粥",
                "benefit": "补气，增强耐力和抵抗力",
                "frequency": "每天1次",
                "timing": "早餐"
            },
            {
                "food": "红枣粥",
                "benefit": "补气血，增强体质",
                "frequency": "每周3次",
                "timing": "晚餐"
            },
            {
                "food": "黑鸡汤",
                "benefit": "大补气血，为比赛储备能量",
                "frequency": "每周1-2次",
                "timing": "午餐"
            }
        ],
        "sleep": "保证每晚8小时睡眠，帮助身体储备能量",
        "acupoint_massage": "足三里穴每天按摩1-2分钟，增强体质"
    },
    "3_days_before": {
        "phase": "赛前3天",
        "focus": "轻量训练，充足休息，精神调理",
        "training": "只进行轻度热身运动（总时间<30分钟），保持手感但不消耗体力",
        "diet": [
            {
                "food": "清淡营养食物",
                "benefit": "减少消化负担，避免肠胃不适",
                "key_point": "避免过油过腻，选择清汤"
            },
            {
                "food": "黄芪红枣茶",
                "benefit": "补气，维持能量",
                "frequency": "每天1-2次"
            },
            {
                "food": "蜂蜜水",
                "benefit": "补充快速能量，缓解紧张",
                "frequency": "每天1-2次"
            }
        ],
        "mental_preparation": [
            "冥想或腹式呼吸（每天10分钟），平复比赛前的紧张心情",
            "充足睡眠（8-9小时），为比赛日储备精力"
        ],
        "avoid": ["过度兴奋", "过度饮食", "过度训练"]
    },
    "race_day": {
        "phase": "比赛当日",
        "focus": "充分热身，补充能量，心理建设",
        "pre_competition_meal": {
            "timing": "比赛前3小时",
            "recommendation": [
                {
                    "food": "清粥配榨菜和鸡蛋",
                    "benefit": "易消化，快速补充碳水化合物和蛋白质",
                    "amount": "7-8分饱，避免过饱"
                },
                {
                    "food": "香蕉",
                    "benefit": "快速补充能量和钾，缓解肌肉疲劳",
                    "amount": "1-2根"
                }
            ]
        },
        "hydration": {
            "before": "比赛前2小时：温水500ml",
            "during": "如运动超过1小时：运动饮料或盐水补充电解质",
            "after": "充足补水，逐步恢复"
        },
        "warm_up": "15-20分钟充分热身，唤醒身体，提高心率到适宜状态",
        "mental_tips": [
            "做3-5分钟深度腹式呼吸，平复紧张",
            "积极自我暗示（'我已准备好'），增强自信"
        ]
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 过度训练预警指标
# ─────────────────────────────────────────────────────────────────────────────
OVERTRAINING_SIGNS = {
    "description": "过度训练会导致耗气伤精、免疫力下降，以下是 TCM 视角的预警信号",
    "physical_signs": [
        {
            "sign": "持续肌肉酸痛（超过7天未缓解）",
            "tcm_interpretation": "气血瘀滞严重，恢复能力下降",
            "action": "停止高强度训练，进行3-7天轻度恢复"
        },
        {
            "sign": "反复受伤或新伤迭出",
            "tcm_interpretation": "正气不足，身体防御能力降低",
            "action": "减少训练量，加强食疗补气血"
        },
        {
            "sign": "疲劳感持续，休息后不消退",
            "tcm_interpretation": "脾胃虚弱，气血生成不足，脾失健运",
            "action": "进行脾胃调理，健脾益气食疗"
        },
        {
            "sign": "握力下降，反应迟钝",
            "tcm_interpretation": "肾气虚，正气耗尽，需要深度调理",
            "action": "停止训练7-10天，进行肾气补充"
        }
    ],
    "immunological_signs": [
        {
            "sign": "频繁感冒（1个月内≥2次）",
            "tcm_interpretation": "肺卫不固，正气虚，免疫功能下降",
            "action": "黄芪玉屏风散调理，加强休息"
        },
        {
            "sign": "口腔溃疡反复出现",
            "tcm_interpretation": "心脾虚热，阴血不足",
            "action": "滋阴食疗，减少训练强度"
        },
        {
            "sign": "皮肤问题加重（痘痘、过敏）",
            "tcm_interpretation": "热毒堆积，脾胃功能下降",
            "action": "清热祛湿食疗，减少训练"
        }
    ],
    "mental_signs": [
        {
            "sign": "易怒、烦躁、注意力不集中",
            "tcm_interpretation": "肝气郁结，心神不宁，气血不足以养心",
            "action": "疏肝解郁，安神食疗，减少训练"
        },
        {
            "sign": "睡眠质量下降，多梦或失眠",
            "tcm_interpretation": "心脾虚，肾阴虚，心神失养",
            "action": "安神滋阴食疗，3-7天轻度训练"
        },
        {
            "sign": "对训练兴趣下降，动力不足",
            "tcm_interpretation": "脾气虚，正气不足，身心俱疲",
            "action": "停止训练3-7天，进行全面调理"
        }
    ],
    "recovery_protocol": {
        "immediate_action": "如出现以上3个或以上症状，应立即停止高强度训练",
        "recovery_duration": "3-14天（根据症状严重程度）",
        "recovery_method": [
            "7-9小时充足睡眠",
            "健脾益气食疗（黄芪粥、红枣粥）",
            "穴位按摩（足三里、三阴交、脾俞）",
            "温和散步，避免剧烈运动",
            "必要时咨询医生进行更深入的调理"
        ]
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 运动后调养建议
# ─────────────────────────────────────────────────────────────────────────────
def _generate_post_workout_advice(sport_type: str, duration_minutes: int, intensity: str, current_time: str):
    """根据运动参数生成个性化调养建议"""

    # 强度倍数
    intensity_multiplier = {
        "low": 1.0,
        "medium": 1.5,
        "high": 2.0,
        "extreme": 3.0
    }

    multiplier = intensity_multiplier.get(intensity, 1.5)
    energy_cost = duration_minutes * multiplier
    intensity_label = {
        "low": "低强度",
        "medium": "中等强度",
        "high": "高强度",
        "extreme": "极限强度",
    }[intensity]

    advice = {
        "sport_type": sport_type,
        "duration_minutes": duration_minutes,
        "intensity": intensity,
        "energy_cost_score": int(energy_cost),
        "recovery_emphasis": ""
    }

    # 根据能量消耗程度生成建议
    if energy_cost < 50:
        advice["recovery_emphasis"] = f"{intensity_label}运动，累计负荷较低，恢复需求低"
        advice["recovery_priority"] = ["补水", "轻度拉伸", "清淡食物"]
    elif energy_cost < 100:
        advice["recovery_emphasis"] = f"{intensity_label}运动，累计负荷中等，需要标准恢复"
        advice["recovery_priority"] = ["充足补水", "营养补充", "充足睡眠"]
    elif energy_cost < 150:
        advice["recovery_emphasis"] = f"{intensity_label}运动，累计负荷较高，需要深度恢复"
        advice["recovery_priority"] = ["活血化瘀食疗", "穴位按摩", "8小时睡眠"]
    else:
        advice["recovery_emphasis"] = f"{intensity_label}运动，累计负荷极高，需要全面恢复"
        advice["recovery_priority"] = ["立即补充电解质", "高蛋白食疗", "24小时内穴位深度按摩", "9小时以上睡眠"]

    # 运动类型特异性建议
    if sport_type in SPORTS_RECOVERY:
        sport_data = SPORTS_RECOVERY[sport_type]
        advice["sport_specific_care"] = sport_data["immediate_care"][:2]
        advice["recommended_diet"] = [
            d["food"] for d in sport_data.get("diet_recommendations", [])[:3]
        ]
    else:
        advice["sport_specific_care"] = ["休息", "补水"]
        advice["recommended_diet"] = ["温水", "清粥"]

    return advice


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/recovery/{sport_type}", summary="运动类型TCM恢复方案")
async def recovery_plan(sport_type: str):
    """返回指定运动类型的TCM恢复方案。"""
    if sport_type not in SPORTS_RECOVERY:
        raise HTTPException(status_code=404, detail=f"Unknown sport type: {sport_type}. Supported: {list(SPORTS_RECOVERY.keys())}")

    return {
        "success": True,
        "data": SPORTS_RECOVERY[sport_type]
    }


@router.get("/sports", summary="支持的运动类型列表")
async def sports_list():
    """返回所有支持的运动类型。"""
    sports = [
        {
            "sport_id": sport_id,
            "sport_name": sport_data["sport_name"]
        }
        for sport_id, sport_data in SPORTS_RECOVERY.items()
    ]

    return {
        "success": True,
        "data": sports
    }


@router.get("/injury-care/{injury_type}", summary="运动损伤处理")
async def injury_care(injury_type: str):
    """返回指定损伤类型的处理方案。"""
    if injury_type not in INJURY_CARE:
        raise HTTPException(status_code=404, detail=f"Unknown injury type: {injury_type}. Supported: {list(INJURY_CARE.keys())}")

    return {
        "success": True,
        "data": INJURY_CARE[injury_type]
    }


@router.get("/pre-competition", summary="赛前调理方案")
async def pre_competition():
    """返回赛前调理方案（按天数阶段）。"""
    return {
        "success": True,
        "data": PRE_COMPETITION
    }


@router.get("/overtraining-signs", summary="过度训练预警信号")
async def overtraining_signs():
    """返回过度训练的预警信号（TCM视角）。"""
    return {
        "success": True,
        "data": OVERTRAINING_SIGNS
    }


@router.post("/post-workout", summary="运动后调养建议")
async def post_workout(body: PostWorkoutRequest):
    """
    根据运动参数返回个性化恢复方案。
    """
    sport_type = body.sport_type
    duration_minutes = body.duration_minutes
    intensity = body.intensity
    current_time = body.current_time or datetime.now().isoformat()

    # 验证运动类型
    if sport_type not in SPORTS_RECOVERY:
        return {
            "success": False,
            "data": {"error": f"Unknown sport type. Supported: {list(SPORTS_RECOVERY.keys())}"}
        }

    if duration_minutes <= 0:
        return {
            "success": False,
            "data": {"error": "Duration must be positive integer"}
        }

    # 生成建议
    advice = _generate_post_workout_advice(sport_type, duration_minutes, intensity, current_time)

    return {
        "success": True,
        "data": advice
    }
