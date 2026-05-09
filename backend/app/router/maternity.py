"""
顺时 — 孕产妇 TCM 专项养护 API
提供孕期月份养护方案、禁用草药、产后恢复、哺乳期饮食指南。
【医疗免责声明】本内容仅供参考，请遵医嘱，不替代专业医疗建议。
"""

from fastapi import APIRouter, Query, Path, HTTPException
from typing import Optional, List
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/maternity", tags=["maternity_wellness"])

# ─────────────────────────────────────────────────────────────────────────────
# 孕期 10 个月（农历月）养生方案
# ─────────────────────────────────────────────────────────────────────────────
PREGNANCY_MONTHS = [
    {
        "month": 1,
        "theme": "初怀孕，宜静养",
        "fetal_development_stage": "受精卵着床、心脏原基出现",
        "recommended_foods": ["黑芝麻", "红枣", "山药", "薏米", "绿豆", "冬瓜"],
        "forbidden_foods": ["螃蟹", "薏米过量", "马齿苋", "荸荠"],
        "forbidden_herbs": ["红花", "桃仁", "益母草", "三棱", "莪术", "黄芪过量"],
        "safe_acupoints": ["SP6", "ST36"],
        "forbidden_acupoints": ["LI4", "SP6（强刺激禁用）"],
        "exercise_advice": "卧床休息为主，轻缓散步，避免劳累",
        "emotional_focus": "保持宁静心态，避免惊吓、过度思虑",
        "tcm_principle": "肾气初动，精血聚而成形，需静养以安胎",
        "warning_signs": "阴道出血、腹部剧痛、头晕眼花需立即就医"
    },
    {
        "month": 2,
        "theme": "胎元初长，防堕胎",
        "fetal_development_stage": "脑部、脊髓形成，心脏、血管初成",
        "recommended_foods": ["黑芝麻粥", "红枣粥", "鸡汤", "骨汤", "猪脚汤"],
        "forbidden_foods": ["螃蟹", "甲鱼", "薏米", "马齿苋", "冰冷食物"],
        "forbidden_herbs": ["红花", "桃仁", "益母草", "三棱", "莪术", "当归过量", "丹参"],
        "safe_acupoints": ["ST36"],
        "forbidden_acupoints": ["LI4", "SP6", "GV20"],
        "exercise_advice": "宜散步，禁止剧烈运动、性生活",
        "emotional_focus": "远离紧张环境，保持心态平和",
        "tcm_principle": "胎元初长，血液聚于子宫，禁活血化瘀",
        "warning_signs": "腰酸、腹痛、阴道出血、晕眩需急诊"
    },
    {
        "month": 3,
        "theme": "形体初成，宜补气血",
        "fetal_development_stage": "五官雏形初现，四肢萌芽",
        "recommended_foods": ["黄芪炖鸡", "红枣鸡汤", "黑木耳", "银耳粥", "猪肉"],
        "forbidden_foods": ["螃蟹", "薏米", "冷饮", "辛辣刺激食物", "油腻厚腻之物"],
        "forbidden_herbs": ["红花", "桃仁", "益母草", "三棱", "莪术", "丹参", "赤芍"],
        "safe_acupoints": ["ST36", "BL23"],
        "forbidden_acupoints": ["LI4", "SP6", "GV20"],
        "exercise_advice": "温和散步，避免重体力劳动",
        "emotional_focus": "保持喜悦心情，避免愤怒、忧思",
        "tcm_principle": "胎儿形体初成，气血需充足，宜补不宜泻",
        "warning_signs": "腹痛、阴道出血、乏力昏迷需就医"
    },
    {
        "month": 4,
        "theme": "胎儿渐长，滋阴安胎",
        "fetal_development_stage": "身体快速生长，骨骼硬化，性器官初现",
        "recommended_foods": ["燕窝", "银耳莲子粥", "黄芪红枣粥", "鸡汤", "鱼汤", "蛋白"],
        "forbidden_foods": ["螃蟹", "薏米", "辛辣", "咖啡因", "过咸"],
        "forbidden_herbs": ["活血化瘀类（红花、桃仁等）", "温燥大补类"],
        "safe_acupoints": ["ST36", "BL23", "KD3"],
        "forbidden_acupoints": ["LI4", "SP6"],
        "exercise_advice": "温和瑜伽、散步，强度逐渐增加",
        "emotional_focus": "聆听舒缓音乐，培养与胎儿的感应",
        "tcm_principle": "脾主运化气血，肾主系胎，宜滋阴保胎",
        "warning_signs": "腹痛持续、阴道流血、四肢浮肿异常需就医"
    },
    {
        "month": 5,
        "theme": "胎动可感，加强滋补",
        "fetal_development_stage": "胎动明显，听觉器官发育，指甲出现",
        "recommended_foods": ["黑鱼汤", "鸽子汤", "黄芪炖母鸡", "核桃", "黑芝麻", "蛋类"],
        "forbidden_foods": ["螃蟹", "薏米", "辛辣刺激", "过咸过甜"],
        "forbidden_herbs": ["活血破气类", "温燥辛辣类"],
        "safe_acupoints": ["ST36", "BL23", "SP6（温和）"],
        "forbidden_acupoints": ["LI4"],
        "exercise_advice": "散步、孕妇瑜伽、游泳为佳",
        "emotional_focus": "与胎儿互动，听舒缓音乐，避免吵闹环境",
        "tcm_principle": "脾胃强健则气血充足，胎儿方能快速生长",
        "warning_signs": "腹痛、阴道出血、高血压症状、眼花需警惕"
    },
    {
        "month": 6,
        "theme": "形体已具，防胎动过频",
        "fetal_development_stage": "胎儿约500克，肺脏初步形成，眼睛睁开",
        "recommended_foods": ["瘦肉粥", "鱼类", "豆类", "坚果", "新鲜蔬菜", "水果"],
        "forbidden_foods": ["螃蟹", "薏米", "过辛辣", "过甜腻"],
        "forbidden_herbs": ["温燥大补", "活血化瘀类"],
        "safe_acupoints": ["ST36", "BL23", "KD3"],
        "forbidden_acupoints": ["LI4、强力刺激穴位"],
        "exercise_advice": "孕妇操、散步、游泳、瑜伽为主",
        "emotional_focus": "冥想、静坐，培养亲子感应",
        "tcm_principle": "滋阴补气并重，防止阴虚火旺导致胎动频繁",
        "warning_signs": "宫缩异常、胎动剧减/剧增、高血压、水肿加重需就医"
    },
    {
        "month": 7,
        "theme": "胎儿脏腑成，润肺安产",
        "fetal_development_stage": "胎儿约1000克，五脏六腑逐渐功能化，脑细胞活跃",
        "recommended_foods": ["银耳粥", "雪梨", "蜂蜜", "百合", "莲子", "红枣", "鸡汤"],
        "forbidden_foods": ["螃蟹", "薏米", "辛辣温燥", "过咸厚腻"],
        "forbidden_herbs": ["温燥类", "活血破气类"],
        "safe_acupoints": ["ST36", "BL23", "KD3"],
        "forbidden_acupoints": ["LI4、SP6"],
        "exercise_advice": "温和散步、孕妇保健操，为顺产做准备",
        "emotional_focus": "调适心态，预想顺利分娩，减少恐惧",
        "tcm_principle": "肺主气，肺润则呼吸顺畅，有利于顺产",
        "warning_signs": "胎位不正、羊水异常、高血压、蛋白尿需专科跟踪"
    },
    {
        "month": 8,
        "theme": "冲刺孕晚期，调理气机",
        "fetal_development_stage": "胎儿约1500克，中枢神经系统、感觉器官发育完成",
        "recommended_foods": ["黑鱼", "鸡蛋", "坚果", "黑芝麻", "红枣", "葡萄干"],
        "forbidden_foods": ["螃蟹", "薏米", "过辛过热", "过咸过腻"],
        "forbidden_herbs": ["温燥补气过度", "活血类"],
        "safe_acupoints": ["BL23", "KD3", "ST36"],
        "forbidden_acupoints": ["LI4、SP6"],
        "exercise_advice": "散步为主，盆底肌肉锻炼，为分娩储备力量",
        "emotional_focus": "稳定情绪，避免过度劳累和紧张",
        "tcm_principle": "调理气机，防止气滞，为分娩做生理准备",
        "warning_signs": "频繁宫缩、见红、漏尿加重、胎动异常需复诊"
    },
    {
        "month": 9,
        "theme": "胎儿已熟，润肠促产",
        "fetal_development_stage": "胎儿约2000克，器官发育成熟，可独立存活",
        "recommended_foods": ["蜂蜜", "香蕉", "黑芝麻", "核桃", "红枣", "瘦肉粥"],
        "forbidden_foods": ["螃蟹", "薏米", "辛辣厚腻", "过甜过咸"],
        "forbidden_herbs": ["温燥大补", "活血化瘀"],
        "safe_acupoints": ["ST36", "BL23"],
        "forbidden_acupoints": ["LI4、SP6"],
        "exercise_advice": "散步、盆底肌操，为即将来临的分娩做准备",
        "emotional_focus": "平和心态，充分休息，期待新生命",
        "tcm_principle": "润肠通便防止便秘，促进气血流通有利自然分娩",
        "warning_signs": "见红、规律宫缩、阴道流液需立即入院"
    },
    {
        "month": 10,
        "theme": "待产期，沉着应对",
        "fetal_development_stage": "胎儿约2500-3500克，各器官发育完成，随时可出生",
        "recommended_foods": ["清汤面", "清粥", "白煮蛋", "清淡易消化食物"],
        "forbidden_foods": ["辛辣刺激", "厚腻难消化", "过甜过咸"],
        "forbidden_herbs": ["活血催产药需医嘱（不可自行用）"],
        "safe_acupoints": ["足临泣（LV41）仅在医嘱下"],
        "forbidden_acupoints": ["强刺激穴位"],
        "exercise_advice": "散步、深呼吸、盆底操，随时准备分娩",
        "emotional_focus": "放松身心，信任身体的自然分娩能力，减少恐惧",
        "tcm_principle": "静待瓜熟蒂落，顺应自然，避免过度干预",
        "warning_signs": "见红、规律强烈宫缩、破水需立即入院分娩"
    }
]

