"""
顺时 — 专家问答 API (shunshi-expert-qa)
中医专家在线问答、专家简介、问题提交 (PostgreSQL backed)
"""
import uuid
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import ExpertQuestion

router = APIRouter(prefix="/api/v1/expert-qa", tags=["expert-qa"])

_EXPERTS = {
    "expert_001": {
        "expert_id": "expert_001",
        "name": "李明华",
        "title": "主任中医师",
        "specialties": ["体质调理", "脾胃疾病", "亚健康调理"],
        "hospital": "北京中医药大学附属医院",
        "experience_years": 25,
        "rating": 4.9,
        "bio": "从事中医临床25年，擅长体质辨识与调理，发表学术论文50余篇。",
    },
    "expert_002": {
        "expert_id": "expert_002",
        "name": "王秀芳",
        "title": "副主任中医师",
        "specialties": ["妇科调理", "产后恢复", "月经不调"],
        "hospital": "上海中医药大学附属医院",
        "experience_years": 18,
        "rating": 4.8,
        "bio": "专注中医妇科18年，擅长女性体质调理与妇科疾病的中医治疗。",
    },
    "expert_003": {
        "expert_id": "expert_003",
        "name": "张建国",
        "title": "中医主治医师",
        "specialties": ["针灸推拿", "颈肩腰背痛", "亚健康"],
        "hospital": "广州中医药大学第一附属医院",
        "experience_years": 12,
        "rating": 4.7,
        "bio": "针灸推拿专家，擅长运动损伤与慢性疼痛的中医综合治疗。",
    },
}

_FAQ = [
    {"q": "什么是气虚体质？", "a": "气虚体质表现为经常感到疲倦、声音低弱、容易出汗等，需要通过饮食和运动调补元气。"},
    {"q": "如何判断自己的体质？", "a": "可通过舌象、脉象、症状综合判断，或完成我们的体质测评问卷获得初步判断。"},
    {"q": "中医养生需要坚持多久才见效？", "a": "一般轻微偏颇体质调理3个月可见效，慢性问题需要6-12个月的持续调理。"},
    {"q": "食疗能代替药物吗？", "a": "食疗适用于日常保健和轻度偏颇调理，严重疾病需在医生指导下用药，食疗作为辅助手段。"},
]


class QuestionIn(BaseModel):
    user_id: str
    question: str = Field(..., min_length=5)
    category: str = "general"
    expert_id: Optional[str] = None


class AnswerIn(BaseModel):
    expert_id: str
    answer: str = Field(..., min_length=10)


@router.get("/experts", summary="专家列表")
def list_experts():
    return {
        "success": True,
        "data": {
            "experts": list(_EXPERTS.values()),
            "total": len(_EXPERTS),
        }
    }


@router.get("/experts/{expert_id}", summary="专家详情")
def get_expert(expert_id: str):
    if expert_id not in _EXPERTS:
        raise HTTPException(status_code=404, detail="专家不存在")
    return {"success": True, "data": _EXPERTS[expert_id]}


@router.post("/questions", summary="提交问题")
def submit_question(body: QuestionIn, db: Session = Depends(get_db)):
    q = ExpertQuestion(
        id=uuid.uuid4(),
        user_id=body.user_id,
        question=body.question,
        category=body.category,
        expert_id=body.expert_id,
        status="pending",
        created_at=datetime.now(),
    )
    db.add(q)
    db.commit()
    db.refresh(q)
    return {
        "success": True,
        "data": {
            "question_id": str(q.id),
            "status": "pending",
            "message": "问题已提交，专家将在48小时内回复。",
            "expert_id": body.expert_id,
        }
    }


@router.get("/questions/{question_id}", summary="问题详情")
def get_question(question_id: str, db: Session = Depends(get_db)):
    try:
        qid = uuid.UUID(question_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="问题不存在")
    q = db.query(ExpertQuestion).filter(ExpertQuestion.id == qid).first()
    if not q:
        raise HTTPException(status_code=404, detail="问题不存在")
    return {
        "success": True,
        "data": {
            "question_id": str(q.id),
            "user_id": q.user_id,
            "question": q.question,
            "category": q.category,
            "status": q.status,
            "answer": q.answer,
            "answered_by": q.answered_by,
            "expert": _EXPERTS.get(q.answered_by or q.expert_id),
            "created_at": q.created_at.isoformat(),
            "answered_at": q.answered_at.isoformat() if q.answered_at else None,
        }
    }


@router.post("/questions/{question_id}/answer", summary="专家回答问题")
def answer_question(question_id: str, body: AnswerIn, db: Session = Depends(get_db)):
    try:
        qid = uuid.UUID(question_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="问题不存在")
    q = db.query(ExpertQuestion).filter(ExpertQuestion.id == qid).first()
    if not q:
        raise HTTPException(status_code=404, detail="问题不存在")
    if body.expert_id not in _EXPERTS:
        raise HTTPException(status_code=400, detail="专家不存在")
    q.answer = body.answer
    q.answered_by = body.expert_id
    q.status = "answered"
    q.answered_at = datetime.now()
    db.commit()
    return {
        "success": True,
        "data": {
            "question_id": question_id,
            "status": "answered",
            "expert": _EXPERTS[body.expert_id]["name"],
            "answered_at": q.answered_at.isoformat(),
        }
    }


@router.get("/faq", summary="常见问答")
def get_faq():
    return {"success": True, "data": {"faq": _FAQ, "total": len(_FAQ)}}
