"""
顺时 — 宠物养生 API (shunshi-pet-wellness)
宠物健康养护、中医兽医智慧、季节宠物护理
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/pet-wellness", tags=["pet-wellness"])

PET_SEASONAL_CARE = {
    "spring": {
        "season": "春季", "focus": "换毛期护理、过敏预防",
        "dogs": {
            "tips": ["春季换毛期每天梳毛", "注意花粉过敏症状", "增加户外活动时间", "防跳蚤虱子"],
            "diet": ["均衡营养", "增加Omega-3补充"],
            "exercise": ["增加户外时间", "社交化训练"]
        },
        "cats": {
            "tips": ["加强梳毛防止毛球", "防春季发情骚动", "注意花粉过敏"],
            "diet": ["高蛋白食物", "适当添加猫草"],
            "exercise": ["室内互动玩具"]
        }
    },
    "summer": {
        "season": "夏季", "focus": "防暑降温、防蚊虫",
        "dogs": {
            "tips": ["避免正午外出", "提供充足清水", "不留在密闭车内", "定期剪毛"],
            "diet": ["清凉食物", "多补水"],
            "exercise": ["早晨或傍晚运动", "游泳（适合犬类）"]
        },
        "cats": {
            "tips": ["确保室内通风", "提供阴凉区域", "多放水碗"],
            "diet": ["清淡易消化食物", "湿粮补水"],
            "exercise": ["减少激烈运动"]
        }
    },
    "autumn": {
        "season": "秋季", "focus": "增强免疫、驱虫护理",
        "dogs": {
            "tips": ["进行年度驱虫", "注射疫苗", "开始增加运动强度"],
            "diet": ["适当增加热量", "维生素E"],
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
            "diet": ["适当增加热量", "关节保健品"],
            "exercise": ["室内游戏", "短时间户外"]
        },
        "cats": {
            "tips": ["提供温暖睡床", "增加互动防无聊"],
            "diet": ["高能量食物"],
            "exercise": ["室内玩具游戏"]
        }
    }
}

PET_HEALTH_SIGNS = {
    "healthy_signs": {
        "dogs": ["精神活泼", "食欲正常", "毛发光亮", "鼻头湿润凉爽（清醒时）", "大便成形"],
        "cats": ["皮毛光洁", "眼睛明亮", "活动正常", "食欲稳定", "规律如厕"]
    },
    "warning_signs": {
        "dogs": ["精神萎靡", "食欲减退", "呕吐腹泻", "异常嗜睡", "鼻干热"],
        "cats": ["隐藏躲避", "食欲骤减", "呕吐频繁", "排尿异常", "眼睛分泌物增多"],
        "when_to_vet": "出现任何持续超过24小时的警示症状，应立即就诊"
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
    season: str = Query(..., description="季节: spring/summer/autumn/winter"),
    pet_type: str = Query("dogs", description="宠物类型: dogs/cats")
):
    care = PET_SEASONAL_CARE.get(season)
    if not care:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="季节参数无效")
    pet_care = care.get(pet_type, {})
    return {"success": True, "data": {"season": care["season"], "focus": care["focus"], "care": pet_care}}


@router.get("/health-signs", summary="宠物健康信号")
async def get_health_signs(pet_type: Optional[str] = Query(None)):
    return {"success": True, "data": PET_HEALTH_SIGNS}


@router.get("/tcm-wisdom", summary="宠物养生智慧")
async def get_tcm_wisdom():
    return {"success": True, "data": {"wisdom": TCM_PET_WISDOM}}


@router.get("/healthy-foods", summary="宠物健康食物")
async def get_healthy_foods(pet_type: Optional[str] = Query(None)):
    foods = COMMON_PET_HEALTH_FOODS
    if pet_type:
        foods = [f for f in foods if pet_type in f["for"]]
    return {"success": True, "data": {"foods": foods}}


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
