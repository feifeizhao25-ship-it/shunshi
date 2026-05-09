"""
顺时 — 新手引导 API (shunshi-onboarding)
新用户引导流程、体质测试、初始化设置
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.onboarding import OnboardingProgress

router = APIRouter(prefix="/api/v1/onboarding", tags=["onboarding"])

ONBOARDING_STEPS = [
    {
        "step": 1, "id": "welcome", "title": "欢迎来到顺时",
        "description": "顺时，顺应自然节律，科学养生的智慧助手",
        "action": "view_intro",
        "skippable": False,
        "estimated_minutes": 1
    },
    {
        "step": 2, "id": "constitution_test", "title": "体质测试",
        "description": "完成9种体质测试，获取个性化养生方案",
        "action": "complete_constitution_quiz",
        "skippable": False,
        "estimated_minutes": 5
    },
    {
        "step": 3, "id": "health_goals", "title": "设定健康目标",
        "description": "告诉我们您最希望改善的健康方面",
        "action": "select_goals",
        "skippable": False,
        "estimated_minutes": 2
    },
    {
        "step": 4, "id": "lifestyle_info", "title": "基本生活信息",
        "description": "了解您的作息习惯，提供更精准的建议",
        "action": "fill_lifestyle",
        "skippable": True,
        "estimated_minutes": 3
    },
    {
        "step": 5, "id": "notification_setup", "title": "设置提醒",
        "description": "开启节气提醒和养生打卡通知",
        "action": "setup_notifications",
        "skippable": True,
        "estimated_minutes": 1
    },
    {
        "step": 6, "id": "explore_features", "title": "探索功能",
        "description": "快速了解顺时的核心功能",
        "action": "view_tour",
        "skippable": True,
        "estimated_minutes": 2
    }
]

HEALTH_GOALS = [
    {"id": "better_sleep", "label": "改善睡眠", "icon": "moon"},
    {"id": "boost_energy", "label": "提升精力", "icon": "lightning"},
    {"id": "weight_management", "label": "体重管理", "icon": "scale"},
    {"id": "stress_relief", "label": "减压放松", "icon": "leaf"},
    {"id": "immune_boost", "label": "增强免疫", "icon": "shield"},
    {"id": "digestive_health", "label": "肠胃健康", "icon": "stomach"},
    {"id": "skin_care", "label": "皮肤改善", "icon": "sparkle"},
    {"id": "chronic_management", "label": "慢性病管理", "icon": "heart"},
    {"id": "fertility", "label": "备孕/调经", "icon": "flower"},
    {"id": "anti_aging", "label": "抗衰老", "icon": "clock"},
]

CONSTITUTION_QUIZ = [
    {
        "id": "q1", "question": "您经常感到疲乏无力，动辄气喘吗？",
        "options": ["几乎没有", "有时", "经常", "总是"],
        "related_constitution": "qi_deficiency"
    },
    {
        "id": "q2", "question": "您的手脚经常感到发凉吗？",
        "options": ["几乎没有", "有时", "经常", "总是"],
        "related_constitution": "yang_deficiency"
    },
    {
        "id": "q3", "question": "您经常感到口燥咽干，手心发热吗？",
        "options": ["几乎没有", "有时", "经常", "总是"],
        "related_constitution": "yin_deficiency"
    },
    {
        "id": "q4", "question": "您容易起痤疮或皮肤油腻吗？",
        "options": ["几乎没有", "有时", "经常", "总是"],
        "related_constitution": "damp_heat"
    },
    {
        "id": "q5", "question": "您经常感到情绪低落或容易烦躁吗？",
        "options": ["几乎没有", "有时", "经常", "总是"],
        "related_constitution": "qi_stagnation"
    }
]


class OnboardingProgressRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    step_id: str = Field(..., description="步骤ID")
    completed: bool = Field(default=True)
    data: Optional[dict] = Field(None, description="步骤收集的数据")


class ConstitutionQuizAnswerRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    answers: Dict[str, int] = Field(..., description="问题ID到选项索引(0-3)的映射")


@router.get("/steps", summary="引导步骤列表")
async def get_onboarding_steps():
    return {
        "success": True,
        "data": {
            "steps": ONBOARDING_STEPS,
            "total_steps": len(ONBOARDING_STEPS),
            "estimated_total_minutes": sum(s["estimated_minutes"] for s in ONBOARDING_STEPS)
        }
    }


@router.get("/progress/{user_id}", summary="获取用户引导进度")
async def get_progress(user_id: str, db: Session = Depends(get_db)):
    row = db.query(OnboardingProgress).filter(OnboardingProgress.user_id == user_id).first()
    if not row:
        progress_data = {
            "user_id": user_id,
            "completed_steps": [],
            "is_completed": False,
            "started_at": None,
        }
    else:
        answers = row.answers or {}
        completed = list(answers.keys()) if isinstance(answers, dict) else []
        progress_data = {
            "user_id": user_id,
            "completed_steps": completed,
            "is_completed": row.completed,
            "started_at": row.created_at.isoformat() if row.created_at else None,
            "constitution_result": row.constitution_result,
        }

    completed = progress_data.get("completed_steps", [])
    current_step = None
    for step in ONBOARDING_STEPS:
        if step["id"] not in completed:
            current_step = step
            break
    return {
        "success": True,
        "data": {
            "progress": progress_data,
            "current_step": current_step,
            "completion_pct": round(len(completed) / len(ONBOARDING_STEPS) * 100)
        }
    }


@router.post("/progress", summary="更新引导进度")
async def update_progress(request: OnboardingProgressRequest, db: Session = Depends(get_db)):
    row = db.query(OnboardingProgress).filter(OnboardingProgress.user_id == request.user_id).first()
    if not row:
        row = OnboardingProgress(
            user_id=request.user_id,
            current_step=0,
            total_steps=len(ONBOARDING_STEPS),
            answers={},
        )
        db.add(row)
        db.commit()
        db.refresh(row)

    answers = row.answers or {}
    if request.completed:
        answers[request.step_id] = request.data or {"completed": True}
    elif request.data:
        answers[request.step_id] = request.data

    row.answers = answers
    row.current_step = len(answers)
    if len(answers) >= len(ONBOARDING_STEPS):
        row.completed = True
        row.completed_at = datetime.now()
    db.commit()

    return {
        "success": True,
        "data": {
            "progress": {
                "user_id": request.user_id,
                "completed_steps": list(answers.keys()),
                "data": answers,
                "is_completed": row.completed,
                "started_at": row.created_at.isoformat() if row.created_at else None,
            }
        }
    }


@router.get("/health-goals", summary="健康目标选项")
async def get_health_goals():
    return {"success": True, "data": {"goals": HEALTH_GOALS}}


@router.get("/constitution-quiz", summary="体质测试题目")
async def get_constitution_quiz():
    return {"success": True, "data": {"questions": CONSTITUTION_QUIZ}}


@router.post("/constitution-quiz/submit", summary="提交体质测试")
async def submit_constitution_quiz(request: ConstitutionQuizAnswerRequest):
    scores: Dict[str, int] = {}
    for q in CONSTITUTION_QUIZ:
        answer = request.answers.get(q["id"], 0)
        constitution = q["related_constitution"]
        scores[constitution] = scores.get(constitution, 0) + answer

    dominant = max(scores, key=lambda k: scores[k]) if scores else "balanced"
    return {
        "success": True,
        "data": {
            "dominant_constitution": dominant,
            "scores": scores,
            "message": f"您的主要体质倾向为：{dominant}，顺时将为您定制专属养生方案",
            "next_step": "health_goals"
        }
    }
