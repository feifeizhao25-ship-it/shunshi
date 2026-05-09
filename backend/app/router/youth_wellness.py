"""
顺时 — 儿童青少年 TCM 养护 API
提供不同年龄段的个性化 TCM 养护方案，语言轻松活泼。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/youth", tags=["youth_wellness"])

# ─────────────────────────────────────────────────────────────────────────────
# 年龄段分层数据
# ─────────────────────────────────────────────────────────────────────────────
AGE_GROUPS = {
    "6-9": {
        "age_range": "6-9岁",
        "stage_name": "学龄初期",
        "growth_focus": "脾胃健强，为后续生长发育打基础",
        "tcm_organ_priority": ["脾", "胃", "肾"],
        "dietary_needs": "清淡易消化，避免过甜过腻食物；提倡牛奶、鸡蛋、瘦肉等优质蛋白",
        "sleep_requirements": "每天8-10小时；建议21:00前入睡，以保护生长激素分泌",
        "exercise_minutes_daily": "60-90分钟；包括跑跳、游戏、球类运动",
        "common_issues": ["近视防控", "注意力不足", "厌食偏食", "反复感冒", "睡眠不足"],
        "seasonal_focus": {
            "spring": "顺应春阳生发，增加户外活动；适度进补但避免过补",
            "summer": "避免过度吹空调；清淡饮食，适当冬病夏治",
            "autumn": "滋阴润燥，适度进补；秋季是儿童长高黄金期",
            "winter": "温阳护阳气；食用温热食物，避免过度消耗"
        }
    },
    "10-13": {
        "age_range": "10-13岁",
        "stage_name": "学龄中期（生长突增期）",
        "growth_focus": "补脾益气，促进生长发育；关注骨骼密度",
        "tcm_organ_priority": ["脾", "肾", "胃"],
        "dietary_needs": "增加营养摄入，特别是钙、铁、锌；适度补气血；可适当进补（如黄芪粥）",
        "sleep_requirements": "每天8-10小时；此时段容易因学业压力睡眠不足，需重视午睡（20分钟）",
        "exercise_minutes_daily": "60-120分钟；体操、跳绳、篮球等有助长高的运动",
        "common_issues": ["近视防控", "注意力不足", "生长发育迟缓", "考试焦虑", "睡眠不足"],
        "seasonal_focus": {
            "spring": "顺应生长发育加速，增加运动强度；食疗补气血",
            "summer": "清热祛湿，避免贪凉；适度午休保证生长激素分泌",
            "autumn": "秋季长高黄金期，重点进补；食用滋补品（红枣、山药等）",
            "winter": "温阳补肾，储存能量为春季长高做准备"
        }
    },
    "14-18": {
        "age_range": "14-18岁",
        "stage_name": "青少年期（青春期）",
        "growth_focus": "疏肝解郁，调理脾胃；关注身心平衡",
        "tcm_organ_priority": ["肝", "脾", "肾"],
        "dietary_needs": "全面均衡营养；清热解毒（预防青春痘）；适度补气血但避免过补导致早熟",
        "sleep_requirements": "每天7-9小时；此时易出现熬夜现象，需引导健康作息",
        "exercise_minutes_daily": "120-150分钟；可选择自己喜欢的运动（跑步、球类、瑜伽等）",
        "common_issues": ["近视防控", "青春期痘痘", "考试焦虑", "睡眠不足", "情绪波动"],
        "seasonal_focus": {
            "spring": "疏肝解郁，缓解学业压力；增加户外活动调节心情",
            "summer": "清热祛痘；适度运动但避免过度消耗",
            "autumn": "调理肠胃，滋阴润燥；可进行学业冲刺前的身体调理",
            "winter": "温阳保护阳气；充足睡眠，为高考或升学做准备"
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 儿童常见问题TCM方案
# ─────────────────────────────────────────────────────────────────────────────
CONDITIONS = {
    "myopia": {
        "condition_id": "myopia",
        "name": "近视防控",
        "tcm_cause": "久视伤血，肝血不足导致目光无神；脾虚水湿困脾，眼睛容易疲劳",
        "age_applicable": ["6-9", "10-13", "14-18"],
        "prevention_measures": [
            "控制屏幕时间：每看屏幕20分钟，休息20秒，看向6米外",
            "增加户外活动：每天至少2小时户外活动（自然光有助眼睛发育）",
            "正确读书姿势：距离30厘米，光线充足，避免歪斜"
        ],
        "diet": [
            {"ingredient": "枸杞", "benefit": "补肝血，明目", "usage": "泡水或粥，5-10粒/天"},
            {"ingredient": "黑芝麻", "benefit": "补肝肾，黑目光", "usage": "黑芝麻糊，2-3次/周"},
            {"ingredient": "胡萝卜", "benefit": "含β胡萝卜素，保护视力", "usage": "生吃或熟吃，每周3次"},
            {"ingredient": "蓝莓", "benefit": "抗眼疲劳，含花青素", "usage": "新鲜或果干，适量"}
        ],
        "eye_exercises": [
            {
                "name": "眼球转动操",
                "steps": ["眼睛向上、下、左、右各看5秒", "眼睛顺时针转圈5次，逆时针5次"],
                "frequency": "每天2-3次"
            },
            {
                "name": "远近调焦",
                "steps": ["先看近处物体（30cm）10秒", "再看远处（6米外）10秒", "交替进行"],
                "frequency": "每天3次"
            }
        ]
    },
    "attention_deficit": {
        "condition_id": "attention_deficit",
        "name": "注意力不足",
        "tcm_cause": "心脾两虚，心神不宁；脾虚运化不足，大脑供血不足",
        "age_applicable": ["6-9", "10-13", "14-18"],
        "treatment_approach": "健脾益气，安心神",
        "diet": [
            {"ingredient": "红枣", "benefit": "补中益气，安神", "usage": "红枣粥或直接食用，3-5枚/天"},
            {"ingredient": "桂圆", "benefit": "补气血，安神", "usage": "粥或泡水，5-8粒/天"},
            {"ingredient": "黄芪", "benefit": "补气，增强耐力", "usage": "黄芪粥或煮粥，3克/天"},
            {"ingredient": "山药", "benefit": "健脾益气，增强记忆", "usage": "山药粥，每周2-3次"}
        ],
        "brain_boosting_foods": ["核桃", "鸡蛋", "牛奶", "鱼类（DHA丰富）"],
        "lifestyle": [
            "保证充足睡眠（8-10小时）",
            "每天30分钟有氧运动，增加脑部血流量",
            "减少屏幕时间，避免分散注意力",
            "冥想或腹式呼吸（5分钟/天）可提升专注力"
        ]
    },
    "poor_appetite": {
        "condition_id": "poor_appetite",
        "name": "厌食/偏食",
        "tcm_cause": "脾虚，运化功能下降，胃口差；或食欲中枢调理不足",
        "age_applicable": ["6-9", "10-13"],
        "treatment_approach": "健脾开胃，调理脾胃功能",
        "diet": [
            {"ingredient": "山楂", "benefit": "消食健脾，促进消化", "usage": "山楂粥或山楂茶，每周2-3次"},
            {"ingredient": "薏米", "benefit": "健脾利湿，开胃", "usage": "薏米粥，每周2次"},
            {"ingredient": "红豆", "benefit": "健脾利湿", "usage": "红豆粥，每周1-2次"}
        ],
        "home_massage": [
            {
                "name": "推脾经",
                "technique": "从腕部向肘部推，沿拇指内侧，力度温和",
                "duration_minutes": 5,
                "frequency": "每天1次，饭前30分钟"
            },
            {
                "name": "摩腹",
                "technique": "用掌根顺时针摩腹，力度轻柔",
                "duration_minutes": 5,
                "frequency": "每天1-2次"
            }
        ],
        "avoid": ["油腻食物", "冷饮", "过度吃零食"]
    },
    "recurrent_cold": {
        "condition_id": "recurrent_cold",
        "name": "反复感冒",
        "tcm_cause": "肺卫不固，正气虚弱；脾虚运化差，痰湿堆积",
        "age_applicable": ["6-9", "10-13"],
        "prevention_strategy": "增强正气，固表卫气",
        "diet": [
            {"ingredient": "黄芪", "benefit": "补气固表，增强免疫力", "usage": "黄芪粥或黄芪水，3克/天"},
            {"ingredient": "红枣", "benefit": "补中益气，增强抵抗力", "usage": "红枣粥，3-5枚/天"},
            {"ingredient": "姜", "benefit": "温阳祛湿，预防感冒", "usage": "生姜红糖水，每周1-2次"}
        ],
        "formula_recommend": "玉屏风散（黄芪+白术+防风）可长期调理，建议咨询医生",
        "lifestyle": [
            "增加户外活动，增强体质",
            "避免过度疲劳和压力",
            "保持环境通风，减少交叉感染",
            "根据季节增减衣物，避免着凉"
        ]
    },
    "delayed_growth": {
        "condition_id": "delayed_growth",
        "name": "生长发育迟缓",
        "tcm_cause": "脾肾两虚，先天禀赋不足；后天营养摄入不足",
        "age_applicable": ["10-13"],
        "treatment_approach": "脾肾双补，促进生长发育",
        "diet": [
            {"ingredient": "黄芪", "benefit": "补气，促进生长", "usage": "黄芪鸡汤，每周2次"},
            {"ingredient": "黑芝麻", "benefit": "补肝肾，促长高", "usage": "黑芝麻糊，每周3次"},
            {"ingredient": "山药", "benefit": "健脾益肾", "usage": "山药粥，每周3次"},
            {"ingredient": "核桃", "benefit": "补肾，含丰富营养", "usage": "每天1-2枚"}
        ],
        "key_nutrients": ["钙（牛奶、豆制品）", "铁（红肉、绿叶蔬菜）", "锌（牡蛎、瘦肉）", "蛋白质"],
        "important_note": "需定期监测生长指标，如严重迟缓建议就医检查"
    },
    "acne": {
        "condition_id": "acne",
        "name": "青春期痘痘",
        "tcm_cause": "青春期激素分泌旺盛，肺热血热；脾虚湿热困脾",
        "age_applicable": ["14-18"],
        "treatment_approach": "清热解毒，调理肠胃",
        "diet": [
            {"ingredient": "绿豆", "benefit": "清热解毒，清除皮肤热毒", "usage": "绿豆粥或绿豆水，每周2-3次"},
            {"ingredient": "冬瓜", "benefit": "清热利尿，避免热气囤积", "usage": "冬瓜汤，每周2次"},
            {"ingredient": "薏米", "benefit": "清热祛湿", "usage": "薏米粥，每周2次"}
        ],
        "avoid_foods": ["煎炸食物", "辛辣刺激食物", "高糖高脂肪食物", "巧克力", "浓茶咖啡"],
        "skincare": [
            "使用温水洗脸，早晚各一次",
            "避免过度清洁（导致皮肤干燥）",
            "不要用手挤压痘痘（容易留疤）",
            "使用中医护肤品（如绿豆粉面膜）"
        ]
    },
    "sleep_insufficiency": {
        "condition_id": "sleep_insufficiency",
        "name": "睡眠不足/熬夜",
        "tcm_cause": "心肾不交，心火旺盛，难以入睡；或学业压力导致心神不宁",
        "age_applicable": ["14-18"],
        "treatment_approach": "滋阴降火，调理心神",
        "diet": [
            {"ingredient": "百合", "benefit": "滋阴安神，润肺", "usage": "百合粥或百合炖雪梨，每周2次"},
            {"ingredient": "红枣", "benefit": "补气安神", "usage": "红枣茶或粥，3-5枚/天"},
            {"ingredient": "莲子", "benefit": "安神定志，交心肾", "usage": "莲子粥，每周2次"}
        ],
        "sleep_hygiene": [
            "建立规律作息，23:00前入睡",
            "睡前1小时避免屏幕刺激",
            "卧室温度18-22℃，避免过热",
            "可做5-10分钟腹式呼吸或冥想"
        ],
        "acupoint_massage": [
            {
                "name": "按摩神门穴（腕部）",
                "frequency": "睡前5分钟"
            },
            {
                "name": "按摩涌泉穴（脚心）",
                "frequency": "睡前5分钟"
            }
        ]
    },
    "exam_anxiety": {
        "condition_id": "exam_anxiety",
        "name": "考试焦虑",
        "tcm_cause": "肝气郁结，心神不宁；脾虚气弱导致自信心不足",
        "age_applicable": ["10-13", "14-18"],
        "treatment_approach": "疏肝解郁，安心定志",
        "diet": [
            {"ingredient": "玫瑰花", "benefit": "疏肝解郁，舒缓压力", "usage": "玫瑰花茶，每周2-3次"},
            {"ingredient": "红枣", "benefit": "补气安神，增强自信", "usage": "红枣茶，3-5枚/天"},
            {"ingredient": "黄芪", "benefit": "补气，增强体质应对压力", "usage": "黄芪茶，3克/天"}
        ],
        "stress_relief": [
            "每天30分钟运动（释放压力荷尔蒙）",
            "晚间散步（放松身心）",
            "腹式呼吸或冥想（10分钟/天）",
            "与家人交流，获得心理支持"
        ]
    },
    "sports_injury": {
        "condition_id": "sports_injury",
        "name": "运动损伤",
        "tcm_cause": "活动过度，气血瘀滞；或动作不当导致肌肉拉伤",
        "age_applicable": ["10-13", "14-18"],
        "treatment_approach": "活血化瘀，消肿止痛",
        "immediate_care": [
            {
                "phase": "急性期（24小时内）",
                "treatment": "冷敷（冰块或冷毛巾），10-15分钟/次，间隔1小时；限制活动"
            },
            {
                "phase": "缓解期（24小时-3天）",
                "treatment": "热敷（温毛巾或热水袋），10-15分钟/次；轻微活动开始恢复"
            }
        ],
        "diet": [
            {"ingredient": "山楂", "benefit": "活血化瘀，消肿", "usage": "山楂茶，每周2-3次"},
            {"ingredient": "黑木耳", "benefit": "活血化瘀", "usage": "黑木耳粥，每周2次"},
            {"ingredient": "红花油", "benefit": "外用活血", "usage": "适量涂抹伤部，每天2-3次"}
        ],
        "important_note": "严重损伤应及时就医，中医调理仅作为辅助"
    },
    "obesity": {
        "condition_id": "obesity",
        "name": "肥胖倾向",
        "tcm_cause": "痰湿体质，脾虚运化能力弱；食物摄入过多，活动不足",
        "age_applicable": ["6-9", "10-13", "14-18"],
        "treatment_approach": "健脾祛湿，调理代谢",
        "diet": [
            {"ingredient": "薏米", "benefit": "健脾祛湿，利尿", "usage": "薏米粥，每周3次"},
            {"ingredient": "红豆", "benefit": "利尿祛湿，健脾", "usage": "红豆粥或红豆薏米粥，每周2-3次"},
            {"ingredient": "冬瓜", "benefit": "清热利尿，减肥", "usage": "冬瓜汤，每周2次"}
        ],
        "lifestyle": [
            "增加运动时间（每天60-120分钟）",
            "减少高糖高脂肪食物摄入",
            "避免过度进补",
            "建立规律饮食习惯，三餐定时"
        ]
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 季节性儿童养护重点
# ─────────────────────────────────────────────────────────────────────────────
SEASONAL_CARE = {
    "spring": {
        "season": "春季",
        "tcm_principle": "春季阳气生发，儿童阳气也开始活跃，是生长发育的加速期",
        "key_points": [
            "增加户外活动，感受春阳生机",
            "适度进补，但避免过补（易导致早熟）",
            "衣着要'捂'，避免早脱厚衣导致着凉"
        ],
        "recommended_diet": [
            {"food": "春笋", "benefit": "助阳气生发，促进生长"},
            {"food": "春菜", "benefit": "新鲜蔬菜，补充维生素"},
            {"food": "蜂蜜", "benefit": "润肠通便，补气血"},
            {"food": "红枣粥", "benefit": "补气血，顺应春阳"}
        ],
        "avoid": ["过度进补", "油腻厚腻食物", "过早脱掉厚衣"],
        "activities": "增加户外运动，放风筝、跑步、跳绳等"
    },
    "summer": {
        "season": "夏季",
        "tcm_principle": "夏季心火旺盛，儿童容易烦躁不安；需清心安神，同时避免过度吹空调",
        "key_points": [
            "清淡饮食，避免热气堆积",
            "适度冬病夏治（三伏贴等，需专业指导）",
            "避免过度吹空调，导致脾胃虚弱"
        ],
        "recommended_diet": [
            {"food": "绿豆粥", "benefit": "清热祛湿，清心火"},
            {"food": "冬瓜", "benefit": "清热利尿，避免热气囤积"},
            {"food": "薏米粥", "benefit": "健脾祛湿"},
            {"food": "百合", "benefit": "润肺安神，适合夏季"}
        ],
        "avoid": ["过度吹空调", "冷饮过多", "油腻厚腻食物"],
        "activities": "适度运动但避免中午高温；可游泳增强体质"
    },
    "autumn": {
        "season": "秋季",
        "tcm_principle": "秋季是儿童长高黄金期（可长5-10cm），同时秋燥易伤阴液",
        "key_points": [
            "滋阴润燥，适度进补",
            "增加营养摄入，特别是含钙、铁、锌的食物",
            "秋季长高期，运动和睡眠特别重要"
        ],
        "recommended_diet": [
            {"food": "黑芝麻", "benefit": "补肝肾，促进长高"},
            {"food": "蜂蜜", "benefit": "润燥补气"},
            {"food": "银耳", "benefit": "滋阴润肺"},
            {"food": "山药", "benefit": "健脾益肾，促进吸收"}
        ],
        "avoid": ["过度燥热食物", "煎炸食物"],
        "activities": "增加户外活动；跳绳、篮球等有助长高的运动"
    },
    "winter": {
        "season": "冬季",
        "tcm_principle": "冬季是储备能量的季节，需温阳补肾，为春季生长蓄力",
        "key_points": [
            "温阳补肾，适度进补（冬季进补，春来打虎）",
            "保证充足睡眠，冬季阳气潜藏，睡眠特别重要",
            "避免过度消耗，适度运动即可"
        ],
        "recommended_diet": [
            {"food": "黑鸡汤", "benefit": "温阳补气血，冬季重点进补"},
            {"food": "黑豆", "benefit": "补肾，含丰富蛋白"},
            {"food": "红糖生姜水", "benefit": "温阳祛湿"},
            {"food": "核桃", "benefit": "补肾，含DHA益脑"}
        ],
        "avoid": ["过度消耗（运动过度）", "熬夜"],
        "sleep_importance": "冬季需保证8-10小时睡眠，21:00前入睡"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 家长版推拿手法
# ─────────────────────────────────────────────────────────────────────────────
MASSAGE_GUIDE = {
    "techniques": [
        {
            "name": "推法",
            "body_part": "脾经、肾经、心经等",
            "technique": "用拇指从腕部向肘部推，力度温和，节奏均匀",
            "duration_minutes": 3,
            "benefit": "补气血，增强脾胃功能",
            "when_to_use": "厌食、脾虚、疲劳"
        },
        {
            "name": "按摩法",
            "body_part": "穴位（足三里、三阴交、合谷等）",
            "technique": "用拇指指腹按住穴位，旋转按摩，力度适中至酸胀感",
            "duration_minutes": 2,
            "benefit": "激发穴位功效，调理相关脏腑",
            "when_to_use": "提神、缓解疲劳、增强免疫力"
        },
        {
            "name": "摩腹法",
            "body_part": "腹部（脐周）",
            "technique": "用掌根顺时针摩腹，力度轻柔，每周期30秒",
            "duration_minutes": 5,
            "benefit": "健脾和胃，促进消化，增强免疫力",
            "when_to_use": "厌食、腹胀、消化不良"
        },
        {
            "name": "拍打法",
            "body_part": "背部（肺俞、脾俞区域）",
            "technique": "用手掌或五指轻轻拍打，力度温和，避免伤害",
            "duration_minutes": 3,
            "benefit": "激活背部经络，增强免疫力，预防感冒",
            "when_to_use": "预防感冒、增强体质、疲劳"
        },
        {
            "name": "点穴法",
            "body_part": "太阳穴、风池穴等",
            "technique": "用食指或中指指尖轻轻点压，停留3-5秒，逐渐加力",
            "duration_minutes": 2,
            "benefit": "快速提神，缓解头痛和眼疲劳",
            "when_to_use": "困倦、头痛、眼疲劳"
        }
    ],
    "important_notes": [
        "小儿推拿力度要轻，避免造成皮肤损伤",
        "饭后1小时以内避免做推拿（影响消化）",
        "避免在孩子哭闹或饥饿时进行推拿",
        "如皮肤有破损、发烧（>38.5℃）时，避免推拿",
        "推拿时间不宜过长（最多15-20分钟）",
        "建议每周2-3次为宜，坚持进行效果更好"
    ]
}

# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/age-guide/{age_group}", summary="年龄段养护指南")
async def age_guide(age_group: str):
    """返回指定年龄段的养护指南。"""
    if age_group not in AGE_GROUPS:
        raise HTTPException(status_code=404, detail=f"Invalid age group: {age_group}. Supported: {list(AGE_GROUPS.keys())}")

    return {
        "success": True,
        "data": AGE_GROUPS[age_group]
    }


@router.get("/conditions", summary="常见问题列表")
async def conditions():
    """返回儿童常见问题列表。"""
    condition_list = [
        {
            "condition_id": cond_id,
            "name": cond["name"],
            "tcm_cause": cond["tcm_cause"],
            "age_applicable": cond.get("age_applicable", [])
        }
        for cond_id, cond in CONDITIONS.items()
    ]

    return {
        "success": True,
        "data": condition_list
    }


@router.get("/conditions/{condition_id}", summary="详细调养方案")
async def condition_detail(condition_id: str):
    """返回指定问题的详细调养方案。"""
    if condition_id not in CONDITIONS:
        raise HTTPException(status_code=404, detail=f"Unknown condition: {condition_id}")

    return {
        "success": True,
        "data": CONDITIONS[condition_id]
    }


@router.get("/seasonal/{season}", summary="季节性儿童养护")
async def seasonal_care(season: str):
    """返回指定季节的儿童养护重点。"""
    if season not in SEASONAL_CARE:
        raise HTTPException(status_code=404, detail=f"Invalid season: {season}. Supported: {list(SEASONAL_CARE.keys())}")

    return {
        "success": True,
        "data": SEASONAL_CARE[season]
    }


@router.get("/massage-guide", summary="家长版推拿手法指南")
async def massage_guide():
    """返回家长版推拿手法指南。"""
    return {
        "success": True,
        "data": MASSAGE_GUIDE
    }


@router.post("/advice", summary="个性化建议")
async def personalized_advice(body: dict):
    """
    根据年龄和症状返回个性化建议。
    body: {age: 7, symptoms: ["近视", "注意力不足"], season: "spring" (optional)}
    """
    age = body.get("age")
    symptoms = body.get("symptoms", [])
    season = body.get("season", "spring")

    # 判断年龄段
    age_group = None
    if 6 <= age <= 9:
        age_group = "6-9"
    elif 10 <= age <= 13:
        age_group = "10-13"
    elif 14 <= age <= 18:
        age_group = "14-18"
    else:
        return {
            "success": False,
            "data": {"error": "Age must be between 6 and 18"}
        }

    # 获取年龄段指南
    age_guide_data = AGE_GROUPS[age_group]

    # 获取症状方案
    condition_advices = []
    for symptom in symptoms:
        # 模糊匹配症状
        for cond_id, cond in CONDITIONS.items():
            if symptom in cond["name"] or cond["name"] in symptom:
                condition_advices.append({
                    "condition": cond["name"],
                    "tcm_cause": cond["tcm_cause"],
                    "diet": cond.get("diet", [])[:3],  # 返回前3个食疗建议
                    "key_tips": cond.get("lifestyle", cond.get("treatment_approach", ""))[:2]
                })
                break

    # 获取季节性建议
    seasonal_data = SEASONAL_CARE.get(season, SEASONAL_CARE["spring"])

    return {
        "success": True,
        "data": {
            "age": age,
            "age_group": age_group,
            "age_guide_summary": {
                "stage_name": age_guide_data["stage_name"],
                "growth_focus": age_guide_data["growth_focus"],
                "sleep_requirements": age_guide_data["sleep_requirements"],
                "exercise_minutes_daily": age_guide_data["exercise_minutes_daily"]
            },
            "condition_advices": condition_advices if condition_advices else [{"message": "No matching conditions found"}],
            "seasonal_tips": {
                "season": seasonal_data["season"],
                "key_points": seasonal_data["key_points"][:2],
                "recommended_diet": seasonal_data["recommended_diet"][:2]
            }
        }
    }
