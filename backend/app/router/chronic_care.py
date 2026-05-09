"""
顺时 — 慢性病 TCM 辅助调养 API
提供 8 种慢性病的 TCM 调养方案、食疗、穴位、生活方式指导。
【医疗免责声明】本内容仅供参考，不替代专业医疗建议和医生治疗。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/chronic", tags=["chronic_care"])

# ─────────────────────────────────────────────────────────────────────────────
# 8 种慢性病 TCM 调养方案
# ─────────────────────────────────────────────────────────────────────────────
CHRONIC_CONDITIONS_DATA = [
    {
        "id": "chronic_fatigue",
        "condition": "慢性疲劳综合征",
        "tcm_pattern": "气虚脾弱、脾失健运",
        "description": "长期疲劳乏力，不因休息缓解",
        "food_therapy": {
            "recommended": ["黄芪", "红枣", "山药", "薏米", "鸡汤"],
            "typical_recipe": "黄芪炖鸡汤（黄芪 30g、鸡 500g、红枣 5 颗）",
            "frequency": "每周 2-3 次"
        },
        "lifestyle_adjustments": [
            "充足睡眠（7-8 小时）",
            "避免过度劳累和过度思虑",
            "适度运动（散步、太极）",
            "调节工作节奏，避免长期高压"
        ],
        "acupoints": ["足三里（ST36）", "脾俞（BL20）", "气海（CV6）"],
        "herbal_notes": "四君子汤（人参/黄芪、白术、茯苓、甘草）可长期温和补气",
        "avoid_factors": ["过度劳累", "过度思虑", "饮食不规律", "长期熬夜"],
        "see_doctor_warning": "如疲劳持续恶化或伴随其他症状（发热、体重下降），需医学评估排除器质性病变",
        "severity_level": "medium"
    },
    {
        "id": "insomnia",
        "condition": "失眠症",
        "tcm_pattern": "心肾不交、肝火扰神、心脾两虚（分型调养）",
        "description": "入睡困难、易醒、睡眠浅、多梦",
        "food_therapy": {
            "recommended": ["龙眼", "红枣", "酸枣仁", "百合", "黄芪", "蜂蜜"],
            "typical_recipe": "酸枣仁粥（酸枣仁 30g、粳米 50g、蜂蜜适量）或龙眼红枣茶",
            "frequency": "每日 1 次"
        },
        "lifestyle_adjustments": [
            "规律作息（23:00 前入睡）",
            "睡前温水泡脚 30 分钟",
            "睡前避免看屏幕（1 小时）",
            "保持卧室温暖、安静、黑暗",
            "避免过度思虑和情绪波动"
        ],
        "acupoints": ["神门（HT7）", "三阴交（SP6）", "安眠穴（耳后）"],
        "herbal_notes": "酸枣仁汤（酸枣仁、茯神、知母、黄芪、川芎）可改善睡眠质量",
        "avoid_factors": ["咖啡因", "烟酒", "睡前进食", "室温过高或过低"],
        "see_doctor_warning": "若失眠伴随明显情绪障碍或持续超过 3 个月，需精神心理评估",
        "severity_level": "medium"
    },
    {
        "id": "chronic_gastritis",
        "condition": "慢性胃炎",
        "tcm_pattern": "脾胃虚弱、气滞湿困",
        "description": "上腹部不适、消化不良、反酸、腹胀",
        "food_therapy": {
            "recommended": ["山药", "薏米", "红枣", "南瓜", "鸡蛋", "清汤"],
            "typical_recipe": "山药薏米粥（山药 50g、薏米 30g、粳米 50g、红枣 3 颗）",
            "frequency": "每日 1 次，作为早餐"
        },
        "lifestyle_adjustments": [
            "三餐规律，避免暴饮暴食",
            "进食缓慢，充分咀嚼",
            "避免生冷油腻辛辣食物",
            "饭后避免立即工作或运动",
            "保持心态舒畅，避免过度思虑"
        ],
        "acupoints": ["足三里（ST36）", "脾俞（BL20）", "胃俞（BL21）"],
        "herbal_notes": "理中丸（人参、白术、干姜、甘草）可温阳健脾；若湿热明显需六君子汤",
        "avoid_factors": ["生冷硬食物", "油腻厚腻", "过酸过辣", "烟酒", "过冷饮料"],
        "see_doctor_warning": "如出现持续黑便、呕血、剧烈腹痛，需急诊检查排除消化道溃疡或出血",
        "severity_level": "medium"
    },
    {
        "id": "cervical_spondylosis",
        "condition": "颈椎病",
        "tcm_pattern": "气滞血瘀、经络不通",
        "description": "颈部疼痛、僵硬、放射性疼痛、头晕",
        "food_therapy": {
            "recommended": ["黑木耳", "海带", "山楂", "丹参", "黑芝麻"],
            "typical_recipe": "黑木耳海带汤（黑木耳 10g、海带 20g、蜂蜜少许）",
            "frequency": "每周 2-3 次"
        },
        "lifestyle_adjustments": [
            "避免长时间低头看手机（每 30 分钟活动一次）",
            "改正不良坐姿，保持脊柱直立",
            "定期做颈椎操和肩颈拉伸",
            "避免过度提重物",
            "枕头高度应与肩宽相符"
        ],
        "acupoints": ["肩井（GB21）", "风池（GB20）", "曲池（LI11）"],
        "herbal_notes": "活血通络类方剂（血府逐瘀汤、膈下逐瘀汤）可改善气血循环，但需医嘱",
        "avoid_factors": ["长期低头", "坐姿不正", "过度颈部转向", "冷风吹颈"],
        "see_doctor_warning": "如出现双上肢无力、排尿排便困难、严重眩晕，需急诊影像学检查排除脊髓压迫",
        "severity_level": "medium"
    },
    {
        "id": "chronic_rhinitis",
        "condition": "慢性鼻炎",
        "tcm_pattern": "肺卫不固、气虚易感",
        "description": "鼻塞、流涕、嗅觉减退、反复感冒",
        "food_therapy": {
            "recommended": ["黄芪", "红枣", "薏米", "冬瓜", "黑芝麻", "生姜"],
            "typical_recipe": "黄芪红枣粥（黄芪 20g、红枣 5 颗、粳米 50g）",
            "frequency": "每日 1 次"
        },
        "lifestyle_adjustments": [
            "避免接触空气污染和过敏原",
            "保持室内湿度（50-60%）",
            "温暖鼻腔（冷空气吸入时用围巾遮挡）",
            "定期用温盐水冲洗鼻腔",
            "增强体质，适度运动"
        ],
        "acupoints": ["迎香（LI20）", "足三里（ST36）", "肺俞（BL13）"],
        "herbal_notes": "玉屏风散（黄芪、白术、防风）是经典的补肺卫处方，可长期服用",
        "avoid_factors": ["过敏原接触", "冷空气", "烟雾", "过度疲劳", "饮食不当"],
        "see_doctor_warning": "如鼻涕伴血丝、鼻塞严重影响呼吸、持续化脓性分泌物，需耳鼻喉科检查",
        "severity_level": "low"
    },
    {
        "id": "mild_depression_tendency",
        "condition": "抑郁倾向（轻度）",
        "tcm_pattern": "肝郁气滞、心脾不和",
        "description": "心情低落、兴趣减退、疲劳、食欲变化",
        "food_therapy": {
            "recommended": ["玫瑰花", "红糖", "龙眼", "红枣", "黑芝麻", "蜂蜜"],
            "typical_recipe": "玫瑰花茶（玫瑰花 6-8 朵、红糖一块、温水冲泡）",
            "frequency": "每日 1-2 次"
        },
        "lifestyle_adjustments": [
            "保持社交，参加群体活动",
            "进行喜爱的爱好（书法、绘画、音乐）",
            "每日户外活动 30-60 分钟，晒太阳",
            "保持规律作息和运动习惯",
            "必要时寻求专业心理咨询"
        ],
        "acupoints": ["太冲（LV3）", "膈俞（BL17）", "心俞（BL15）"],
        "herbal_notes": "逍遥散（柴胡、薄荷、白芍、白术、茯苓、甘草）可疏肝解郁，但需在医生指导下使用",
        "avoid_factors": ["过度思虑", "社交隔离", "长期压力", "缺乏运动"],
        "see_doctor_warning": "如出现严重抑郁、自伤念头、持续失眠，需立即就医并寻求精神心理专科评估",
        "severity_level": "high"
    },
    {
        "id": "pre_diabetes",
        "condition": "糖尿病前期",
        "tcm_pattern": "脾虚湿盛、胰岛功能减退",
        "description": "空腹血糖 100-125 mg/dL，或 HbA1c 5.7-6.4%",
        "food_therapy": {
            "recommended": ["糙米", "燕麦", "黑芝麻", "薏米", "南瓜", "冬瓜"],
            "typical_recipe": "糙米粥（糙米 50g、薏米 20g、冬瓜 30g）",
            "frequency": "每日 1 次，作为主食替代"
        },
        "lifestyle_adjustments": [
            "控制总热量摄入，维持健康体重",
            "避免甜食和精白米面",
            "增加纤维摄入（蔬菜、全谷物）",
            "每日运动 30-60 分钟（有氧+力量）",
            "定期检测血糖，监测进展"
        ],
        "acupoints": ["足三里（ST36）", "脾俞（BL20）", "三阴交（SP6）"],
        "herbal_notes": "六君子汤或补中益气汤可强健脾胃，但需定期复查血糖调整方案",
        "avoid_factors": ["高糖食物", "精白米面", "油腻厚腻", "过度劳累", "长期压力"],
        "see_doctor_warning": "需定期复查血糖和 HbA1c（每 3-6 个月），密切监测是否进展为糖尿病",
        "severity_level": "high"
    },
    {
        "id": "hypertension_tendency",
        "condition": "高血压倾向（血压 130-139/80-89 mmHg）",
        "tcm_pattern": "肝阳上亢、气血失调",
        "description": "血压升高但未达诊断标准，无症状或偶有头晕",
        "food_therapy": {
            "recommended": ["海带", "冬瓜", "黑木耳", "山楂", "绿豆", "蜂蜜"],
            "typical_recipe": "海带冬瓜汤（海带 15g、冬瓜 100g、清汤）或山楂蜂蜜茶",
            "frequency": "每周 3-4 次"
        },
        "lifestyle_adjustments": [
            "减少盐摄入（<6g/天）",
            "避免过咸、过油、过甜食物",
            "戒烟限酒",
            "每日运动 30-60 分钟（有氧运动或散步）",
            "学习放松技巧（冥想、瑜伽）",
            "定期监测血压"
        ],
        "acupoints": ["太冲（LV3）", "曲池（LI11）", "三阴交（SP6）"],
        "herbal_notes": "天麻钩藤饮（天麻、钩藤、石决明、黄芩、栀子等）可平肝潜阳，但需医嘱",
        "avoid_factors": ["高盐饮食", "烟酒", "过度劳累", "长期情绪激动", "缺乏运动"],
        "see_doctor_warning": "需定期复查血压（每 3-6 个月），若升至 140/90 需启动药物治疗",
        "severity_level": "high"
    }
]

# ─────────────────────────────────────────────────────────────────────────────
# 医疗免责声明
# ─────────────────────────────────────────────────────────────────────────────
MEDICAL_DISCLAIMER = {
    "zh": """
