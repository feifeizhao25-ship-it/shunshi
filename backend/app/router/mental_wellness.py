"""
顺时 — TCM 情志健康辅助 API
提供五行情志分析、冥想引导、情志打卡、危机资源
（非医疗诊断，需含专业帮助提醒）
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

router = APIRouter(prefix="/api/v1/mental", tags=["mental_wellness"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求/响应模型
# ─────────────────────────────────────────────────────────────────────────────

class DominantEmotion(str, Enum):
    anger = "怒"
    joy = "喜"
    pensiveness = "思"
    sadness = "悲"
    fear = "恐"
    other = "其他"


class MentalCheckInRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    dominant_emotion: str = Field(..., description="主要情绪：怒/喜/思/悲/恐/其他")
    intensity: int = Field(..., ge=1, le=5, description="强度 1-5（1最轻，5最强）")
    notes: Optional[str] = Field(None, max_length=500, description="可选备注")


# ─────────────────────────────────────────────────────────────────────────────
# 情志健康知识库
# ─────────────────────────────────────────────────────────────────────────────

# 五行情志对应
FIVE_ELEMENTS_EMOTIONS = {
    "anger": {
        "emotion_name": "怒（Anger）",
        "element": "木",
        "organ": "肝",
        "season": "春",
        "description": "属肝阳之气，过度则伤肝阴。",
        "element_en": "Wood",
    },
    "joy": {
        "emotion_name": "喜（Joy）",
        "element": "火",
        "organ": "心",
        "season": "夏",
        "description": "属心火，过喜则散；适度喜乐有益心神。",
        "element_en": "Fire",
    },
    "pensiveness": {
        "emotion_name": "思（Pensiveness/Overthinking）",
        "element": "土",
        "organ": "脾",
        "season": "长夏（季节交替）",
        "description": "思虑过度则伤脾气，导致消化和免疫问题。",
        "element_en": "Earth",
    },
    "sadness": {
        "emotion_name": "悲（Sadness）",
        "element": "金",
        "organ": "肺",
        "season": "秋",
        "description": "悲忧易伤肺气，影响呼吸和皮肤。",
        "element_en": "Metal",
    },
    "fear": {
        "emotion_name": "恐（Fear）",
        "element": "水",
        "organ": "肾",
        "season": "冬",
        "description": "恐惧伤肾阳，长期恐惧导致腰膝酸软和性功能障碍。",
        "element_en": "Water",
    },
}

# 五种常见情志问题的TCM分析与调节
MENTAL_CONDITIONS = {
    "anxiety": {
        "id": "anxiety",
        "condition_name": "焦虑 (Anxiety)",
        "tcm_patterns": [
            {
                "pattern": "心气虚",
                "symptoms": "易惊、易怒、心烦、失眠、健忘",
                "food_therapy": ["红枣粥", "龙眼茶", "黄芪炖鸡"],
                "acupoints": ["神门穴(HT7)", "内关穴(PC6)", "三阴交(SP6)"],
            },
            {
                "pattern": "肝郁化火",
                "symptoms": "心烦、口苦、眼干、易怒、失眠多梦",
                "food_therapy": ["玫瑰花茶", "冬瓜薏米粥", "绿茶"],
                "acupoints": ["太冲穴(LV3)", "合谷穴(LI4)", "膈俞(BL17)"],
            },
        ],
        "breathing_exercises": [
            {
                "name": "4-7-8呼吸法",
                "steps": "吸气4秒 → 屏息7秒 → 呼气8秒，重复4次。",
            },
            {
                "name": "腹式呼吸",
                "steps": "鼻吸口呼，深吸腹部，每次10分钟。",
            },
        ],
        "lifestyle_adjustments": [
            "避免过度工作，规律作息",
            "晨起散步，顺应春阳生发",
            "避免过度思虑，减少刺激性食物",
        ],
        "when_to_seek_professional_help": "如焦虑持续超过2周或影响日常生活，请寻求心理咨询或就医。",
    },
    "low_mood": {
        "id": "low_mood",
        "condition_name": "抑郁倾向 (Low Mood/Depression)",
        "tcm_patterns": [
            {
                "pattern": "肝郁气滞",
                "symptoms": "心情抑郁、胸闷、易烦躁、月经不调",
                "food_therapy": ["玫瑰花茶", "香椿鸡蛋", "山楂麦芽茶"],
                "acupoints": ["太冲穴(LV3)", "膈俞(BL17)", "期门穴(LV14)"],
            },
            {
                "pattern": "心脾两虚",
                "symptoms": "心悸、健忘、失眠、食欲差、疲劳",
                "food_therapy": ["黄芪红枣粥", "龙眼肉茶", "黄芪炖乌鸡"],
                "acupoints": ["心俞(BL15)", "脾俞(BL20)", "足三里(ST36)"],
            },
        ],
        "breathing_exercises": [
            {
                "name": "胸部开放式呼吸",
                "steps": "双臂展开，深吸气，感受胸部扩张，缓慢呼气。",
            },
        ],
        "lifestyle_adjustments": [
            "增加户外光照，每天30分钟",
            "适度运动，如八段锦或太极",
            "温暖的食物和社交连接",
        ],
        "when_to_seek_professional_help": "如症状持续或加重，请寻求专业心理咨询。",
    },
    "irritability": {
        "id": "irritability",
        "condition_name": "易怒 (Irritability)",
        "tcm_patterns": [
            {
                "pattern": "肝阳上亢",
                "symptoms": "易怒、头晕、耳鸣、口苦、面红",
                "food_therapy": ["绿豆薏米粥", "冬瓜汤", "绿茶"],
                "acupoints": ["太冲穴(LV3)", "合谷穴(LI4)", "行间穴(LV2)"],
            },
            {
                "pattern": "肝火旺盛",
                "symptoms": "易怒、口苦、目赤、便秘、烦躁",
                "food_therapy": ["苦瓜绿豆粥", "冬瓜海带汤", "薏米粥"],
                "acupoints": ["太冲穴(LV3)", "侠溪穴(TE8)", "阳陵泉(GB34)"],
            },
        ],
        "breathing_exercises": [
            {
                "name": "长呼吸法",
                "steps": "缓慢深吸气，延长呼气时间至吸气的两倍。",
            },
        ],
        "lifestyle_adjustments": [
            "避免熬夜和过度工作",
            "减少辛辣刺激食物",
            "多做户外活动，舒缓肝气",
        ],
        "when_to_seek_professional_help": "如易怒严重影响人际关系或工作，请寻求专业帮助。",
    },
    "mood_swings": {
        "id": "mood_swings",
        "condition_name": "情绪波动 (Mood Swings)",
        "tcm_patterns": [
            {
                "pattern": "心神失养",
                "symptoms": "情绪不稳、易哭易笑、失眠、心烦",
                "food_therapy": ["红枣粥", "酸枣仁茶", "莲子心茶"],
                "acupoints": ["心俞(BL15)", "神门穴(HT7)", "三阴交(SP6)"],
            },
            {
                "pattern": "冲任失调（女性多见）",
                "symptoms": "月经前后情绪波动、烦躁、易怒、乳房胀痛",
                "food_therapy": ["黄芪红枣茶", "玫瑰花茶", "山楂陈皮茶"],
                "acupoints": ["三阴交(SP6)", "气海穴(CV6)", "关元穴(CV4)"],
            },
        ],
        "breathing_exercises": [
            {
                "name": "平衡呼吸法",
                "steps": "吸气4秒，呼气4秒，保持均匀节奏10分钟。",
            },
        ],
        "lifestyle_adjustments": [
            "规律作息，顺应天时变化",
            "月经期前一周增加自我关照",
            "避免过度刺激和压力",
        ],
        "when_to_seek_professional_help": "如情绪波动严重影响生活，请寻求心理咨询或医学评估。",
    },
    "overthinking": {
        "id": "overthinking",
        "condition_name": "思虑过度 (Overthinking)",
        "tcm_patterns": [
            {
                "pattern": "心脾两虚",
                "symptoms": "思虑过度、健忘、失眠、疲劳、食欲不振",
                "food_therapy": ["黄芪红枣粥", "龙眼肉粥", "黄芪炖乌鸡"],
                "acupoints": ["脾俞(BL20)", "心俞(BL15)", "足三里(ST36)"],
            },
        ],
        "breathing_exercises": [
            {
                "name": "正念呼吸",
                "steps": "专注于呼吸，每次呼吸持续5秒，持续15分钟。",
            },
        ],
        "lifestyle_adjustments": [
            "避免过度工作和学习",
            "定期休息和冥想",
            "培养兴趣爱好，转移注意力",
        ],
        "when_to_seek_professional_help": "如思虑成为强迫性思维，影响生活质量，请寻求专业心理咨询。",
    },
}

# 冥想引导
MEDITATION_GUIDES = {
    "heart_calming": {
        "id": "heart_calming",
        "name": "心安宁冥想",
        "duration_minutes": 10,
        "suitable_for": ["焦虑", "失眠", "心烦"],
        "steps": [
            "舒适地坐着，闭上眼睛",
            "将注意力集中在心脏区域，想象一道温暖的绿光",
            "缓慢呼吸，每次呼吸5秒",
            "重复默念：'我的心是安定的，我是平静的'",
            "维持10分钟，缓慢睁开眼睛",
        ],
        "tcm_theory": "通过引导意念到心脏，养护心神，安定心志。",
    },
    "liver_qi_free_flow": {
        "id": "liver_qi_free_flow",
        "name": "肝气疏泄冥想",
        "duration_minutes": 12,
        "suitable_for": ["抑郁", "烦躁", "易怒"],
        "steps": [
            "站立或坐着，双臂自然下垂",
            "深吸气3秒，想象绿光从脚升起，流经全身",
            "呼气5秒，想象郁闷化作烟雾散出体外",
            "重复10次，逐渐加深呼吸",
            "静坐2分钟，感受身体的轻松",
        ],
        "tcm_theory": "疏泄肝气，缓解郁滞，促进气血流通。",
    },
    "spleen_strengthening": {
        "id": "spleen_strengthening",
        "name": "健脾益气冥想",
        "duration_minutes": 15,
        "suitable_for": ["思虑过度", "疲劳", "食欲差"],
        "steps": [
            "坐下，双手放在膝盖上",
            "吸气3秒，想象黄色温暖的光在腹部聚集",
            "呼气5秒，感受脾胃被温暖充满",
            "重复15次，默念：'我的脾胃强健，我充满能量'",
            "静坐3分钟，感受内部的力量",
        ],
        "tcm_theory": "通过调理脾胃，恢复消化能力和精力。",
    },
    "lung_relief": {
        "id": "lung_relief",
        "name": "肺部释放冥想",
        "duration_minutes": 10,
        "suitable_for": ["悲伤", "抑郁", "呼吸困难"],
        "steps": [
            "舒适地坐着，放松肩膀",
            "深吸气4秒，感受气流填满肺部",
            "长呼气6秒，想象悲伤随着呼吸离开",
            "重复8次，逐渐感受内心的空旷和宁静",
            "静坐2分钟，接纳宁静",
        ],
        "tcm_theory": "释放肺部的郁闷，让悲伤流动和转化。",
    },
    "kidney_restoration": {
        "id": "kidney_restoration",
        "name": "肾阳温阳冥想",
        "duration_minutes": 12,
        "suitable_for": ["恐惧", "疲劳", "缺乏动力"],
        "steps": [
            "坐下，双手覆盖下腹部（丹田）",
            "吸气4秒，想象深蓝色温暖的光在丹田聚集",
            "呼气4秒，感受内部被温暖充满",
            "重复12次，默念：'我充满勇气和力量'",
            "静坐3分钟，感受内部的温暖",
        ],
        "tcm_theory": "温阳补肾，驱散恐惧，恢复生命力。",
    },
}

# 危机资源
CRISIS_RESOURCES = [
    {
        "region": "中国",
        "organization": "北京心理危机研究与干预中心",
        "phone": "010-58951332",
        "available": "24小时",
        "service": "心理危机干预、心理援助",
    },
    {
        "region": "中国",
        "organization": "全国心理援助热线",
        "phone": "400-161-9995",
        "available": "24小时",
        "service": "心理援助、情绪支持",
    },
    {
        "region": "国际",
        "organization": "国际求助热线联盟 (International Association for Suicide Prevention)",
        "website": "https://www.iasp.info/resources/Crisis_Centres/",
        "available": "各地不同",
        "service": "多语言心理危机支持",
    },
    {
        "region": "中国",
        "organization": "生命热线（台湾）",
        "phone": "1925",
        "available": "24小时",
        "service": "自杀防治和心理援助",
    },
]

# 内存数据存储
_mental_checkins = {}  # {user_id: [{"emotion": ..., "timestamp": ...}, ...]}


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/conditions", summary="支持的情志问题列表")
async def get_conditions():
    """返回所有支持的情志问题及其中英对照。"""
    conditions = []
    for cond_id, cond_data in MENTAL_CONDITIONS.items():
        conditions.append({
            "id": cond_id,
            "name": cond_data["condition_name"],
            "pattern_count": len(cond_data["tcm_patterns"]),
        })
    return {
        "success": True,
        "data": {
            "conditions": conditions,
            "total": len(conditions),
        },
    }


@router.get("/conditions/{condition_id}", summary="情志问题详细调节方案")
async def get_condition_detail(condition_id: str):
    """获取指定情志问题的详细TCM调节方案。"""
    if condition_id not in MENTAL_CONDITIONS:
        raise HTTPException(
            status_code=404,
            detail=f"Condition '{condition_id}' not found. Valid: {list(MENTAL_CONDITIONS.keys())}",
        )

    cond = MENTAL_CONDITIONS[condition_id]
    return {
        "success": True,
        "data": {
            **cond,
            "professional_help_reminder": "如症状持续或加重，请寻求专业心理咨询。",
        },
    }


@router.get("/five-elements-emotions", summary="五行情志对应关系")
async def get_five_elements_emotions():
    """获取五行情志完整对应关系说明。"""
    elements_list = []
    for emotion_id, emotion_data in FIVE_ELEMENTS_EMOTIONS.items():
        elements_list.append({
            **emotion_data,
            "emotion_id": emotion_id,
        })

    return {
        "success": True,
        "data": {
            "five_elements": elements_list,
            "tcm_theory": "中医五行学说：怒伤肝、喜伤心、思伤脾、悲伤肺、恐伤肾。平衡五行情志是健康的关键。",
        },
    }


@router.get("/meditation-guides", summary="冥想引导列表")
async def get_meditation_guides():
    """返回所有可用的冥想引导。"""
    guides_list = []
    for guide_id, guide_data in MEDITATION_GUIDES.items():
        guides_list.append({
            "id": guide_id,
            "name": guide_data["name"],
            "duration_minutes": guide_data["duration_minutes"],
            "suitable_for": guide_data["suitable_for"],
        })

    return {
        "success": True,
        "data": {
            "guides": guides_list,
            "total": len(guides_list),
        },
    }


@router.get("/meditation-guides/{guide_id}", summary="冥想引导详情")
async def get_meditation_guide_detail(guide_id: str):
    """获取指定冥想引导的详细步骤。"""
    if guide_id not in MEDITATION_GUIDES:
        raise HTTPException(
            status_code=404,
            detail=f"Guide '{guide_id}' not found. Valid: {list(MEDITATION_GUIDES.keys())}",
        )

    guide = MEDITATION_GUIDES[guide_id]
    return {
        "success": True,
        "data": guide,
    }


@router.post("/check-in", summary="情志打卡")
async def mental_checkin(request: MentalCheckInRequest):
    """记录用户的情志状态并返回TCM分析与调节建议。"""
    # 验证情绪值
    valid_emotions = ["怒", "喜", "思", "悲", "恐", "其他"]
    if request.dominant_emotion not in valid_emotions:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid emotion '{request.dominant_emotion}'. Valid: {valid_emotions}",
        )

    # 记录到内存
    if request.user_id not in _mental_checkins:
        _mental_checkins[request.user_id] = []

    checkin_record = {
        "emotion": request.dominant_emotion,
        "intensity": request.intensity,
        "notes": request.notes,
        "timestamp": datetime.now().isoformat(),
    }
    _mental_checkins[request.user_id].append(checkin_record)

    # TCM分析
    emotion_mapping = {
        "怒": ("肝", "木"),
        "喜": ("心", "火"),
        "思": ("脾", "土"),
        "悲": ("肺", "金"),
        "恐": ("肾", "水"),
    }

    organ, element = emotion_mapping.get(request.dominant_emotion, ("未知", "未知"))

    # 生成建议
    intensity_insight = ""
    if request.intensity <= 2:
        intensity_insight = "情绪强度较轻，可通过简单的调息和穴位按摩改善。"
    elif request.intensity <= 3:
        intensity_insight = "情绪强度中等，建议配合食疗和生活调理。"
    else:
        intensity_insight = "情绪强度较强，建议进行系统的TCM调理或寻求专业帮助。"

    return {
        "success": True,
        "data": {
            "checked_in": True,
            "emotion": request.dominant_emotion,
            "intensity": request.intensity,
            "timestamp": datetime.now().isoformat(),
            "tcm_analysis": {
                "organ": organ,
                "element": element,
                "insight": intensity_insight,
            },
            "suggestions": {
                "immediate": "停下当前活动，深呼吸3次，给自己5分钟平静。",
                "short_term": "选择相关穴位按摩，或进行冥想引导。",
                "long_term": "调整生活方式，规律作息，配合食疗调理。",
            },
            "professional_help_reminder": "如症状持续或加重，请寻求专业心理咨询。",
        },
    }


@router.get("/crisis-resources", summary="心理危机资源列表")
async def get_crisis_resources():
    """获取心理危机援助资源列表。"""
    return {
        "success": True,
        "data": {
            "resources": CRISIS_RESOURCES,
            "emergency_note": "如有自杀倾向或急性心理危机，请立即拨打当地紧急求助热线或前往医院。",
            "crisis_hotlines": {
                "china": "400-161-9995 (全国心理援助热线)",
                "beijing": "010-58951332 (北京心理危机研究与干预中心)",
                "international": "https://www.iasp.info/resources/Crisis_Centres/",
            },
        },
    }
