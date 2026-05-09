"""
顺时 — 用户反馈 API (shunshi-feedback)
用户反馈提交、问题上报、功能建议 (PostgreSQL backed)
"""
import uuid
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import UserFeedback

router = APIRouter(prefix="/api/v1/feedback", tags=["feedback"])

_FEEDBACK_TYPES = [
    {"id": "bug", "name": "Bug 反馈", "description": "功能异常、崩溃问题"},
    {"id": "suggestion", "name": "功能建议", "description": "新功能或改进建议"},
    {"id": "complaint", "name": "投诉", "description": "服务或内容不满"},
    {"id": "praise", "name": "表扬", "description": "正面反馈"},
    {"id": "other", "name": "其他", "description": "其他类型反馈"},
]


class FeedbackIn(BaseModel):
    user_id: str
    type: str = Field(default="other")
    title: Optional[str] = None
    content: str = Field(..., min_length=2)
    platform: Optional[str] = None
    app_version: Optional[str] = None


class RatingIn(BaseModel):
    user_id: str
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


class StatusUpdateIn(BaseModel):
    status: str
    admin_note: Optional[str] = None


@router.post("/submit", summary="提交反馈")
def submit_feedback(body: FeedbackIn, db: Session = Depends(get_db)):
    entry = UserFeedback(
        id=uuid.uuid4(),
        user_id=body.user_id,
        feedback_type=body.type,
        title=body.title,
        content=body.content,
        platform=body.platform,
        app_version=body.app_version,
        status="pending",
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return {
        "success": True,
        "data": {
            "feedback_id": str(entry.id),
            "status": "pending",
            "message": "感谢您的反馈！我们将在3个工作日内处理。",
        }
    }


@router.get("/{feedback_id}", summary="查询反馈状态")
def get_feedback(feedback_id: str, db: Session = Depends(get_db)):
    try:
        fid = uuid.UUID(feedback_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="反馈不存在")
    entry = db.query(UserFeedback).filter(UserFeedback.id == fid).first()
    if not entry:
        raise HTTPException(status_code=404, detail="反馈不存在")
    return {
        "success": True,
        "data": {
            "feedback_id": str(entry.id),
            "type": entry.feedback_type,
            "title": entry.title,
            "content": entry.content,
            "status": entry.status,
            "admin_note": entry.admin_note,
            "created_at": entry.created_at.isoformat(),
            "updated_at": entry.updated_at.isoformat(),
        }
    }


@router.get("/admin/list", summary="[管理] 反馈列表")
def admin_list(
    status: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    q = db.query(UserFeedback)
    if status:
        q = q.filter(UserFeedback.status == status)
    total = q.count()
    rows = q.order_by(UserFeedback.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    return {
        "success": True,
        "data": {
            "feedbacks": [
                {
                    "feedback_id": str(r.id),
                    "user_id": r.user_id,
                    "type": r.feedback_type,
                    "title": r.title,
                    "status": r.status,
                    "created_at": r.created_at.isoformat(),
                }
                for r in rows
            ],
            "total": total,
            "page": page,
            "page_size": page_size,
        }
    }


@router.patch("/admin/{feedback_id}/status", summary="[管理] 更新反馈状态")
def update_status(feedback_id: str, body: StatusUpdateIn, db: Session = Depends(get_db)):
    try:
        fid = uuid.UUID(feedback_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="反馈不存在")
    entry = db.query(UserFeedback).filter(UserFeedback.id == fid).first()
    if not entry:
        raise HTTPException(status_code=404, detail="反馈不存在")
    entry.status = body.status
    if body.admin_note:
        entry.admin_note = body.admin_note
    entry.updated_at = datetime.now()
    db.commit()
    return {
        "success": True,
        "data": {
            "feedback_id": feedback_id,
            "new_status": body.status,
            "message": "状态已更新",
        }
    }


@router.get("/types/list", summary="反馈类型")
def feedback_types():
    return {"success": True, "data": {"types": _FEEDBACK_TYPES}}


@router.post("/rating", summary="快速评分反馈")
def quick_rating(body: RatingIn, db: Session = Depends(get_db)):
    content = f"评分: {body.rating}/5" + (f" - {body.comment}" if body.comment else "")
    entry = UserFeedback(
        id=uuid.uuid4(),
        user_id=body.user_id,
        feedback_type="rating",
        content=content,
        status="pending",
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )
    db.add(entry)
    db.commit()
    return {
        "success": True,
        "data": {
            "rating": body.rating,
            "feedback_id": str(entry.id),
            "message": "感谢您的评分！",
        }
    }


# Flutter 兼容别名：/rate -> /rating
@router.post("/rate", summary="快速评分反馈（别名）", include_in_schema=False)
def quick_rating_alias(body: RatingIn, db: Session = Depends(get_db)):
    return quick_rating(body, db)