【医疗免责声明】

本应用提供的所有内容（包括但不限于 TCM 调养建议、食疗方案、穴位指导、生活方式建议）仅供参考，不构成医疗建议，也不替代专业医疗诊断和治疗。

重要提示：
1. 本内容不能用于自行诊断或治疗任何疾病
2. 如有任何健康问题，请咨询合格的医疗专业人士
3. 在使用任何 TCM 草药或进行穴位按摩前，请向中医师咨询
4. 不应因阅读本内容而延迟或停止任何医学治疗
5. 对于本内容引起的任何不良后果，本应用不承担责任

本应用致力于提供基于传统中医理论的健康信息，但不能替代正规医疗机构的诊疗。
    """,
    "en": """
[MEDICAL DISCLAIMER]

All content provided by this application, including but not limited to TCM wellness suggestions, food therapy plans, acupoint guidance, and lifestyle recommendations, is for informational purposes only and does not constitute medical advice or replace professional medical diagnosis and treatment.

Important Notes:
1. This content cannot be used for self-diagnosis or self-treatment of any disease
2. Please consult qualified medical professionals for any health concerns
3. Consult a TCM practitioner before using any herbal remedies or performing acupoint massage
4. Do not delay or discontinue any medical treatment based on this content
5. This application assumes no responsibility for any adverse consequences from using this content

