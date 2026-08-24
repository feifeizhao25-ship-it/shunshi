"""
顺时 — 宠物养生 API (shunshi-pet-wellness)
宠物健康养护、中医兽医智慧、季节宠物护理
"""

from fastapi import APIRouter, Query
from typing import Optional
from datetime import datetime

router = APIRouter(prefix="/api/v1/pet-wellness", tags=["pet-wellness"])

VETERINARY_NOTICE = "内容仅作日常护理参考，不替代执业兽医诊断；饮食、补充剂、疫苗和驱虫方案应按物种、年龄与病史咨询兽医。"

PET_SEASONAL_CARE = {
    "spring": {
        "season": "春季", "focus": "换毛期护理、过敏预防",
        "dogs": {
            "tips": ["春季换毛期每天梳毛", "注意花粉过敏症状", "增加户外活动时间", "防跳蚤虱子"],
            "diet": ["维持适合犬只生命阶段的完整均衡主粮；补充剂先咨询兽医"],
            "exercise": ["增加户外时间", "社交化训练"]
        },
        "cats": {
            "tips": ["加强梳毛防止毛球", "防春季发情骚动", "注意花粉过敏"],
            "diet": ["维持适合猫生命阶段的完整均衡主粮；不随意添加人用食物或补充剂"],
            "exercise": ["室内互动玩具"]
        }
    },
    "summer": {
        "season": "夏季", "focus": "防暑降温、防蚊虫",
        "dogs": {
            "tips": ["避免高温时段外出", "持续提供清洁饮水", "绝不留在停放车辆内", "不要为降温随意剃除双层被毛"],
            "diet": ["维持完整均衡主粮并确保饮水；食欲下降或疑似中暑立即就医"],
            "exercise": ["早晨或傍晚运动", "游泳（适合犬类）"]
        },
        "cats": {
            "tips": ["确保室内通风", "提供阴凉区域", "多放水碗"],
            "diet": ["维持完整均衡饮食；更换湿粮或饮食前逐步过渡并咨询兽医"],
            "exercise": ["减少激烈运动"]
        }
    },
    "autumn": {
        "season": "秋季", "focus": "增强免疫、驱虫护理",
        "dogs": {
            "tips": ["按兽医制定的地区风险方案驱虫和接种疫苗", "依据体况逐步调整运动"],
            "diet": ["依据体况评分调整热量，不自行补充维生素E"],
            "exercise": ["增加户外活动"]
        },
        "cats": {
            "tips": ["秋季发情期管理", "室内环境除螨"],
            "diet": ["营养均衡", "适当增加"],
            "exercise": ["猫爬架攀爬"]
        }
    },
    "winter": {
        "season": "冬季", "focus": "保暖防寒、关节护理",
        "dogs": {
            "tips": ["穿宠物保暖衣（短毛犬）", "避免在冰雪上长时间行走", "关注老年犬关节"],
            "diet": ["依据体况而非季节自动增加热量；关节补充剂先咨询兽医"],
            "exercise": ["室内游戏", "短时间户外"]
        },
        "cats": {
            "tips": ["提供温暖睡床", "增加互动防无聊"],
            "diet": ["室内猫通常无需因冬季改用高能量食物，按体况维持完整均衡饮食"],
            "exercise": ["室内玩具游戏"]
        }
    }
}

PET_HEALTH_SIGNS = {
    "healthy_signs": {
        "dogs": ["精神和活动符合平常状态", "食欲饮水稳定", "呼吸平稳", "排便排尿规律"],
        "cats": ["皮毛光洁", "眼睛明亮", "活动正常", "食欲稳定", "规律如厕"]
    },
    "warning_signs": {
        "dogs": ["精神或行为突然改变", "食欲饮水明显改变", "反复呕吐腹泻", "呼吸困难", "排尿异常"],
        "cats": ["隐藏躲避", "食欲骤减", "呕吐频繁", "排尿异常", "眼睛分泌物增多"],
        "when_to_vet": "呼吸困难、抽搐、昏倒、疑似中毒、无法排尿、严重出血或中暑应立即急诊；其他异常请尽快联系兽医，不要固定等待24小时。"
    }
}

TCM_PET_WISDOM = [
    {"tip": "节气换季注意宠物保暖", "detail": "宠物和人一样对气候变化敏感，换季时注意观察宠物状态"},
    {"tip": "规律作息促进宠物健康", "detail": "固定喂食、玩耍和睡眠时间，有助于宠物生物钟稳定"},
    {"tip": "情绪影响宠物健康", "detail": "宠物会感受到主人的情绪，保持积极心态对宠物也有好处"},
    {"tip": "适度运动不过劳", "detail": "运动要适度，避免过度疲劳导致免疫力下降"},
]

COMMON_PET_HEALTH_FOODS = [
    {"name": "南瓜", "for": ["dogs", "cats"], "benefit": "富含纤维，改善消化，辅助减重"},
    {"name": "蓝莓", "for": ["dogs"], "benefit": "抗氧化剂丰富，促进认知健康"},
    {"name": "胡萝卜", "for": ["dogs"], "benefit": "低热量零食，促进牙齿健康"},
    {"name": "金枪鱼", "for": ["cats"], "benefit": "富含Omega-3，促进皮毛健康"},
    {"name": "鸡胸肉（无调味）", "for": ["dogs", "cats"], "benefit": "优质蛋白质来源"},
]


@router.get("/seasonal-care", summary="宠物季节养护")
async def get_seasonal_care(
    season: Optional[str] = Query(None, description="季节: spring/summer/autumn/winter"),
    pet_type: str = Query("dogs", description="宠物类型: dogs/cats")
):
    if season is None:
        month = datetime.now().month
        season = "spring" if month in (3, 4, 5) else "summer" if month in (6, 7, 8) else "autumn" if month in (9, 10, 11) else "winter"
    pet_type = {"dog": "dogs", "cat": "cats"}.get(pet_type, pet_type)
    care = PET_SEASONAL_CARE.get(season)
    if not care:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="季节参数无效")
    pet_care = care.get(pet_type, {})
    seasonal_care = {"season": care["season"], "focus": care["focus"], "care": pet_care}
    return {"success": True, "data": {**seasonal_care, "seasonal_care": seasonal_care, "veterinary_notice": VETERINARY_NOTICE}}


@router.get("/health-signs", summary="宠物健康信号")
async def get_health_signs(pet_type: Optional[str] = Query(None)):
    return {"success": True, "data": {**PET_HEALTH_SIGNS, "veterinary_notice": VETERINARY_NOTICE}}


@router.get("/tcm-wisdom", summary="宠物养生智慧")
async def get_tcm_wisdom():
    return {"success": True, "data": {"wisdom": TCM_PET_WISDOM}}


@router.get("/healthy-foods", summary="宠物健康食物")
async def get_healthy_foods(pet_type: Optional[str] = Query(None)):
    foods = COMMON_PET_HEALTH_FOODS
    if pet_type:
        foods = [f for f in foods if pet_type in f["for"]]
    return {"success": True, "data": {"foods": foods, "veterinary_notice": VETERINARY_NOTICE, "serving_note": "这些只能作为经兽医确认后的少量辅食，不能替代完整均衡主粮。"}}


@router.get("/overview", summary="宠物养生概览")
async def get_overview():
    return {
        "success": True,
        "data": {
            "message": "宠物是家庭的重要成员，顺时帮助您了解宠物在不同季节的养护需求",
            "pet_types": ["dogs", "cats"],
            "key_principles": ["规律作息", "适度运动", "均衡营养", "定期检查", "情感关怀"]
        }
    }
