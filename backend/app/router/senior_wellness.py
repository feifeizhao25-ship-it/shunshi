"""
顺时 — 50 岁以上老年用户 TCM 专项养护 API
提供 5 大老年常见问题调养方案、低强度运动指导、季节性养生重点。
"""

from fastapi import APIRouter, Query, HTTPException, Path
from typing import Optional, List
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/senior", tags=["senior_wellness"])

# ─────────────────────────────────────────────────────────────────────────────
# 5 大老年常见问题的 TCM 调养方案
# ─────────────────────────────────────────────────────────────────────────────
SENIOR_CONDITIONS = [
    {
        "id": "hypertension",
        "condition": "三高管理（高血压、糖尿病、高血脂）",
        "problems": {
            "hypertension": {
                "tcm_understanding": "肝阳上亢、气血失调",
                "recommended_foods": ["海带", "冬瓜", "山楂", "黑木耳", "绿豆"],
                "forbidden_foods": ["辛辣刺激", "油腻厚腻", "过咸过甜", "烟酒"],
                "acupoints": ["太冲（LV3）", "三阴交（SP6）", "曲池（LI11）"],
                "cautions": "避免剧烈运动，晨起避免突然活动"
            },
            "diabetes": {
                "tcm_understanding": "脾虚湿盛、气虚失调",
                "recommended_foods": ["燕麦", "糙米", "薏米", "黑芝麻", "南瓜"],
                "forbidden_foods": ["甜食糖分", "精白米面", "油炸厚腻", "烟酒"],
                "acupoints": ["足三里（ST36）", "阴陵泉（SP9）", "三阴交（SP6）"],
                "cautions": "定期检测血糖，不可随意停药"
            },
            "hyperlipidemia": {
                "tcm_understanding": "脾虚湿盛、血脂积滞",
                "recommended_foods": ["山楂", "黑木耳", "冬瓜", "绿豆芽", "醋"],
                "forbidden_foods": ["肥肉动物脂肪", "蛋黄过量", "油炸食物", "高糖食品"],
                "acupoints": ["足三里（ST36）", "脾俞（BL20）", "胃俞（BL21）"],
                "cautions": "需配合运动和药物治疗，定期复查血脂"
            }
        },
        "comprehensive_plan": "三高需综合调理，兼顾气血脾胃，禁忌温燥大补，宜清补"
    },
    {
        "id": "osteoporosis",
        "condition": "骨质疏松",
        "tcm_understanding": "肾主骨，年老肾阳衰，骨质疏松源于肾虚",
        "recommended_foods": ["黑芝麻", "黑豆", "核桃", "虾皮", "牛奶", "豆制品"],
        "forbidden_foods": ["过咸食物", "烟酒", "咖啡因过量"],
        "acupoints": ["肾俞（BL23）", "气海俞（BL24）", "足三里（ST36）"],
        "additional_advice": {
            "sunlight": "每日晒太阳 30-60 分钟，促进钙吸收",
            "exercise": "散步、太极、八段锦，增强骨密度",
            "herbal_tea": "黑芝麻粥、黑豆粥、核桃露常饮"
        },
        "warning": "髋部疼痛、身高下降需医学评估"
    },
    {
        "id": "memory_decline",
        "condition": "记忆力下降",
        "tcm_understanding": "心肾不交，心藏神，肾藏精，精血充足则神明",
        "recommended_foods": ["黑芝麻", "核桃", "龙眼", "红枣", "黄鱼", "鸡蛋"],
        "forbidden_foods": ["过饱", "油腻厚腻", "刺激辛辣"],
        "acupoints": ["心俞（BL15）", "肾俞（BL23）", "三阴交（SP6）", "神门（HT7）"],
        "cognitive_exercises": [
            "阅读、书法、绘画，每日 1 小时",
            "学习新技能，刺激大脑",
            "社交活动，保持心情愉悦"
        ],
        "dietary_formula": "黑芝麻核桃粥（健脑益智）、龙眼红枣茶"
    },
    {
        "id": "constipation",
        "condition": "老年便秘",
        "tcm_understanding": "年老气虚，推动无力；或阴虚血少，大肠失润",
        "recommended_foods": ["蜂蜜", "香蕉", "黑芝麻", "海带", "冬瓜", "绿叶蔬菜"],
        "forbidden_foods": ["刺激辛辣", "厚腻难消化", "过冷冷饮"],
        "treatment": {
            "food_therapy": "蜂蜜温水晨起饮，或黑芝麻粥",
            "acupoints": ["足三里（ST36）", "阿是穴（腹部按摩）", "三阴交（SP6）"],
            "massage": "腹部顺时针按摩 10-15 分钟，每日 2 次",
            "herbal_option": "麻子仁丸（气虚型），润肠通便且不损伤脾阳"
        },
        "caution": "避免长期依赖泻药，需调理根本"
    },
    {
        "id": "insomnia",
        "condition": "老年失眠",
        "tcm_understanding": "心气虚、心神不宁；或阴虚火旺、虚热扰神",
        "recommended_foods": ["龙眼", "红枣", "黄芪", "酸枣仁", "蜂蜜", "桂圆茶"],
        "forbidden_foods": ["咖啡因", "烟酒", "辛辣刺激", "睡前过饱"],
        "acupoints": ["神门（HT7）", "安眠穴（耳后）", "三阴交（SP6）"],
        "bedtime_ritual": [
            "睡前 1 小时温水泡脚，加艾草或生姜",
            "按摩神门穴 5-10 分钟",
            "安神茶：龙眼红枣茶，睡前 2 小时饮用",
            "避免午睡过长（不超过 30 分钟）"
        ],
        "lifestyle": "规律作息，睡前避免看屏幕，保持卧室温暖舒适"
    }
]