# ─────────────────────────────────────────────────────────────────────────────
# 禁用草药完整列表（孕期）
# ─────────────────────────────────────────────────────────────────────────────
FORBIDDEN_HERBS_DATA = [
    {"name": "红花", "danger_level": "high", "reason": "活血破血，易引起流产", "trimester": "1-3"},
    {"name": "桃仁", "danger_level": "high", "reason": "活血化瘀，有堕胎风险", "trimester": "1-3"},
    {"name": "益母草", "danger_level": "high", "reason": "活血调经，孕期禁用", "trimester": "1-3"},
    {"name": "三棱", "danger_level": "high", "reason": "破血行气，可导致流产", "trimester": "1-3"},
    {"name": "莪术", "danger_level": "high", "reason": "活血破气，易伤胎气", "trimester": "1-3"},
    {"name": "丹参", "danger_level": "medium", "reason": "活血化瘀，孕早期禁用", "trimester": "1-3"},
    {"name": "赤芍", "danger_level": "medium", "reason": "活血散瘀，孕早期应避免", "trimester": "1-3"},
    {"name": "黄芪", "danger_level": "medium", "reason": "过量补气易导致气滞，可加重妊娠反应", "trimester": "1-3"},
    {"name": "当归", "danger_level": "medium", "reason": "补血活血，孕早期过量有风险", "trimester": "1-3"},
    {"name": "肉桂", "danger_level": "high", "reason": "温阳散寒，易引起流产", "trimester": "1-10"},
    {"name": "干姜", "danger_level": "high", "reason": "温中助阳，孕期禁用", "trimester": "1-10"},
    {"name": "附子", "danger_level": "high", "reason": "温阳回阳，有毒性，孕期禁用", "trimester": "1-10"},
    {"name": "麝香", "danger_level": "high", "reason": "活血通经，明确致流产", "trimester": "1-10"},
    {"name": "冰片", "danger_level": "high", "reason": "辛香走窜，易伤胎气", "trimester": "1-10"},
    {"name": "薄荷", "danger_level": "medium", "reason": "辛散太过，孕早期应避免", "trimester": "1-3"},
]

