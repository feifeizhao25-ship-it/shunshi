"""
顺时 — 夫妻养生 API (shunshi-couple-wellness)
夫妻共同养生方案、节气两人养生计划
"""

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict

router = APIRouter(prefix="/api/v1/couple-wellness", tags=["couple-wellness"])

_couple_plans: Dict[str, dict] = {}

COUPLE_WELLNESS_TOPICS = [
    {
        "id": "joint_exercise", "title": "双人养生运动",
        "description": "适合夫妻共同参与的养生运动，增进感情的同时促进健康",
        "activities": [
            {"name": "双人太极拳", "benefit": "调和气血，增进默契"},
            {"name": "共同散步", "benefit": "简单易行，增加沟通时间"},
            {"name": "双人瑜伽", "benefit": "增强柔韧性，促进感情"},
            {"name": "早晨八段锦", "benefit": "共同健康习惯的建立"}
        ]
    },
    {
        "id": "harmonious_diet", "title": "和谐饮食搭配",
        "description": "根据双方体质，制定适合两人的共同饮食方案",
        "tips": [
            "了解彼此体质，制定各有侧重的饮食方案",
            "共同进餐，营造温馨的饮食氛围",
            "一起学习节气养生食谱",
            "避免互相影响不良饮食习惯"
        ]
    },
    {
        "id": "emotional_harmony", "title": "情志调和",
        "description": "中医认为七情过极伤身，夫妻关系的和谐对健康至关重要",
        "practices": [
            {"name": "共同冥想", "duration": "每晚10分钟", "benefit": "减压放松，心灵沟通"},
            {"name": "感恩练习", "method": "每日互相说一句感谢", "benefit": "增进感情，保持积极心态"},
            {"name": "情绪表达", "tip": "学会健康表达情绪，避免压抑积累"},
        ]
    }
]

SEASONAL_COUPLE_PLANS = {
    "spring": {
        "season": "春季双人养生",
        "focus": "疏肝解郁，户外踏青",
        "activities": ["一起踏青赏花", "双人慢跑", "共同学习新的兴趣爱好"],
        "diet": ["共饮玫瑰花茶", "共享韭菜春笋炒蛋"],
        "romance_tip": "春天是生机勃发的季节，适合共同制定新计划和目标"
    },
    "summer": {
        "season": "夏季双人养生",
        "focus": "清心降火，避暑纳凉",
        "activities": ["早晚共同散步", "游泳", "室内太极"],
        "diet": ["共享绿豆汤", "西瓜蜂蜜汁", "清淡蔬菜"],
        "romance_tip": "夏夜星空是增进感情的好时机，一起仰望星空聊天"
    },
    "autumn": {
        "season": "秋季双人养生",
        "focus": "润肺养阴，收敛情志",
        "activities": ["一起爬山赏秋色", "读书品茶", "户外摄影"],
        "diet": ["共享银耳莲子汤", "梨汤", "栗子粥"],
        "romance_tip": "秋天适合表达感情，写一封手写信给对方"
    },
    "winter": {
        "season": "冬季双人养生",
        "focus": "温阳固精，共同进补",
        "activities": ["室内养生功法", "温泉泡浴", "共读一本书"],
        "diet": ["共享羊肉汤", "姜枣茶", "温补糯米饭"],
        "romance_tip": "冬日围炉共饮，是增进亲密关系的最好方式"
    }
}

class CouplePlanRequest(BaseModel):
    couple_id: str = Field(..., description="夫妻ID（唯一标识）")
    person_a_constitution: str = Field(default="balanced", description="一方体质")
    person_b_constitution: str = Field(default="balanced", description="另一方体质")
    # 兼容早期移动端字段；新客户端使用 person_a/person_b 命名。
    user1_constitution: Optional[str] = None
    user2_constitution: Optional[str] = None
    season: str = Field(default="spring", description="当前季节")
    goals: Optional[List[str]] = Field(None, description="共同健康目标")


@router.get("/topics", summary="双人养生主题")
async def get_topics():
    return {"success": True, "data": {"topics": COUPLE_WELLNESS_TOPICS}}


@router.get("/seasonal/{season}", summary="季节双人养生方案")
async def get_seasonal_plan(season: str):
    plan = SEASONAL_COUPLE_PLANS.get(season)
    if not plan:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="季节参数无效")
    return {"success": True, "data": plan}


@router.post("/plan", summary="生成双人养生计划")
async def create_couple_plan(request: CouplePlanRequest):
    seasonal = SEASONAL_COUPLE_PLANS.get(request.season, SEASONAL_COUPLE_PLANS["spring"])
    person_a = request.user1_constitution or request.person_a_constitution
    person_b = request.user2_constitution or request.person_b_constitution
    plan = {
        "couple_id": request.couple_id,
        "season": request.season,
        "person_a_constitution": person_a,
        "person_b_constitution": person_b,
        "shared_activities": seasonal["activities"],
        "shared_diet": seasonal["diet"],
        "romance_tip": seasonal["romance_tip"],
        "individual_notes": {
            "person_a": f"体质{person_a}者注意个性化调理",
            "person_b": f"体质{person_b}者注意个性化调理"
        }
    }
    _couple_plans[request.couple_id] = plan
    return {"success": True, "data": {"plan": plan}}


@router.get("/plan/{couple_id}", summary="获取双人养生计划")
async def get_couple_plan(couple_id: str):
    plan = _couple_plans.get(couple_id)
    if not plan:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="计划不存在")
    return {"success": True, "data": plan}