# ─────────────────────────────────────────────────────────────────────────────
# 适合老年人的低强度运动 (10 种)
# ─────────────────────────────────────────────────────────────────────────────
SENIOR_EXERCISES = [
    {
        "name": "站桩",
        "duration": "15-30 分钟",
        "intensity": "very_low",
        "description": "站立静止，调匀呼吸，强健脾胃、增强体质",
        "contraindications": "心脏病、严重骨质疏松者需避免",
        "tips": "双脚分开与肩同宽，膝盖微弯，全身放松"
    },
    {
        "name": "太极",
        "duration": "30-45 分钟",
        "intensity": "low",
        "description": "缓慢连贯的身体动作，增强平衡感、柔韧性",
        "contraindications": "急性关节炎、严重骨质疏松",
        "tips": "动作要柔和，呼吸自然，避免突然转向"
    },
    {
        "name": "八段锦（坐式版）",
        "duration": "15-20 分钟",
        "intensity": "very_low",
        "description": "八个简单的伸展和扭转动作，适合腿脚不便的老人",
        "contraindications": "腰椎间盘突出需谨慎",
        "tips": "坐在椅子上完成，柔和缓慢，避免过度伸展"
    },
    {
        "name": "健步走",
        "duration": "30-60 分钟",
        "intensity": "low",
        "description": "以能说话的速度行走，增强心肺功能、下肢力量",
        "contraindications": "严重心脏病、关节炎发作期",
        "tips": "选择平坦路面，穿舒适鞋子，避免过快"
    },
    {
        "name": "颈椎操",
        "duration": "10-15 分钟",
        "intensity": "very_low",
        "description": "温和的头颈旋转和伸展，缓解颈椎僵硬",
        "contraindications": "颈椎不稳定、严重颈椎病",
        "tips": "动作缓慢，避免急速旋转，感到微微酸胀即可"
    },
    {
        "name": "肩颈保健操",
        "duration": "10-15 分钟",
        "intensity": "very_low",
        "description": "肩膀旋转、颈部伸展，改善肩颈疲劳",
        "contraindications": "肩脱位、严重肩周炎",
        "tips": "每个动作重复 8-10 次，力度温和"
    },
    {
        "name": "腰部保健操",
        "duration": "10-15 分钟",
        "intensity": "very_low",
        "description": "腰部旋转、侧弯，强健腰椎，增强脾阳",
        "contraindications": "腰椎间盘突出急性期",
        "tips": "站立或坐位均可，动作柔和，避免过度弯曲"
    },
    {
        "name": "八段锦（站式版）",
        "duration": "20-30 分钟",
        "intensity": "low",
        "description": "传统八段锦完整版，强健全身气血",
        "contraindications": "严重平衡障碍、髋部骨折恢复期",
        "tips": "可扶着椅子或墙壁，确保安全"
    },
    {
        "name": "五禽戏",
        "duration": "20-30 分钟",
        "intensity": "low",
        "description": "模仿 5 种动物的动作，舒展全身筋骨",
        "contraindications": "心脏病、严重骨质疏松",
        "tips": "动作可简化，以舒适为原则"
    },
    {
        "name": "温和瑜伽（老年版）",
        "duration": "20-30 分钟",
        "intensity": "low",
        "description": "缓慢伸展，增强柔韧性和平衡感",
        "contraindications": "颈椎不稳定、脊椎问题",
        "tips": "不必追求深度伸展，以舒适和安全为优先"
    }
]