# ─────────────────────────────────────────────────────────────────────────────
# 产后月子方案（分顺产/剖腹产）
# ─────────────────────────────────────────────────────────────────────────────
POSTPARTUM_PLANS = {
    "natural": {
        "delivery_type": "顺产（自然分娩）",
        "plan": [
            {
                "days_range": "1-7",
                "focus": "排恶露、宫缩恢复、防感染",
                "recommended_foods": ["清汤面", "清粥", "清鸡汤", "清鱼汤（清汤）"],
                "forbidden_foods": ["油腻厚腻", "辛辣刺激", "冷饮冰品"],
                "recovery_tips": "卧床休息，温水擦浴，避免吹风受凉，保持阴部清洁干燥",
                "tcm_formula_suggestion": "可用生化汤促进恶露排出（1-5 天内）",
                "breastfeeding_diet_notes": "清淡温和，不宜进补，防止堵奶"
            },
            {
                "days_range": "8-21",
                "focus": "气血恢复、伤口愈合、增强体力",
                "recommended_foods": ["黄芪炖鸡", "红枣鸡汤", "黑鱼汤", "猪脚汤", "蛋类"],
                "forbidden_foods": ["生冷油腻", "刺激性食物"],
                "recovery_tips": "逐渐增加活动量，温和散步，继续温阳，促进新陈代谢",
                "tcm_formula_suggestion": "八珍汤、四君子汤可温和补气血",
                "breastfeeding_diet_notes": "营养充足但不过腻，通乳穴位按摩（膈俞、脾俞）"
            },
            {
                "days_range": "22-42",
                "focus": "脾胃强化、气血充足、子宫复旧完成",
                "recommended_foods": ["黄芪红枣粥", "山药粥", "黑鸡汤", "核桃、黑芝麻"],
                "forbidden_foods": ["过冷过辣"],
                "recovery_tips": "可恢复正常活动，避免重体力劳动和性生活，持续保暖",
                "tcm_formula_suggestion": "黄芪建中汤强健脾胃，增强体质",
                "breastfeeding_diet_notes": "充分营养支持，促进乳汁分泌，避免过油易堵奶"
            }
        ]
    },
    "cesarean": {
        "delivery_type": "剖腹产（手术分娩）",
        "plan": [
            {
                "days_range": "1-7",
                "focus": "伤口愈合、防感染、排恶露",
                "recommended_foods": ["清汤面", "清粥", "清鸡汤", "蛋羹"],
                "forbidden_foods": ["油腻厚腻", "辛辣", "冷硬难消化"],
                "recovery_tips": "卧床休息，避免腹部用力，伤口保持干燥无菌，温水浴",
                "tcm_formula_suggestion": "生化汤+黄芪可促进恶露排出和伤口愈合",
                "breastfeeding_diet_notes": "清淡好消化，为后续进补做准备"
            },
            {
                "days_range": "8-21",
                "focus": "伤口完全愈合、气血恢复、防粘连",
                "recommended_foods": ["黄芪炖鸡", "黑鱼汤", "红枣粥", "猪脚汤", "核桃"],
                "forbidden_foods": ["过油过腻", "刺激性食物"],
                "recovery_tips": "逐渐增加活动，避免腹部受力，温阳促进血循环有利愈合",
                "tcm_formula_suggestion": "黄芪建中汤+生化汤可加速伤口愈合和恶露排出",
                "breastfeeding_diet_notes": "营养充足支持乳汁分泌，避免过油导致堵奶"
            },
            {
                "days_range": "22-42",
                "focus": "体力恢复、脾胃强化、疤痕软化",
                "recommended_foods": ["黑鸡汤", "山药粥", "黑芝麻核桃", "瘦肉粥"],
                "forbidden_foods": ["过冷过辣"],
                "recovery_tips": "可恢复日常活动，避免重体力和性生活，伤口可按摩促进疤痕软化",
                "tcm_formula_suggestion": "黄芪建中汤强体质，玫瑰花+丹参活血软化疤痕",
                "breastfeeding_diet_notes": "充分营养，但要循序渐进，防止过度进补导致内热"
            }
        ]
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 哺乳期饮食禁忌
# ─────────────────────────────────────────────────────────────────────────────
BREASTFEEDING_AVOID_FOODS = [
    {"food": "螃蟹", "reason": "性质寒凉，易导致婴儿腹泻"},
    {"food": "冰镇饮料", "reason": "过冷易损伤脾阳，影响乳汁质量"},
    {"food": "辛辣刺激物", "reason": "易引起婴儿便秘或腹泻，刺激皮肤"},
    {"food": "油腻厚腻食物", "reason": "易导致乳腺堵奶，甚至乳腺炎"},
    {"food": "咖啡因饮品（咖啡、茶）", "reason": "进入乳汁导致婴儿睡眠不足、易烦躁"},
    {"food": "酒精饮品", "reason": "进入乳汁影响婴儿脑部发育"},
    {"food": "腌制食品", "reason": "盐分过高，影响婴儿代谢"},
    {"food": "烧烤油炸食物", "reason": "热性食物易导致母亲内热，转入乳汁影响婴儿"},
    {"food": "薏米", "reason": "性质滑利，易导致脾胃虚弱影响乳汁质量"},
    {"food": "山楂、柚子（过量）", "reason": "过酸易引起婴儿胃酸反流"},
    {"food": "冷饮冷食", "reason": "伤脾阳，影响乳汁分泌和质量"},
    {"food": "鸭肉", "reason": "性质偏凉，不利于产后气血恢复"},
    {"food": "螺类", "reason": "性质寒凉，易导致婴儿腹泻腹痛"},
    {"food": "薄荷", "reason": "易导致乳汁回流，乳量减少"},
    {"food": "人参（红参）", "reason": "过度温燥易导致奶结、乳腺炎"}
]

# ─────────────────────────────────────────────────────────────────────────────
# 安全穴位（按孕期分类）
# ─────────────────────────────────────────────────────────────────────────────
SAFE_ACUPOINTS_BY_TRIMESTER = {
    "first": {
        "trimester": "孕早期（1-3月）",
        "caution": "禁用活血化瘀穴位，禁强刺激合谷、三阴交",
        "safe_points": ["足三里（ST36）", "肾俞（BL23）", "脾俞（BL20）"],
        "description": "宜温和轻度刺激，促进气血但不损胎气"
    },
    "second": {
        "trimester": "孕中期（4-6月）",
        "caution": "避免强力刺激，活血穴位仍应谨慎",
        "safe_points": ["足三里（ST36）", "肾俞（BL23）", "脾俞（BL20）", "三阴交（SP6，温和）"],
        "description": "可逐渐增加刺激强度，促进气血循环"
    },
    "third": {
        "trimester": "孕晚期（7-10月）",
        "caution": "禁用催产穴位（足临泣、合谷等），避免强刺激",
        "safe_points": ["足三里（ST36）", "肾俞（BL23）", "脾俞（BL20）"],
        "description": "保守治疗，避免触发宫缩"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Pydantic 模型
# ─────────────────────────────────────────────────────────────────────────────

class PersonalizedAdviceRequest(BaseModel):
    pregnancy_month: int
    constitution_type: str  # "qi_deficiency", "blood_deficiency", "spleen_weakness", etc.
    current_symptoms: List[str]  # e.g., ["nausea", "fatigue", "lower_back_pain"]


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

from fastapi import Path

# ... existing imports ...

@router.get("/pregnancy/{month}", summary="孕期指定月份养护方案")
async def get_pregnancy_plan(month: int = Path(..., ge=1, le=10)):
    """返回指定月份（1-10）的孕期养护方案，含禁忌高亮。

    【医疗免责声明】本内容仅供参考，请遵医嘱，不替代专业医疗建议。
    """
    if month < 1 or month > 10:
        raise HTTPException(status_code=400, detail="Pregnancy month must be 1-10")

    plan = next((p for p in PREGNANCY_MONTHS if p["month"] == month), None)
    if not plan:
        raise HTTPException(status_code=404, detail=f"No plan found for month {month}")

    return {
        "success": True,
        "data": {
            "month": month,
            "plan": plan,
            "disclaimer": "请遵医嘱，本内容仅供参考，不替代专业医疗建议。如有不适需立即就医。"
        }
    }


@router.get("/forbidden-herbs", summary="孕期禁用中草药完整列表")
async def get_forbidden_herbs(danger_level: Optional[str] = Query(None, description="high|medium")):
    """返回孕期禁用草药列表，支持按危险等级筛选。

    【医疗免责声明】本内容仅供参考，请遵医嘱，不替代专业医疗建议。
    """
    herbs = FORBIDDEN_HERBS_DATA.copy()

    if danger_level and danger_level in ["high", "medium"]:
        herbs = [h for h in herbs if h["danger_level"] == danger_level]

    return {
        "success": True,
        "data": {
            "total": len(herbs),
            "herbs": herbs,
            "disclaimer": "请遵医嘱，本内容仅供参考。所有中草药需在医生指导下使用。",
            "note": "danger_level 'high' 表示高度风险，'medium' 表示中等风险"
        }
    }


@router.get("/postpartum/{delivery_type}", summary="产后月子方案")
async def get_postpartum_plan(delivery_type: str = Path(..., description="natural|cesarean")):
    """返回产后月子方案，支持顺产/剖腹产两种分娩方式。

    【医疗免责声明】本内容仅供参考，请遵医嘱，不替代专业医疗建议。
    """
    if delivery_type not in POSTPARTUM_PLANS:
        raise HTTPException(
            status_code=400,
            detail=f"delivery_type must be 'natural' or 'cesarean'"
        )

    plan = POSTPARTUM_PLANS[delivery_type]

    return {
        "success": True,
        "data": {
            "delivery_type": delivery_type,
            "plan": plan,
            "disclaimer": "请遵医嘱，本内容仅供参考，不替代专业医疗建议。"
        }
    }


@router.get("/breastfeeding-guide", summary="哺乳期饮食完整指南")
async def get_breastfeeding_guide():
    """返回哺乳期饮食禁忌指南。

    【医疗免责声明】本内容仅供参考，请遵医嘱，不替代专业医疗建议。
    """
    return {
        "success": True,
        "data": {
            "total_avoid_foods": len(BREASTFEEDING_AVOID_FOODS),
            "avoid_foods": BREASTFEEDING_AVOID_FOODS,
            "general_tips": [
                "选择温性、清淡、营养充足的食物",
                "避免过油腻导致乳腺堵奶",
                "保持充足睡眠和心态舒畅",
                "多喝温汤水，促进乳汁分泌",
                "定期按摩乳房和穴位预防乳腺炎"
            ],
            "disclaimer": "请遵医嘱，本内容仅供参考，不替代专业医疗建议。"
        }
    }


@router.get("/safe-acupoints/{trimester}", summary="孕期安全穴位指南")
async def get_safe_acupoints(trimester: str = Path(..., description="first|second|third")):
    """返回指定孕期（孕早/中/晚期）的安全穴位清单。

    【医疗免责声明】本内容仅供参考，请遵医嘱，不替代专业医疗建议。
    """
    if trimester not in SAFE_ACUPOINTS_BY_TRIMESTER:
        raise HTTPException(
            status_code=400,
            detail="trimester must be 'first', 'second', or 'third'"
        )

    acupoints = SAFE_ACUPOINTS_BY_TRIMESTER[trimester]

    return {
        "success": True,
        "data": {
            "trimester": trimester,
            "acupoints": acupoints,
            "disclaimer": "请遵医嘱，本内容仅供参考。穴位按摩需在专业人士指导下进行。"
        }
    }


@router.post("/personalized", summary="个性化孕期建议")
async def get_personalized_advice(request: PersonalizedAdviceRequest):
    """基于孕期月份、体质和症状，返回个性化的 TCM 养护建议。

    【医疗免责声明】本内容仅供参考，请遵医嘱，不替代专业医疗建议。
    """
    if request.pregnancy_month < 1 or request.pregnancy_month > 10:
        raise HTTPException(status_code=400, detail="Pregnancy month must be 1-10")

    # 获取该月份的基础方案
    plan = next(
        (p for p in PREGNANCY_MONTHS if p["month"] == request.pregnancy_month),
        None
    )
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    # 根据症状调整建议
    personalized_recommendations = []

    if "nausea" in request.current_symptoms:
        personalized_recommendations.append("生姜、甘蔗汁可缓解恶心")
    if "fatigue" in request.current_symptoms:
        personalized_recommendations.append("增加黄芪、红枣、鸡汤的摄入")
    if "lower_back_pain" in request.current_symptoms:
        personalized_recommendations.append("适当按摩肾俞穴和腰部，避免过度劳累")
    if "constipation" in request.current_symptoms:
        personalized_recommendations.append("多吃纤维蔬菜、蜂蜜，避免温燥食物")

    return {
        "success": True,
        "data": {
            "pregnancy_month": request.pregnancy_month,
            "constitution_type": request.constitution_type,
            "symptoms": request.current_symptoms,
            "base_plan": plan,
            "personalized_recommendations": personalized_recommendations,
            "disclaimer": "请遵医嘱，本内容仅供参考，不替代专业医疗建议。症状持续请就医。"
        }
    }
