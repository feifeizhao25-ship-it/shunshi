"""反思记录模块：契约以 Flutter 客户端实际调用为准（reflection_page.dart）。

- POST /api/v1/reflections  body {"mood", "question", "notes", "recorded_at"} → {"id", "saved": true}
- GET  /api/v1/reflections  → {"items": [...]}（仅本人记录，客户端暂未调用，供数据页/导出核对）
"""

import time

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..deps import current_user, get_session
from ..models import Reflection, new_id

router = APIRouter(prefix="/api/v1/reflections", tags=["reflections"])


class ReflectionBody(BaseModel):
    mood: str = Field(min_length=1, max_length=32)
    question: str = Field(default="", max_length=500)
    notes: str = Field(default="", max_length=10000)
    recorded_at: str = Field(default="", max_length=64)


@router.post("")
def create_reflection(
    body: ReflectionBody,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    item = Reflection(
        id=new_id(),
        user_id=user_id,
        mood=body.mood,
        question=body.question,
        notes=body.notes,
        recorded_at=body.recorded_at,
        created_at=int(time.time()),
    )
    session.add(item)
    session.flush()
    return {"id": item.id, "saved": True}


@router.get("")
def list_reflections(
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    rows = session.scalars(
        select(Reflection)
        .where(Reflection.user_id == user_id)
        .order_by(Reflection.created_at.desc())
        .limit(100)
    ).all()
    return {
        "items": [
            {
                "id": row.id,
                "mood": row.mood,
                "question": row.question,
                "notes": row.notes,
                "recorded_at": row.recorded_at,
                "created_at": row.created_at,
            }
            for row in rows
        ]
    }