# ─────────────────────────────────────────────────────────────────────────────
# 季节性老年养生重点
# ─────────────────────────────────────────────────────────────────────────────
SEASONAL_WELLNESS = {
    "spring": {
        "season": "春季",
        "tcm_principle": "春季阳气生，肝主春，需疏肝理气，避免肝阳上亢",
        "dietary_focus": {
            "recommended": ["春笋", "香椿", "春菜", "蜂蜜", "大枣"],
            "avoid": ["过酸", "过油腻", "辛辣刺激"],
            "principle": "甘味入脾，蜜与春菜合用，健脾疏肝"
        },
        "lifestyle": {
            "wake_time": "5-6 点起床，顺应阳气生发",
            "exercise": "散步、太极，舒展筋骨",
            "emotional": "远离烦恼，心态平和，避免肝气郁结"
        },
        "acupoints": ["太冲（LV3）", "合谷（LI4）"],
        "warning": "春季易血压波动，三高人群需监测"
    },
    "summer": {
        "season": "夏季",
        "tcm_principle": "夏季心主令，需养心神，避免过度出汗损伤阴液",
        "dietary_focus": {
            "recommended": ["绿豆", "冬瓜", "苦瓜", "莲子", "红枣", "红豆"],
            "avoid": ["过冷冷饮", "厚腻油腻"],
            "principle": "清心火，补心气，养心阴"
        },
        "lifestyle": {
            "wake_time": "5-6 点起床，适当午睡 30 分钟",
            "exercise": "清晨散步，避免午间烈日运动",
            "emotional": "避免过度兴奋，保持心态宁静"
        },
        "acupoints": ["神门（HT7）", "心俞（BL15）"],
        "caution": "避免贪凉吹空调，防止夏季感冒"
    },
    "autumn": {
        "season": "秋季",
        "tcm_principle": "秋季肺主令，需滋阴润肺，防止秋燥伤肺",
        "dietary_focus": {
            "recommended": ["银耳", "蜂蜜", "百合", "雪梨", "山药", "黑芝麻"],
            "avoid": ["辛辣刺激", "过干燥食物"],
            "principle": "甘味润肺，滋阴防燥，强健脾胃"
        },
        "lifestyle": {
            "wake_time": "6-7 点起床，早睡早起润肺",
            "exercise": "散步、太极，适度出汗",
            "emotional": "避免悲伤，保持乐观心态"
        },
        "acupoints": ["肺俞（BL13）", "足三里（ST36）"],
        "special_care": "秋季易咳嗽、皮肤干燥，需加强保湿"
    },
    "winter": {
        "season": "冬季",
        "tcm_principle": "冬季肾主令，需温阳补肾，储备精力迎春",
        "dietary_focus": {
            "recommended": ["黑芝麻", "核桃", "黑豆", "羊肉汤", "红枣", "桂圆"],
            "avoid": ["过冷冷饮", "过度温燥"],
            "principle": "温阳补肾，温而不燥，储备能量"
        },
        "lifestyle": {
            "wake_time": "7-8 点起床，避免过早起床",
            "exercise": "温和散步、站桩，避免过度出汗",
            "emotional": "避免过度思虑，保持心情舒畅"
        },
        "acupoints": ["肾俞（BL23）", "气海（CV6）"],
        "special_care": "冬季需保暖，避免受风着凉，特别是脚部和腰部"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 老年人理想作息（TCM 节律）
# ─────────────────────────────────────────────────────────────────────────────
DAILY_ROUTINE = {
    "routine": [
        {
            "time": "5:00-6:00",
            "activity": "起床",
            "tcm_explanation": "此时阳气初生，符合自然节律，有利于阳气升发",
            "recommendation": "温水漱口，温和散步 20 分钟，温阳健脾"
        },
        {
            "time": "6:30-7:30",
            "activity": "早餐",
            "tcm_explanation": "脾胃阳气最旺，消化功能强，是进食最佳时间",
            "recommendation": "清粥、馄饨汤、鸡蛋，温和易消化，避免油腻过饱"
        },
        {
            "time": "7:30-11:30",
            "activity": "上午活动",
            "tcm_explanation": "阳气充足，精力最佳，宜进行学习、社交、轻度运动",
            "recommendation": "散步、太极、社交活动，适度活动全身"
        },
        {
            "time": "11:30-13:00",
            "activity": "午餐与午休",
            "tcm_explanation": "心经当令，宜安神保心，午睡有利于阳气蓄积",
            "recommendation": "适量午餐，午睡 20-30 分钟（不超过 1 小时）"
        },
        {
            "time": "13:00-17:00",
            "activity": "下午活动",
            "tcm_explanation": "膀胱经当令，宜进行适度运动，增强体质",
            "recommendation": "温和散步、听音乐、阅读，适度活动"
        },
        {
            "time": "17:00-18:30",
            "activity": "晚餐",
            "tcm_explanation": "脾胃功能逐渐减弱，宜清淡易消化，避免过饱",
            "recommendation": "清淡粥、蔬菜、清汤，量少便于消化"
        },
        {
            "time": "18:30-21:00",
            "activity": "晚间活动",
            "tcm_explanation": "阳气收敛，宜缓慢柔和活动，为睡眠做准备",
            "recommendation": "散步、太极、听舒缓音乐、按摩穴位"
        },
        {
            "time": "21:00-21:30",
            "activity": "睡眠准备",
            "tcm_explanation": "此时应入睡，使阴气得以蓄积，恢复能量",
            "recommendation": "温水泡脚、按摩神门穴、安神茶，助眠"
        },
        {
            "time": "21:30-5:00",
            "activity": "睡眠",
            "tcm_explanation": "深度睡眠时间，肝血回流，脏腑修复，不宜被打扰",
            "recommendation": "卧室保暖舒适，关闭灯光和噪音，充分睡眠 7-8 小时"
        }
    ],
    "key_principles": [
        "顺应四时，遵循自然日出日落规律",
        "避免熬夜，保证充足睡眠（7-8 小时）",
        "避免过饱，七八分饱为宜",
        "适度运动，避免过度劳累",
        "保持心态平和，避免过度思虑"
    ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Pydantic 模型
# ─────────────────────────────────────────────────────────────────────────────

class HealthCheckRequest(BaseModel):
    age: int
    symptoms: List[str]
    conditions: List[str]


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/conditions", summary="老年常见问题列表")
async def list_conditions():
    """返回 50+ 老年用户的常见问题 TCM 调养方案列表。"""
    conditions_list = [
        {
            "id": c["id"],
            "condition": c["condition"],
            "brief": c.get("tcm_understanding", "")[:100] if isinstance(c, dict) else ""
        }
        for c in SENIOR_CONDITIONS
    ]
    return {
        "success": True,
        "data": {
            "total": len(conditions_list),
            "conditions": conditions_list
        }
    }


@router.get("/conditions/{condition_id}", summary="老年问题详细 TCM 调养方案")
async def get_condition_detail(condition_id: str):
    """返回指定老年问题的详细 TCM 调养方案。"""
    condition = next((c for c in SENIOR_CONDITIONS if c["id"] == condition_id), None)
    if not condition:
        raise HTTPException(status_code=404, detail=f"Condition '{condition_id}' not found")

    return {
        "success": True,
        "data": condition
    }


@router.get("/exercises", summary="适合老年人的运动列表")
async def get_exercises(intensity: Optional[str] = Query(None, description="very_low|low")):
    """返回适合老年人的低强度运动列表，支持按强度筛选。"""
    exercises = SENIOR_EXERCISES.copy()

    if intensity:
        if intensity not in ["very_low", "low"]:
            raise HTTPException(status_code=400, detail="intensity must be 'very_low' or 'low'")
        exercises = [e for e in exercises if e["intensity"] == intensity]

    return {
        "success": True,
        "data": {
            "total": len(exercises),
            "exercises": exercises,
            "note": "所有运动应循序渐进，避免过度用力，感到疲劳应停止"
        }
    }


@router.get("/seasonal/{season}", summary="季节性老年养生重点")
async def get_seasonal_wellness(season: str = Path(..., description="spring|summer|autumn|winter")):
    """返回指定季节的老年养生重点和饮食建议。"""
    if season not in SEASONAL_WELLNESS:
        raise HTTPException(
            status_code=400,
            detail="season must be 'spring', 'summer', 'autumn', or 'winter'"
        )

    seasonal_plan = SEASONAL_WELLNESS[season]

    return {
        "success": True,
        "data": seasonal_plan
    }


@router.get("/daily-routine", summary="老年人理想作息")
async def get_daily_routine():
    """返回遵循 TCM 节律的老年人理想作息安排。"""
    return {
        "success": True,
        "data": DAILY_ROUTINE
    }


@router.post("/check", summary="老年健康自查")
async def health_check(request: HealthCheckRequest):
    """基于年龄、症状和现有疾病，返回 TCM 养护建议和就医提醒。"""
    if request.age < 50:
        raise HTTPException(status_code=400, detail="This endpoint is for users 50+ years old")

    # 构建初步建议
    recommendations = []
    medical_alerts = []

    # 根据症状生成建议
    if "fatigue" in request.symptoms:
        recommendations.append("气虚症状，建议增加黄芪、红枣等补气食物")
    if "insomnia" in request.symptoms:
        recommendations.append("失眠症状，建议按摩神门穴，饮龙眼红枣茶")
    if "memory_decline" in request.symptoms:
        recommendations.append("记忆力下降，建议黑芝麻核桃粥，增加认知活动")
    if "back_pain" in request.symptoms:
        recommendations.append("腰痛症状，建议按摩肾俞穴，避免劳累")
    if "constipation" in request.symptoms:
        recommendations.append("便秘症状，建议蜂蜜温水，腹部按摩，增加纤维摄入")

    # 根据现有疾病生成建议
    if "hypertension" in request.conditions:
        recommendations.append("高血压患者需监测血压，避免过饱过劳")
        medical_alerts.append("定期检查血压，遵医嘱用药")
    if "diabetes" in request.conditions:
        recommendations.append("糖尿病患者需控制糖分和精白米面")
        medical_alerts.append("定期检查血糖，不可随意停药")
    if "osteoporosis" in request.conditions:
        recommendations.append("骨质疏松患者需补钙，避免跌倒风险")
        medical_alerts.append("定期骨密度检查，防止骨折")

    # 若无任何症状和疾病
    if not recommendations:
        recommendations = [
            "身体状况良好，继续保持规律作息、适度运动、清淡饮食",
            "按照四时调理，春季疏肝理气，夏季养心神，秋季润肺，冬季温阳补肾"
        ]

    return {
        "success": True,
        "data": {
            "age": request.age,
            "symptoms": request.symptoms,
            "conditions": request.conditions,
            "tcm_recommendations": recommendations,
            "medical_alerts": medical_alerts if medical_alerts else ["无特殊警告"],
            "suggested_exercises": "散步、太极、八段锦等低强度运动，每日 30-60 分钟",
            "note": "本建议仅供参考，如有症状需持续，请咨询医疗专业人士"
        }
    }
