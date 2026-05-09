"""
顺时 — AI健康计划 API (shunshi-ai-wellness-plan)
AI生成个性化养生方案、动态调整计划
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime, date

router = APIRouter(prefix="/api/v1/ai-wellness-plan", tags=["ai-wellness-plan"])

_plans: Dict[str, dict] = {}

PLAN_TEMPLATES = {
    "qi_deficiency": {
        "constitution": "qi_deficiency", "constitution_cn": "气虚质",
        "morning": {"wake_time": "07:00", "actions": ["温水一杯", "八段锦第3节（调理脾胃须单举）", "早餐：山药小米粥"]},
        "midday": {"actions": ["午休30分钟", "按摩足三里穴3分钟"]},
        "evening": {"actions": ["散步20分钟", "泡脚15分钟", "早睡（22:30前）"]},
        "diet_focus": ["健脾补气", "山药", "红枣", "黄芪"],
        "avoid": ["生冷食物", "过度劳累", "熬夜"],
        "weekly_plan": [
            {"day": "周一", "focus": "补气", "exercise": "散步30分钟"},
            {"day": "周二", "focus": "健脾", "exercise": "八段锦全套"},
            {"day": "周三", "focus": "调补", "exercise": "太极拳"},
            {"day": "周四", "focus": "休养", "exercise": "轻柔伸展"},
            {"day": "周五", "focus": "补气", "exercise": "散步30分钟"},
            {"day": "周六", "focus": "活动", "exercise": "户外散步踏青"},
            {"day": "周日", "focus": "休息", "exercise": "养生静坐冥想"},
        ]
    },
    "yin_deficiency": {
        "constitution": "yin_deficiency", "constitution_cn": "阴虚质",
        "morning": {"wake_time": "07:00", "actions": ["温水+蜂蜜", "缓和太极拳", "早餐：百合莲子粥"]},
        "midday": {"actions": ["午休（不超过1小时）", "按压三阴交穴"]},
        "evening": {"actions": ["散步（避免剧烈运动）", "温水泡脚+加盐", "睡前按摩涌泉穴"]},
        "diet_focus": ["滋阴润燥", "百合", "银耳", "枸杞", "梨"],
        "avoid": ["辛辣燥热", "熬夜", "大量出汗"],
        "weekly_plan": [
            {"day": "周一", "focus": "滋阴", "exercise": "瑜伽"},
            {"day": "周二", "focus": "润燥", "exercise": "散步"},
            {"day": "周三", "focus": "养肾", "exercise": "游泳（适度）"},
            {"day": "周四", "focus": "安神", "exercise": "冥想"},
            {"day": "周五", "focus": "滋阴", "exercise": "太极拳"},
            {"day": "周六", "focus": "调养", "exercise": "轻度瑜伽"},
            {"day": "周日", "focus": "休息", "exercise": "静坐冥想"},
        ]
    }
}


class PlanGenerationRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    constitution: str = Field(..., description="体质类型")
    season: str = Field(default="spring", description="当前季节")
    health_goals: Optional[List[str]] = Field(None, description="健康目标")
    available_time_minutes: int = Field(default=30, ge=10, le=120, description="每日可用时间(分钟)")
    fitness_level: str = Field(default="beginner", description="运动水平: beginner/moderate/advanced")
    dietary_restrictions: Optional[List[str]] = Field(None, description="饮食限制")


class PlanFeedbackRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    plan_id: str = Field(..., description="计划ID")
    rating: int = Field(..., ge=1, le=5)
    completed_items: Optional[List[str]] = Field(None, description="已完成的项目")
    feedback_note: Optional[str] = Field(None, max_length=500)


@router.post("/generate", summary="AI生成个性化养生计划")
async def generate_plan(request: PlanGenerationRequest):
    template = PLAN_TEMPLATES.get(request.constitution, PLAN_TEMPLATES.get("qi_deficiency"))
    plan_id = f"plan_{request.user_id}_{date.today().isoformat()}"

    # 根据可用时间调整
    if request.available_time_minutes < 20:
        exercise_note = "时间有限，优先选择八段锦1-2节或散步10分钟"
    elif request.available_time_minutes < 45:
        exercise_note = "建议八段锦全套或20-30分钟有氧运动"
    else:
        exercise_note = "时间充裕，建议完整功法+20分钟有氧运动"

    plan = {
        "plan_id": plan_id,
        "user_id": request.user_id,
        "constitution": request.constitution,
        "season": request.season,
        "generated_at": datetime.now().isoformat(),
        "daily_schedule": {
            "morning": template["morning"],
            "midday": template["midday"],
            "evening": template["evening"]
        },
        "diet": {
            "focus": template["diet_focus"],
            "avoid": template["avoid"],
            "seasonal_adjustment": f"{request.season}季额外注意：应季饮食调整"
        },
        "exercise": {
            "note": exercise_note,
            "fitness_level": request.fitness_level,
            "available_time_minutes": request.available_time_minutes
        },
        "weekly_plan": template["weekly_plan"],
        "ai_notes": [
            f"根据您的{template['constitution_cn']}体质生成专属方案",
            f"当前{request.season}季，建议配合节气调整饮食",
            "建议坚持21天，逐步建立养生习惯"
        ]
    }
    _plans[plan_id] = plan
    return {"success": True, "data": {"plan": plan}}


@router.get("/plan/{plan_id}", summary="获取计划详情")
async def get_plan(plan_id: str):
    if plan_id not in _plans:
        raise HTTPException(status_code=404, detail="计划不存在")
    return {"success": True, "data": _plans[plan_id]}


@router.get("/user/{user_id}/latest", summary="获取用户最新计划")
async def get_latest_plan(user_id: str):
    user_plans = {k: v for k, v in _plans.items() if v["user_id"] == user_id}
    if not user_plans:
        raise HTTPException(status_code=404, detail="暂无养生计划，请先生成")
    latest = max(user_plans.values(), key=lambda x: x["generated_at"])
    return {"success": True, "data": latest}


@router.post("/feedback", summary="计划反馈与优化")
async def submit_plan_feedback(request: PlanFeedbackRequest):
    if request.plan_id not in _plans:
        raise HTTPException(status_code=404, detail="计划不存在")
    _plans[request.plan_id]["last_feedback"] = {
        "rating": request.rating,
        "completed_items": request.completed_items,
        "note": request.feedback_note,
        "submitted_at": datetime.now().isoformat()
    }
    suggestions = []
    if request.rating <= 3:
        suggestions.append("计划难度可能偏高，建议降低运动强度")
    if request.completed_items and len(request.completed_items) < 3:
        suggestions.append("建议从最简单的习惯开始，逐步增加")
    return {
        "success": True,
        "data": {
            "message": "反馈已记录，AI将据此优化您的下次计划",
            "suggestions": suggestions
        }
    }


@router.get("/constitution-tips", summary="各体质养生要点速查")
async def get_constitution_tips():
    tips = [
        {"constitution": k, "constitution_cn": v["constitution_cn"],
         "diet_focus": v["diet_focus"], "avoid": v["avoid"]}
        for k, v in PLAN_TEMPLATES.items()
    ]
    return {"success": True, "data": {"tips": tips}}