This application aims to provide health information based on traditional Chinese medicine theory but cannot replace diagnosis and treatment from qualified medical institutions.
    """
}

# ─────────────────────────────────────────────────────────────────────────────
# Pydantic 模型
# ─────────────────────────────────────────────────────────────────────────────

class SymptomCheckRequest(BaseModel):
    symptoms: List[str]  # e.g., ["fatigue", "insomnia", "constipation"]


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/conditions", summary="支持的慢性病列表")
async def list_conditions():
    """返回支持的慢性病列表，含 TCM 分型说明。

    【医疗免责声明】本内容仅供参考，不替代专业医疗建议。
    """
    conditions_list = [
        {
            "id": c["id"],
            "condition": c["condition"],
            "tcm_pattern": c["tcm_pattern"],
            "severity_level": c["severity_level"]
        }
        for c in CHRONIC_CONDITIONS_DATA
    ]
    return {
        "success": True,
        "data": {
            "total": len(conditions_list),
            "conditions": conditions_list,
            "disclaimer": "本内容仅供参考，所有建议需在医生指导下使用。"
        }
    }


@router.get("/conditions/{condition_id}", summary="慢性病详细调养方案")
async def get_condition_detail(condition_id: str):
    """返回指定慢性病的详细 TCM 调养方案。

    【医疗免责声明】本内容仅供参考，不替代专业医疗建议。
    """
    condition = next((c for c in CHRONIC_CONDITIONS_DATA if c["id"] == condition_id), None)
    if not condition:
        raise HTTPException(status_code=404, detail=f"Condition '{condition_id}' not found")

    return {
        "success": True,
        "data": condition,
        "disclaimer": "本内容仅供参考，请在医生指导下进行调养。"
    }


@router.get("/food-therapy/{condition_id}", summary="慢性病专项食疗方")
async def get_food_therapy(condition_id: str):
    """返回该慢性病的专项食疗方案。

    【医疗免责声明】本内容仅供参考，不替代专业医疗建议。
    """
    condition = next((c for c in CHRONIC_CONDITIONS_DATA if c["id"] == condition_id), None)
    if not condition:
        raise HTTPException(status_code=404, detail=f"Condition '{condition_id}' not found")

    return {
        "success": True,
        "data": {
            "condition": condition["condition"],
            "food_therapy": condition["food_therapy"],
            "additional_tips": [
                "食疗需持续 4-8 周才能见效",
                "食疗不替代医学治疗，仅作辅助调养",
                "如对任何食材过敏，需立即停止使用",
                "食疗方案应根据个人体质灵活调整"
            ],
            "disclaimer": "本食疗仅供参考，如有食物过敏或特殊病情，请咨询医生。"
        }
    }


@router.post("/symptom-check", summary="症状自查")
async def check_symptoms(request: SymptomCheckRequest):
    """基于输入症状，返回可能对应的 TCM 模式和建议就医提醒。

    【医疗免责声明】本内容仅供参考，不替代专业医疗诊断。
    """
    symptoms = request.symptoms
    matched_conditions = []

    # 简单的症状-疾病映射逻辑
    symptom_condition_map = {
        "fatigue": ["chronic_fatigue"],
        "insomnia": ["insomnia"],
        "poor_sleep": ["insomnia"],
        "stomach_discomfort": ["chronic_gastritis"],
        "indigestion": ["chronic_gastritis"],
        "neck_pain": ["cervical_spondylosis"],
        "nasal_congestion": ["chronic_rhinitis"],
        "runny_nose": ["chronic_rhinitis"],
        "low_mood": ["mild_depression_tendency"],
        "depression": ["mild_depression_tendency"],
        "high_blood_sugar": ["pre_diabetes"],
        "high_blood_pressure": ["hypertension_tendency"]
    }

    found_conditions = set()
    for symptom in symptoms:
        if symptom in symptom_condition_map:
            found_conditions.update(symptom_condition_map[symptom])

    for cond_id in found_conditions:
        condition = next((c for c in CHRONIC_CONDITIONS_DATA if c["id"] == cond_id), None)
        if condition:
            matched_conditions.append({
                "condition": condition["condition"],
                "tcm_pattern": condition["tcm_pattern"],
                "see_doctor_warning": condition["see_doctor_warning"]
            })

    return {
        "success": True,
        "data": {
            "input_symptoms": symptoms,
            "matched_conditions": matched_conditions if matched_conditions else "未找到明确匹配的慢性病模式",
            "recommendations": [
                "本自查仅基于症状的初步分析，不能替代医学诊断",
                "请根据医生的正式诊断进行针对性的治疗",
                "TCM 调养应在医生指导下进行，不可自行用药"
            ],
            "disclaimer": "这是症状初筛，不构成诊断。如症状持续，请就医咨询专业医生。"
        }
    }


@router.get("/lifestyle/{condition_id}", summary="慢性病生活方式调整清单")
async def get_lifestyle_adjustments(condition_id: str):
    """返回该慢性病的生活方式调整清单。

    【医疗免责声明】本内容仅供参考，不替代专业医疗建议。
    """
    condition = next((c for c in CHRONIC_CONDITIONS_DATA if c["id"] == condition_id), None)
    if not condition:
        raise HTTPException(status_code=404, detail=f"Condition '{condition_id}' not found")

    return {
        "success": True,
        "data": {
            "condition": condition["condition"],
            "lifestyle_adjustments": condition["lifestyle_adjustments"],
            "avoid_factors": condition["avoid_factors"],
            "implementation_tips": [
                "从易到难，逐步实施生活方式改变",
                "建议制定 1-3 个月的短期目标",
                "定期评估进展，适时调整计划",
                "寻求家人和医生的支持和督导"
            ],
            "disclaimer": "生活方式调整需结合医疗治疗，不能替代医学治疗。"
        }
    }


@router.get("/disclaimer", summary="医疗免责声明")
async def get_disclaimer(language: str = Query("zh", description="zh|en")):
    """返回标准医疗免责声明（中英双语版本）。"""
    if language not in ["zh", "en"]:
        language = "zh"

    disclaimer_text = MEDICAL_DISCLAIMER[language]

    return {
        "success": True,
        "data": {
            "language": language,
            "disclaimer": disclaimer_text.strip(),
            "version": "1.0"
        }
    }
